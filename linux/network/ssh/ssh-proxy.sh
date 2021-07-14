#!/bin/bash
#ssh proxy ， remote port forwarding
#Author: copyright @ Levinit

set -e #u
unalias -a

#--remote host, as a proxy server
remote_host=''
remote_sshd_port=22
remote_ssh_user=sshproxy #user on remote host
proxyPort=10122          #an available port of remote host, should >=1024 for normal user

#--local host (target sshd server)
target_host=localhost
target_sshd_port=22
target_ssh_user=$USER       #a user of target host
private_key="~/.ssh/id_rsa" #private_key of $target_ssh_user

#params for cron task
restart_cron_time="5 5 * * * " #cron time for restart sshproxy
cron_interval_min=10           #cron task interval (every n mins)
check_timeout=30               #max secs for checking ssh session status

#---sshproxy inf file (put in the remote host)
ssh_proxy_info_file="$HOSTNAME" #name of sshproxy info file, eg. home-nas

info_file_dir_on_remote_host=proxy-hosts #proxy info file path, default is ~/proxy-hosts

target_host_comment="server $HOSTNAME" #comments text, will add to sshproxy inf file

#--log file
log=./proxy.log   #proxy log
log_maxsize=10000 #Bytes

#---do not edit below, if you don't know what you're doing
script_path=$(readlink -f "$0")
script_name=$(basename $0)
script_dir_path=$(dirname $script_path)

#ssh options
options='-o TCPKeepAlive=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=10 -o ControlMaster=auto -o ControlPath=~/.ssh/%r@%h:%p -o ControlPersist=yes -o StrictHostKeyChecking=no'
#---do not edit above, if you don't know what you're doing

#~~~~~~~~~~~~~~~~~~~~~~~~~~
#===check params
function check_ssh_params() {
    #check local port
    [[ -z $target_sshd_port ]] && echo "[ERR]: target_sshd_port can not be empty!" >>$log && exit 1

    #check remote sshd port 检查远程主机sshd端口
    [[ -z $remote_sshd_port ]] && echo "[ERR]: remote_sshd_port can not be empty!" >>$log && exit 1

    #check remote host 验证远程sshd主机
    [[ -z $remote_host ]] && echo "[ERR]: remote_host can not be empty!" >>$log && exit 1

    #check remote host 验证远程sshd主机
    [[ -z $remote_ssh_user ]] && echo "[ERR]: remote_ssh_user can not be empty!" >>$log && exit 1

    #check ssh private key file 检查密钥文件
    [[ -f $private_key ]] && echo "[ERR]: Can not find ssh private key file : $private_key !" >>$log && exit 1

    #check ssh proxy info file
    if [[ -z "$/tmp/ssh_proxy_info_file" ]]; then
        /tmp/ssh_proxy_info_file=${HOSTNAME}-$remote_sshd_port
        echo "[WARN]: param /tmp/ssh_proxy_info_file is empty! Fallback: ==> $/tmp/ssh_proxy_info_file " >>$log
    fi

    if [[ -z "$target_host_comment" ]]; then
        target_host_comment="$HOSTNAME-$(uname -a)"
    fi
}

#===proxy log 日志
function check_log_file() {
    local log_file_parent_dir=$(dirname $log)
    [[ -d $log_file_parent_dir ]] || mkdir -p $log_file_parent_dir

    #log file size control 日志文件大小控制 10000Bytes
    if [[ $(stat -c %s $log) -gt $log_maxsize ]]; then
        local tmp_log=$(mktemp)
        tail -n 100 $log >$tmp_log #keep 100 lines log
        cat $tmp_log >$log
    fi
    echo "======LOG @ $(date)======" >>$log
}

