#!/bin/bash
unalias -a
set -e

if [[ $(id -u) -ne 0 ]]; then
  echo "need root or $sudo." && exit 126
fi

sudo='sudo'
[[ $(command -v sudo) ]] || sudo=''

#-----
jail_file=/etc/fail2ban/jail.d/jail.local

jails=(sshd mongodb-auth mysqld-auth vsftpd vnc-auth)

default_jail=(sshd)

logpath=''

#log path

bandtime=360000 #默认秒s无须写出 其他可用单位m h d w
findtime=3600   #
maxretry=5

#-----

function install_fail2ban() {
  if [[ $(command -v pacman) ]]; then
    pacman -Syy fail2ban --no-confirm
  elif [[ $(command -v yum) ]]; then
    yum install -y epel-release && yum makecache
    yum install -y fail2ban
  elif [[ $(command -v apt) ]]; then
    apt install -y fail2ban
  else
    echo "not support package manager, please install fail2ban"
    exit 1
  fi
  systemctl enable fail2ban
}

function add_vnc_auth_filter() {
  echo "[Definition]
failregex = authentication failed from <HOST>
ignoreregex =" >/etc/fail2ban/filter.d/vnc-auth.conf
}

function gen_jail_file() {
  [[ -f $jail_file ]] && mv $jail_file $jail_file.bak

  echo "[DEFAULT]
bantime = $bandtime
findtime = $findtime
maxretry = $maxretry
" >$jail_file
}

function services_logpath() {
  case $1 in
  mongodb-auth)
    logpath=/var/log/mongodb/mongod.log
    ;;
  vnc-auth)
    echo -e "!!! should add \e[1m logpath \e[0m and \e[1m port \e[0m below \e[33m vnc-auth \e[0m section in /etc/fail2ban/$jail_file"
    echo "===eg:
    [vnc-auth]
    port=5901
    logpath=/home/testuser/.vnc/*.log
    "
    ;;
  *)
    echo ''
    ;;
  esac
}

function add_jails() {
  echo "$(tput bold)Select filter service：$(tput sgr0)"
  local i=0
  for jail in ${jails[*]}; do
    echo "$i) $jail $([[ $i -eq 0 ]] && echo [default])"
    i=$((i + 1))
  done

  echo "-------------"
  read select_jails
  echo "---selected jails: ${select_jails[*]}"

  [[ "$select_jails" ]] || select_jails='0'

  for select_jail in $select_jails; do
    local this_jail=${jails[$select_jail]}
    [[ $this_jail ]] || continue

    #gen jail
    services_logpath $this_jail
    [[ $logpath ]] && log="logpath = $logpath"

    echo "[$this_jail]
enabled = true
"$log"
" >>$jail_file
  done

  systemctl restart fail2ban
}

function gen_scripts() {
  local jail_list=$(fail2ban-client status | grep -i 'Jail list' | cut -d ":" -f 2)
  local scripts=(banip unbanip addignoreip delignoreip)

  cd /tmp
  for script in {banip,unbanip}; do
    echo '#!/bin/bash
jail=$1
ip="${@:2:$#}"' >$script

    echo "
jails=\"$jail_list\"
if [[ ! \$(echo \$jails |grep $jail) ]]
then
  echo you should specified jail name
  echo jails: $jail_list
  exit 1
fi" >>$script
  done

  #banip
  echo '
if [[ "$ip" ]]
then
  fail2ban-client set $jail banip "$ip"
else
  echo "usage: banip [jail_name] [ip]"
  echo "eg: banip sshd 10.0.0.1"
fi' >> banip

  #unbanip
  echo '
if [[ $ip == 'all' ]]
then
  fail2ban-client set $jail unban --all
elif [[ "$ip" ]]
then
  fail2ban-client set $jail unbanip $ip
else
  echo "usage: unbanip [jail_name] [ip|all]"
  echo "eg: unbanip sshd 10.0.0.1"
  echo "eg: unbanip sshd all"
fi
' >> unbanip

  #ignore ip
  cp -av banip addignoreip
  sed -i -E "s/banip/addignoreip/g" addignoreip

  ##delete ignore ip
  cp -av addignoreip delignoreip
  sed -i -E "s/addignoreip/delignoreip/g" delignoreip

  ##sshd blacklist
  echo '#!/bin/bash
jail=${1:-all}

if [[ $jail == 'all' ]]
then
  jail_list=$(grep -Eo "\[.+\]" /etc/fail2ban/jail.d/jail.local |grep -v DEFAULT)
  for jail_item in ${jail_list[*]}
  do
    jail_name=${jail_item:1:-1}
    echo -e "\e[1m +++++jail $jail_name +++++ \e[0m"
    $sudo fail2ban-client status ${jail_name}
  done
else
  $sudo fail2ban-client status ${jail}
fi

echo -e "\e[1m ++++++++++ \e[0m"
echo "usage blacklist [jail_name|all]
eg. 
blacklist sshd   #default jail_name is sshd
blacklist vsftpd
"

echo "=====commands for $jail jail=====
banip sshd [ip1 ip2]        : ban 1 IP or more IPs, eg, banip 8.8.8.8 9.9.9.9
unbanip sshd [ip1 ip2]      : unban 1 IP or more IPs
unbanip sshd all            : unban all IPs
addignoreip sshd [ip1 ip2]     : ignore 1 IP or more IPs
delignoreip sshd [ip1 ip2]  : delete a ignored IP"

' >blacklist

  for script in ${scripts[@]}; do
    install -m 755 $script /usr/local/bin/
  done

  install -m 755 blacklist /usr/local/bin/
}

#=====
command -v fail2ban-server || install_fail2ban
gen_jail_file
add_jails
gen_scripts

#=====
echo "Generate jail file done. see $jail_file"
blacklist
