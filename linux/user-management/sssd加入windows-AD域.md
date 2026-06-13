

以下所述以CentOS7.x为例

---

# 准备工作

- windows域控服务器配置AD域相关操作

- DNS

  linux客户端配置好DNS解析(网卡配置DNS或者`/etc/resolv.conf`中添加`nameserver`)

  *如果AD域控服务器即DNS服务器，则DNS填写域控服务器的IP或主机名或域名。*

  hosts文件可解析AD域控服务器（可选）

- 时间同步

  保证AD域控服务器和客户端时间一致性。（或者差距不要太大）

- 防火墙

  windows和linux主机均要主要防火墙策略，临时关闭防火墙或放行相关端口。

  如网络中有其他防火墙存在，应当放行相关端口。

  linux要临时修改SELINUX为允许或添加相关放行规则。

  ```shell
  systemctl stop firewalld
  setenforce 0
  ```

# realm加入AD域

1. 安装相关包

   ```shell
    yum install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common \
    krb5-libs krb5-devel pam_krb5 krb5-workstation \
    # #openldap-clients policycoreutils-python \
    winbind samba-client samba-winbind-clients
    #yum install -y smaba-winbind
   ```

2. 使用realm加入AD域

   ```shell
   #ad_server也可以使用ip，建议配置好DNS或hosts，使用域名而非IP
   realm join <ad_server> -U <ad_user> -v
   #realm join <ad_server> --user=<ad_user> -v
   ```

   - `-v`打印详细信息
   - `-U`或`--user`指定AD域控服务器上的用户（需要有添加到域的权限），如不指定则为`Administrator`

   *可参看[常见问题解决](常见问题解决)。*

   相关命令：

   ```shell
   realm discover <ad_server>  #发现域控服务器
   realm leave [ad] #离开已经加入的域
   realm list  #列出域
   #（加入域后）指定允许登录的用户组
   realm permit -g <group-name>@<ad>
   # realm deny拒绝用户登录　realm -h查看更多使用参数
   ```

3. 验证

   - 检查sssd服务

     ```shell
     systemctl status sssd
     ```

     使用realm加入域后会自动生成或更新sssd配置文件sssd.conf（一般在`/etc/sssd/sssd.conf`），并自动启用sssd服务。

   - 验证用户信息

     ```shell
     id <username>@<ad>    #例如test@office.cluster
     #或
     id <username>//<ad>
     ```

   *可参看[常见问题解决](常见问题解决)。*

## 配置



## sssd.conf

更改sssd.conf后需重启sssd服务。

配置示例及说明：

```shell
 [sssd]
 domains = xxx.yy
 config_file_version = 2
 services = nss, pam
  
 [domain/xxx.yy] #域名
ad_domain = xxx.yy
krb5_realm = XXX.YY  #大写的ad_domain
#realmd_tags = manages-system joined-with-adcli
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash   #登陆时的默认shell
ldap_id_mapping = True
#是否使用用户全名（包含域名的长用户名）如 test@xxx.yy
#值为Fasle则可以不加上域名使用，例如直接使用test
use_fully_qualified_names = False
#用户家目录　％u表示用户名　%d表示域名
#fallback_homedir = /home/%u@%d
fallback_homedir = /home/%u
access_provider = ad
```



# 附

## 常见问题解决

- could not connect xxx, Couldn't authenticate to active directory: SASL(-1): generic failure

  该问题与DNS（反向DNS解析）有关。

  创建/etc/krb5.conf（如果没有），并确保如下配置：

  ```shell
  [libdefaults]
  default_realm = xxx.com #改为实际的AD server域名
  rdns = false
  ```

