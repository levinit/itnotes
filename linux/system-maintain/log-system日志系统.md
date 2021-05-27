# rsyslog日志系统

一个替代syslog的综合日志管理系统。

## 日志配置文件

rsyslog的主配置位于`/etc/rsyslog.conf`，一般不修改该文件，而是在`/etc/rsyslog.d/`目录下添加配置文件覆盖主配置文件中的配置。

日志服务为`rsyslog`，修改配置后应该重启日志服务。

配置语法参看主配置文件中的示例，以

> 日志过滤规则  日志操作行为

的格式配置。

- 过滤规则

  过滤规则部分包含两部分：`设施(facility)`和`优先级(priority)`，二者以`.`分隔：`facility.priority`。

  - 设施（产生日志的子系统）包含：

     - 认证过程  auth  pam验证） authpriv（特权信息）
     - 计划任务  cron（crontab ，at）
     - 守护进程  daemon（
     - Linux内核  kern
     - 打印机  lpr
     - 邮件  mail
     - syslog  rsyslog守护进程生成的消息
     - 自定义消息  local0 ~ local7
     - 所有设施  `*`

  - 优先级规则中可以使用限定符，以收集符合需要的日志信息。

    日志优先级参看下文[systemd日志的优先级](#journal日志优先级)，其只比systemd的日志优先级多两个级别：`none`（没有级别）和`*`(所有级别，除了none）。

    优先级限定符：

    - `*`  任何级别的日志
    - `=` 仅符合指定级别的日志
    - `!`  除了某个级别之外的日志

- 日志记录行为(action)

  其描述了如何记录日志，如果有多个日志记录行为，可以用`&`连接。

  日志记录行为可以是：

  - 记录到普通文件或设备

    - 一个本系统中的文件（使用文件路径即可），如`/var/log/log1`
    - 串行或并行设备（标识符），如`/dev/ttyS2`

  - 转发到远程日志服务器

    以`@地址`形式，如`@192.168.1.222:514`，默认使用UDP，如果使用TCP，则需要使用两个`@`，如`@@192.168.1.222:514`。

    参看[日志服务器](#rsyslog日志服务器)

  - 发送到指定用户的终端

    前提是当前该用户已经登录，如`admin1`

  - 忽略或丢弃日志，使用`~`

  - 执行指定的脚本

示例：

```shell
*.*                                         @192.168.1.99:514
authpriv.*                          var/log/secure
local7.*                               /var/log/boot.log
cron.*                                   /var/log/cron
```

## rsyslog日志服务器

rsyslog既可以作为客户端发送日志，也可以作为服务端接收日志。

- 客户端

  ```shell
  $ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
  $ModLoad imjournal # provides access to the systemd journal
  $WorkDirectory /var/lib/rsyslog
  $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
  $template myFormat,"%timestamp% %fromhost-ip% %msg%\n"   #######自定义模板的相关信息
  $IncludeConfig /etc/rsyslog.d/*.conf
  $OmitLocalLogging on
  $IMJournalStateFile imjournal.state
  *.*          @192.168.99.99:514                      ########该声明告诉rsyslog守护进程，将系统上各个设备的各种日志的所有消息路由到远程rsyslog服务器（192.168.99.99）的UDP端口514。@@是通过tcp传输，一个@是通过udp传输。
  *.info;mail.none;authpriv.none;cron.none                /var/log/messages
  authpriv.*                                              /var/log/secure
  mail.*                                                  -/var/log/maillog
  cron.*                                                  /var/log/cron
  *.emerg                                                 :omusrmsg:*
  uucp,news.crit                                          /var/log/spooler
  local7.*                                                /var/log/boot.log
  local0.*                                             /etc/keepalived/keepalived.log
  ```

- 服务端

  ```shell
  $ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
  $ModLoad imjournal # provides access to the systemd journal
  
   # 开启udp接收日志
  $ModLoad imudp
  $UDPServerRun 514
  $template RemoteHost,"/data/syslog/%$YEAR%-%$MONTH%-%$DAY%/%FROMHOST-IP%.log"   
  *.*  ?RemoteHost
  & ~
  # 开启tcp协议接受日志
  $ModLoad imtcp
  $InputTCPServerRun 514
  
  $WorkDirectory /var/lib/rsyslog
  $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
  
  # 启用/etc/rsyslog.d/*.conf目录下所有以.conf结尾的配置文件
  $IncludeConfig /etc/rsyslog.d/*.conf     
  
  $OmitLocalLogging on
  $IMJournalStateFile imjournal.state
  *.info;mail.none;authpriv.none;cron.none                /var/log/messages
  authpriv.*                                              /var/log/secure
  mail.*                                                  -/var/log/maillog
  cron.*                                                  /var/log/cron
  *.emerg                                                 :omusrmsg:*
  uucp,news.crit                                          /var/log/spooler
  local7.*                                                /var/log/boot.log
  local0.*                                                /etc/keepalived/keepalived.log
  ```




## logrotate日志轮转





由于systemd的普及，一些应用已经将日志信息交由[systemd journal](#systemd journal日志系统)接管（syslog可以直接将未迁移的应用的日志传入journal中），参看下文。

# systemd journal日志系统

systemd 提供名为journal的日志系统，使用systemd 日志，无需额外安装日志服务（syslog）。使用`journalctl`查看日志输出。

图形界面工具：

- gnome-logs

## coredump

## journal日志优先级

0. emerg
1. alert
2. crit
3. err
4. waring
5. notice
6. info
7. debug

## 过滤日志

`journalctl`可以根据特定字段过滤输出，常用日志过滤参数：

- `-f`  监控新的日志信息

- 根据[日志等级](#journal日志优先级)过滤：`-p` 或`--priority=` 其后指定日志等级（可是使用名字或数字）

  指定等级范围时，在两个等级间使用`..`，如：`emerg..waring`（或`0..4`）

- 指定起止时间之间的日志

  - `-S`或`--since`  某个时间之后的日志信息
  - `-U`或`--until`  某个时间之前的日志信息

- 启动日志：`-b`或`--boot`

  其后可使用`-数字`指定查看某次启动的信息，`0`表示本次启动。

  ```shell
  journalctl -b  #所有记录在案的启动日志
  journalctl -b -0  # 本次启动的日志
  journalctl -b -1  #上次启动的日志  -1上一次 -2 上上一次，以此类推
  ```

- 内核日志：`-k`或`--dmesg` 

- 特定服务单元日志：`-u`或`--unit` 其后指定服务单元名字

  ```shell
  journalctl -u sshd --since "2018-11-11 11:11:11" --until "10 min ago"
  journalctl -u sshd -p emerg..warning
  ```

## 日志清理和容量限制

日志存放在`/var/log/journal`，可以直接删除相关文件，`journactl`也提供了`--vaccum`参数用以清理超过指定范围的日志内容：

```shell
max_size=200M  #最大日志保存容量
oldest_date=2weeks  #最旧日志保存时间
journalctl --vacuum-size=$max_size  #超出200M空间的旧日志将被清理
journalctl --vacuum-size=$oldest_date  #两周前的日志将被清理 
```

默认日志最大限制为所在文件系统容量的 10%，可在`/etc/systemd/journald.conf.d/`中添加单独的配置文件限制大小：

```shell
journal_size=200M  #最大日志容量
echo "[Journal]
SystemMaxUse=$journal_size" > /etc/systemd/journald.conf.d/00-journal-size.conf
systemctl restart systemd-journald.service
```

# 用户行为记录相关日志

以二进制保存，需要使用特定工具查看。

- `/var/run/utmp`  当前登录的每个用户的信息。 

  ```shell
  who  #主要用于查看当前在线上的用户
  ```

- `/var/log/wtmp`  登录、注销及系统的启动、停机的事件

  ```shell
  w  #登录到系统的用户情况  比who内容更多 包含用户正在运行的进程信息
  last  #历次登录情况
  ```

- `/var/log/btmp`  记录失败的登录尝试

  ```shell
  lastb  #登录失败的记录
  ```

- `/var/log/lastlog`  用户最近一次登录记录

  ```shell
  lastlog  #所有用户最近一次登录记录
  ```


