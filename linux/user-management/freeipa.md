https://www.freeipa.org/page/Quick_Start_Guide

IPA的RedHat企业版[IPA- Red Hat Identity Management](https://www.google.com/search?client=safari&rls=en&q=redhat+IPA&ie=UTF-8&oe=UTF-8)

# 服务端

## 环境准备

以RHEL及其衍生版（如CentOS，RockyLinux）为例



### 域名解析

**强烈建议**在生产环境中为服务器主机正确配置 DNS（无论是 IPA 集成还是外部托管）。

> - **服务发现**：FreeIPA依赖DNS的SRV记录定位Kerberos KDC、LDAP服务器等关键服务。
> - **反向解析**：FreeIPA的证书签发和主机验证需要双向解析（正向A记录和反向PTR记录）。
> - **维护成本**：节点扩容或IP变更时需手动同步所有主机的hosts文件，易出错且不适用于动态环境。
> - **安全风险**：硬编码IP可能导致DNS欺骗攻击，而集成DNS支持DNSSEC（DNS安全扩展）。

`freeipa-server-dns` 提供了一个集成的 BIND (named) DNS 服务器环境，并使用 `bind-dyndb-ldap` 插件将 DNS 的配置和记录数据直接存放到 FreeIPA 核心的 LDAP 目录数据库中。



如果在小规模集群（如 HPC 环境）中，节点统一使用自动化工具维护 `/etc/hosts` 进行短主机名解析，那么在技术上也可以不强制要求全局 DNS，但**必须保证所有节点（服务器和客户端）的 `/etc/hosts` 中都能正确解析 IPA Server 的 FQDN 和各节点自身的名称**。或者保留hosts解析同时，增加IPA DNS解析用于接入IPA的FQDN域名。



**在安装 FreeIPA 之前，安装脚本会进行严格的前置检查，要求本机必须能够将自己的 FQDN 正确解析为自身的 IP**（否则安装会直接报错退出）。因此，如果你没有现成的上游 DNS 能提供该解析，或者你想确保解析的优先级和稳定性，**必须在 `/etc/hosts` 中优先配置好自身的 IP 与 FQDN 映射**：

```shell
# 格式：<本机IP> <FQDN长主机名> <短主机名>
10.1.1.251  ipa.grp.hpc  ipa
```



如果已经有上游DNS服务也可以解析当前主机域名，要配置好上游DNS服务。

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
  Domains=~ipa.grp.hpc
  FallbackDNS=<your upstream DNS addr>
  ```

- `NetworkManager`

  ```shell
  nmcli connection show           #查看所有网卡连接配置
  nmcli connection modify <连接名> ipv4.dns "<DNS addr>"
  ```

-  `dhclient` / `nmcli` / `ifup` 脚本



### 主机名

主机名必须是完全限定域名，如 `ipa.grp.hpc`。

如果按以上方式设置了hosts，主机名也可以只设置为短主机名，只是要确保`hostname -f`输出的一定是完全限定的域名。

```shell
hostnamectl hostname ipa
```



### 时间同步服务

时间同步对于 Kerberos 认证至关重要（如果时间偏差过大，所有认证都会失败）。

FreeIPA 也是默认使用 **Chrony** (`chronyd`) 来提供和管理 NTP 服务的。如果在安装 FreeIPA Server 或 Client 时不加 `--no-ntp` 选项，**它会自动帮你安装并根据 IPA 的需求配置好 Chrony**。

如果在安装时加上了 `--no-ntp` 选项，则需要在使用 IPA 之前自行确保各节点的时间是精确同步的：

```shell
dnf install chrony -y
systemctl enable --now chronyd
timedatectl set-ntp true
#chrony的具体配置省略......
```



### 防火墙端口

**需要确保要使用到的服务所需端口没有被其他程序占用**。

这里以firewalld为例。

如果不使用防火墙，可以关闭：

```shell
systemctl disable --now firewalld
```



如果开启了防火墙，IPA server需要的放行入站的端口：

- 身份认证，必须：

  - LDAP  389/TCP
  - LDAPS 636/TCP
  - Kerberos 88,464/TCP,UDP

  如果只使用LDAPS，可以不放行389（LDAP）。

  


- 可选的服务：

  - DNS：53/TCP  53/UDP
  - NTP(chrony)：123/UDP
  - WebUI：
    - HTTP： 80/TCP
    - HTTS： 443/TCP
  



- 仅本地使用的服务端口，不要开放：

  - Tomcat - PKI：支持CA的IPA副本使用端口8005,8009,8080,8443 /TCP

  - kadmind：KDC管理使用端口749/TCP



可以firewall-cmd可以添加相关服务即可，下同。

```shell
#根据情况决定要开放的服务：
services=freeipa-ldap,freeipa-ldaps,http #,https,chronyd,
firewall-cmd --add-service=freeipa-ldap --add-service=freeipa-ldaps --permanent
firewall-cmd --reload
```





## 安装部署 FreeIPA Server


安装 FreeIPA 服务端（如果不需要集成DNS则不安装freeipa-server-dns） 

```shell
dnf install -y freeipa-server

# 如果还要使用IPA集成的DNS服务
dnf install -y freeipa-server-dns
```



- 交互式安装向导

  ```shell
  # --no-ntp不使用IPA设置ntp
  # --no-ui-redirect不让IPA配置的httpd服务的根路径跳到ipa/ui路径（这样可以在80/443处理其他web服务）
  ipa-server-install --no-ntp --no-host-dns #--no-ui-redirect
  ```

  默认只询问以下内容，如果需要更多设置项，需要增加相关的命令行选项参数。示例：

  >```shell
  >Do you want to configure integrated DNS (BIND)? [no]: no
  >Server host name [ipa.grp.hpc]: [Enter]
  >Please confirm the domain name [ipa.grp.hpc]: [Enter]
  >Please provide a realm name [GRP.HPC]: [Enter]
  >Directory Manager password: [输入密码]
  >IPA admin password: [输入密码]
  >Do you want to configure chrony with NTP server? [yes]: [Enter]
  >Continue to configure the system with these values? [no]: yes
  >```



- 非交互安装

  需要使用`-U`/`--unattended`选项，并且必须给定必要的选项：

  - `--realm`  指定 realm，一般就是大写的域名
  - `--domain`  指定 domain，小写的域名
  - `--ds-password`  指定 Directory Manager 密码
  - `--admin-password`  指定 IPA admin 密码
  
  
  
  ```shell
  # 示例 1：不安装 DNS，仅使用外部 DNS 或本地 hosts（去掉了与 DNS 相关的参数）
  ipa-server-install --realm=GRP.HPC --domain=ipa.grp.hpc --ds-password=pwd_admin_ --admin-password=pwd_admin_ --no-ntp --no-host-dns --unattended #--no-ui-redirect 
  
  # 示例 2：启用并自动配置集成 DNS (-setup-dns)
  ipa-server-install --realm=GRP.HPC --domain=ipa.grp.hpc --ds-password=pwd_admin_ --admin-password=pwd_admin_ --ssh-trust-dns --setup-dns --forwarder=192.168.122.247 --no-ntp --unattended #--no-ui-redirect
  ```
  
  
  
  `--setup-dns`相关（建议）
  
  - `--no-host-dns`  安装期间不使用DNS查找设置的主机名
  
    如果不是从上游DNS获取的主机名，应当使用此选项避免从DNS查询（却查不到出现问题）
  
  - `--auto-forwarders`  （默认行为）使用`/etc/resolv.conf`配置的DNS进行转发
  
  - `--forwarder`  指定一个上游DNS地址（该选项可以使用多次）
  
  - `--no-forwarders`  不要添加任何DNS转发，用于根服务器
  
  可以安装期间使用`--no-forwarders`，避免不必要的解析，在安装完毕后补充forwarder：
  
  ```shell
  ipa dnsconfig-mod --forwarder=<DNS1> [--forwarder=<DNS2>] --forward-policy=first
  ```
  
  



其他常用选项说明：
  - `--no-ntp`：不使用IPA设置ntp
  - `--no-ui-redirect`：不让IPA配置的httpd服务的根路径跳到ipa/ui路径（这样可以在80/443处理其他web服务）
  - `--ip-address`: 在多网卡环境或 DNS 解析尚未完全就绪时非常重要，它可以强制指定 IPA 绑定的 IP，避免脚本自动检测出错。
  - `--hostname`：指定 IPA 服务的 FQDN。虽然脚本会尝试自动修改系统主机名，但最稳妥的做法是预先使用 `hostnamectl set-hostname <FQDN>` 设置好并验证 `hostname -f` 正确后再安装。
  - `--ca-cert-file`： (可选) 如果你需要使用外部 CA 证书或者在极其严格的网络环境下辅助客户端信任，可以使用此参数指定 CA 证书路径。



安装完成后，会输出管理 Web UI 地址（如 `https://ipa.grp.hpc`），在该地址的`/ipa/ui`路径即 IPA 的 Web 管理平台，使用 admin 用户及其密码登录。



建议在配置完成后禁止admin帐号作为系统帐号登录：

```shell
ipa user-mod admin --loginshell=/sbin/nologin
ipa user-mod admin --homedir=/var/empty
```



卸载：

```shell
ipa-server-install --uninstall
```



### 验证服务

```shell
# 检查服务状态
systemctl status ipa
ipactl status  #查看所有ipa server相关服务的运行状态

# 测试 Kerberos 认证
kinit admin
klist
```



## 添加副本节点（可选）

FreeIPA **支持多主复制（Multi-Master Replication）**，本质上就是一种 **"双活"或"多活"** 的机制，所有节点均可同时处理读写请求，数据通过实时同步保持一致。需要：

- **所有节点** 共享相同的 Kerberos Realm（如 `GRP.HPC`）
- **DNS 轮询** 或 **负载均衡器** 对外提供服务



前置条件：

- **至少 2 台服务器**（RHEL/CentOS 8/9）
- **时间同步**（所有节点时间差 ≤ 5 分钟）
- **DNS 解析**（所有节点能互相解析主机名）
- **主节点已安装 FreeIPA**



### 副本节点加入

```shell
# 在副本节点（ipa2.ipa.grp.hpc）执行：
ipa-replica-install \
--principal admin \
--admin-password admin密码 \
--setup-dns \
--setup-ca \
--no-host-dns
```

 选项说明：
- `--principal` 主节点的管理员账号（如 `admin`）
- `--admin-password`  主节点的管理员密码      
- `--setup-dns`  同步 DNS 记录
- `--setup-ca`   复制 CA 证书（如果主节点启用了 CA） 



 移除副本节点， 需要在主节点执行：

```shell
ipa-replica-manage del ipa3.ipa.grp.hpc
```

 

### 验证副本同步

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



### 配置 DNS 负载均衡

- 方案 1：DNS 轮询（简单）

  在 DNS 服务器（如 BIND）中为 `ipa.grp.hpc` 添加多个 A 记录：

  ```shell
   ipa.grp.hpc.    IN    A    192.168.1.10  # ipa1
   ipa.grp.hpc.    IN    A    192.168.1.11  # ipa2
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

- 域名解析

  为客户端设置DNS/hosts域名解析，以保证客户端能解析服务端。

  参看服务端的DNS配置。如果IPA集成了DNS，将IPA的网卡地址作为DNS服务器地址加入即可。

  ```shell
  dig @<IPA server IP>  <IPA server的全限定主机名>   #测试
  #配置DNS ...
  ```

- 主机名

  参照服务端配置的方法

- 时间同步



## 使用ipa-client加入

安装ipa-client及相关依赖

```shell
# 安装必要软件
dnf install -y freeipa-client

# 如果需要自动创建用户家目录，安装oddjob-mkhomedir（如果家目录已经由共享文件系统挂载则没有必要安装）
dnf install -y oddjob-mkhomedir
```



加入freeIPA域

- 交互式加入

  ```shell
  ipa-client-install
  ```

  根据提示操作，实例：

  > ```shell
  > Continue to configure the system with these values? [no]: yes
  > User authorized to enroll computers: admin
   > Password for admin@GRP.HPC: [输入密码]
  > ```



- 非交互式

  需要使用`-U`/`--unattended`选项，并且必须给定必要的选项才行，必要选项：

  - `--domain`： FreeIPA 域名（如 `ipa.grp.hpc`）
  
  - `--server`： FreeIPA 服务器主机名（如 `ipa.grp.hpc`）
  
  - `--realm`： Kerberos Realm（通常是大写的域名，如 `GRP.HPC`）
  
  - `--principal`： 有权限加入客户端的用户（如 `admin`）
  
  - `--password`： 管理员密码（明文，需注意安全）
  
    如果要更严格的安全要求，建议使用OTP（一次性密码）：
  
    1. 在 IPA Server 上为新节点预创账号
  
       ```shell
       kinit admin
       ipa host-add node01.grp.hpc --password=RANDOM_OTP1
       ```
  
    2. 在客户端使用该 OTP 加入使用`--password=RANDOM_OTP`而不需要 `--principal=admin`
    
       ```shell
       ipa-client-install \
           --domain=ipa.grp.hpc \
           --server=ipa.grp.hpc \
           --realm=GRP.HPC \
           --no-ntp \
           --password=<OTP> \
           --ssh-trust-dns \
           --request-cert \
           --collect-stats \
           --enable-dns-updates \
           --unattended
           
       #--principal=admin \
       ```
    
       
  
  


其他常用选项说明：

 - `--enable-dns-updates`： 启用 DNS 更新
 - `--mkhomedir`： 自动创建用户家目录（如果家目录已经由共享文件系统挂载则不要使用）
 - `--ca-cert-file`： 手动指定服务器 CA 证书路径（若自动探测失败）
 - `--config-firefox`： 配置firefox使用IPA域名的证书（将自动倒入
 - `--firefox-dir`： 指定firefox配置目录



## 使用realmd加入

1. 安装 `realmd` 和依赖：

   ```shell
   dnf install -y realmd sssd
   ```
   
2. 加入 FreeIPA 域

   ```shell
   # 发现域
    realm discover ipa.grp.hpc
   
   # 加入域（需管理员密码）
   # 如有多个服务器，客户端会自动从 DNS SRV 记录发现所有可用的 FreeIPA 服务器。
    realm join ipa.grp.hpc -U admin
   
   # 验证
   realm list
   ```



## 验证客户端

```shell
# 检查用户信息
id admin@ipa.grp.hpc

# 测试登录
su - admin@ipa.grp.hpc

# 检查 Kerberos 票据
kinit admin
klist

# 查看 FreeIPA 用户信息
id admin@ipa.grp.hpc

# 检查 SSSD 状态
systemctl status sssd
```



## 自动创建家目录

**如果家目录已经由共享文件系统挂载则不要使用！**

如果ipa-client-install时没有使用`--mkhomedir`选项，或者使用realmd加入后没有自动配置自动创建家目录，而当前场景需要自动创建家目录，可以手动启用该功能。


```shell
dnf install -y oddjob-mkhomedir
authselect enable-feature with-mkhomedir
#对于centos7等只有authconfig，则使用
#authconfig --enablemkhomedir --updat
systemctl enable --now oddjobd

#对于debian系列使用
#pam-auth-update --enable mkhomedir
```



# 管理 FreeIPA

## Web 管理界面

访问`https://ipa_server域名/ipa/ui`即可，如 `https://ipa.grp.hpc/ipa/ui`，使用 `admin` 账号登录。

> 如果访问该地址的主机不能解析这个域名，可以在该主机的hosts添加域名解析，或者统一配置DNS解析。
> **必须使用 FQDN 域名访问！** 如果你尝试直接使用 IP 地址（例如 `https://10.1.1.251/ipa/ui`），FreeIPA 内置的 Web 服务（Apache/WSGI）也会强制将你 **HTTP 301 重定向** 到该服务器配置的 FQDN 上。因此，你的客户端浏览器所在的系统必须能正确解析这个 FQDN（如果没有全局 DNS，则必须配置本地的 hosts）。

如不指定证书等，IPA默认会自动颁发，可使用以下方法安装其CA证书

1. 从`https://IPA域名或IP/ipa/config/ca.crt`下载证书

   如果浏览器访问直接显示的证书密文，可以右键另存为以下载

2. 安装证书。

   windows：

   1. 双击该文件 -> 安装证书
   2. 选择“本地计算机” -> 将所有证书放入下列存储
   3. 浏览并选择 “受信任的根证书颁发机构”
   4. 安装完成后重启浏览器访问IPA的web网站（地址栏就有安全锁了）。



## 添加客户端主机

```shell
#添加主机
ipa host-add client1.ipa.grp.hpc

#允许用户登录客户端 realm管理
realm permit user1@ipa.grp.hpc
```



## 用户管理

管理普通用户需要先登录管理员：

```shell
kinit admin
klist    #检查票据是否获取成功
```



### 添加/删除用户和设置密码

注意：IPA的用户管理主要为Unix设计，因此默认创建的就是posixAccount，位于`cn=users,cn=accounts`下，而且如果不指定用户组，则默认在ipausers（Non-POSIX组）。其Web UI的users列表也只会显示这些用户。

创建非posixAccount参看[创建仅查询服务的用户](#创建仅查询服务的用户)

  ```shell
  #添加用户 --password需要交互式填入密码 --random可以生成随机密码
  ipa user-add --first=<first_name> --last=<last_name> [--uid-=<uid> --gidnumber=<gid1[,gid2,...]>] [--password ] <username>
  
  #删除用户 --preserve=false会删除用户家目录
  ipa user-del <username> [--preserve=false]
  #检验用户是否已经删除
  ipa user-find --login=<username>  # 应返回空结果
  
  #查看用户信息
  ipa user-find [--all]                 #查看所有用户
  ipa user-show <username> -all [--raw] #--all查看指定用户所有信息，--raw展示原始信息
  
  #设置密码
  ipa passwd <username> --password  #输入两次密码
  
  #修改shell
  ipa user-mod --shell=/bin/bash <username>
  ```

  

  用户自己修改密码：

  ```shell
  kinit <用户名>  # 用户先获取 Kerberos 票据
  ipa passwd     # 根据提示输入旧密码和新密码
  ```



### 用户组管理

  ```shell
  #查看现有组列表
  ipa group-find
  
  #创建组（支持 POSIX 组）,非posix组使用--nonposix
  ipa group-add --gid=<GID> <group_name>
  
  #删除组
  ipa group-del <group_name>
  
  #将用户添加到某个组
  ipa group-add-member <group_name> --users=<username>
  
  #从组中移除用户
  ipa group-remove-member <group_name> --users=<username>
  
  #修改用户的主组（Primary GID）
  ipa user-mod <username> --gidnumber=<new_gid>
  
  #查看用户组信息
  ipa group-show ipausers --all
  ```



### 用户密码策略

  ```shell
  #查看当前全局密码策略
  ipa pwpolicy-show
  
  #修改全局策略（如密码长度、有效期）
  ipa pwpolicy-mod --minlength=8  #密码最小长度
  ipa pwpolicy-mod --maxlife=0    #0或99999表示不过期，默认过期时间90天
  
  #设置指定用户密码过期时间
  ipa user-mod <username> --password-expiration="20240101000000Z"
  #可使用now立即过期（用户登录后必须修改密码）
  ipa user-mod <username> --password-expiration="now"
  ```



### 锁定/解锁用户

  ```shell
  #锁定用户
  ipa user-disable <username>
  
  #解锁用户
  ipa user-enable <username>
  ```



### 创建仅查询服务的用户

这些用户主要用户服务/查询，不允许登录系统，建议创建非posixAccount用户或者创建不可登录shell（设置为/sbin/nologin）的用户。

以用户名为ldapbind为例。

- 创建一个存在于`cn=sysaccounts,cn=etc`下的非posixAccount

  ```shell
  kinit admin #获取票据后创建
  
  ldapadd -Y GSSAPI <<EOF
  dn: uid=ldapbind,cn=sysaccounts,cn=etc,dc=dev,dc=vm
  objectClass: account
  objectClass: simpleSecurityObject
  uid: ldapbind
  userPassword: 改用户的密码写在这里
  EOF
  ```

  创建的用户的Bind DN为 `uid=ldapbind,sysaccounts,cn=etc,dc=grp,dc`

  `cn=sysaccounts,cn=etc`是 FreeIPA 的底层目录树（DIT）中，这是专门为**纯服务、纯机器查询**预留的，不会被同步到*nix主机上，且默认就不会密码过期。缺点是**不能在IPA web ui的users列表中看到**。
  
  ```shell
  # 确保你已经 kinit admin
  ldapsearch -Y GSSAPI -b "cn=sysaccounts,cn=etc,dc=dev,dc=vm" "(uid=ldapbind)"
  ```



- 创建不可登录的posixAccount账户，shell为/sbin/nologin

  ```shell
  # 1. 创建不可登录的用户
  ipa user-add ldapbind --first="LDAP" --last="Bind" --shell=/sbin/nologin --password
  # 2. 设置密码不过期
  ipa pwpolicy-add-user --users=ldapbind --maxlife=999999
  
  # （建议）创建专门的组来存放这类账号，并将账号从ipausers中移除
  ipa group-add searchonly --nonposix --desc "Service accounts for LDAP binding"
  ipa group-add-member searchonly  --users=ldapbind
  ipa group-remove-member ipausers --users=ldapbind
  ```
  创建的用户的Bind DN为：`uid=ldapbind,cn=users,cn=accounts,dc=grp,dc=hpc`



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

