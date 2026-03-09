

# Linux 上配置LDAP客户端

以下介绍在Linux系统中将主机作为客户端加入ldap，以RHEL及其衍生版为例

## 使用sssd（建议）

> SSSD（System Security Services Daemon）是一个开源的系统服务守护进程，用于提供集中的身份验证和授权服务。SSSD的主要目标是简化和改进Linux和Unix系统中的身份管理和访问控制。

SSSD是一种集成的解决方案，它提供了更简化和自动化的方式来实现各种身份验证和授权服务。

- 使用authconfig-tui或authconfig命令配置（建议）：

  ```shell
  dnf install -y openldap-clients nss-pam-ldapd authconfig sssd sssd-client oddjob-mkhomedir
  
  ldapserver=freeipa.lab.home
  ldapbasedn='dc=lab,dc=home'
  enable_tls=false
  
  #authconfig --enableldap --enableldapauth --ldapserver=<server1[,sever2]> --ldapbasedn=<dn> [--enableldaptls] [--ldaploadcacert=<URL>]
  
  tls_option="--enableldaptls "  #ldaploadcacert=<URL>
  if [ $tls_option == false ]  && tls_option="--disableldaptls"
  
  authconfig --enableldap $tls_option --enableldapauth --enablemkhomedir \
  --enablesssd --enablesssdauth --enablelocauthorize  \
  --ldapserver=$ldapserver --ldapbasedn="$ldapbasedn" --enableshadow \
  --update #updateall
  
  systemctl enable --now sssd && systemctl restart sssd
  
  #test
  authconfig --test
  ```
  
  `--enablemkhomedir`选项可以在用户登录时自动创建home目录（如果home目录不存在），如果指定创建home目录时引用的skel目录（该目录内容将复制到新建的home目录中），可以参考下面的方法在`[sssd]`小节中添加`override_homedir = /path/to/skel`行。



- 或者编辑`/etc/sssd/sssd.conf` 文件，修改/添加ldap相关部分：

  ```ini
  [domain/default]
  
  autofs_provider = ldap
  auth_provider = ldap
  ldap_search_base = dc=lab,dc=home
  id_provider = ldap
  ldap_id_use_start_tls = False
  #ldap_tls_reqcert = allow
  chpass_provider = ldap
  cache_credentials = True
  ldap_tls_cacertdir = /etc/openldap/cacerts
  ldap_uri = ldap://freeipa.lab.home/
  
  [sssd]
  services = nss, pam, autofs
  domains = default
  
  [nss]
  homedir_substring = /home
  override_homedir = /etc/skel #skel目录 默认是/etc/skel
  ```
  
  然后启用sssd：

  ```shell
  systemctl restart --now sssd oddjobd
  ```



## 使用freeipa的client

安装freeipa后，可使用`ipa-client-install`工具进行配置





## 使用nslcd

> nslcd（Name Service LDAP Client Daemon）是一个开源的守护进程，用于在Linux和Unix系统中提供本地名称服务（如用户和组）与LDAP服务器之间的集成。它充当本地系统和远程LDAP服务器之间的中间层，通过LDAP协议与LDAP服务器通信。

- 使用authconfig-tui或authconfig命令配置（建议）：

  ```shell
  dnf install -y openldap-clients nss-pam-ldapd authconfig
  
  ldapserver=freeipa.lab.home
  ldapbasedn='dc=lab,dc=home'
  enable_tls=false
  
  #authconfig --enableldap --enableldapauth --ldapserver=<server1[,sever2]> --ldapbasedn=<dn> [--enableldaptls] [--ldaploadcacert=<URL>]
  
  tls_option="--enableldaptls "  #ldaploadcacert=<URL>
  if [ $tls_option == false ]  && tls_option="--disableldaptls"
  
  systemctl disable --now sssd
  
  authconfig --enableldap --enableldapauth --enablemkhomedir  --enableshadow \
    --disablesssd --disablesssdauth --enableldaptls --enablelocauthorize \
    --ldapserver=$ldapserver --ldapbasedn="$ldapbasedn" \
    --update #--enableforcelegacy
  
  #===add mkdir pam module
  if [[ ! $(grep pam_mkdir.so /etc/pam.d/system-auth) ]]; then #?pam__mkdir
    echo "session optional pam_mkhomedir.so skel=/etc/skel umask=077" >>/etc/pam.d/system-auth
  fi
  
  if [[ ! $(grep pam_mkhomedir /etc/pam.d/sshd) ]]; then
    echo "session    required     pam_mkhomedir.so  skel=/etc/skel/ umask=0022" >>/etc/pam.d/sshd
  fi
  
  systemctl enable --now nscd nslcd && systemctl restart nscd nslcd
  
  #test
  authconfig --test
  ```

  

