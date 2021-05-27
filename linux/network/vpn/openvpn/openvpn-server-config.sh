#!/bin/sh
[[ $(which openvpn) ]] || echo "can not find openvpn"

server='1.2.3.4' #your server ip or domain
local=0.0.0.0
interface=eth0  #your server interface
subnet=10.0.0.0 #virtual subnet
prefix=24
mask=255.255.255.0 #virtual subnet netmask
dns1=119.29.29.29  #dns1 for vpn clients(optional)
dns2=223.5.5.5     #dns2 for vpn clients(optional)

#bridge mode (optional)
bridge_gateway=192.168.1.251
bridge_ip_start=192.168.1.100
bridge_ip_end=192.168.1.200

config_name=server

#vpn mode : tap (bridge) or tun (NAT)
dev=tun    #a virtual interface device name
port=1194  #default is 1194
proto=udp4 #udp or udp4 or tcp or tcp4

crt_name=server
server_name=$crt_name
cert=$crt_name.crt
key=$crt_name.key

ipp=/etc/openvpn/server/ipp.txt
ccd=/etc/openvpn/server/ccd #assign static IP for users , not recommended with duplicate-cn
#duplicate-cn # allow 2 or more connection for same user(or cert)

log_dir=/var/log/openvpn
status=$log_dir/status.log
log=$log_dir/server.log

check_script=/etc/openvpn/server/check-user-pwd.sh
user_pwd_file=/etc/openvpn/server/user-pwd

function env_check() {
  if [[ ! $(which openvpn) || ! $(which easyrsa) ]]; then
    echo "need openvpn and easyrsa"
    exit 1
  fi
  #check
  #modinfo tap -n
  #modinfo tun -n
}

function gen_certs() {
  cd /etc/easy-rsa
  export EASYRSA=$(pwd)
  export KEY_COUNTRY="CN"
  export KEY_PROVINCE="BJ"
  export KEY_CITY="beijing"
  export KEY_ORG="unkown"
  export KEY_OU="some"

  export KEY_EMAIL="xx@yy.zz"
  export KEY_CN="yy"
  export KEY_NAME=$server
  #export PKCS11_MODULE_PATH="some"
  #export PKCS11_PIN=123456
  cd /etc/easy-rsa
  easyrsa init-pki

  #=====gen server files

  #ca.crt    CA public certificate
  easyrsa build-ca $crt_name nopass
  cp /etc/easy-rsa/pki/ca.crt /etc/openvpn/server/

  #$crt_name.key    Server private key
  easyrsa gen-req $server_name nopass
  cp /etc/easy-rsa/pki/private/$key /etc/openvpn/server/

  #$crt_name sign the Server certificates on the CA
  echo yes | easyrsa sign-req server $crt_name
  cp /etc/easy-rsa/pki/issued/$cert /etc/openvpn/server/

  #dh.pem     Diffie-Hellman (DH) parameters file
  openssl dhparam -out /etc/openvpn/server/dh.pem 2048

  #ta.key     Hash-based Message Authentication Code (HMAC) key
  openvpn --genkey --secret /etc/openvpn/server/ta.key

  #=====gen client files (optional, for cert-file-authentication method)
  #client.key    certificate and private key
  easyrsa gen-req client1 nopass
  cp /etc/easy-rsa/pki/private/client1.key /etc/openvpn/client/

  #client.crt  sign the Client certificates on the CA
  easyrsa sign-req client client1
  cp etc/easy-rsa/pki/issued/client1.crt /etc/openvpn/client/
}

function net_forward() {
  if [[ $(sudo sysctl -n net.ipv4.ip_forward) -eq 0 ]]; then
    #echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward=1" >/etc/sysctl.d/99-sysctl.conf
    sysctl --system
  fi

  iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE

  #iptables -t nat -A POSTROUTING -s $subnet/$prefix -o $interface -j MASQUERADE

  iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  # iptables -A FORWARD -p tcp --syn -s $subnet/$prefix -j TCPMSS --set-mss 1460

  iptables-save >>/etc/iptables/iptables.rules
}

