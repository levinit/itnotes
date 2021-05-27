#!/bin/sh
bridge=br0
interface=eno1
addr=10.10.10.251/24

#1 create a bridge and start it
sudo ip link add name $bridge type bridge
sudo ip link set up dev $bridge

#2 add interface device to bridge
sudo ip link set dev $interface promisc on
sudo ip link set dev $interface up
sudo ip link set dev $interface master $bridge

#3 assign address
sudo ip addr add dev $bridge $addr
ip a

####delete
#sudo ip link set $interface promisc off
#sudo ip link set $interface down
#sudo ip link set dev $interface nomaster
#sudo ip link delete $bridge type bridge