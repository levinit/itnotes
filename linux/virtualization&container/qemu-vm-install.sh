#!/bin/sh
set -eu
vm_name=centarm

arch=aarch64

#not need for x86_64
machine_type=virt #qemu-system-$arch -M help (or -machine help)

os_iso_file=/data/softwares/linux-distros/cent7-arm/CentOS-7-aarch64-Everything-1810.iso

virt_disk_type=qcow2 #raw | qcow2
virt_disk_file=$PWD/$vm_name
virt_disk_size=8G

#===qemu efi file===
#pacakger installation
#for Archlinux : ovmf  ovmf-aarch64(aur)
#for rhel/centos/fedora: search pkg "edk2" "ovmf"

#file path: /usr/share/ovmf or /usr/share/OVMF or /usr/share/edk2/ovmf

#download
#https://pkgs.org/download/edk2-aarch
#aarch64 https://github.com/hoobaa/qemu-aarc64/raw/master/QEMU_EFI.fd
#x86 pkgs: https://pkgs.org/download/ovmf
qemu_efi_file=$PWD/QEMU_EFI.fd

#more cpu mode
#aarch64 : qemu-system-aarch64 -machine $machine_type help
#x86_64 : qemu-system-x86_64  -cpu help
cpu_model=cortex-a57
cpu_num=2

memory=2G

#graphical=''
graphical='-nographic'

#========
function msg() {
  echo $1
  exit
}

#preparation
[[ -f $os_iso_file ]] || msg "can not found $os_iso_file"
[[ -f $qemu_efi_file ]] || msg "can not found $qemu_efi_file"

qemu-img create -f $virt_disk_type $virt_disk_file $virt_disk_size
[[ $? -ne 0 ]] && msg "create $virt_disk_file failed"

function aarch64() {
  qemu-system-$arch -m $memory -cpu $cpu_model -M $machine_type -bios $qemu_efi_file $graphical $virt_disk_file -cdrom $os_iso_file

  echo"#!/bin/sh
qemu-system-$arch -m $memory -cpu $cpu_model -M $machine_type -bios $qemu_efi_file $graphical $virt_disk_file
" >run-$vm_name.sh

  chmod +x run-$vm_name.sh
  qemu-system-$arch -m $memory -cpu $cpu_model -M $machine_type -bios $qemu_efi_file $graphical $virt_disk_file
}

function x86_64() {
  qemu-system-$arch -m $memory -smp $cpu_num -cdrom $os_iso_file $virt_disk_file #$graphical
  qemu-system-$arch -m $memory -smp $cpu_num $virt_disk_file
}

# installation
case $arch in
'x86_64')
  :
  x86_64
  ;;
'aarc64')
  :
  aarch64
  ;;
*) ;;
esac
