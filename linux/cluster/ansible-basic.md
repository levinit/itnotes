[ansible doc](https://docs.ansible.com)

# 安装

[ansible installation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

参看文档确定系统环境满足[ansible使用要求](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#prerequisites)，一般需要：

- 控制节点（安装和执行ansible的主机）

  - python2.7+（建议python3+）
  - *nix （Unix及衍生版，Linux），windows系统不可以做控制主机

- 被管理节点

  - python2.7+（建议python3+）

  - 开启sshd

    管理主机默认使用ssh与托管节点通信，使用 sftp传输文件，如果 sftp 不可用，可在 ansible.cfg 配置文件中配置成 scp 的方式。

  - 如果开启了selinux，需要安装`libselinux-python`

# 配置

## 配置文件

* `ANSIBLE_CONFIG`环境变量对应的文件

  ```shell
  export ANSIBLE_CONFIG=/path/to/conf_file
  ```

* 当前目录（`$PWD`）中的ansible.cfg

* `~/.ansible.cfg`

* ansible程序默认的config文件，例如包管理安装的ansbile的配置文件一般是`/etc/ansible/ansible.cfg`



### anisble-config工具

`ansible-config`工具：实用程序允许用户查看所有可用的配置设置、它们的默认值、如何设置它们以及它们的当前值来自何处，其参数的作用如下：

> ```shell
> list            Print all config options
> dump            Dump configuration
> view            View configuration file  #查看当前生效的配置文件
> ```



### 配置文件安全

注意配置文件的读写权限：如果允许从全局可写（其他任何用户都可写）的当前工作目录中加载ansible.cfg，会造成严重的安全风险；因此，如果配置目录全局写入，则不会自动从当前工作目录中加载配置文件。

一般不建议在配置文件中写上ssh的密码信息（使用密码认证），建议配置好控制节点到被管理节点的密钥认证。



### ansible主配置文件

INI格式的一种变体，哈希号（#）和分号（；）都可以作为注释标记。但是，如果注释与规则值内联，则只允许分号引入注释。

```ini
[defaults]       ;默认的配置项，可在inventory文件中覆盖这些项的值
inventory      = ~/.ansible/hosts         ;库存文件 该文件配置被管理主机信息
#library        = /usr/share/my_modules/  ;Ansible模块位置
#remote_tmp     = ~/.ansible/tmp
#local_tmp      = ~/.ansible/tmp
log_path=/var/log/ansible.log  ;默认不记录
#---
#ansible在被管理节点使用的ssh相关配置项，这些值也可在inventory文件中设置
host_key_checking = False
#ansible_ssh_user=root
#an
#ansible_ssh_port=22
#ansible_ssh_pass=pwd@root
#ansible_ssh_key=/root/.ssh/id_rsa
#private_key_file = ~/.ssh/id_rsa
#---
forks = 16        ;并发连接数，默认为5

[privilege_escalation] ;用户权限相关
#become=True           ;是否使用sudo
#become_method=sudo 
#sudo_user=root    ;默认执行命令的用户
#ask_sudo_pass = True
#ask_pass      = True  ;如果主机清单没有配置远程密码，则执行ansible命令会询问密码
#---
#timeout=60
#---
#ansible_shell_type =   ;默认sh（现在Linux发行版中实际sh多指向bash/dash等）
#interpreter_python = /usr/bin/python3     ;被管理节点使用的python路径
```



### inventory文件

文件格式支持ini和yaml两种格式。一个inventory文件示例（INI）：

```ini
#-----未分组的主机，一行一个主机地址
manage-server
10.0.0.201
#--如果ssh端口不是默认的22，可在主机名后指定ssh的端口
login01:10022
#--在主机后面可以添加为本主机特别指定的环境变量
db01    ansible_ssh_port=10022
#--连接类型，默认smart，会使用ssh且启用ssh的ControlPersist保持连接（如果可用）
mgt01   ansible_connection=local  ;本机使用local

#-----主机分组
[computing]       ;方括号中是组名
fat01
#--前缀相同，而后缀有一定连续递增的规律的主机可使用简写形式
cn[01:03]          ;数字简写，表示cn01 cn02 cn03
gpu-[a:c]          ;字母简写，表示gpu-a gpu-b gpu-c

#-----组变量
[computing:vars]  ;组名:vars
nterpreter_python = /usr/bin/python

[vm]
vm[01:06]

#-----一个组可包含其他组
[clients:children]  ;组名:children 其他组成为本组的子组
computing
vm

```



### 主机环境变量文件

在 inventory 主文件中保存所有的变量并不是最佳的方式，还可以保存在与 inventory 文件保持关联的独立的文件中，文件格式为 YAML。

```yaml
```



# 使用

```shell
ansible <host-pattern> [options]
```

`<host-pattern`指inventory中的主机名或主机组名，特别的，`all`或`*`：inventory中的所有主机。



常用选项：

- `-m <module>`  指定模块名称，如不指定，默认使用`command`模块（设置默认模块可以修改`module_name`变量）



```shell
ansible all --list-host  #查看所有主机

#简单的测试，-m指定使用ping模块，检查所有主机连通性
ansible all -m ping

#对于没有进行ssh密钥认证的主机，也可以调用authorized_key模块完成公钥上传
ansible all -m authorized_key -a "user=root key='{{ lookup('file', '/root/.ssh/id_rsa.pub') }}' path=/root/.ssh/authorized_keys manage_dir=yes" --ask-pass

#再不指定module的情况
```

ansible 返回的类型是一个键值对的 json 格式的数据，`ping`返回内容示例：

>```shell
>localhost | SUCCESS => {
>    "changed": false,
>    "ping": "pong"
>}
>```



## 模块

