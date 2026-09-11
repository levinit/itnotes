# MySQL 高可用与读写分离

在私有化基础设施与容器环境中，关系型数据库广泛承载着关键系统（如作业调度系统后台、监控审计、内部研发平台等）。此类业务对数据强一致性（RPO=0）与故障自愈（RTO 秒级）有明确要求。

本文记录在物理机/虚拟机及容器环境中构建 MySQL 高可用与读写分离的标准架构与配置。

[TOC]

---

## 1. 架构设计

集群采用官方 **InnoDB Cluster (MySQL Group Replication / MGR)** 配合 **ProxySQL**，提供强一致性与透明读写分离。

```
                    ┌────────────────────────────────────────────────────────┐
                    │                      业务应用程序                      │
                    └───────────┬────────────────────────────────┬───────────┘
                                │ (写请求: 端口 6033)            │ (读请求: 端口 6033)
                                ▼                                ▼
                    ┌────────────────────────────────────────────────────────┐
                    │               读写分离中间件 (ProxySQL)                │
                    │       规则路由 / 连接池管理 / 自动识别集群主从拓扑     │
                    └───────────┬────────────────────────────────┬───────────┘
                                │ (写入 Primary)                 │ (轮询读取 Replicas)
                                ▼                                ▼
       ┌─────────────────────────────────────────────────────────────────────────────┐
       │                          MySQL 8.0/8.4 InnoDB Cluster                       │
       │                                                                             │
       │  ┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────────┐ │
       │  │    Node 1 (Primary)  │  │   Node 2 (Secondary) │  │ Node 3 (Secondary)│ │
       │  │      Read/Write      │  │       Read-Only      │  │     Read-Only      │ │
       │  └──────────┬───────────┘  └──────────┬───────────┘  └──────────┬─────────┘ │
       │             │                         │                         │           │
       │             └────────────── Paxos 分布式通信组 (MGR) ─────────────┘           │
       │                              (强一致共识机制)                               │
       └─────────────────────────────────────────────────────────────────────────────┘
```

* **高可用机制**：基于 Paxos 分布式共识协议（少数服从多数）。三节点集群可容忍单节点宕机。主节点发生故障时，剩余节点自动投票选举新主，避免脑裂。
* **读写分离机制**：前端挂载 ProxySQL，通过查询规则将写入事务发往 Primary，只读查询路由至 Secondary。

---

## 2. 物理机 / 虚机环境部署 (InnoDB Cluster + ProxySQL)

### 2.1 MySQL 节点基础配置 (`/etc/my.cnf`)

三个节点配置一致的集群参数，仅 `server_id` 与绑定 IP 不同：

```ini
[mysqld]
server_id = 101                    # Node2 设为 102, Node3 设为 103
gtid_mode = ON
enforce_gtid_consistency = ON
master_info_repository = TABLE
relay_log_info_repository = TABLE
binlog_checksum = NONE
log_bin = mysql-bin
log_slave_updates = ON
binlog_format = ROW

# MGR 通信配置
plugin_load_add = group_replication.so
group_replication_group_name = "8a2f643e-b6a8-4e3a-9694-000000000001"
group_replication_start_on_boot = OFF
group_replication_local_address = "192.168.1.101:33061"
group_replication_group_seeds = "192.168.1.101:33061,192.168.1.102:33061,192.168.1.103:33061"
group_replication_bootstrap_group = OFF
group_replication_single_primary_mode = TRUE   # 单主模式
group_replication_enforce_update_everywhere_checks = FALSE
```

### 2.2 使用 MySQL Shell (mysqlsh) 构建集群

通过 `mysqlsh` 的 AdminAPI 完成自动化组网：

```javascript
// 连接至 node1: mysqlsh --uri root@192.168.1.101:3306

// 检查各节点配置合规性
dba.checkInstanceConfiguration('root@192.168.1.101:3306')
dba.checkInstanceConfiguration('root@192.168.1.102:3306')
dba.checkInstanceConfiguration('root@192.168.1.103:3306')

// 创建集群
cluster = dba.createCluster('cluster_prod');

// 加入从节点 (使用 Clone 插件自动同步全量存量数据)
cluster.addInstance('root@192.168.1.102:3306', {recoveryMethod: 'clone'});
cluster.addInstance('root@192.168.1.103:3306', {recoveryMethod: 'clone'});

// 查看集群状态
cluster.status();
```

