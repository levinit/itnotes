# LDAP协议简介

**LDAP**，Lightweight Directory Access Protocol，是轻量目录访问协议，提供访问控制和维护分布式信息的目录信息。使用LDAP构建一个统一的账号管理、身份验证平台，实现SSO单点登录机制（用户在多个应用服务系统中使用同一套帐号密码）。



整个LDAP目录信息集可以表示为一个目录信息树，树中的一个节点称为条目（Entry），条目中包含该节点的属性及属性值。



- Directory目录：存放信息单元

- entry条目：LDAP的基本信息单元。由属性（attribute）的一个聚集组成，具有一个唯一的**专有名称**（**distinguished name**，DN）。

  - 对象类：与某个实体类型对应的一组属性（可继承）。
  - attribute 属性：与entry直接关联的信息，描述条目的某个信息，由一个属性类型和一个或多个属性值组成。

- LDIF：  LDAP数据交换格式（ *LDAP Data Interchange Format* ）是一种标准的文本文件，该文件的格式如下： 

  > ```text
  > [id] dn: distinguished_name
  > attribute_type: attribute_value…
  > attribute_type: attribute_value…
  > ```

  这种标准化格式称之为schema，schema指定对象的类型，以及每一个类型中的可选属性。

  


ldap中组织结构的描述术语：

- DC, domain component，域组件，一个组织的名字

  例如公司的名字，公司abc.com表示为dc=abc,dc=com

- OU, organization unit，组织单元，

  例如公司的一个部门，ou=research

  一个组织单元可以包含其他的一个活多个组织单元，例如research部门下属有dev部门和test部门。

- CN, common name，公用名称，一个组织单元中的一个成员

  例如公司某个部门的员工或员工的电脑主机名，cn=member1

  cn描述人的姓名时，可以使用属性sn(surname，姓)和givenName（名）组合。

- DN, distinguished name，专有名称，ldap全局唯一的名字，由CN、OU和DC组成

  例如公司abc.com的research部门的leader，dn表示为：`cn=leader,ou=research,dc=abc,dc=com`

- RDN, relative istinguished name，相对辨识名，类似文件系统中的相对路径，dn中的每个组成部分都是rdn

  例如`cn=user1,ou=users,dc=cluster,dc=org`中逗号分隔的每个部分就是这个dn的rdn。



一个ldap树状结构示例：

> ```
>                 公司(DC)
>  ｜-----------------｜-------------|------------|
> 研发部(OU)                      市场部(OU)     人事部(OU)
>  ｜-----------|---------|
> CTO(CN）  开发组(OU)  测试组(OU)
>               |
>            张三(CN)
> ```



# LDAP协议实现

- [openldap](https://openldap.org)

  开源的LDAP协议实现。

- [389 Directory Server](https://directory.fedoraproject.org)（389 DS），[Red Hat Directory Server(RHDS)](https://www.redhat.com/en/contact) 和 Red Hat Identity Management(RH Idm) 

  *Redhat7.4+版本和SUSE15.3+版本开始不再提供对openldap的官方支持，替代品为389 DS或RHDS。*

  389 DS由Fedora Directory Server项目发展而来；RHDS是389 DS的商业版本，提供一些高级管理功能；RH Idm是基于RHDS的身份管理解决方案，提供了完整的身份认证和授权功能，包括LDAP目录服务，Kerberos认证，证书管理和访问控制等。

- [Apache Directory Server](https://directory.apache.org)  (apache DS)

- [freeIPA](https://www.freeipa.org/page/Main_Page)

  开源身份认证和授权解决访问，集成389 DS，MIT Kerberos，AD，NTP、[DNS](https://pagure.io/bind-dyndb-ldap)、[Dogtag证书系统](http://pki.fedoraproject.org/)、[SSSD](https://pagure.io/SSSD/sssd)等。

- Microsoft Active Directory(windows AD)

- IBM Directory Server(基于DB2)

- Oracel Internet Directory(OID)

# 图形界面管理工具

- [freeIPA](https://www.freeipa.org/page/Main_Page)
- [ldap-account-manager](https://www.ldap-account-manager.org/lamcms/) (LAM)
- [ldapadmin](http://www.ldapadmin.org)
- [apache ds studio](https://directory.apache.org/studio/downloads.html)
- windows AD管理器
