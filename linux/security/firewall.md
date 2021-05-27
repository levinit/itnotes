

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

- 区域zone

  firewalld通过将网络划分成不同的区域，制定出不同区域之间的访问控制策略来控制不同程序区域间传送数据流。

  初始化区域

  - 公共区域（public）：不相信网络上的任何计算机，只有选择接受传入的网络连接。**默认的区域。**
  - 阻塞区域（block）：任何传入的网络数据包都将被阻止。
  - 工作区域（work）：相信网络上的其他计算机，不会损害你的计算机
  - 家庭区域（home）：相信网络上的其他计算机，不会损害你的计算机。
  - 隔离区域（DMZ）：也称为非军事区域，内外网络之间增加的一层网络，起到缓冲作用。对于隔离区域，只有选择接受传入的网络连接。
  - 信任区域（trueted）：所有网络连接都可以接受。
  - 丢弃区域（drop）：任何传入的网络连接都被拒绝。
  - 内部区域（internal）：信任网络上的其他计算机，不会损害你的计算机。只选择接受传入的网络连接。
  - 外部区域（external）：不相信网络上的其他计算机，不会损害你的计算机。只选择接受传入的网络连接。

​	*区域的名字是为了让使用者易读，其规则都是可以更改的。也可以新增区域。*



firewall-cmd对zone的操作默认只是临时生效，重启服务后失效，添加`--permanent`参数确保永久生效。

```shell
firewall-cmd --list-all   #列出所有规则（激活的zone的信息）
firewall-cmd --get-active-zones   #获取激活的zone的信息
firewall-cmd --get-default-zone    #获取默认zone
firewall-cmd --get-zone-of-interface=eth0 #获取某个网口的zone信息
#修改网卡的zone
firewall-cmd --permanent --zone=trusted --change-interface=eno1
#从zone移除网卡
firewall-cmd --zone=public --permanent --remove-interface=eth0

#添加端口或服务（的默认端口）   可使用1022-1025模式指定一个区域的端口
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-service=https   #开放https服务 默认443端口

#端口转发
firewall-cmd --zone=public --add-forward-port=port=22:proto=tcp:toport=10022 --permanent
firewall-cmd --zone=public --add-forward-port=port=22:proto=tcp:toport=10022:toaddr=192.168.10.10 --permanent

firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o eno1 -j MASQUERADE -s 172.16.1.0/24
```

 



# iptables

防火墙会从上至下的顺序来读取配置的策略规则，在找到匹配项后就立即结束匹配工作并去执行匹配项中定义的行为（即放行或阻止）。**规则是有顺序的，规则的顺序很重要，当规则顺序排列错误时，会产生很严重的错误。**

如果在读取完所有的策略规则之后没有匹配项，就去执行默认的策略。

iptables服务把用于处理或过滤流量的策略条目称之为规则，多条规则可以组成一个规则链，而规则链则依据数据包处理位置的不同进行分类。

```shell
iptables -L #查看规则链
iptables -F #清空规则链

iptables -I INPUT -p icmp -j ACCEPT
iptables -A INPUT -s 192.168.10.0/24 -p tcp --dport 22 -j ACCEPT

iptables -A POSTROUTING -t nat -o eno2 -j MASQUERADE
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