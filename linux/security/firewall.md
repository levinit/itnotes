

# firewalld和iptables

firewalld服务底层仍然是调用iptables。

> - firewalld可以动态修改单条规则，动态管理规则集，允许更新规则而不破坏现有会话和连接；iptables，在修改了规则后必须得全部刷新才可以生效。
>
>   ```shell
>   firewall-cmd --reload  #firewalld 重载配置
>   iptables-save          #保存iptables的配置
>   ```
>
> - firewalld使用区域和服务而不是链式规则。
>
> - firewalld默认是拒绝的，需要设置以后才能放行；iptables默认是允许的，需要拒绝的才去限制。
>
> - firewalld自身并不具备防火墙的功能，而是和iptables一样需要通过内核的netfilter来实现。firewalld和iptables一样，它们的作用都用于维护规则，而真正使用规则干活的是内核的netfilter。只不过firewalld和iptables的结果以及使用方法不一样！



# firewalld

firewalld配置方法主要有三种：firewall-config（图形化工具）、firewall-cmd（命令行工具） 和 直接编辑XML文件（不建议）。

## ZONE区域管理

firewalld通过将网络划分成不同的区域，制定出不同区域之间的访问控制策略来控制不同程序区域间传送数据流。

- 内置的区域

  - 丢弃区域（drop）

    任何传入的网络包都被丢弃，且不会回应任何数据；只有传出网络连接才可用。


  - 阻塞区域（block）

    任何传入的网络连接都会被以icmp-host-prohibited的消息拒绝，只有在此系统内启动的网络连接才可用。


  - 公共区域（public）

    **默认的区域**，你不信任网络上的其他计算机，只接受选定的传入连接。


  - 外部区域（external）

    适用于启用IPv4伪装的外部网络，特别是针对路由器。你不信任网络上的其他计算机，只接受选定的传入连接。


  - 隔离区域（DMZ）

    也称为非军事区（Demilitarized Zone），可以被公开访问，但对的内部网络的访问受到限制，只接受选定的传入连接。


  - 工作区域（work）

    你相信网络上的大多数其他计算机，只接受选定的传入连接。


  - 家庭区域（home）

    你相信网络上的大多数其他计算机，只接受选定的传入连接。


  - 内部区域（internal）

    你相信网络上的大多数其他计算机，只接受选定的传入连接。


  - 信任区域（trueted）

    所有网络连接都可以接受

​	

**所有预定区域的传出请求都不会被阻断。**

预定的区域的默认规则实际上按策略分可简单分为完全阻断传入连接，接受特定的传入连接，完全信任几种。几个“只接受选定的传入连接”的区域在策略上有细微区别，具体可以看它们的配置策略，当然区域的策略都是可以更改的。

firewall-cmd都必须在firewalld服务启用时才可以使用，firewall-offline-cmd工具可以在未启用firewalld的情况下配置规则。

firewall-cmd对zone的操作默认只是临时生效，重启服务后失效，**添加`--permanent`参数确保永久生效**。



或者使用一些命令将当前临时生效的配置转为永久有效：

```shell
firewall-cmd --runtime-to-permanent
```



### 区域配置信息

```shell
firewall-cmd --get-zones                   #列出可用的zones
firewall-cmd --get-active-zones            #获取激活的zone的信息
firewall-cmd --get-default-zone            #获取默认zone
firewall-cmd --get-zone-of-interface=eth0  #获取某个网口所属的zone信息
firewall-cmd --list-all                    #列出默认的active的zone的信息
firewall-cmd --list-all --zone=<zone>      #列出指定zone的所有信息
```



### 创建/删除区域

除了使用内置区域，也可以自建区域。

创建/修改/删除区域都需要重新加载firewalld配置：

```shell
firewall-cmd --reload
firewall-cmd --get-zones  #验证
```



自定义区域的配置文件通常放在 `/etc/firewalld/zones/` 目录下，需要复制一个现有的区域文件（如public.xml）作为模板，然后进行修改。

修改后的文件示例：