#=====Remote Port Forward======远程主机转发
function ssh_remote_forwarding() {
    #======checking 转发前检查
    if [[ $(timeout $check_timeout ssh -i $private_key -p $remote_sshd_port $remote_ssh_user@$remote_host "hostname") ]]; then
        echo "" >>$log
    else
        echo "[ERR] Can not connect $remote_host:$remote_sshd_port." >>$log
        exit 1
    fi

    if [[ $(timeout $check_timeout ssh -i $private_key -p $remote_sshd_port $remote_ssh_user@$remote_host "ss -tlpn4 |grep :$proxyPort") ]]; then
        echo "ssh forwarding status is OK." >>$log
        exit 0 #本地转发进程存在，远程ssh端口测试连接正常，退出
    fi

    [[ -n $forwarding_pid ]] && kill -s SIGTERM $forwarding_pid

    echo "---start ssh proxy---" >>$log
    local errlog=$(mktemp)
    ssh -gfCNTR $proxyPort:$target_host:$target_sshd_port $remote_ssh_user@$remote_host -i $private_key -p $remote_sshd_port $options 1>>$log 2>$errlog

    ##ssh参数说明
    #-g 允许远程主机连接转发端口
    #-f 后台执行
    #-C 压缩数据
    #-N 不要执行远程命令
    #-R 远程转发
    #if some err occur
    if [[ $? -ne 0 ]]; then
        local proxyPID=$(ps -eo pid,command | grep $proxyPort:$target_host:$target_sshd_port | grep -v grep | awk '{print $1}')
        cat $errlog >>$log
        [[ $proxyPID ]] && kill -s SIGTERM $proxyPID
        exit 1
    fi

    #saved proxy info and copy to the remote host
    ssh -p $remote_sshd_port $remote_ssh_user@$remote_host "mkdir -p $info_file_dir_on_remote_host"

    echo -e "=== Generate @ $(date) ===
+++++ target server info +++++
about:$target_host_comment
os:$(uname -a)
hostname:$HOSTNAME
ssh-user:$target_ssh_user
ssh-port:$target_sshd_port
---------------------
client === $remote_host:$proxyPort <--->$hostname:$target_sshd_port

ssh -J $remote_host:$target_sshd_port localhost -p $proxyPort -l <user-on-target-host>
---------------------
ssh -p $proxyPort <user-at-target-host>@$remote_host
" >/tmp/$ssh_proxy_info_file

    scp -P $remote_sshd_port /tmp/$ssh_proxy_info_file $remote_ssh_user@$remote_host:~/$info_file_dir_on_remote_host/ >/dev/null
}

#installation 安装
function install() {
    #ssh key auth target_host --> remote host  ssh密钥认证 本机-->远程主机
    echo "Check ssh key auth!"
    if [[ $(timeout $check_timeout ssh -p $remote_sshd_port -i $private_key $remote_ssh_user@$remote_host "hostname") ]]; then
        echo "authenticated!"
    else
        echo "!!!authenticated failed, please run below command :"
        echo "ssh-copy-id -p $remote_sshd_port $remote_ssh_user@$remote_host"
        echo
        echo "then re-run $0 again."
        exit 1
    fi

    echo "+++++++++++++"

    crontab -l >/tmp/sshproxy_cron
    sed -i -E "/$script_name/d" /tmp/sshproxy_cron

    echo "@reboot bash $script_path start
$restart_cron_time bash $script_path restart
*/$cron_interval_min * * * * bash $script_path start" >>/tmp/sshproxy_cron

    sed -i -E "/^$/d" /tmp/sshproxy_cron
    crontab /tmp/sshproxy_cron

    echo "cron task list:"
    crontab -l
}
#+++++++++
#1.
pid=$(ps -eo pid,command | grep $proxyPort:$target_host:$target_sshd_port | grep -v grep | awk '{print $1}')

action=${1:start} #star|restart|stop|install
case $action in
stop)
    echo "stop sshproxy" >>$log
    [[ -n $pid ]] && kill -s SIGTERM $pid
    exit 0
    ;;
restart)
    echo "restart sshproxy" >>$log
    [[ -n $pid ]] && kill -s SIGTERM $pid
    ;;
start)
    if [[ -n $pid ]]; then
        echo "sshproxy is running. PID=$pid" >>$log
        exit 0
    fi
    echo "start sshproxy..." >>$log
    ;;
install)
    install
    ;;
*)
    echo "useage $script_path install|start|restart|stop"
    exit 1
    ;;
esac

#2.
check_log_file

#3.
check_ssh_params

#4.
ssh_remote_forwarding $pid
