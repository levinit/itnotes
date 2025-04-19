# DNS服务器

## bind

 [BIND](https://www.isc.org/downloads/bind/) (Berkeley Internet Name Daemon，伯克利互联网名称服务）。

1. 安装bind。

2. 配置

   如果安装了bind-chroot，BIND会被封装到一个伪根目录内，配置文件的位置变为：
   `/var/named/chroot/etc/named.conf`和`/var/named/chroot/var/named/`

   - `/etc/named.conf`（bind配置文件）

     ```shell
     options{
         directory "/var/named";
     };
     
     zone "example.com" {
         type master;
         file "example.com.zone";
     }
     ```

   - `/var/named/*.zone`  zone文件（域的dns信息）
     ``/var/named/example.com.zone`文件示例：

     ```shell
     $TTL 3600;
     @ IN SOA example.com. user1.example.com. (222 1H 15M 1W 1D)
     @ IN NS dns1.example.com.
     dns1 IN A 123.123.123.123
     www IN A 233.233.233.233
     ```

3. 启用`named`服务。

## dnsmasq

[Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) 提供 DNS 缓存和 DHCP 服务功能。



TTL值
 TTL值全称是“生存时间（Time To Live)”，表示解析记录在DNS服务器中的缓存时间，`TTL`的时间长度单位是秒。

