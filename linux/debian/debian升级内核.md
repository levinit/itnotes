添加 `Backports` 源并安装新内核

```bash
source /etc/os-release 

echo "deb http://deb.debian.org/debian $VERSION_CODENAME-backports main" > /etc/apt/sources.list.d/backports.list
apt update
apt -t $VERSION_CODENAME-backports install linux-image-amd64 linux-headers-amd64
```

