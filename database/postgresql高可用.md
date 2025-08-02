

# PostgreSQL 主从复制（Streaming Replication）

```text
             WAL日志流（流复制）
[Primary 主库]  ───────────►  [Standby 从库]
       │                          │
       └────客户端读写            └──（可选：只读查询）
```



## 主库配置

编辑 `postgresql.conf`：

```conf
# 开启WAL日志
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/archive/%f'
max_wal_senders = 10
wal_keep_size = 512MB

# 建议开启日志
log_connections = on
log_disconnections = on
```

编辑 `pg_hba.conf`，允许从库连接复制：

```conf
# host replication 用户 IP段 认证方式
host replication repl_user 192.168.1.0/24 md5
```

创建复制用户：

```bash
psql -U postgres
CREATE ROLE repl_user REPLICATION LOGIN ENCRYPTED PASSWORD 'your_password';
```



##  从库准备

在从库上执行（清空已有数据）：

```bash
rm -rf /var/lib/postgresql/data/*
pg_basebackup -h 主库IP -U repl_user -D /var/lib/postgresql/data --wal-method=stream -P
```

创建 `standby.signal` 文件（表示从库身份）：

```bash
touch /var/lib/postgresql/data/standby.signal
```

配置 `postgresql.conf`：

```conf
primary_conninfo = 'host=主库IP port=5432 user=repl_user password=your_password'
```

启动从库

```bash
systemctl start postgresql
```

现在从库会通过 WAL 流复制主库的数据，**从库默认是只读的**。



# 高可用配置（HA）方案）

主从复制只解决数据复制问题，并 **不具备自动切换能力**，主库宕机会导致整个服务不可用，因此需要引入 **高可用机制**。



## Patroni + etcd + HAProxy（推荐）

| 组件           | 作用                               |
| -------------- | ---------------------------------- |
| **Patroni**    | 管理 PostgreSQL 主从状态、自动选主 |
| **etcd**       | 存储集群状态（选主一致性协议）     |
| **HAProxy**    | 作为代理层，自动路由到主库         |
| **Keepalived** | 提供高可用虚拟 IP（VIP）           |

架构：

```text
                     +---------------------+
                     |     etcd Cluster     |
                     +---------------------+
                          ▲         ▲
                 +--------+         +--------+
                 |                           |
         +---------------+         +---------------+
         |  Patroni 主库 |         | Patroni 从库  |
         +---------------+         +---------------+
                 ▲                           ▲
                 +-----------+ +-------------+
                             |
                       +-------------+
                       |   HAProxy   |
                       +-------------+
                             ▲
                        [客户端连接]
```



| 目标         | 建议方式                            |
| ------------ | ----------------------------------- |
| 主从复制     | Streaming Replication               |
| 自动故障转移 | Patroni + etcd + HAProxy            |
| 高可用地址   | HAProxy + Keepalived (VIP)          |
| 数据备份     | pg_basebackup / pgBackRest / Barman |
| 防止单点故障 | etcd + 多从库 + HAProxy健康检查     |



### 1. 部署 ETCD 集群

1~3 台机器，配置参考：

```bash
etcd --name node1 --initial-advertise-peer-urls http://localhost:2380 \
     --listen-peer-urls http://localhost:2380 \
     --listen-client-urls http://0.0.0.0:2379 \
     --advertise-client-urls http://localhost:2379 \
     --initial-cluster-token etcd-cluster-1 \
     --initial-cluster node1=http://localhost:2380 \
     --initial-cluster-state new
```



### 2. 配置 Patroni（每台 PostgreSQL 节点）

配置文件示例 `/etc/patroni.yml`：

```yaml
scope: postgres_cluster
name: node1

etcd:
  host: 127.0.0.1:2379

postgresql:
  data_dir: /var/lib/postgresql/data
  bin_dir: /usr/lib/postgresql/14/bin
  authentication:
    superuser:
      username: postgres
      password: your_password
    replication:
      username: repl_user
      password: your_password
  parameters:
    wal_level: replica
    hot_standby: "on"
    max_wal_senders: 10
    wal_keep_size: 512MB

bootstrap:
  initdb:
    - encoding: UTF8
    - locale: en_US.UTF-8
    - data-checksums
  users:
    postgres:
      password: your_password
  dcs:
    ttl: 30
    loop_wait: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        archive_mode: "on"
        archive_command: "cp %p /var/lib/postgresql/archive/%f"

restapi:
  listen: 127.0.0.1:8008
  connect_address: 127.0.0.1:8008

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
```

启动：

```bash
patroni /etc/patroni.yml
```



### 3. 配置 HAProxy

```bash
# /etc/haproxy/haproxy.cfg

frontend pgsql
    bind *:5432
    default_backend postgresql_backend

backend postgresql_backend
    option httpchk GET /master
    server node1 192.168.1.101:5432 check port 8008
    server node2 192.168.1.102:5432 check port 8008
```

让 HAProxy 只把流量导向主节点（Patroni 提供 HTTP 检查 `/master`）。



### 4. Keepalived 提供 VIP（可选）

设置一个虚拟 IP，保证客户端连接固定地址，HAProxy 切换内部真实节点。