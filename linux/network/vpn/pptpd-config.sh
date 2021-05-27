#!/bin/sh
option='/etc/ppp/pptpd-options'
localip='10.0.0.251'  #your server ip
remoteip='10.0.0.1-100' #IPs for vpn clients
network_interface=eth0

dns1='119.29.29.29'
dns2='223.5.5.5'

username='vpnuser'
password='user@vpn'

#check user
if [[ $(id -u) -ne 0 ]]; then
  echo "need root permission"
  exit 1
fi

#check pptp support
modprobe ppp-compress-18
if [[ $? -ne 0 ]]; then
  echo "do not support pptp"
  exit 1
fi

#check TUN
# if [[ $(cat /dev/net/tun) ]]
# then
#   echo "TUN check failed"
#exit 1
# fi

#check pptpd app
if [[ ! $(which pptpd) ]]; then
  echo "pptpd not found"
  exit 127
fi

#check iptables
if [[ ! $(which iptables) ]]; then
  echo "iptables not found" && exit 127
fi

echo "
option $option
localip $localip
remoteip $remoteip
" >/etc/pptpd.conf

echo "
name pptpd
#debug
#refuse-pap
#refuse-chap
#refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
lock
nobsdcomp
novj
novjccomp
mppe-stateful
#nologfd
logfile /var/log/pptpd.log
ms-dns $dns1
ms-dns $dns2
" >$option

echo -n "$username   pptpd   $password   *" >/etc/ppp/chap-secrets

###IP forward
#check ip4 ipforward
if [[ $(sudo sysctl -n net.ipv4.ip_forward) -eq 0 ]]; then
  #echo 1 > /proc/sys/net/ipv4/ip_forward
  echo "net.ipv4.ip_forward=1" >/etc/sysctl.d/99-sysctl.conf
  sysctl --system
fi

#iptables
iptables -A INPUT -p gre -j ACCEPT
iptables -A OUTPUT -p gre -j ACCEPT

iptables -A INPUT -i ppp+ -j ACCEPT
iptables -A OUTPUT -o ppp+ -j ACCEPT

iptables -A INPUT -p tcp --dport 1723 -j ACCEPT

iptables -A INPUT -p 47 -j ACCEPT
iptables -A OUTPUT -p 47 -j ACCEPT

iptables -F FORWARD
iptables -A FORWARD -j ACCEPT

iptables -A POSTROUTING -t nat -o $network_interface -j MASQUERADE
iptables -A POSTROUTING -t nat -o ppp+ -j MASQUERADE

iptables -A FORWARD -p tcp --syn -s 10.0.0.0/24 -j TCPMSS --set-mss 1356

iptables-save >/etc/iptables/iptables.rules
#  rc.d save iptables
#service iptables save

systemctl restart iptables

modprobe nf_conntrack_pptp
echo "nf_conntrack_pptp" > /etc/modules-load.d/nf_conntrack_pptp.conf

systemctl enable pptpd
systemctl start pptpd

echo "VPN INFO
username: $username
password: $password
"
echo "pptpd need open ports:$(tput bold) TCP-1723$(tput sgr0)"

#客户端691 服务端 LCP: timeout sending Config-Requests

#可能是没启用 nf_conntrack_pptp
#可能是连接服务器的网络中有设备不支持GRE协议或NAT-T造成的

#云运营商也可能屏蔽pptp