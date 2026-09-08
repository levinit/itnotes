[toc]



# 服务端

安装和配置openldap server。

## 安装

从[openldap官网](https://openldap.org)下载源码[编译安装openldap](https://openldap.org/doc/admin26/quickstart.html)，或者在linux系统中使用包管理器安装。

不同发行版中openldap的包名可能不同，根据具体情况安装软件包。

一些发行版将openldap服务端和客户端及各个功能模块分开打包，可以在服务端将客户端及其他所需模块的包也均安装上（下不赘述）。

关闭或配置selinux规则。

ldap默认监听389端口。

- debian系：`slapd`

  ```shell
  apt install -y slapd
  #安装slapd时会自动打开tui界面让用户配置密码，或者按后文方法设置
  systemctl enable --now slapd
  ```

- rhel系/suse系：`openldap-servers`

  注：redhat7.4+版本和suse15.3+版本的官方软件仓库不再提供openldap相关包，他们选择的替代品为389 Directory Server或RHDS。如果需要使用openldap可以选择编译安装。

  ```shell
  yum install -y openldap-clients openldap-servers
  chown -R ldap:ldap /var/lib/ldap
  chown -R ldap:ldap /etc/openldap
  \cp -av /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
  systemctl enable --now slapd
  slaptest  #检测ldap相关文件是否正常
  ```
  



## 配置

参看：

- [openladp manpage](https://www.openldap.org/software/man.cgi?query=slapd)
- [redhat-wiki: openldap](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system-level_authentication_guide/openldap)
- [debian wiki: openldap setup](https://wiki.debian.org/LDAP/OpenLDAPSetup)

新版本的OpenLDAP不再从/etc/openldap/slapd.conf文件中读取其配置，它使用位于/etc/openldap/slapd.d/目录中的配置数据库，编写ldif文件后使用openldap提供的命令导入到数据库中。

对于原先版本的slapd.conf文件，可以通过运行以下命令将其转换为新格式：

```shell
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/
```

可参看`/usr/share`中openldap的ldif文件进行后续配置。



约定配置信息：

- 管理员：用户名`Manager`，密码`123456`
- 域名：`example.com`，即`dc=example,dc=com`



server端常用工具：

| 命令         | 介绍                                                         |
| :----------- | :----------------------------------------------------------- |
| `slapacl`    | 检查检查对属性列表的访问                                     |
| `slapadd`    | 将LDIF文件中的条目添加到LDAP目录中                           |
| `slapauth`   | 检查身份验证和授权权限的ID列表                               |
| `slapcat`    | 以默认格式从LDAP目录中提取条目，并将其保存在LDIF文件中       |
| `slapdn`     | 根据可用的模式语法检查区分名称（DN）列表                     |
| `slapindex`  | 重新索引slapd目录（更新索引），更改配置文件的索引选项后需运行 |
| `slappasswd` | 创建一个加密的用户密码，用于ldapmodify实用程序或slapd配置文件 |
| `slapschema` | 检查数据库是否符合相应模式（schema）                         |
| `slaptest`   | 检查LDAP服务器配置                                           |





### 导入模块

导入`/etc/openldap/schema`目录下的配置`.ldif`文件，默认情况下该目录中的`core.ldif`已被加载。

```shell
#加载需要的schema，例如常用的
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

#或加载所有
cd  /etc/openldap/schema
for schema in $(ls *.ldif)
do
    echo "import schema file $schema"
	ldapadd -Y EXTERNAL -H ldapi:/// -f $schema
done
cd -
```



### 配置域

本文所有示例配置中均使用`dc=example,dc=com`的域。

创建文件`domain.ldif`：

```shell
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
```

导入配置文件：

```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f domain.ldif
```



### 设置管理员

本文所有示例配置中均使用Manager为管理员用户，dn为`cn=Manager,dc=example,dc=com`。

生成加密的管理员密码。

*debian系的发行版安装slapd时会自动打开tui界面让用户配置密码。*

```shell
slappasswd -s 123456
```

以上命令将会把密码字符串（示例中为`123456`）加密转换为类似以下形式的字符串，复制该字符串备用：

> {SSHA}iTII/2MM15EycpLXZL54WlPL3ai2GQtS

创建文件`admin.ldif`，写入下面的内容，注意要将其中的`dc=example,dc=com`换成你实际的内容：

```ldif
# 管理员
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=example,dc=com

# 管理员密码 olcRootPW出填写上文slappasswd生成的加密字符串
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}FlOtw2k90oV/tFntidd42MPPiDAwBws6

# 为管理授予访问权限
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=example,dc=com" read by * none
```

导入配置文件：

```shell
ldapmodify -Y EXTERNAL -H ldapi:/// -f admin.ldif
```



### 创建基本组织信息

可选，可以使用图形工具完成。

编译一个包含基本组织信息的文件`org.ldif`：

```ldif
dn: ou=People,dc=example,dc=com
ou: People
objectClass: top
objectClass: organizationalUnit

dn: ou=Group,dc=example,dc=com
ou: Group
objectClass: top
objectClass: organizationalUnit
```

导入基本组织信息：

```shell
ldapadd -x -D cn=Manager,dc=example,dc=com -f org.ldif -w <password>
```



### TLS（可选）

使用openssl：

```shell
#1. 生成ca密钥ca.key， 或者使用其他权威机构的ca key
openssl genrsa -out /etc/openldap/cacerts/ca.key 4096

#2. 使用ca.key签名生成证书ca.crt
openssl req -new -x509 -nodes -key /etc/openldap/cacerts/ca.key -days 3650 -out  /etc/openldap/cacerts/ca.crt
#将提示输入一些信息，根据需要填写，或输入.表示留空，或者直接回车使用默认值
#也可以在生成前编辑/etc/pki/tls/openssl.cnf 预先设置好国家城市过期时间等值

#3. 生成ldap私钥
openssl genrsa -out /etc/openldap/certs/ldap.key
#4. 生成ldap证书请求文件
openssl req -new -node -key /etc/openldap/certs/ldap.key -out /etc/openldap/certs/ldap.csr

#
openssl ca -in  /etc/openldap/certs/ldap.csr -out /etc/openldap/certs/ldap.crt

chown ldap:ldap /etc/openldap/certs/*
chmod 600 /etc/openldap/certs/*
```

创建`tls.ldif`文件，并将下面的信息复制进去：

```ldif
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/server.crt
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/server.key
```

将新的配置文件更新到slapd服务程序：

```
ldapmodify -Y EXTERNAL -H ldapi:/// -f tls.ldif
```



### 防火墙（可选）

```shell
 firewall-cmd --permanent --add-port=389/TCP
 firewall-cmd --permanent --add-port=636/TCP
 firewall-cmd --reload
```

## ldap常用命令

ldap命令常用参数

> -x：进行简单认证。
> -D：用来绑定服务器的dn。
> -w：绑定dn的密码。
> -b：指定要查询的根节点。 
> -H：制定要查询的服务器。
> -h：目录服务的地址



添加：ldapadd

```shell
ldapadd -x -D "cn=Manager,dc=example,dc=com" -w <password> -f name.ldif
```



查找：ldapsearch

```shell
ldapsearch -x -b "dc=example,dc=com" 
```



修改：ldapmodify，分为交互式修改和文件修改，推荐文件修改

将sn属性由“Test User Modify”修改为“Test User”

> dn: cn=test,ou=Managers,dc=users,dc=corp  
> changetype: modify  
> replace: sn  
> sn: Test User

```shell
ldapmodify -x -D "cn=Manager,dc=example,dc=com" -w secret -f modify  
```



删除：ldapdelete

```shell
ldapdelete -x -D "cn=Manager,dc=example,dc=com" -w <password> "cn=test,ou=Managers,dc=dlw,dc=com"  
```



### 管理用户示例

可使用[图形界面管理工具](#图形界面管理工具)

- 添加组示例

  编写文件`group-example.ldif`

  ```ldif
  dn: cn=users,ou=Group,dc=example,dc=com
  objectClass: posixGroup
  cn: users
  gidNumber: 9999
  memberUid: users
  ```

  导入：

  ```shell
  ldapadd -x -D cn=Manager,dc=example,dc=com -W -f group-example.ldif
  ```

  

- 添加用户示例

  编写文件`user-example.ldif`

  ```ldif
  dn: uid=hpctest,ou=People,dc=example,dc=com
  objectClass: account
  objectClass: posixAccount
  objectClass: top
  objectClass: shadowAccount
  userPassword: {SSHA}5D94oKzVyJYzkCq21LhXDZFNZpPQD9uE
  cn: hpctest
  uid: hpctest
  loginShell: /bin/bash
  uidNumber: 50001
  gidNumber: 50001
  homeDirectory: /share/home/hpctest
  ```

  导入：

  ```shell
  ldapadd -x -D "cn=Manager,dc=example,dc=com" -W -f user-example.ldif 
  ```

  检查：

  ```shell
  #-W交互式输入密码
  ldapsearch -x  -D "cn=Manager,dc=example,dc=com"  -H ldap://127.0.0.1 "(uid=hpctest)" -W
  #-w指定密码
  ldapsearch -x  -D "cn=Manager,dc=example,dc=com"  -H ldap://127.0.0.1 "(uid=hpctest)" -w <passwor>
  ```



## 镜像模式mirror mode

两台ldap服务器互为镜像进行同步。配置前确保两台服务器，均以及完成[配置域](#配置域)和[配置管理员](#配置管理员)的操作。

在镜像服务器上分别执行：

1. 增加syncprov模块，编写`mod-syncprov.ldif`：

   ```ldif
   dn: cn=module,cn=config
   objectClass: olcModuleList
   cn: module
   olcModulePath: /usr/lib64/openldap
   olcModuleLoad: syncprov.la
   ```

   导入：

   ```shell
   ldapadd -Y EXTERNAL -H ldapi:/// -f mod-syncprov.ldif
   #ldapmodify -Y EXTERNAL -H ldapi:/// -f mod-syncprov.ldif
   ```

2. 配置syncprov模块，编写`syncprov.ldif`：

   ```ldif
   dn:olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
   #changetype: add   #主从模式中主服务器配置
   objectClass: olcOverlayConfig
   objectClass: olcSyncProvConfig
   olcOverlay: syncprov
   olcSpSessionLog: 100
   ```

   导入：

   ```shell
   ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov.ldif
   ```

3. 配置同步信息

   为server1编写`mirror-server1.ldif`:
   
   ```ldif
   dn: cn=config
   changetype: modify
   replace: olcServerID
   olcServerID: 1       #该值不同主机要唯一
   
   dn: olcDatabase={2}hdb,cn=config
   changetype: modify
   add: olcSyncRepl
   olcSyncRepl: rid=001
                provider=ldap://10.1.1.2:389  #另一个ldap主机的uri
                bindmethod=simple
                binddn="cn=Manager,dc=example,dc=com"
                credentials="paswd1"  #Manager的密码
                #credentials=mirrormode
                searchbase="dc=example,dc=com"
                filter="(objectClass=*)"
                #attrs="*,+"
                scope=sub
                schemachecking=on
                type=refreshAndPersist
                interval=00:00:02:00
                retry="30 5 300 +"
                
   add: olcMirrorMode
   olcMirrorMode: TRUE
   
   #add: olcDbIndex
   #olcDbIndex: entryUUID eq
   
   #add: olcDbIndex
   #olcDbIndex: entryCSN eq
   
   dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
   changetype: add
   objectClass: olcOverlayConfig
   objectClass: olcSyncProvConfig
   olcOverlay: syncprov
   ```
   
   导入：
   
   ```shell
   ldapmodify -Y EXTERNAL -H ldapi:/// -f mirror-server1.ldif
   ```
   
   
   
   为server2编写`mirror-server2.ldif`，参照上面的文件内容，主要修改：
   
   - `ServerID`值，必须与其他主机的不同
   - `provider`值，填写另一个ldap镜像主机的URI
   
   同样导入：
   
   ```shell
   ldapmodify -Y EXTERNAL -H ldapi:/// -f mirror-server2.ldif
   ```



配置完成后在各个镜像服务器上查询是否有一致的用户信息：

```shell
ldapsearch -x  -D "cn=Manager,dc=example,dc=com"  -H ldap://127.0.0.1  -w <Manager密码>
```



附，如果使用原slapd.conf文件，可以添加如下内容，使用slaptest转化。

```shell
##### Mirror Mode
#--- Global section
serverID    001    #每台ldap服务器配置中的serverID要不同

# database section

# syncrepl directive
# Consumer
##rid标识: 复制使用者站点中的当前syncrep指令，值000-999，RID's only need to be unique inside a given consumer
syncrepl rid=001
         provider=ldap://10.1.1.2    #要同步的来源（另一个镜像服务器的ldap uri）
         bindmethod=simple
         binddn="cn=Manager,dc=example,dc=com"
         credentials="master_userPassword_from_slappasswd"
         searchbase="dc=example,dc=com"
         attrs="*,+"
         type=refreshAndPersist
         interval=00:00:01:00
         retry="60 +"

# Provider
overlay syncprov
syncprov-checkpoint 50 1
syncprov-sessionlog 50

mirrormode on
```



## 备份还原

```shell
#备份：
ldapsearch -x -b "dc=ldap,dc=test,dc=net" -D "cn=Manager,dc=example,dc=com" -w "password" > ldap.ldif

#删除：
ldapdelete -x -c -D "cn=Manager,dc=example,dc=com" -w "password" -r 'dc=example,dc=com'

#还原：
ldapadd -x -c -D "cn=Manager,dc=example,dc=com" -w "password" -f ldap.ldif
```



## 迁移到ldap

从其他账号管理模式迁移到ldap，可一使用migrationtools工具，以rhel为例，安装后在`/usr/share/migrationtools`中含有许多perl脚本。

使用前先修改migrate_common.ph中ldap的信息：

```shell
# Default DNS domain
$DEFAULT_MAIL_DOMAIN = "padl.com";

# Default base 
$DEFAULT_BASE = "dc=padl,dc=com";
```

使用migrate_base.pl生成ldif文件：

```shell
./migrate_base.pl > base.ldif
```

生成ldif后编辑该文件，文件中可能包含了许多不需要导入的系统用户和组的信息，根据需要修改。

导入ldap：

```shell
ldapadd -x -D "cn=Manager,dc=example,dc=com" -W -f base.ldif 
```



迁移用户/组/密码等，以用户为例：

```shell
#示例：
#getent passwd|grep -v nobody| sort -t ":" -k 3 -n| awk -F ":" '{if ($3>1000) print}' > users.list
cat /etc/passwd |grep -v nobody| sort -t ":" -k 3 -n| awk -F ":" '{if ($3>1000) print}' > users.list

./migrate_passwd.pl users.list > users.ldif

ldapadd -x -D "cn=Manager,dc=example,dc=com" -W -f uers.ldif

cat /etc/group |grep -v nobody| sort -t ":" -k 3 -n| awk -F ":" '{if ($3>1000) print}' > groups.list
./migrate_group.pl groups.list > groups.ldif 

ldapadd -x -D "cn=Manager,dc=example,dc=com" -W -f groups.ldif 
```

