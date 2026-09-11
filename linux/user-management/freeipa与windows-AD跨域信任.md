# FreeIPA 与 Windows AD 跨域信任

在企业多部门协作环境中，通常由 IT 部门维护 Windows Active Directory（管理全员办公电脑、人事域账号），由研发/算力运维部门独立维护 FreeIPA（管理 Linux 物理机集群、节点权限与计算存储）。

本文记录通过 **Kerberos 跨林信任（Cross-Forest Trust）** 打通两套系统，在保持**两部门域控主权独立、权限互不干涉**的前提下，通过外部组与 HBAC 门禁规则，**仅放行指定部门/人员跨域登录指定主机**的配置方法。

[TOC]

---

## 1. 架构拓扑与设计原则

```
      【Windows 部门 (IT 运维)】                             【Linux 部门 (算力/研发运维)】
      AD 域名: CORP.EXAMPLE.COM                             IPA 域名: HPC.EXAMPLE.COM
  ┌──────────────────────────────┐                      ┌──────────────────────────────┐
  │  Windows AD 域控制器 (DC)     │                      │       FreeIPA 集群           │
  │                              │                      │                              │
  │  - 管理全员 Win 办公电脑     │                      │  - 管理 Linux 计算/存储节点  │
  │  - 管理员工账号 (张三, 李四) │                      │  - 管理 Linux 节点权限与挂载 │
  │  - 独立维护密码策略与 GPO    │                      │  - 独立维护 UID/GID/Shell    │
  └──────────────┬───────────────┘                      └──────────────┬───────────────┘
                 │                                                     │
                 └─────────────── Kerberos 跨林信任通道 (Trust) ───────┘
                                           │
                                           ▼
                            ┌─────────────────────────────┐
                            │    Linux 物理算力/登录节点  │
                            │ (通过 HBAC 白名单放行指定人)│
                            └─────────────────────────────┘
```

* **管理权责解耦**：双方均不需要将 Domain Admins 权限交给对方，彼此不需要在对方系统中创建计算机对象。
* **白名单访问控制**：信任通道建立后，默认并不放行所有人；只有通过“外部组映射 + HBAC 门禁规则”显式放行的 AD 组，其成员才能登录 Linux 节点。

---

## 2. 前置准备：网络与 DNS 条件转发

跨林信任必须依赖双向正确的 DNS 解析与关键端口互通。

### 2.1 网络端口连通
确保 FreeIPA 节点与 Windows 域控之间防火墙放行：
* Kerberos：`88/TCP,UDP`、`464/TCP,UDP`
* LDAP / LDAPS：`389/TCP`、`636/TCP`
* MS-RPC / SMB：`135/TCP`、`445/TCP`、`138/UDP`、`139/TCP`

### 2.2 DNS 互相转发

双方的 DNS 必须能够准确解析对方的域名及其 SRV 记录。

#### FreeIPA 侧添加针对 AD 的转发区域
在 FreeIPA 上执行（将 `corp.example.com` 转发给 AD 域控 IP）：

```shell
ipa dnsforwardzone-add corp.example.com --forwarder=192.168.1.10 --forward-policy=only
```

测试解析：
```shell
dig @127.0.0.1 corp.example.com
dig -t SRV _ldap._tcp.corp.example.com
```

#### Windows AD 侧添加针对 FreeIPA 的条件转发器
在 Windows 域控上打开 **DNS 管理器**：
1. 展开服务器节点，右键点击“条件转发器 (Conditional Forwarders)” -> “新建条件转发器”；
2. 输入 DNS 域名：`hpc.example.com`；
3. 输入主服务器 IP：填写 FreeIPA 服务器的 IP 地址；
4. 勾选“在 Active Directory 中存储此条件转发器”，点击确定。

---

## 3. 在 FreeIPA 侧建立跨林信任

### 3.1 安装信任组件与初始化

以 RHEL / Rocky Linux 为例，在 FreeIPA 服务器上执行：

```shell
# 安装 AD 信任扩展包
dnf install -y freeipa-server-trust-ad

# 运行初始化配置（会自动配置 Samba Winbind 后台服务用于处理 AD 凭据转换）
ipa-adtrust-install --unattended     --netbios-name=HPC     --add-sids
```

完成后获取管理员票据并验证服务：
```shell
kinit admin
ipactl status
```

### 3.2 创建信任关系

通常采用**单向信任（One-way Trust）**（FreeIPA 信任 Windows AD，即允许 AD 员工登录 Linux，但 Linux 账号不可访问 Windows 域资源，安全性更高）：

