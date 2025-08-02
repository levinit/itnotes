https://www.freeipa.org/page/Quick_Start_Guide

IPA的RedHat企业版[IPA- Red Hat Identity Management](https://www.google.com/search?client=safari&rls=en&q=redhat+IPA&ie=UTF-8&oe=UTF-8)

# 服务端

## 1.1 环境准备

以RHEL/CentOS为例

### DNS

服务器主机必须正确配置 DNS，无论 DNS 服务器是在IPA中集成还是外部托管。

如果当前IPA服务器在上游DNS服务中还有解析，或者说后续安装使用IPA集成的DNS，先配置`/etc/hosts`：

```shell
10.1.1.251. ipa-server.grp1.hpc  ipa-server
```

> 生产环境中IPA使用DNS是必须的：
>
> - **服务发现**：FreeIPA依赖DNS的SRV记录定位Kerberos KDC、LDAP服务器等关键服务。
> - **反向解析**：FreeIPA的证书签发和主机验证需要双向解析（正向A记录和反向PTR记录）。
> - **维护成本**：节点扩容或IP变更时需手动同步所有主机的hosts文件，易出错且不适用于动态环境。
> - **安全风险**：硬编码IP可能导致DNS欺骗攻击，而集成DNS支持DNSSEC（DNS安全扩展）。

如果已经有上游DNS服务可以解析当前主机域名，要配置好上游DNS服务。

可以修改`/etc/resolv.conf`增加解析：

```shell
nameserver <DNS_addr>
```

不过在大多数现代 Linux下修改该文件可能只能临时使用，因为它经常特定的网络管理组件覆盖，无法持久化。

不同网络管理组件的持久化配置：

-  `systemd-resolved`

  ```shell
  mkdir -p /etc/systemd/resolved.conf.d
  vim /etc/systemd/resolved.conf.d/dns.conf
  ```

  在该文件中配置：

  ```shell
  [Resolve]
  DNS=127.0.0.1
  Domains=~grp1.hpc
  FallbackDNS=<your upstream DNS addr>
  ```

- `NetworkManager`

  ```shell
  nmcli connection show.          #查看所有网卡连接配置
  nmcli connection modify <连接名> ipv4.dns "<DNS addr>"
  ```

-  `dhclient` / `nmcli` / `ifup` 脚本



### 主机名

主机名必须是完全限定域名，如 `server.example.com`。

如果按以上方式设置了hosts，主机名也可以只设置为短主机名，只是要确保`hostname -f`输出的一定是完全限定的域名。



### 时间同步服务

IPA集成了NTP服务，如果不使用IPA管理时间同步，需要自行配置：

```shell
sudo dnf install chrony -y
sudo systemctl enable --now chronyd
timedatectl set-ntp true
#chrony的具体配置省略......
```



### 所需端口

**需要确保要使用到的服务所需端口没有被其他程序占用**。

- 身份管理服务的端口，需要开放防火墙：

  | 服务       | 端口     | 协议       |
  | ---------- | -------- | ---------- |
  | HTTP/HTTPS | 80, 443  | TCP        |
  | LDAP/LDAPS | 389, 636 | TCP        |
  | Kerberos   | 88, 464  | TCP 和 UDP |
  | DNS        | 53       | TCP 和 UDP |
  | NTP        | 123      | UDP        |

  如果使用firewalld，可以添加freeipa相关服务即可：

  ```shell
  firewall-cmd --add-service=freeipa-ldap --add-service=freeipa-ldaps --permanent
  firewall-cmd --add-service=freeipa-ldap --add-service=freeipa-ldaps
  ```


- 可选的服务的端口，如果让IPA服务端启用这些服务的话，需要开发防火墙：

  - DNS：53/TCP  53/UDP
  - NTP：123/UDP

  如果使用firewalld，可以添加freeipa相关服务即可：

  ```shell
  firewall-cmd --add-service=dns --add-service=ntp --permanent --permanent
  firewall-cmd --add-service=dns --add-service=ntp --permanent
  ```



- 仅本地使用的服务端口，不要开放防火墙：

  - Tomcat - PKI：支持CA的IPA副本使用端口8005,8009,8080,8443 /TCP

  - kadmind：KDC管理使用端口749/TCP



## 1.2 安装 FreeIPA Server

```shell
# 安装 FreeIPA 服务端
sudo dnf install -y freeipa-server freeipa-server-dns

# 运行安装向导（交互式）
# --no-ntp不使用IPA设置ntp
# --no-ui-redirect不让IPA配置的httpd服务的根路径跳到ipa/ui路径（这样可以在80/443处理其他web服务）
sudo ipa-server-install --no-ntp --no-ui-redirect

# 非交互安装（无人值守）需要使用-U/--unattended选项，并且必须给定必要的选项才行，示例：
ipa-server-install --realm=GRP1.HPC --domain=grp1.hpc --ds-password=pwd_admin_ --admin-password=pwd_admin_ --mkhomedir --ssh-trust-dns --setup-dns --forwarder=192.168.122.247 --no-host-dns --no-ntp --no-ui-redirect --unattended
```

安装向导选项示例：

> ```shell
> Do you want to configure integrated DNS (BIND)? [no]: no
> Server host name [ipa-server.example.com]: [Enter]
> Please confirm the domain name [example.com]: [Enter]
> Please provide a realm name [EXAMPLE.COM]: [Enter]
> Directory Manager password: [输入密码]
> IPA admin password: [输入密码]
> Do you want to configure chrony with NTP server? [yes]: [Enter]
> Continue to configure the system with these values? [no]: yes
> ```

DNS服务可以使用ipa server的bind或者自建其他dns服务（例如dnsmasq），或使用已有的DNS服务器。

安装完成后，会输出管理 Web UI 地址（如 `https://ipa-server.example.com`），在改地址的`/ipa/ui`路径即IPA的web管理平台，使用amdin用户及其密码登录。



建议在配置完成后禁止admin帐号作为系统帐号登录：

```shell
ipa user-mod admin --loginshell=/sbin/nologin
ipa user-mod admin --homedir=/var/empty
```



## 1.3 验证服务

```shell
# 检查服务状态
sudo systemctl status ipa
ipactl status  #查看所有ipa server相关服务的运行状态

# 测试 Kerberos 认证
kinit admin
klist
```



## 1.4 添加副本节点（可选）

FreeIPA **支持多主复制（Multi-Master Replication）**，本质上就是一种 **"双活"或"多活"** 的机制，所有节点均可同时处理读写请求，数据通过实时同步保持一致。需要：

- **所有节点** 共享相同的 Kerberos Realm（如 `EXAMPLE.COM`）
- **DNS 轮询** 或 **负载均衡器** 对外提供服务



前置条件：

- **至少 2 台服务器**（RHEL/CentOS 8/9）
- **时间同步**（所有节点时间差 ≤ 5 分钟）
- **DNS 解析**（所有节点能互相解析主机名）
- **主节点已安装 FreeIPA**



1. 参照前文方法在副本节点安装freeipa server

2. 副本节点加入

   ```shell
   # 在副本节点（ipa2.example.com）执行：
   sudo ipa-replica-install \
       --principal admin \
       --admin-password admin密码 \
       --setup-dns \
       --setup-ca \
       --no-host-dns
   ```

   选项说明：

   |        参数        |                作用                 |
   | :----------------: | :---------------------------------: |
   |   `--principal`    |  主节点的管理员账号（如 `admin`）   |
   | `--admin-password` |         主节点的管理员密码          |
   |   `--setup-dns`    |            同步 DNS 记录            |
   |    `--setup-ca`    | 复制 CA 证书（如果主节点启用了 CA） |

   移除副本节点， 需要在主节点执行：

   ```shell
   ipa-replica-manage del ipa3.example.com
   ```

   

3. 验证副本同步

   ```shell
   # 在主节点检查副本状态
   ipa-replica-manage list
   
   # 在副本节点测试 Kerberos
   kinit admin
   klist
   
   # 任意节点执行，查看所有副本
   ipa-replica-manage list
   
   # 检查复制状态（应显示所有节点健康）
   ipa-csreplica-manage status
   ```



4. 配置 DNS 负载均衡

   - 方案 1：DNS 轮询（简单）

     在 DNS 服务器（如 BIND）中为 `ipa.example.com` 添加多个 A 记录：

     ```shell
     ipa.example.com.    IN    A    192.168.1.10  # ipa1
     ipa.example.com.    IN    A    192.168.1.11  # ipa2
     ```

   - 方案 2：负载均衡器（推荐）

     使用 **HAProxy** 或 **Nginx** 对 FreeIPA 服务（HTTP/HTTPS/LDAP/Kerberos）做负载均衡：

     ```shell
     # HAProxy 示例配置（/etc/haproxy/haproxy.cfg）
     frontend freeipa_https
         bind *:443
         default_backend ipa_servers
     
     backend ipa_servers
         balance roundrobin
         server ipa1 192.168.1.10:443 check
         server ipa2 192.168.1.11:443 check
     ```



# 客户端

## 安装准备

- DNS

  为客户端设置DNS以保证客户端能解析服务端（临时测试也可以设置hosts，但最终生产环境必须配置DNS）

  参看服务端的DNS配置。如果IPA集成了DNS，将IPA的网卡地址作为DNS服务器地址加入即可。

  ```shell
  dig @<IPA server IP>  <IPA server的全限定主机名>   #测试
  #配置DNS ...
  ```

- 主机名

  参看服务端配置的要求

- 时间同步



## 使用ipa-client

1. 安装ipa-client及相关依赖

   ```shell
   # 安装必要软件
   sudo dnf install -y freeipa-client oddjob-mkhomedir
   ```
   
2. 加入freeIPA域

   - 交互式加入

     > ```shell
     > Continue to configure the system with these values? [no]: yes
     > User authorized to enroll computers: admin
     > Password for admin@EXAMPLE.COM: [输入密码]
     > ```

   - 非交互式

     ```shell
     # 1. 创建临时密码文件（权限限制为 root）
     echo "YourAdminPassword" > /tmp/ipa-password
     chmod 600 /tmp/ipa-password
     
     # 2. 非交互式加入
     sudo ipa-client-install \
         --domain=example.com \
         --server=ipa-server.grp.hpc \
         --realm=GRP1.HPC \
         --principal=admin \
         --password=<password_of_admin> \
         --mkhomedir \
         --enable-dns-updates \
         --unattended
     
     # 3. 删除密码文件
     rm -f /tmp/ipa-password
     ```
     
     选项：
     
     | `--domain`     | FreeIPA 域名（如 `example.com`）                     |
     | -------------- | ---------------------------------------------------- |
     | `--server`     | FreeIPA 服务器主机名（如 `ipa-server.example.com`）  |
     | `--realm`      | Kerberos Realm（通常是大写的域名，如 `EXAMPLE.COM`） |
     | `--principal`  | 有权限加入客户端的用户（如 `admin`）                 |
     | `--password`   | 管理员密码（明文，需注意安全）                       |
     | `--mkhomedir`  | 自动创建用户家目录                                   |
     | `--unattended` | 非交互模式，跳过所有确认提示                         |



3. 验证客户端

   ```shell
   # 检查用户信息
   id admin@example.com
   
   # 测试登录
   su - admin@example.com
   
   # 检查 Kerberos 票据
   kinit admin
   klist
   
   # 查看 FreeIPA 用户信息
   id admin@example.com
   
   # 检查 SSSD 状态
   systemctl status sssd
   ```

   

## 使用 `realmd`加入

1. 安装 `realmd` 和依赖：

   ```shell
   sudo dnf install -y realmd sssd oddjob oddjob-mkhomedir
   ```

2. 加入 FreeIPA 域

   ```shell
   # 发现域
   sudo realm discover example.com
   
   # 加入域（需管理员密码）
   # 如有多个服务器，客户端会自动从 DNS SRV 记录发现所有可用的 FreeIPA 服务器。
   sudo realm join example.com -U admin
   
   # 验证
   sudo realm list
   ```

3. 动创建家目录

   ```shell
   sudo authselect enable-feature with-mkhomedir
   ```

4. 测试登录

   ```shell
   su - admin@example.com
   ```



# 管理 FreeIPA

## Web 管理界面

访问`ipa server域名/ip/ui`即可，如 `https://ipa-server.grp1.hcp/ipa/ui`，使用 `admin` 账号登录。

如果访问该地址的主机不能解析这个域名，可以在该主机的hosts添加域名解析。



## 添加客户端主机

```shell
#添加主机
ipa host-add client1.example.com

#允许用户登录客户端 realm管理
realm permit user1@example.com
```



## 用户管理

管理普通用户需要先登录管理员：

```shell
kinit admin
klist    #检查票据是否获取成功
```

- 添加/删除用户和设置密码

  ```shell
  #添加用户
  ipa user-add --first=<first_name> --last=<last_name> [--uid-=<uid> --gidnumber=<gid1[,gid2,...]>] [-p <password>] <username>
  
  #删除用户 --preserve=false会删除用户家目录
  ipa user-del <username> [--preserve=false]
  #检验用户是否已经删除
  ipa user-find --login=<username>  # 应返回空结果
  
  #查看用户信息
  ipa user-find [--all]         #查看所有用户
  ipa user-find <username> -all #查看指定用户所有信息
  
  #设置密码
  ipa passwd <username> --password  #输入两次密码
  ```

  

  用户自己修改密码：

  ```shell
  kinit <用户名>  # 用户先获取 Kerberos 票据
  ipa passwd     # 根据提示输入旧密码和新密码
  ```



- 用户组管理

  ```shell
  #查看现有组列表
  ipa group-find
  
  #如果组不存在，先创建组（支持 POSIX 组）
  ipa group-add --gid=<GID> <group_name>
  
  #将用户添加到某个组
  ipa group-add-member <group_name> --users=<username>
  
  #从组中移除用户
  ipa group-remove-member <group_name> --users=<username>
  
  #修改用户的主组（Primary GID）
  ipa user-mod <username> --gidnumber=<new_gid>
  ```



- 密码策略

  ```shell
  #查看当前全局密码策略
  ipa pwpolicy-show
  
  #修改全局策略（如密码长度、有效期）
  ipa pwpolicy-mod --minlength=8 --maxlife=1000 #默认过期时间90天
  
  #设置指定用户密码过期时间
  ipa user-mod <username> --password-expiration="20240101000000Z"
  #可使用now立即过期（用户登录后必须修改密码）
  ipa user-mod <username> --password-expiration="now"
  ```



- 锁定/解锁用户

  ```shell
  #锁定用户
  ipa user-disable <username>
  
  #解锁用户
  ipa user-enable <username>
  ```




## 权限控制

- 日常管理中，如无必要应当减少使用`admin`管理，一些常用的管理操作如用户管理可以在策略管理中授权给特定的用户；一些需要root执行的命令如`firewalld`可以添加sudo规则授权给特定用户。
- 应当禁止admin登录系统



## 数据备份

- 备份服务端数据

  ```shell
  ipa-backup --online
  # --data	只备份 LDAP 数据，不含配置与证书
  # --logs	包含 FreeIPA 的日志文件（例如 /var/log/dirsrv/）
  # --online 不断服务情况下在线备份（默认是“停服务”再备份）
  # --location /your/path	改变备份目录（默认是 /var/lib/ipa/backup）
  ```

- 还原备份

  注意：**不要用 `ipa-restore` 恢复到一个不同主机名或不同 IP 的系统**，否则 Kerberos 和证书全部失效。

  ```shell
  ipa-restore --online /path/to/backup-data #--data
  ipactl restart
  ipa-healthcheck
  ```

  

## 故障排查

常见问题：

- **DNS 解析失败**：确保客户端能解析 FreeIPA 服务器。
- **时间不同步**：检查 `chronyd` 服务状态。
- **权限不足**：使用 `admin` 账号操作。

```shell
# FreeIPA 服务端日志
journalctl -u ipa -f

# 客户端 SSSD 日志
journalctl -u sssd -f
```

