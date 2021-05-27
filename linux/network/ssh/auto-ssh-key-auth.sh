#!/bin/sh
uploadPrivateKey=yes
username=root
password=$root_pwd
port=22
hosts="${nodes[*]}" # (node{1..5})

#generate ssh key
function gen_ssh_key_pairs() {
  if [[ ! -f ~/.ssh/id_rsa ]]; then
    echo -e "\e[33m === ssh key will be generated === \e[0m"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo -e "\e[33m === ssh key has been generated === \e[0m"
  else
    echo -e "\e[1m ssh key already exists \e[0m"
  fi

  cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
  chmod 644 ~/.ssh/authorized_keys
  echo "StrictHostKeyChecking no
    ForwardAgent yes
    ServerAliveInterval 30
    ServerAliveCountMax 60
    " >>~/.ssh/config
  chmod 644 ~/.ssh/config
}

#upload ssh key-*
function ssh_key_auth() {
  [[ $(which expect) ]] || yum install -y expect
  for host in ${hosts[*]}; do
    expect -c "
    spawn ssh-copy-id $username@$host -p $port
    expect {
        "*yes/no*" { send "yes"\r }
        "*password*" { send "$password"\r }
    }
    expect eof
    "
  done
}

function upload_key_pairs() {
  if [[ $uploadPrivateKey == yes ]]; then
    for host in ${hosts[*]}; do
      scp -r -P $port ~/.ssh/* $username@$host:~/.ssh/
    done
  fi
}

#-----
gen_ssh_key_pairs

eval "$(ssh-agent -s)"
ssh-add

ssh_key_auth
upload_key_pairs

#ssh key auth config for other users in cluster
cp -av auto-ssh-config.sh /etc/profile.d/