### 2.3 读写分离中间件 ProxySQL 配置

安装并启动 ProxySQL：
```bash
dnf install -y proxysql
systemctl enable --now proxysql
mysql -u admin -padmin -h 127.0.0.1 -P 6032 --prompt='ProxySQLAdmin> '
```

配置后端节点与路由规则：
```sql
-- 1. 添加后端 MySQL 实例 (10 为写组，20 为读组)
INSERT INTO mysql_servers (hostgroup_id, hostname, port, max_connections) VALUES
(10, '192.168.1.101', 3306, 500),
(20, '192.168.1.102', 3306, 500),
(20, '192.168.1.103', 3306, 500);
LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;

-- 2. 启用 MGR 拓扑感知 (自动维护 Primary 与 Secondary 角色变更)
INSERT INTO mysql_group_replication_hostgroups (writer_hostgroup, backup_writer_hostgroup, reader_hostgroup, offline_hostgroup, active, max_writers)
VALUES (10, 11, 20, 99, 1, 1);
LOAD MYSQL GROUP REPLICATION TO RUNTIME; SAVE MYSQL GROUP REPLICATION TO DISK;

-- 3. 配置读写分离路由规则
-- 规则 A: 带有 FOR UPDATE 的 SELECT 语句强制路由到写库 (Hostgroup 10)
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply_empty)
VALUES (1, 1, '^SELECT.*FOR UPDATE', 10, 1);

-- 规则 B: 常规 SELECT 语句路由到从库组 (Hostgroup 20)
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply_empty)
VALUES (2, 1, '^SELECT', 20, 1);

LOAD MYSQL QUERY RULES TO RUNTIME; SAVE MYSQL QUERY RULES TO DISK;
```

业务端统一连接 ProxySQL 的服务端口 `6033`，中间件自动完成透明路由与故障切换。

---

## 3. 容器与 Kubernetes 环境部署 (MySQL Operator)

在容器化环境中，MySQL 集群通过 **MySQL Operator** 进行声明式编排管理（如 Oracle 官方 MySQL Operator 或 Percona PXC Operator）。

### 3.1 核心机制
* **StatefulSet 管理存储与网络**：每个 Pod 拥有固定的 DNS 标识与独立的持久卷 (PVC)。
* **Sidecar 拓扑感知**：Operator 注入的 Sidecar 容器监听集群状态并自动维护共识配置。
* **暴露 Service 访问入口**：
  * `cluster-primary`：只指向当前处于写角色的 Pod。
  * `cluster-replicas`：负载均衡到所有只读 Pod。

### 3.2 声明式配置样例 (基于官方 MySQL Operator)

```yaml
apiVersion: mysql.oracle.com/v2
kind: InnoDBCluster
metadata:
  name: prod-mysql-cluster
  namespace: database
spec:
  instances: 3                      # 编排 3 节点 MGR
  router:
    instances: 2                    # 部署读写路由代理
  secretName: mysql-secret
  edition: community
  version: 8.0.36
  datadirVolumeClaimTemplate:
    spec:
      storageClassName: local-storage
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 300Gi
  mycnf: |
    [mysqld]
    max_connections=1500
    innodb_buffer_pool_size=16G
```

---

## 4. 运维注意事项

1. **心跳超时与节点踢出保护**：
   * MGR 依赖低延迟内网通信。在网络易发生波动的环境中，可调整心跳超时参数：
     ```sql
     SET GLOBAL group_replication_member_expel_timeout = 5;
     ```
     防止瞬时抖动导致正常节点被误剔除。
2. **事务体积限制**：
   * MGR 在事务提交阶段需要经过组内认证，单次大事务（如一次性更新数百万行记录）会阻塞组通信队列。批量操作应分批次提交。
3. **备份方案**：
   * 高可用无法防止误操作删库，依然需要定期备份。配置定时物理热备（如使用 `Percona XtraBackup`），将全量与增量备份定期归档至异机存储。
