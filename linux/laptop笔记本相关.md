[TOC]

# 无线连接

## Wi-Fi
一般地，安装`linux-firmware` 即可，许多发行版会默认安装此包，如果安装主流的桌面环境，也会自动安装它。

还可以尝试`linux-firmware-iwlwifi`(也可能名为`firmware-iwlwifi`) ，此软件包为intel相关网卡驱动。

一些网卡可能需要寻找相应的驱动，可到其官网寻找支持，或者以网卡名、具体型号加firmware作为关键字搜索解决方案。可使用`lspci | grep Network`查看具体显卡情况。

其他解决思路：换网卡；使用免驱动安装的usb网卡。

## 蓝牙

一般地，安装`bluez`即可，一些发行版会默认安装此包，如果安装主流的桌面环境，也会自动安装它。

特别的驱动解决思路参考上文“wi-fi”。

可以参考这篇文章- [archwifi-蓝牙](https://wiki.archlinux.org/index.php/Bluetooth_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))

---

**rfkill**：某些情况下，wifi或者蓝牙被关闭（尤其是硬关闭）但是又找不打开的方法，可以使用`rfkill`这个工具解决，常用命令：

```shell
rfkill list    #查看所有无线设备的状态
rfkill unblock all    #启用所有设备
rfkill --help    #查看rfkill相关命令
```

# 触摸板

一般安装桌面环境（如gnome、plasma等等）会自动安装上触摸板相关驱动；如果使用的一些窗口管理器（如i3wm、awesom）则可能需要自行安装。

安装驱动 ` xf86-input-synaptics` 

如果从其他桌面环境改用gnome作为桌面环境，则要用`libinput` 替换掉 ` xf86-input-synaptics` （GNOME 目前不再支持 [synaptics](https://wiki.archlinux.org/index.php/Synaptics)），卸载掉 `xf86-input-synaptics`。

# 电源管理

## 电源管理工具

- 桌面环境的电源管理工具

  桌面环境一般都有自己的电源管理工具，可设置对各种使用行为响应的电源动作 ，如使用电池时的亮度、灭屏时间、挂起时间、睡眠时间、盖上笔记本盖子的响应动作、按下电源键的响应动作等等。

  可参看下文[电源相关行为的响应动作](#电源相关行为的响应动作)进行一些更为详细或者电源管理工具为提供的设置，推荐配合tlp或laptop-mode-tools使用。

- [tlp](https://github.com/linrunner/TLP)

  多功能电源管理工具，其默认配置已经针对常见使用情况进行优化，安装后执行`systemctl enable tlp` 使其开启自启动即可。如需进行更多配置，可修改[/etc/default/tlp](config/etc/default/tlp) 文件。另可再安装tlp-rdw用以设置无线设备。

  可参看[tlp英文文档](http://linrunner.de/en/tlp/docs/tlp-configuration.html#rdw) 。

  tlpui：一个tlp的guI工具。

- [laptop-mode-tools](https://github.com/rickysarraf/laptop-mode-tools)

  让内核开启适合的笔记本电脑的模式以达到相关电源控制的目的。功能较多，配置较tlp复杂，和tlp二选一即可。

  可参看[archwiki-Laptop Mode Tools (简体中文)](https://wiki.archlinux.org/index.php/Laptop_Mode_Tools_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E5.9B.BA.E6.80.81.E7.A1.AC.E7.9B.98) 。


- [powertop](https://github.com/fenrus75/powertop)    intel处理器使用的电源管理工具。

  使用`sudo powertop --auto-tune`可启用所有选项，欲开机自启动`auto-tune`参看[powertop(简体中文)](https://wiki.archlinux.org/index.php/Powertop_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)) 。

  提示：如果使用了tlp和laptop-mode-tools，几乎没必要再启用该工具，前二者功能覆盖了powertop的设置项。

- thermald

  一个用于防止平台过热的守护进程。此守护进程会监控平台温度，并采用可用的冷却方式来降低温度。该软件安装即可，无需额外设置。

  提示：该工具**可能**过早启用风扇或风扇转速更快，从而带来较原使用情况下更大的噪音，宜根据设备具体情况和个人使用体验考虑是否使用。

## 电源相关行为的响应动作

这些行为及响应动作多能在桌面环境的电源管理工具中进行设置，参看[综合型电源管理工具](#综合型电源管理工具)

### 按键和盖子的响应动作

针对按下电源相关按钮（如挂起/休眠/电源等按键）和盖上笔记本盖子等行为而响应的电源动作。一般的桌面环境都集成了相关功能。

systemd 能够处理某些电源相关的事件，编辑[/etc/systemd/logind.conf ](config/etc/systemd/logind.conf)可进行配置，其主要包含以下事件：

- HandlePowerKey：按下电源键
- HandleSleepKey：按下挂起键
- HandleHibernateKey: 按下休眠键
- HandleLidSwitch：合上笔记本盖
- HandleLidSwitchDocked：插上扩展坞或者连接外部显示器情况下合上笔记本盖子

取值可以是 ignore、poweroff、reboot、halt、suspend、hibernate、hybrid-sleep、lock 或 kexec。

其中：

- poweroff和halt均是关机（具体实现有区别）
- suspend是挂起（暂停），设备通电，内容保存在内存中
- hybernate是休眠，设备断电（同关机状态），内容保存在硬盘中
- hybrid-sleep是混合睡眠，设备通电，内容保存在硬盘和内存中
- lock是锁屏
- kexec是从当前正在运行的内核直接引导到一个新内核（多用于升级了内核的情况下）
- ignore是忽略该动作，即不进行任何电源事件响应

注意，系统默认设置为：

```shell
HandlePowerKey=poweroff    #按下电源键关机
HandleSuspendKey=suspend    #按下挂起键挂起（暂停）
HandleHibernateKey=hibernate    #按下休眠键休眠
HandleLidSwitch=suspend    #盖上笔记本盖子挂起
```

例如要设置盖上笔记本盖子进行休眠，在该文件中配置：

```shell
HandleLidSwitch=hibernate
```

保存文件后，执行 `systemctl restart systemd-logind` 使其生效。

注意：**一些Linux发行版可能需要自行对休眠进行配置，参考后文[休眠配置](休眠配置)**，或者借助pm-utils之类的工具实现。


### 电池低电量的响应动作

如希望在电池电量极低的时候自动关机，可以通过修改[/etc/UPower/UPower.conf](config/etc/UPower/UPower.conf)相关配置，示例，在电量低至%5时自动休眠：

```shell
PercentageLow=15  #<=15%低电量
PercentageCritical=10  #<=10%警告电量
PercentageAction=5  #<=5%执行动作（即CriticalPowerAction)的电量
CriticalPowerAction=PowerOff #(在本示例中是电量<=5%）执行休眠
```

CriticalPowerAction的取值有Poweroff、Hibernate和Hybid-sleep。

更多配置项参考该文件中的说明。

## 处理器调整

使一般是降低频率以**减少发热**，同时**降低风扇**转速以减少**噪音**，并**提升**笔记本的电池**续航**时间。

在`/sys/devices/system/cpu`目录下有着cpu相关信息。

如intel处理器的设备，其系统在`/sys/devices/system/cpu/intel_pstate` 目录下（可能存在）的文件规定着cpu运行频率相关参数，如：

- max_perf_pct    最高频率百分比，数字0 - 100
- min_perf_pct    最低频率百分比，数字0 - 100
- no_turbo    睿频开启状态，数字0或1，1表示关闭

### 调频工具

**cpupower**属于Linux内核工具系列，但有的发行版不一定会默认安装。

执行`cpupower frequency-info` 可查看到相关信息，`cpupower set`可进行频率设置。

- cpupower-gui    图形界面的cpupower

- [gnome-shell-extension-cpupower](https://github.com/martin31821/cpupower)    可在[Gnome 插件网站](https://extensions.gnome.org/extension/945/cpu-power-manager/)找到此插件

一般搜索cpupower、freq、cpu加freq等关键字可以找到此类工具。

示例：使用cpupower控制频率

编辑/etc/default/cpupower，找到`min_freq`.`max_freq` 这两行，去掉其注释的`#`， 填写好频率并保存

```shell
min_freq="0.25GHz"    #最小频率
max_freq="2.5GHz"    #最大频率
```

执行`systemctl enable cpupower.service` 使其生效。

### 关闭睿频

可使用命令 ：`cat /sys/devices/system/cpu/intel_pstate/no_turbo` 查看睿频开启状态，如果显示0则表示开启睿频，显示1则表是关闭睿频。（intel）

一些关闭睿频的方法：

- 如果bios支持，在bios中设置。

- 使用工具，如上文提到的工具cpupower-gui，图形界面，操作简单。

- root执行` echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo` （重启后会恢复睿频）

- 使用**tlp**（推荐）或**laptop-mode-tools**等电源管理工具

  如tlp，编辑[/etc/tlp.conf](config-backup/etc/tlp.conf)，找到其中的两行CPU_BOOST，修改为：

  ```shell
  CPU_BOOST_ON_AC=0   #0表示关闭 1表示开启
  CPU_BOOST_ON_BAT=0    #同上
  ```


### intel_pstate

只针对intel处理器中**SandyBridge（含IvyBridge）及更新的构架**的CPU。

intel构架列表：[List of Intel CPU microarchitectures](https://en.wikipedia.org/wiki/List_of_Intel_CPU_microarchitectures)。

援引：

> **Linux内核**对CPU的工作频率管理，已经跟不上现代的CPU的需求，无法在效能与省电取得平衡，所以intel自己写了一段内核代 码，Intel_pstate……内核3.13中，已经放入这段代码，但没有默认启用。

检查intel_pastate是否启用：执行`cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver`，如果显示`intel_pstate`则表示启用成功，否则是未启用成功或不支持该功能。

启用方法：

编辑[/etc/default/grub](config/etc/default/grub)，在`GRUB_CMDLINE_LINUX_DEFAULT`一行添加`intel_pstate=enable`，例如该行原有内容是：

> GRUB_CMDLINE_LINUX_DEFAULT=”quiet”

添加添加`intel_pstate=enable`后即是：

> GRUB_CMDLINE_LINUX_DEFAULT=”quiet intel_pstate=enable”

然后执行`sudo grub-mkconfig -o /boot/grub/grub.cfg` ，重启生效。



## 休眠配置

如果桌面环境无休眠相关选项，可参考以下方法手动配置。

1. 合适大小的swap

   休眠（hibernate）需要将内存中的内容写入磁盘的swap，如果swap大小比当前休眠所需空间小，则无法保证能够正确地休眠。具体的swap的大小根据个人使用情况（要休眠时的内存占用）而定。

2. 在bootloader 中增加resume内核参数

   假如使用swap文件为/home/swap，需要编辑[/etc/default/grub](config/etc/default/grub) 文件，在`GRUB_CMDLINE_LINUX_DEFAULT`中添加`resume=/home/swap`，让系统在启动时读取swap分区中的内容。（如果使用swap分区，则resume对应的为swap的盘符，例如/dev/sdc）

   例如该行的原有内容是：

   > GRUB_CMDLINE_LINUX_DEFAULT=”quiet intel_pstate=enable”

   添加resume参数后就是：

   > GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=/home/swap"

   然后更新 grub 配置 `grub-mkconfig -o /boot/grub/grub.cfg`

3. 配置 initramfs的resume钩子

   编辑[/etc/mkinitcpio.conf](config/etc/mkinitcpio.conf)，在`HOOKS`行中添加`resume`钩子，例如该行原有内容是：

   > HOOKS="base udev autodetect modconf block filesystems keyboard fsck"

   添加`resume`后就是：

   > HOOKS="base udev resume autodetect modconf block filesystems keyboard fsck"

   **注意**：如果使用lvm分区，需要将`resume`放在`lvm2`后面，示例：

   > HOOKS="base udev autodetect modconf block lvm2 resume filesystems keyboard fsck"

   重新生成 initramfs 镜像: `mkinitcpio -p linux`

## 显卡管理

amd使用开源mesa（无需额外配置）即可，以下描述中的独显均指Linus钦点的F**k Nvidia，且只讨论显卡用于图像输出的问题。

参看[archwiki-NVIDIA](https://wiki.archlinux.org/index.php/NVIDIA)

### 显卡切换Optimus

[archwiki-NVIDIA_Optimus](https://wiki.archlinux.org/index.php/NVIDIA_Optimus)

Nvidia Optimus技术可根据需求在集成GPU和Nvidia GPU之间实时无缝切换，已达到节能省电的目的（因此在笔记本电脑上有使用该技术的需求），但在Linux下该功能的实现效果较差。

如果BIOS支持选择输出显卡，可在BIOS中选择使用指定卡（但不是所有设备都具有该功能），例如只使用集成显卡或独立显卡。

目前Optimus可选方案：

- 由NVIDIA提供的Optimus方案，性能好，但目前bug丛生。

- 放弃NVIDIA驱动，改用开源nouveau驱动，其PRIME技术可实现Optimus，但性能差。

- 使用第三方程序

  - [bumblebee](https://wiki.archlinux.org/index.php/Bumblebee_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))　稳定、配置简单、使用较方便，但性能差，相对不推荐，考虑使用optimus。

    安装bumblebee和bbswitch，并启用`bumblebeed`服务，此外还需要将用户加入到bumblebee组中：

    ```shell
    pacman -S bumblebee bbswitch --noconfirm  #以archlinux为例
    gpasswd -a $(whoami) bumblebee #需要将普通用户加入bumblebee组
    systemctl enable bumblebeed
    ```
    
    
    
    可根据需要编辑bumblebee配置文件`/etc/bumblebee/bumblebee.conf`。
    
    [bbswitch](https://github.com/Bumblebee-Project/bbswitch)（具体参考链接内容设置）默认情况下使用bbswitch禁用NVIDIA，需要运行使用NVIDIA的程序时，使用特定的命令运行该程序。
    
    需要使用NVDIA运行程序时，可使用以下方案单独运行该程序：
    
    - `optirun`
    
      Bumblee中的命令，使用`optirun [options] <application>`运行程序。
    
    - `primusrun`  [primus](https://github.com/amonakov/primus)方案
    
      比optirun性能更好，使用`primusrun [options] <application>`运行程序。
    
    - `pvkrun`  [primus_vk](https://github.com/felixdoerre/primus_vk)方案 支持vulkan
    
  - [nvidia-xrun](https://github.com/Witko/nvidia-xrun)  启动后使用核显，默认不加载NVIDIA驱动。需要时使用`nvidia-xrun <application>`启动程序。
  
- [optimus-manager](https://github.com/Askannz/optimus-manager)

  图形前端：

  - [optimus-manager-qt](https://github.com/Shatur95/optimus-manager-qt)
  - [optimus-manager-argos](https://github.com/inzar98/optimus-manager-argos)（GNOME shell扩展）
