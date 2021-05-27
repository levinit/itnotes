#!/bin/sh
user_pwd_file=/etc/openvpn/server/user-pwd

echo "select a operateion"
echo "1) add user"
echo "2) delete user"

read -p ": " selection

case $selection in
1)
  :
  read -p "username: " username
  read -p "password: " password
  if [[ $username && $password ]]; then
    if [[ ! $(cut -d " " -f 1 user-pwd | grep $username) ]]; then
      echo -n "$username $password" >>$user_pwd_file
    fi
  fi
  ;;
2)
  :
  echo 2
  read -p "username: " username
  if [[ $username ]]; then
    if [[ $(cut -d " " -f 1 user-pwd | grep $username) ]]; then
      line=$(cat user-pwd -n | awk '{print $1 " " $2}' | grep $username | cut -d " " -f 1)
      sed -i "$line d" $user_pwd_file
    fi
  fi
  ;;
*) ;;

esac