- 或者编辑`/etc/nslcd.conf`文件，主要是这些行：

  ```ini
  uid nslcd
  gid ldap
  base dc=lab,dc=home
  ssl no                   #no/off or yes/on
  tls_cacertdir /etc/openldap/cacerts
  uri ldap://freeipa.lab.home/
  ```

  然后：

  ```shell
  systemctl enable --now nscd nslcd && systemctl restart nscd nslcd
  ```

  

可能还需要检查是有ldap的pam相关设置（配置ldap时如果没有被自动更新到pam中），这些文件一般在`/etc/pamd.d/`目录中，

- rhel中主要是

  - password-auth

    > ```shell
    > auth        sufficient    pam_ldap.so forward_pass
    > password    sufficient    pam_ldap.so use_authtok
    > session     optional      pam_ldap.so
    > ```

  - system-auth

    >```shell
    >auth        sufficient    pam_ldap.so forward_pass
    >password    sufficient    pam_ldap.so use_authtok
    >session     optional      pam_ldap.so
    >#注意selinux开启会影响mkhome的创建，除非配置相应的规则允许创建
    >session   optional   pam_mkhomedir.so   skel=/etc/skel   umask=077
    >```

- debian参看：[debian-wiki: LDAP/PAM](https://wiki.debian.org/LDAP/PAM)

  - common-auth

    ```
    auth    sufficient      pam_unix.so nullok_secure
    auth    requisite       pam_succeed_if.so uid >= 1000 quiet
    auth    sufficient      pam_ldap.so use_first_pass
    auth    required        pam_deny.so
    ```

  - common-password

    ```
    password    sufficient    pam_unix.so md5 obscure min=4 max=8 nullok try_first_pass
    password    sufficient    pam_ldap.so
    password    required      pam_deny.so
    ```

# windows加入ldap

- [pGina](http://pgina.org/download.html)




## 用户自己修改密码

```shell
ldappasswd -H ldap://server_domain_or_IP -x -D "user_dn" -W -A -S
```

# 问题

## sssd缓存造成用户信息未更新

如果客户端使用sssd，可使用以下命令清除缓存

```shell
sss_cache -E          #清除全部
sss_cache -u <user>   #清除指定用户
```

可以在`/etc/sssd/sssd.conf`中配置 entry_cache_timeout（默认5400秒）：

```shell
 entry_cache_timeout=600
```



## gentent passwd无法获取用户信息

检验：

```shell
getent passwd             #查看是否有ldap server的用户
getent passwd <username>  #查看指定用户的信息
```

默认情况下，`sssd.conf`的用户信息枚举功能是关闭的，`getent passwd`不能获取到域中的用户列表，只能获取指定用户的信息。

如果需要开启用户枚举功能，需要在`/etc/sssd/sssd.conf`中的domain配置节中配置：

```ini
[domain/your_domain_name]
enumerate = True
```

重启sssd后即可枚举所有用户信息。



如果仍然不能获取到用户信息，检查`/etc/nssswitch.conf`中是否有sss（使用sssd）或ldap（使用nslcd）的配置，如：

```shell
passwd:     files sss #ldap
group:      files sss #ldap
```

因为LDAP 通常不直接存储密码影子信息，而是负责存储用户的基本信息，`getent shadow`不一定能获取到位于LDAP中的用户的shadow信息，除非LDAP服务器上的密码策略配置支持密码影子信息的检索。