```shell
# 与 AD 建立单向信任 (需输入一次 AD 域管理员凭据用于双向握手协商)
ipa trust-add --type=ad corp.example.com --admin Administrator --password

# 验证信任状态 (应显示 Status: Verified)
ipa trust-show corp.example.com
```

---

## 4. 权限与人员控制：仅放行指定人员登录 Linux

建立信任后，不能无限制对所有 AD 用户开放。通过 **外部组（External Group）** 与 **HBAC** 实现精细化授权。

### 4.1 映射 AD 用户组到 FreeIPA

假设 Windows AD 中存在一个安全组：`IC_Designers`（芯片设计组），需要允许该组员工登录 Linux 计算节点。

```shell
# 1. 在 FreeIPA 中创建一个“外部映射组”
ipa group-add ad_ic_designers_ext --external --desc="AD IC_Designers External Map"

# 2. 将 Windows AD 的组绑定到该外部组
ipa group-add-member ad_ic_designers_ext --external "CORP\IC_Designers"

# 3. 在 FreeIPA 中创建一个原生 POSIX 组（作为衔接桥梁）
ipa group-add hpc_eda_users --desc="POSIX Group for EDA Cluster"

# 4. 将外部映射组加入到该 POSIX 组中
ipa group-add-member hpc_eda_users --groups=ad_ic_designers_ext
```

### 4.2 配置 HBAC 门禁规则

通过 HBAC 仅允许 `hpc_eda_users` 登录特定的主机组：

```shell
# 1. 禁用全员放行的默认规则
ipa hbacrule-disable allow_all

# 2. 新建规则：允许指定组 SSH 访问计算节点组
ipa hbacrule-add allow_eda_ssh --desc="Allow EDA group to SSH into compute nodes"
ipa hbacrule-add-user allow_eda_ssh --groups=hpc_eda_users
ipa hbacrule-add-host allow_eda_ssh --hostgroups=compute-nodes,login-nodes
ipa hbacrule-add-service allow_eda_ssh --hbacsvcs=sshd

# 3. 模拟测试权限
ipa hbactest --user=zhangsan@corp.example.com --host=node01.hpc.example.com --service=sshd
```

*效果：仅属于 `IC_Designers` 组的 AD 用户能成功通过 SSH 登录；其余 AD 员工（如行政、财务）即使密码输入正确，也会在 PAM 认证阶段被拦截丢弃。*

---

## 5. Linux 属性与 ID 覆盖 (ID Views)

Windows AD 默认不具备 Linux 特有的属性（UID、GID、Home 目录、默认 Shell）。

FreeIPA 默认会通过 SID 哈希算法自动为每个 AD 用户分配固定的数值型 UID/GID。若特定用户需要定制属性（如需要固定 UID 为 10001、指定 Shell 为 `/bin/tcsh`、家目录为 `/home/projects/user1`），可通过 FreeIPA 的 **ID Views (ID 视图)** 覆盖，**完全无需修改 Windows AD**：

```shell
# 为特定的 AD 用户设置在 Linux 集群内的覆盖属性
ipa idoverrideuser-add "Default Trust View" "zhangsan@corp.example.com"     --uid=10001     --gidnumber=10001     --homedir=/home/projects/zhangsan     --shell=/bin/tcsh

# 查看覆盖配置
ipa idoverrideuser-show "Default Trust View" "zhangsan@corp.example.com"
```

---

## 6. 客户端验证与排查

在已经加入 FreeIPA 的 Linux 计算节点上验证：

### 6.1 验证用户解析与属性

```shell
# 刷新 SSSD 缓存
sss_cache -E

# 检索 AD 用户（注意带域名后缀）
id zhangsan@corp.example.com
getent passwd zhangsan@corp.example.com
```

### 6.2 测试登录与票据

```shell
# 使用 AD 账号密码通过 SSH 登录
ssh zhangsan@corp.example.com@node01.hpc.example.com

# 检查登录后的 Kerberos 票据
klist
```

### 6.3 常见问题排查

1. **时钟偏差错误 (`Clock skew too great`)**：
   * Kerberos 要求 FreeIPA 与 Windows 域控的时钟偏差 ≤ 5 分钟。确保两边节点均配置了相同的上游 Chrony/NTP 时钟源。
2. **找不到用户 (`User not found`)**：
   * 检查 Linux 客户端节点的 `/etc/sssd/sssd.conf`，确保已启用信任域发现：
     ```ini
     [domain/hpc.example.com]
     subdomain_inherit = passkey_child_opts
     ```
3. **HBAC 鉴权失败 (`System error / Access denied`)**：
   * 检查节点安全日志 `/var/log/secure` 是否输出 `pam_sss(sshd:auth): Access denied for user ... by HBAC rules`，使用 `ipa hbactest` 检查用户组与主机组匹配情况。