```xml
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>My Custom Zone</short>
  <description>A custom zone for specific network interfaces or sources.</description>
  <target>default</target>
  <service name="ssh"/>
  <port port="8080" protocol="tcp"/>
</zone>
```

删除区域只需要删除文件并重新加载firewalld即可。



### 默认区域配置

操作firewalld时如不指定区域则默认将操作应用于该区域。

```shell
#默认zone的查看
firewall-cmd --get-default-zone
#默认zone的修改（该设置无需--permanent也是永久生效的）
firewall-cmd --set-default-zone <zone_name>
```



### 网口的区域分配

将网口分配到指定区域

```shell
#修改网口的zone
firewall-cmd --permanent --zone=trusted --change-interface=eno1
#从zone移除网口
firewall-cmd --permanent --zone=public --remove-interface=eth0
#向zone中添加网口
firewall-cmd --permanent --zone=trusted --add-interface=eth0
```



### 区域的端口/服务配置

服务service是一个包含了默认配置的规则集合，例如ssh服务中配置了放行端口22对tcp。

```shell
#添加端口或服务（的默认端口）   可使用1022-1025模式指定一个区域的端口
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-service=https   #开放https服务 默认443端口
#移除改为--remove-port 或 --remove-service即可

#获取所有服务
firewall-cmd --get-services
#查看特定服务的信息
firewall-cmd --info-service=<service_name>
```



### 区域的端口转发

```shell
#端口转发 将public zone上22/tcp 流量转发到192.168.10.10的22/tcp
firewall-cmd --zone=public --add-masquerade --permanent

firewall-cmd --zone=public --add-forward-port=port=10022:proto=tcp:toaddr=192.168.10.10:toport=22 --permanent

#firewall-cmd --zone=public --add-forward-port=port=22:proto=tcp:toport=10022 --permanent
#firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o eno1 -j MASQUERADE -s 172.16.1.0/24
```



# iptables

iptables防火墙会从上至下的顺序来读取配置的策略规则，在找到匹配项后就立即结束匹配工作并去执行匹配项中定义的行为（即放行或阻止）。**规则是有顺序的，规则的顺序很重要，当规则顺序排列错误时，会产生很严重的错误。**

如果在读取完所有的策略规则之后没有匹配项，就去执行默认的策略。

iptables服务把用于处理或过滤流量的策略条目称之为规则，多条规则可以组成一个规则链，而规则链则依据数据包处理位置的不同进行分类。

```shell
iptables -L #查看规则链
iptables -F #清空规则链

iptables -I INPUT -p icmp -j ACCEPT
iptables -A INPUT -s 192.168.10.0/24 -p tcp --dport 22 -j ACCEPT

iptables -A POSTROUTING -t nat -o eno2 -j MASQUERADE

iptables-save #保存规则
#一些发型版执行以下命保存
iptables-save >>/etc/iptables/iptables.rules
```

- 对要处理的数据包添加规则

   `-I`或`--insert`在规则链最前插入     `-A`或`--append`在规则链最后面添加

  `-D`或`--delete` 从规则链中删除规则

  数据包根据处理位置分类

  - PREROUTING     在进行路由选择前处理数据包
  - POSTROUTING  在进行路由选择后处理数据包
  - INPUT                  处理流入的数据包
  - OUTPUT              处理流出的数据包
  - FORWARD           处理转发的数据包

- `-j`  处理数据包的方式

  - ACCEPT   允许通过
  - REJECT     拒绝通过 返回拒绝响应的信息
  - LOG         记录日志信息
  - DROP       丢弃请求 拒绝通过 不返回任何信息
  - MASQUERADE    封包伪装

- `-p`  协议类型，如：`tcp`  `udp`   `icmp`

- `-s`  指定数据包来源地址

- `-o`或`--output-interface`  指定网卡

- `--dport`  指定端口



firewalld和iptables在规则上的一大区别是：firewalld默认是拒绝的（大多数zone，除了像trusted之类的zone），需要设置以后才能放行。而iptables默认是允许的，需要拒绝的才去限制；

因此，当iptables和firewall同时存在时，如果在firewalld上已经添加了某个禁止策略，单依然能访问，应当排查下iptables是否启用了。