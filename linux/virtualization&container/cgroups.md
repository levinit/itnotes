# 简介

> **cgroups**，其名称源自**控制组群**（英语：control groups）的简写，是[Linux内核](https://zh.wikipedia.org/wiki/Linux内核)的一个功能，用来限制、控制与分离一个[进程组](https://zh.wikipedia.org/wiki/行程群組)的[资源](https://zh.wikipedia.org/wiki/資源_(計算機科學))（如CPU、内存、磁盘输入输出等）。

相比`nice`命令或`/etc/security/limits.conf `，

一些linux发行版默认就挂载了cgroup，

```shell
df | grep cgroup
ls /sys/fs/cgroup/
```







# cgroups管理

## 创建控制群组

```none
systemd-run --unit=name --scope --slice=slice_name command

systemd-run --unit=toptest --slice=test top -b

#永久
systemctl enable xx
```

- `--unit=name`  此systemd单位的名称（自定义），可选但建议设置

  如果 `--unit` 没有被指定，单位名称会自动生成。建议选择一个描述性的名字，在单位运行时期间，此名字需为独一无二的。

-  `--scope`   参数创建临时 scope单位来替代默认创建的 service单位，可选

- `--slice=slice_name`   将新近创建的 service 或 scope单位可以成为指定 slice 的一部分

  用现存 slice（如 `systemctl -t slice` 输出所示）的名字替代 slice_name，或者通过传送一个独有名字来创建新 slice。默认情况下，service 和 scope 做为 **system.slice** 的一部分被创建。

- 最后的command 部分是指本单位中运行的指令替代