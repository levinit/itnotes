# LDAP客户端接入

在 Linux 系统中，将主机作为客户端接入 LDAP 目录服务（如 OpenLDAP 或 FreeIPA），推荐使用 **SSSD (System Security Services Daemon)** 进行统一身份验证、凭据本地缓存以及与 NSS / PAM 的集成。

[TOC]

---

## 1. 使用 SSSD 接入标准 LDAP

### 1.1 安装依赖软件包

以 RHEL / Rocky Linux 为例：

```bash
dnf install -y sssd sssd-client sssd-tools openldap-clients oddjob oddjob-mkhomedir authselect
```

Debian / Ubuntu 系列：
```bash
apt install -y sssd sssd-tools libpam-sss libnss-sss libpam-oddjob-mkhomedir
```

### 1.2 配置 PAM 与 NSS 认证选择器 (authselect)

在 RHEL / Rocky 8/9 系统中，`authconfig` 已由 `authselect` 取代。一条命令即可自动配置 `/etc/pam.d/` 和 `/etc/nsswitch.conf`，并启用用户初次登录自动创建家目录：

```bash
# 启用 sssd 配置文件，并开启自动创建家目录支持
authselect select sssd with-mkhomedir --force

# 启动并开机自启 oddjobd (用于生成家目录)
systemctl enable --now oddjobd
```

### 1.3 编写 SSSD 配置文件 (`/etc/sssd/sssd.conf`)

创建并编辑 `/etc/sssd/sssd.conf`：

```ini
[sssd]
services = nss, pam, autofs
domains = default

[domain/default]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
autofs_provider = ldap

# LDAP 服务器地址与基础 DN
ldap_uri = ldap://ldap.example.com/
ldap_search_base = dc=example,dc=com

# 安全传输 (启用 TLS/SSL 时配置)
ldap_id_use_start_tls = True
ldap_tls_cacert = /etc/openldap/certs/ca.crt
ldap_tls_reqcert = demand

# 离线缓存与用户属性映射
cache_credentials = True
ldap_schema = rfc2307bis
enumerate = False

[nss]
homedir_substring = /home

[pam]
```

### 1.4 设置文件权限与启动服务

SSSD 对配置文件权限有严格要求，权限不正确服务会拒绝启动：

```bash
chmod 600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf

systemctl enable --now sssd
```

---

## 2. FreeIPA 客户端接入

如果服务端是 FreeIPA，无需手动编写 `sssd.conf` 和调用 `authselect`，直接使用官方提供的 `ipa-client-install` 一键完成：

```bash
# 安装客户端包
dnf install -y freeipa-client

# 一键加入域 (自动配置 DNS、Kerberos、SSSD、PAM、自动建家目录)
ipa-client-install --mkhomedir --enable-dns-updates --unattended     --server=ipa.example.com     --domain=example.com     --realm=EXAMPLE.COM     -p admin -w 'SecretPassword'
```

---

## 3. 用户自主修改密码

客户端用户若需修改自己在 LDAP 上的密码，可直接使用系统 `passwd`（通过 PAM 传递），或者使用 LDAP 命令行工具：

```bash
ldappasswd -H ldap://ldap.example.com -x -D "uid=user01,ou=people,dc=example,dc=com" -W -A -S
```

---

## 4. 常见问题与排查

### 4.1 SSSD 缓存导致用户信息未即时更新

SSSD 默认会在本地缓存用户与用户组信息，若在服务端修改了用户属性或权限，客户端未生效时需手动刷新缓存：

```bash
# 清除全部 SSSD 缓存
sss_cache -E

# 仅清除指定用户的缓存
sss_cache -u <username>

# 清除指定用户组的缓存
sss_cache -g <groupname>

# 重启 SSSD 重新加载
systemctl restart sssd
```

可在 `/etc/sssd/sssd.conf` 中调整缓存超时时间（默认 5400 秒）：
```ini
entry_cache_timeout = 600
```

### 4.2 getent passwd 无法列出所有用户 (枚举问题)

* **现象**：`getent passwd <username>` 能查到指定用户，但单纯执行 `getent passwd` 无法显示 LDAP 中的用户列表。
* **原因**：默认情况下 `sssd.conf` 中 `enumerate = False`，用户信息枚举功能是关闭的。在大规模集群或数千用户的环境中，枚举操作会引发大量网络查询甚至导致 SSSD 响应变慢，因此生产环境默认建议关闭枚举。
* **解决**：若在测试环境确实需要列出所有用户，可在 `[domain/default]` 节中配置：
  ```ini
  enumerate = True
  ```
  修改后执行 `sss_cache -E && systemctl restart sssd` 生效。

### 4.3 检查 /etc/nsswitch.conf

验证系统是否优先通过本地文件查找，再通过 SSSD 查找：

```text
passwd:     files sss
group:      files sss
shadow:     files sss
```

### 4.4 排查 SSSD 运行日志

当认证异常时，可调大 SSSD 日志级别进行定位：

在 `/etc/sssd/sssd.conf` 的 `[sssd]` 与 `[domain/default]` 下增加：
```ini
debug_level = 6
```
日志保存在 `/var/log/sssd/` 目录下（如 `sssd_default.log`、`sssd_nss.log`、`sssd_pam.log`）。