function vpn_server_config() {
  mkdir $ccd -p
  echo "
;local 0.0.0.0
port $port
proto $proto
dev $dev
ca ca.crt
cert $cert
key $key
dh dh.pem
ifconfig-pool-persist $ipp
client-config-dir /etc/openvpn/server/ccd
;tls-auth ta.key 0
topology subnet
server $subnet $mask
$([[ $(echo $dev | grep tap) ]] && echo "server-bridge $bridge_gateway $mask $bridge_ip_start $bridge_ip_end")
keepalive 60 360
push \"dhcp-option DNS $dns1\"
push \"dhcp-option DNS $dns2\"
push \"redirect-gateway def1 bypass-dhcp\"
#push "route 1.2.3.4 0.0.0.0 net_gateway"
#push "route 10.0.0.1 255.255.255.0 vpn_gateway"
client-to-client
duplicate-cn
;comp-lzo
persist-key
persist-tun
;max-clients 100
;user nobody
;group nobody
status $status
log $log
log-append $log
verb 3
client-cert-not-required
verify-client-cert none
explicit-exit-notify 1
username-as-common-name
script-security 3
;plugin /usr/lib/openvpn/openvpn-auth-pam.so login
auth-user-pass-verify $check_script via-env
" >/etc/openvpn/server/$config_name.conf

  systemctl start openvpn-server@$config_name
  systemctl enable openvpn-server@$config_name

}

function gen_check_user_pwd_script() {
  if [[ -f check-user-pwd.sh ]]; then
    cp -f check-user-pwd.sh $check_script
    chmod +x $check_script
  fi
}

function gen_client_ovpn_file() {
  echo "
client
dev $dev
proto $proto
remote $server $port
resolv-retry infinite
nobind
;user nobody
;group nobody
;persist-key
persist-tun
ca ca.crt
;cert client1.crt
;key client1.key
;ns-cert-type server
comp-lzo
verb 3
auth-user-pass
;auth-user-pass user-pwd-file
reneg-sec 3600000
;route 172.16.100.0 0.0.0.0 net_gateway
;route 10.252.252.0 255.255.255.0 vpn_gateway
  " >/etc/openvpn/client/client.ovpn
}

function gen_ccd_file_script() {
  echo '#!/bin/sh
    username=$1
    ip=$2
    netmask=$3
    touch /etc/openvpn/server/$username
    echo "ifconfig-push $ip $netmask" > $username
  ' >/etc/openvpn/server/gen_user_ccd_config.sh
  chmod +x /etc/openvpn/server/gen_user_ccd_config.sh
}

function gen_list_vpn_clients_script() {
  echo "#!/bin/sh
echo '-------online openvpn clients-------'
# grep -E  ^ROUTING_TABLE $status
grep -E  ^ROUTING_TABLE openvpn-status.log|awk -F ',' '{for(i=2;i<=5;i++) printf("%s | ",$i);printf("\n");}'
" >/usr/local/bin/openvpnclients
  chmod +x /usr/local/bin/openvpnclients
}

env_check
gen_certs
net_forward
gen_check_user_pwd_script
vpn_server_config
gen_client_ovpn_file
gen_ccd_file_script
gen_list_vpn_clients_script

echo "add username and password in $user_pwd_file"
echo "#username     password" | tee $user_pwd_file

echo "=======client files====="
echo "Generated a client vpn profile config: /etc/openvpn/client/client.ovpn"

echo "=======user password file ($user_pwd_file) syntax======="
echo -e "user1    pwd1\nuser2    pwd2"

echo "=======static ip config files ($ccd)======="
echo -e "1. Create a file with the same name as username"
echo -e "2. Add a line as below to the file"
echo "ifconfig-push 10.0.0.2 255.255.255.0"

echo "show online vpn clients: openvpnclients"
