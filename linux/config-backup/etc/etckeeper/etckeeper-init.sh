#!/bin/sh
if [[ $(whoami) != root ]]
then
    echo 'Need root'
    exit
fi

if [[ $(which pacman) ]]
then
    pacman -S etckeeper
    echo "sudo pacman -Qq > /etc/pkglist" > /etc/etckeeper/pre-commit.d/40pkglist
elif [[ $(which yum) ]]
then
    yum install -y epel-release
    yum install etckeeper
elif [[ $(which dnf) ]]
then
    dnf install -y epel-release
    dnf install etckeeper
elif [[ $(which apt) ]]
then
    apt install etckeeper
fi

etckeeper init

echo '
#ignore all
*

#white list
!*/
!pkglist
!etckeeper-init.sh
!.gitignore
!.etckeeper

!bluetooth/audio.conf
!default/grub
!default/tlp
!etckeeper/etckeeper.conf
!etckeeper/**/40pkglist
!pulse/default.pa
!sysctl.d/
!systemd/coredump.conf
!systemd/journald.conf
!systemd/logind.conf
!systemd/**/nvidia-enable.service
!UPower/
!xrdp/xrdp.ini
!environment
!locale.conf
!mkinitcpio.conf
!pacman.conf

!proxychains.conf
!docker/daemon.json
!nginx/nginx.conf
!nginx/conf.d/

'> /etc/.gitignore

rsa_key='/root/.ssh/id_rsa'
if [[ ! -e $rsa_key && ! -e $rsa_key.pub ]]
then
    echo "\e[1m not found ssh key-pair, generate ssh key-pair \e[0m"
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
fi
echo -e "\e[1m upload root's public key to git server\e[0m"

read -p "input remote git repo url:" repo_url

sed -i '/PUSH_REMOTE/d' /etc/etckeeper/etckeeper.conf
echo "PUSH_REMOTE=\"$repo_url\"" >> /etc/etckeeper/etckeeper.conf

etckeeper commit "first etckeeper commit..."

git push --set-upstream $repo_url master
unset rsa_key
unset repo_url