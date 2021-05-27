[toc]

# 简介

**LDAP**，Lightweight Directory Access Protocol，是轻量目录访问协议，提供访问控制和维护分布式信息的目录信息。使用LDAP构建一个统一的账号管理、身份验证平台，实现SSO单点登录机制（用户在多个应用服务系统中使用同一套帐号密码）。

常见基于LDAP协议的产品：

- [openldap](https://openldap.org)  开源的项目（本文中使用其搭建ldap server）

- Microsoft Active Directory(windows AD)
- IBM Directory Server(基于DB2)
- Oracel Internet Directory(OID)
- Apache Directory Server
- Red Hat Directory Server

## 术语

### LDAP目录树

整个LDAP目录信息集可以表示为一个目录信息树，树中的一个节点称为条目（Entry），条目中包含该节点的属性及属性值。

- Directory目录：存放信息单元
- entry条目：LDAP的基本信息单元。由属性（attribute）的一个聚集组成，并由一个唯一性的名字引用，即**专有名称**（**distinguished name**，DN）。
  - 对象类：与某个实体类型对应的一组属性（可继承）。
  - attribute 属性：与entry直接关联的信息，描述条目的某个信息，由一个属性类型和一个或多个属性值组成。

- LDIF：  LDAP数据交换格式（ *LDAP Data Interchange Format* ）是一种标准的文本文件，该文件的格式如下： 

  > ```text
  > [id] dn: distinguished_name
  > attribute_type: attribute_value…
  > attribute_type: attribute_value…
  > ```

  这种标准化格式称之为schema，schema指定对象的类型，以及每一个类型中的可选属性。

  


ldap中各种组织结构的描述术语：

- `dn`->`distinguished name `  专有名称（全局唯一的名字）

- `rdn`->`real dn`  相对辨识名

  类似相对路径，与目录树结构无关的部分，例如`uid-admin`、`cn=ADMIN`

- `o` -> `organization`（组织-公司） 

- `ou` -> `organization unit`（组织单元-部门）

  组织单元最多可以有四个层级

- `cn` -> `common name`（通用名称） 

  用户或主机的名称，一个用户或主机可以同时拥有多个cn

- `c` -> `country name`（国家）

  用于cn或c的描述，可有可无

- `dc` -> `domain component`（域名）

- `sn` -> `surname`（姓）

- `Givenname` 名

*可以按照对文件目录的理解，将ldap看成一个文件系统，类似目录和文件树。*

# 服务端

以centos/rhel 7+为例，后同。

### 安装应用和启动服务

```shell
yum install -y openldap openldap-clients openldap-servers
systemctl enable --now slapd
\cp -av /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap
systemctl status slapd
slaptest #检测ldap相关文件是否正常
```

ldap默认监听389端口。

## 配置

配置文件位于`/etc/openldap/slapd.d/cn=config`目录下，更新配置信息通过ldapmodify等命令导入ldif文件进行修改，**不要直接修改该目录下任何配置文件的内容**。

*不要修改`/etc/openldap/slapd.d/cn=config.ldif`文件，该文件中标注了`AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify`。*

约定配置信息：

- 管理员：用户名`Manager`，密码`123456`
- 域名：`users.corp`，即`dc=users,dc-crop`

### 导入基本模块

导入`/etc/openldap/schema`目录下的配置`.ldif`文件，默认情况下该目录中的`core.ldif`已被加载。

```shell
#加载需要的schema，一般需要：
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

#或者可以使用循环加载所有
cd  /etc/openldap/schema
for schema in $(ls *.ldif)
do
    echo "import schema file $schema"
	ldapadd -Y EXTERNAL -H ldapi:/// -f $schema
done
cd -
```

### 配置域名和管理员

- 生成加密的管理员密码

  ```shell
  slappasswd -s 123456
  ```

  以上命令将会把密码字符串（示例中为`123456`）加密转换为类似以下形式的字符串，复制该字符串备用：

  > {SSHA}iTII/2MM15EycpLXZL54WlPL3ai2GQtS

  创建文件`domain_info.ldif`，写入下面的内容，注意要将其中的`dc=users,dc=crop`换成你实际的内容：

  ```ldif
  #修改域名
  dn: olcDatabase={2}hdb,cn=config
  changetype: modify
  replace: olcSuffix
  olcSuffix: dc=users,dc=crop
  
  # 修改管理员用户
  dn: olcDatabase={2}hdb,cn=config
  changetype: modify
  replace: olcRootDN
  olcRootDN: cn=Manager,dc=users,dc=crop
  
  # 修改管理员密码 olcRootPW出填写上文slappasswd生成的加密字符串
  dn: olcDatabase={2}hdb,cn=config
  changetype: modify
  replace: olcRootPW
  olcRootPW: {SSHA}FlOtw2k90oV/tFntidd42MPPiDAwBws6
  
  # 修改访问权限
  dn: olcDatabase={1}monitor,cn=config
  changetype: modify
  replace: olcAccess
  olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=users,dc=crop" read by * none
  ```

  导入配置文件：

  ```shell
  ldapmodify -Y EXTERNAL -H ldapi:/// -f domain_info.ldif
  ```

  创建基本信息base_info.ldif

  ```ldif
  dn: dc=users,dc=crop
  dc: users
  objectClass: top
  objectClass: domain
  
  dn: ou=People,dc=users,dc=crop
  ou: People
  objectClass: top
  objectClass: organizationalUnit
  
  dn: ou=Group,dc=users,dc=crop
  ou: Group
  objectClass: top
  objectClass: organizationalUnit
  ```

  导入配置文件：

  ```shell
  ldapadd -x -w 123456 -D cn=Manager,dc=users,dc=crop -f base_info.ldif
  ```

  ### 生成证书（可选）

  ```shell
  openssl req -new -x509 -nodes -out /etc/openldap/certs/cert.pem -keyout /etc/openldap/certs/priv.pem -days 9999
  chown ldap:ldap /etc/openldap/certs/*
  chmod 600 /etc/openldap/certs/priv.pem
  ```

  创建`pem.ldif`文件，并将下面的信息复制进去：

  ```
  dn: cn=config
  changetype: modify
  replace: olcTLSCertificateFile
  olcTLSCertificateFile: /etc/openldap/certs/cert.pem
  
  dn: cn=config
  changetype: modify
  replace: olcTLSCertificateKeyFile
  olcTLSCertificateKeyFile: /etc/openldap/certs/priv.pem
  ```

  将新的配置文件更新到slapd服务程序：

  ```
  ldapmodify -Y EXTERNAL -H ldapi:/// -f pem.ldif
  ```

  重启 slapd 服务

  ```shell
  systemctl restart slapd
  ```



部署秘钥

安装httpd服务程序：

```shell
yum install httpd -y
```



  将密钥文件上传至网站目录：

  ```
cp /etc/openldap/certs/cert.pem /var/www/html
  ```

  将httpd服务程序重启，并添加到开机启动项：

  ```

  systemctl restart httpd
  systemctl enable httpd
  ```

  这样用户就可以使用 TLS 加密链接访问 LDAP 服务器了。

  

1. 导入管理员账户

   新建chrootpw.ldif配置文件（该文件可以存放到任何位置），添加如下信息：

   ```shell
   dn: olcDatabase={0}config,cn=config
   changetype: modify
   add: olcRootPW
   olcRootPW: {SSHA}iTII/2MM15EycpLXZL54WlPL3ai2GQtS
   ```

   ​		输出类似:

   > SASL/EXTERNAL authentication started
   > SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
   > SASL SSF: 0
   > modifying entry "olcDatabase={0}config,cn=config"

   - dn行表示指定要执行配置文件（可在`/etc/openldap/slapd.d/cn=config`目录下找到` olcDatabase={0}config.ldif `）
   - changetype行指定操作类型为modify
   - add行表示添加 olcRootPW 配置项
   - olcRootPW行设置密码（即上文中使用`slappasswd`命令生成的加密字符串）

   再使用`ldapadd`指定上面的文件进行ldap配置操作：

   ```shell
    ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif
   ```

   执行完成后，设置的用户密码将写入`/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif`中（该文件新增了一行`olcRootPW`）。

   

2. 配置基础域名

   编辑或新建`/etc/openldap/chdomain.ldif `配置文件，添加如下信息：

   ```shell
   dn: olcDatabase={1}monitor,cn=config
   changetype: modify
   replace: olcAccess
   olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=admin,dc=site,dc=com" read by * none
    
   dn: olcDatabase={2}hdb,cn=config
   changetype: modify
   replace: olcSuffix
   olcSuffix: dc=site,dc=com
    
   dn: olcDatabase={2}hdb,cn=config
   changetype: modify
   replace: olcRootDN
   olcRootDN: cn=admin,dc=site,dc=com
    
   dn: olcDatabase={2}hdb,cn=config
   changetype: modify
   replace: olcRootPW
   olcRootPW: {SSHA}iTII/2MM15EycpLXZL54WlPL3ai2GQtS
    
   dn: olcDatabase={2}hdb,cn=config
   changetype: modify
   add: olcAccess
   olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=admin,dc=site,dc=com" write by anonymous auth by self write by * none
   olcAccess: {1}to dn.base="" by * read
   olcAccess: {2}to * by dn="cn=admin,dc=site,dc=com" write by * read
   ```

   其中`cn` 为管理员用户名，`dc`组成域名，例如`dc=site`和`dc=com`，则域名为`site.com`。

   执行：

   ```shell
   ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/openldap/chdomain.ldif
   ```

3. 启用memberof功能

   该模块的作用是当新添加用户时，将会自动给这些用户添加一个`memberOf`属性，用以查询某一个用户是属于哪一个或多个组。

   - 新增add-memberof.ldif，开启memberof支持并新增用户支持memberof配置：

     ```shell
     dn: cn=module{0},cn=config
     cn: modulle{0}
     objectClass: olcModuleList
     objectclass: top
     olcModuleload: memberof.la
     olcModulePath: /usr/lib64/openldap
     
     dn: olcOverlay={0}memberof,olcDatabase={2}hdb,cn=config
     objectClass: olcConfig
     objectClass: olcMemberOf
     objectClass: olcOverlayConfig
     objectClass: top
     olcOverlay: memberof
     olcMemberOfDangling: ignore
     olcMemberOfRefInt: TRUE
     olcMemberOfGroupOC: groupOfUniqueNames
     olcMemberOfMemberAD: uniqueMember
     olcMemberOfMemberOfAD: memberOf
     ```

     更新配置：

     ```shell
     ldapadd -Q -Y EXTERNAL -H ldapi:/// -f add-memberof.ldif
     ```

   - 新增refint1.ldif文件：

     ```shell
     dn: cn=module{0},cn=config
     add: olcmoduleload
     olcmoduleload: refint
     ```

     更新配置：

     ```shell
     ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f refint1.ldif
     ```

   - 新增refint2.ldif文件：

     ```shell
     dn: olcOverlay=refint,olcDatabase={2}hdb,cn=config
     objectClass: olcConfig
     objectClass: olcOverlayConfig
     objectClass: olcRefintConfig
     objectClass: top
     olcOverlay: refint
     olcRefintAttribute: memberof uniqueMember  manager owner
     ```

     更新配置：

     ```shell
     ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint2.ldif
     ```

4. 创建角色和组织单元：

   ```shell
   dn: dc=site,dc=com
   objectClass: top
   objectClass: dcObject
   objectClass: organization
   o: site Company
   dc: site
    
   dn: cn=admin,dc=site,dc=com
   objectClass: organizationalRole
   cn: admin
    
   dn: ou=People,dc=site,dc=com
   objectClass: organizationalUnit
   ou: People
    
   dn: ou=Group,dc=site,dc=com
   objectClass: organizationalRole
   cn: Group
   ```

   更新配置：

   ```shell
   ldapadd -x -D cn=admin,dc=site,dc=com -W -f base.ldif
   ```

5. 重启`slapd`服务

   ```shell
   systemctl restart slapd
   ```



## ldap命令

ldap命令常用参数

> -x：进行简单认证。
> -D：用来绑定服务器的dn。
> -w：绑定dn的密码。
> -b：指定要查询的根节点。 
> -H：制定要查询的服务器。
> -h：目录服务的地址

主要是
添加，将name.ldif文件中的条目加入到目录中

> ldapadd -x -D "cn=root,dc=dlw,dc=com" -w secret -f name.ldif

查找，使用ldapsearch命令查询“dc=dlw, dc=com”下的所有条目

> ldapsearch -x -b "dc=dlw,dc=com" 

修改，分为交互式修改和文件修改，推荐文件修改
将sn属性由“Test User Modify”修改为“Test User”

> dn: cn=test,ou=managers,dc=dlw,dc=com  
> changetype: modify  
> replace: sn  
> sn: Test User

输入命令

> ldapmodify -x -D "cn=root,dc=dlw,dc=com" -w secret -f modify  

删除，删除目录数据库中的“cn=test,ou=managers,dc=dlw,dc=com”条目

> ldapdelete -x -D "cn=root,dc=dlw,dc=com" -w secret "cn=test,ou=managers,dc=dlw,dc=com"  

# 客户端

图形客户端：

- Evolution
- Thunderbird
- Ekiga

安装：

```shell
yum install -y openldap-clients nscd nss-pam-ldapd #sssd authconfig-tui #authconfig-gtk
```

配置：

authconfig-tui和authconfig-gtk可选，分别提供命令行中的图形风格界面和gtk图形前端配置工具。图形界面中需要选择Use LDAP和Use LDAP Authentication，TLS认证可选。

authconfig命令配置LDAP，参数对应者图形界面中的各个选项：

```shell
#基本配置如下
ldapserver=192.9.20.1
ldapbasedn='dc=example,dc=com'

#authconfig --enableldap --enableldapauth --ldapserver=<server> --ldapbasedn=<dn> [--enableldaptls] [--ldaploadcacert=<URL>]

authconfig --enableldap --enableldapauth --enablemkhomedir --disablesssd --disablesssdauth --disableldaptls --enablelocauthorize --ldapserver=$ldapserver --ldapbasedn="$ldapbasedn" --enableshadow --update  #--enableforcelegacy

#如果配置TLS使用--enableldaptls, --enableldapstarttls和--ldaploadcacert=<URL>参数
#authconfig --enableldap --enableldapauth --ldapserver=<server> --ldapbasedn=<dn>  --enableldaptls ldaploadcacert=<URL>

systemctl enable --now nslcd
systemctl restart nslcd
```

可能还需要一些pam相关设置：

```shell
#===add mkdir pam module
if [[ ! $(grep pam_mkdir.so /etc/pam.d/system-auth) ]]; then #?pam__mkdir
  echo "session optional pam_mkhomedir.so skel=/etc/skel umask=077" >>/etc/pam.d/system-auth
fi

if [[ ! $(grep pam_mkhomedir /etc/pam.d/sshd) ]]; then
  echo "session    required     pam_mkhomedir.so  skel=/etc/skel/ umask=0022" >>/etc/pam.d/sshd
fi
```

检验：

```shell
getent passwd  #查看是否有ldap server的用户
ldapwhoami     #检查和ldapserver连接情况
```

ldap一般默认在389端口