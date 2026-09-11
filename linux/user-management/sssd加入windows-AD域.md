# SSSD 加入 Windows AD 域

在企业网络环境中，通常使用微软 Active Directory (AD) 作为集中账号源。Linux 主机通过 **realmd + SSSD + adcli** 工具链加入 Windows AD 域，实现使用 AD 域账号密码统一登录 Linux 系统，并支持离线凭据缓存与动态权限控制。

[TOC]

---

## 1. 准备工作

### 1.1 DNS 解析
Linux 客户端必须能够正确解析 AD 域控的域名与 SRV 记录。将主机的 DNS 指向 Windows AD 域控服务器 IP：

```shell
# 测试能否解析域控
ping -c 2 ad.company.com

# 检查 SRV 记录
dig -t SRV _ldap._tcp.ad.company.com
```

### 1.2 时间同步
Kerberos 认证要求客户端与 AD 域控的时钟偏差必须在 5 分钟以内。确保使用 Chrony 同步时间：

```shell
# 检查同步状态
chronyc sources
systemctl enable --now chronyd
```

### 1.3 防火墙端口
确保客户端与 AD 域控之间的关键端口连通：
* Kerberos: 88, 464 (TCP/UDP)
* LDAP: 389, 636 (TCP)
* MS-RPC / SMB: 135, 445 (TCP)

---

## 2. 软件包安装与加入 AD 域

使用 `adcli` 作为加域后端组件，无需安装额外的 Samba Winbind 组件。

### 2.1 安装软件包

```shell
dnf install -y realmd sssd adcli oddjob oddjob-mkhomedir krb5-workstation
```

### 2.2 探测与加入域

```shell
# 1. 探测 AD 域信息
realm discover ad.company.com

# 2. 交互式加入 AD 域（使用具有加域权限的 AD 账号）
realm join ad.company.com -U Administrator --verbose

# 也可以通过标准输入非交互式传递密码：
# echo "YourPassword" | realm join ad.company.com -U Administrator --verbose
```

### 2.3 权限控制与验证

```shell
# 查看当前加入的域状态
realm list

# 默认允许所有域用户登录。如需限制仅特定组登录：
# 1. 拒绝所有人登录
realm deny --all

# 2. 仅允许指定的 AD 安全组登录
realm permit -g "IC_Designers@ad.company.com"

# 3. 允许特定用户登录
realm permit zhangsan@ad.company.com

# 验证用户信息（支持带域名后缀查询）
id zhangsan@ad.company.com
```

---

## 3. SSSD 常用配置 (`/etc/sssd/sssd.conf`)

`realm join` 会自动生成 `/etc/sssd/sssd.conf`。根据实际运维习惯，可调整如下常用参数：

```ini
[sssd]
domains = ad.company.com
config_file_version = 2
services = nss, pam

[domain/ad.company.com]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = AD.COMPANY.COM
realmd_tags = manages-system joined-with-adcli
id_provider = ad
access_provider = ad

# 用户名格式控制：
# 设置为 False 时，登录与查询可直接使用短用户名（如 zhangsan），无需输入 @ad.company.com 后缀
use_fully_qualified_names = False

# 家目录路径规则：%u 表示用户名，%d 表示域名
# fallback_homedir = /home/%u@%d
fallback_homedir = /home/%u

# 自动将 AD 的 SID 映射为固定数值型 UID/GID
ldap_id_mapping = True
```

修改配置文件后需确保权限正确并重启服务：
```shell
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd
```

---

## 4. 自动创建家目录配置

如果家目录未通过 NFS/Lustre 等共享存储集中挂载，需在用户首次登录时自动在本地生成家目录：

```shell
# 开启 PAM 自动创建家目录功能
authselect enable-feature with-mkhomedir

# 启动 oddjob 守护进程
systemctl enable --now oddjobd
```

---

## 5. 常见问题排查

### 5.1 SASL(-1): generic failure (反向 DNS 解析校验失败)
* **现象**：`Couldn't authenticate to active directory: SASL(-1): generic failure`
* **原因**：Kerberos 默认会尝试进行反向 DNS (rDNS) 校验，当内网缺少 PTR 反向解析记录时报错。
* **解决**：在 `/etc/krb5.conf` 的 `[libdefaults]` 中关闭反向解析校验：
  ```ini
  [libdefaults]
  default_realm = AD.COMPANY.COM
  rdns = false
  ```
  修改后重启 SSSD：`systemctl restart sssd`。

### 5.2 GSSAPI 错误 (Server not found in Kerberos database)
* **原因**：SSSD 配置中如果显式指定了 `ad_server = IP`，可能导致 Kerberos SPN 服务主体名称匹配失败。
* **解决**：在 `/etc/sssd/sssd.conf` 中注释或删除 `ad_server` 行，让 SSSD 依靠 DNS SRV 记录自动发现域控；同时确保 `/etc/krb5.conf` 中包含 `rdns = false`。

### 5.3 用户信息未即时刷新
* **解决**：SSSD 本地存在缓存，AD 侧改动后若需立即生效，执行缓存清理：
  ```shell
  sss_cache -E
  systemctl restart sssd
  ```

---

## 6. 自动化批量加域脚本示例

适用于物理机或虚机批量交付时的一键加域：

```shell
#!/bin/bash
set -e

AD_DOMAIN="ad.company.com"
AD_SERVER_IP="192.168.1.10"
AD_ADMIN_USER="Administrator"
AD_ADMIN_PASS="YourPassword"
DEFAULT_SHELL="/bin/bash"

# 1. 安装必要依赖（采用 adcli，无 winbind 冲突）
dnf install -y realmd sssd adcli oddjob oddjob-mkhomedir krb5-workstation

# 2. 配置 DNS 指向域控
if ! grep -q "$AD_SERVER_IP" /etc/resolv.conf; then
    echo "nameserver $AD_SERVER_IP" >> /etc/resolv.conf
fi

# 3. 避免反向 DNS 校验失败
mkdir -p /etc/krb5.conf.d
cat <<EOF > /etc/krb5.conf.d/ad_rdns.conf
[libdefaults]
rdns = false
EOF

# 4. 非交互式加入 AD 域
echo "$AD_ADMIN_PASS" | realm join "$AD_DOMAIN" -U "$AD_ADMIN_USER" --verbose

# 5. 调整 SSSD 参数（支持短用户名、自定义 Shell）
sed -i -E   -e "s|default_shell = .*|default_shell = $DEFAULT_SHELL|"   -e "s|use_fully_qualified_names = .*|use_fully_qualified_names = False|"   -e "s|fallback_homedir = .*|fallback_homedir = /home/%u|"   /etc/sssd/sssd.conf

# 6. 开启自动创建家目录
authselect enable-feature with-mkhomedir
systemctl enable --now oddjobd
systemctl restart sssd

echo "Successfully joined $AD_DOMAIN"
```