- GSSAPI Error: Unspecified GSS failure.  Minor code may provide more information (Server not found ...

  查看`/etc/sssd/sssd.conf`是否存在`ad_server=`行，注释或删除该行；

  查看`/etc/krb5.conf`，在`[libdefaults]`这个区块下添加：

  ```shell
  rdns = false  #如果存在该行且值为True，修改值为False
  ```

  重启sssd服务

- 如果sssd的log中提示类似：

  > Unable to load module [ad] with path [/usr/lib64/sssd/libsss_ad.so]: libwbclient.so.0: cannot open shared object file: No such file or directory

  samba库依赖问题，确认已经安装libwbclient，手动添加其到LD_LIBRARY环境变量中。也可将配置写入到`/etc/ld.so.conf.d/`目录下的文件中，示例：

  ```shell
   #rhel/centos可使用rqm -ql libwbclient查看位置，其他发行版思路类似
   echo '
   /usr/lib64/samba/wbclient/
   ' >/etc/ld.so.conf.d/samba.conf
  ldconfig -v | grep libwbclient
  ```

- 无错误但是没有验证到用户信息

  设置`/etc/resolv.conf`的`nameserver`值为正确的DNS服务器地址（也可以直接设置网卡的DNS）。

  DNS应该和AD服务器配置的DNS一致。

  *当AD服务器作为DNS服务器时，nameserver应为AD服务器的IP或域名。*

## sssd配置脚本示例

```shell
#!/bin/sh
#===ad信息
ad='xxx'  #ad域的名字
#ad_server_ip为ad域控主机的IP，ad_server为AD域控主机的域名
#只要客户端能解析ad_server，ad主机IP也可不填写，只填写ad_server
ad_server_ip='10.0.48.31'
ad_server="xxx.yyy.zzz" # $(timeout 10 nslookup $ad_server_ip|cut -d "=" -f 2|sed -E "s/.$//" )
ad_user='xxx' #在AD主机上具有添加欲权限的用户，默认是 Administrator
ad_user_pwd='xxx'  #ad_user对应的密码

#===sssd.conf配置相关
user_home_parent_dir='/home'
user_shell='csh' #defautl is bash

#===
yum install sssd realmd oddjob oddjob-mkhomedir adcli krb5-libs openldap-clients ipa-client pam_krb5 krb5-workstation samba-winbind samba-common-tools ntp -y #sssd-winbind-idmap samba-winbind

#firewalld和selinux判断
firewall=$(systemctl status firewalld|grep -E "active.+running")

setenforce=0

#sync time (optional)
ntpdate $ad_server_ip

#add nameserver -- /etc/resolv.conf
echo "
search $ad
nameserver $ad_server_ip
" >/etc/resolv.conf

#add ad_server -- /etc/hosts
if [[ -n $ad_server ]]; then
  if [[ ! $(grep "$ad_server_ip $ad_server" /etc/hosts) ]]; then
    sed -i "2a $ad_server_ip $ad_server" /etc/hosts
  fi
fi

#samba libarary
if [[ ! $(ldconfig -v | grep libwbclient.so.0 2>/dev/null) ]]; then
  echo '/usr/lib64/samba/wbclient/' >/etc/ld.so.conf.d/samba.conf
  ldconfig -v | grep libwbclient
fi

#leave AD
#realm leave

#discover AD server (optional)
realm discover -v $ad_server_ip

if [[ $? -eq 0 ]]; then
  #add to AD
  [[ $(which expect 2>/dev/null) ]] || yum install -y expect
  expect -c "
spawn realm join --user=$ad_user $ad_server_ip -v
expect {
"Password*" { send "$ad_user_pwd"\r }
}
expect eof
"
else
  echo "cant not discover AD server $ad_server_ip"
fi

#modify config sssd file
sed -i -E \
  -e "s/bash/$user_shell/" \
  -e "/fallback_homedir/ c fallback_homedir = $user_home_parent_dir/%u@%d" \
  -e "/use_fully_qualified_names/ s/True/False/" \
  -e "/ad_server/d" \
  /etc/sssd/sssd.conf

systemctl restart sssd
```



