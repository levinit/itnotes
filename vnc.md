# vnc简介

VNC 由AT&T 的剑桥研究实验室开发，可实现远程图像显示和控制。

VNC可是指一种通信协议——[Virtual Network Computing](https://en.wikipedia.org/wiki/Virtual_Network_Computing)，也代指实现这种协议的工具——Virtual Network Console（ 虚拟网络控制台）。



VNC的服务端目的是分享其所运行机器的屏幕，服务端被动的允许客户端控制它。VNC客户端（或Viewer）观察控制服务端，与服务端交互。



# 常见VNC实现

VNC作为一种通用协议，现有多种实现工具：

- [Tightvnc](http://tightvnc.com)

  - [TigerVNC](https://www.tigervnc.org)

    派生自TightVNC，如今Linux发行版中最常用的VNC实现（一些发行版中安装vncserver包即是安装tigervnc）。

    tigervnc包含一个vnc客户端vncviewer。

  - [TurboVNC](https://turbovnc.org/)

    派生自TightVNC，特点是对图形传输方面的优化。可配合使用[VirtualGL](https://www.virtualgl.org)调用服务端显卡渲染。

    

  - RemoteVNC

    派生自TightVNC，增加了自动穿越NAT和防火墙。

- [RealVNC](http://www.realvnc.com)

  2002年剑桥研究室实验室关闭，后来VNC的创始人创立的RealVNC公司开发的产品，客户端可以通过该产品的服务器连接服务端，提供商用版本，以及有一定限制的免费版本。

  有著名的vnc客户端vnc viewer。

  

- [vino](https://wiki.gnome.org/Projects/Vino)及[vinagre](https://wiki.gnome.org/Apps/Vinagre)

  [GNOME](https://www.gnome.org)项目的子项目，vino为服务端，vinagre为客户端（还支持SPICE、RDP、SSH等协议）。

  GNOME 3.8.0后vino从GNOME包组中移除，GNOME设置中心的远程控制（remote access）中集成了远程控制服务端功能。

- x11vnc

  仅实现展示真实的X显示器（即与物理显示器、键盘和鼠标相对应的显示器）。
  
  

# VNC服务端配置

以下以tightvnc系的tigervnc为主，tightvnc命令与之类似。

redhat/centos安装`tigervnc-server tigervnc-server-module`

vnc 客户端与服务端端连接称为会话（session）。

vnc会话根据展示内容不同分为虚拟会话和物理会话（非正式称呼，本文为叙述方便所自定义）

## 虚拟会话

vnc启动的多个虚拟会话，会话从端口`:1`开始（vnc默认的1对应端口为`5901`，后续会话端口以此类推），各个会话课同时并行运行，互不干扰。



- 启动会话

  最简单方法是执行`vncserver`，它是`Xvnc`的包装脚本（`Xvnc`命令使用和`x0vncserver`类似）。

  用户首次执行该命令，会提示创建适用于该用户vnc会话的密码。

  ```shell
  vncserver  #如果没有会话，一般从:1开始 端口5901
  vncserver :2  #指定会话为:2 端口5902
  ```
  
- 管理vnc会话

  - `vncserver -list`参数查看会话列表

  - `vncserver -kill <会话编号>`参数终止某个会话
  
    ```shell
    vncserver -kill :1  #终止1号会话
    ```
  
  - `vncpassword`修改密码
  
- 相关增强功能s

  - 在xstartup中启动`autocutsel` 以实现服务端和客户端的剪切板互通。

  

### turbovnc+virtualGL使用服务端3D图形加速器

 [VNC](https://zh.wikiqube.net/wiki/Virtual_Network_Computing) 和其他用于Unix和Linux的瘦客户端环境都不支持运行 [的OpenGL](https://zh.wikiqube.net/wiki/OpenGL) 应用程序或强制渲染OpenGL应用程序。

> 传统上，通过硬件加速来远程显示3D应用程序需要使用“间接渲染”。间接渲染使用 [葛兰素史克](https://zh.wikiqube.net/wiki/GLX) 扩展到 [X Window系统](https://zh.wikiqube.net/wiki/X_Window_System) （“ X11”或“ X”）将OpenGL命令封装在 [X11协议流](https://zh.wikiqube.net/wiki/X_Window_System_protocols_and_architecture) 并将它们从应用程序发送到X显示器。

间接渲染的所有OpenGL命令都由vnc客户端计算机执行，因此对于3D程序，需要客户端必须具有快速的3D图形加速器；某些OpenGL扩展在间接渲染环境中不起作用，一些扩展要求具有直接访问3D图形硬件的能力。

VirualGL 则能作为一个代理使用服务器的 OpenGL 在服务器端进行渲染，使用远程服务器的图形硬件进行渲染，并以交互方式将渲染的输出显示到客户端。

以配置nvidia headless服务器的turbovnc+virtualGL为例：

1. 配置好服务器的nvidia驱动，参看[virtualGL headless-nv](https://virtualgl.org/Documentation/HeadlessNV)

   ```shell
   resolution=1920x1200
   busid=$(busid=$(nvidia-xconfig --query-gpu-info | grep BusID|grep -Eo "[0-9]+[0-9:]+$"|head -n 1))
   nvidia-xconfig -a --allow-empty-initial-configuration --use-display-device=None \
   --virtual=1920x1200 --busid $busid
   
   sed -i -E '/Section "Screen"/a Option "HardDPMS" "false"' /etc/X11/xorg.conf
   ```

   重启X服务器：

   ```shell
   systemctl isolate multi-user  #init 3
   systemctl isolate graphical   #init 5
   
   #也可重启dm实现该目的，如：
   #systemctl restart gdm
   ```

2. 安装virtualGL 、turbovnc及其依赖turbojpeg

   ```shell
   yum install -y 
   ```

3. 使用TurboVNC启动vnc

   ```shell
   /opt/TurboVNC/bin/vncserver -vgl
   ```



## 直接转发物理画面

直接转发服务端本地物理画面（物理显示器展示的画面），其为运行在端口`:0`（vnc一般监听在5900端口）。

TigerVNC使用`x0vncserver`，RealVNC有自己的实现，还可以使用`x11vnc`。

`x0vncserver`实现更为低效，较之更推荐`x11vnc`。



### x0vncserver

```shell
#-display指定使用的物理显示 并指定密码文件（可由vncpasswd生成）
x0vncserver -rfbauth ~/.vnc/passwd -display :0
x0vncserver -display :0 -passwordfile ~/.vnc/passwd  #作用同上
```

注意：x0vncserver不支持剪切板共享，即使使用`autocutsel`。



### x11vnc

启动服务：

```shell
x11vnc -display :0  #没有安全保证 将建立一个没有密码的VNC!!!
#设置一个密码 但是在服务端执行ps查看进程可看到密码
x11vnc -wait 50 -noxdamage -passwd PASSWORD -display :0 -forever -o /var/log/x11vnc.log -bg

x11vnc -gui  #可以启动一个tk编写的图形界面前端
```

直接运行将建立一个没有密码的VNC，`-passwd`虽然能设置密码，但仍能通过ps命令查询进程获取密码信息。

- 加密

  - ssh转发加密

    1. 使用`-localhost`参数启动服务，绑定vnc服务到localhost从而拒绝外部连接：

       ```shell
       x11vnc -localhost
       ```

    2. 客户端使用ssh转发，将服务端的5900端口到客户端的5900端口，在客户端执行：

       ```shell
       ssh <x11vnc-server-host> 5900:localhsot:5900
       ```

       而后客户端连接自己的5900端口即可。

  - auth加密

    ```shell
    x11vnc -display :0 -auth ~/.Xauthority  #root用户
    
    #GDM 以下将打开gdm登录界面（120是gdm的uid）
    x11vnc -display :0 -auth /var/lib/gdm/:0.Xauth
    #新版本gdm可使用：
    x11vnc -display :0 -auth /run/user/120/gdm/Xauthority
    
    #lightdm
    x11vnc -display :0 -auth /var/run/lightdm/root/\:0
    
    #sddm
    11vnc -display :0 -auth $(find /var/run/sddm/ -type f)
    ```
    
  - 设置密码

    ```shell
    x11vnc -usepw  #生成密码文件~/.vnc/passwd
    ```

    

- 持续运行

  默认情况下，x11vnc将接受第一个VNC会话，并在会话断开时关闭。为了避免这种情况，可以使用-many或-forever参数启动x11vnc：

  ```shell
  x11vnc -many -display :0
  #或
  x11vnc --loop  #这将在会话完成后重新启动服务器 
  ```

## vnc配置文件

**如果默认情况下连接vncserver后符合需求，无需更改相关配置文件。**

用户的vnc配置文件再`~/.vnc`目录下，主要是`config`和`xstarup`。（也有配置文件为是`~/.vnc/vncserver-config-defaults`的）

一般首次执行vncserver相关命令会创建`~/.vnc`目录并生成这两个文件。

`config`文件中的配置可在`vncserver`命令参数中指定，`xstartup`中的配置只能写在一个文件中，可使用`vncserver`的`-xstartup`参数指定文件。

### config文件

`~/.vnc/config`文件配置根据名称即可获知其用途，示例如下：

```shell
# desktop=sandbox
geometry=1920x1080  #分辨率
# localhost  #仅监听本地端口
# alwaysshared
dpi=96
```

该文件中的参数也可以在`Xvnc`和`vncserver`中直接指定，如：

```shell
vncserver -dpi 96 -geometry=1600x960
```



### xstarup文件

多数发行版默认的配置文件都直接可用，如无特别需要，无需更改。

`~/.vnc/xstartup`文件供启动虚拟会话时使用，是一个shell文件，配置启动会话时的相关环境，最重要的是配置启动会话的桌面环境或窗口管理器，示例如下：

```shell
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1

#vnc config tool show at the top-left in vnc window 开启后连上vnc会再左上角看到一个配置窗口
command -v vncconfig && vncconfig -iconic &

#一些发行版安装vncserver后，调用执行/etc/X11/xinit/xinitrc文件即可
[[ -r /etc/X11/xinit/xinitrc ]] && source /etc/X11/xinit/xinitrc
#/etc/X11/xinit/xinitrc文件中包含执行exec行，如果顺利执行，下面的内容并不会执行

#设置x资源 如果用户使用自定义的.xinitrc时执行：
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

#指定要使用什么桌面环境或窗口管理器
#session=startxfce4    #xfce
#session=startlxde     #lxde
session=gnome-session  #GNOME
#session='gnome-session --session=gnome-classic'
#session=mate-session  #MATE
#session=startdde      #DDE(Deepin桌面)
#session=startkde      #KDE Plasma
#session=i3            #i3wm

# Copying clipboard content from the remote machine (need install autocutsel)
command -v autocutsel && autocutsel -fork
    
#exec $session
exec /usr/bin/dbus-daemon "$session"

vncserver -kill $DISPLAY
```



# vnc安全

在互联网中开启vnc相对不安全，需要考虑明文密码及客户端与服务端之间未加密通信的问题。可以借助ssh隧道对vnc通信加密以提升安全性。

1. 如果在vnc的config文件中启用了`localhost`选项（默认注释），则其vnc会话仅监听localhost。

   也可以启用`vncserver`时，使用`-localhost`参数，若`vncserver`命令对`-localhost`参数不支持，该用`Xvnc`

   ```shell
   vncserver -localhost :1
   #或者
   Xvnc -localhost :1
   ```

   

2. 对vnc会话端口使用ssh端口转发（即ssh隧道）加密

   这里示例使用本地转发将vnc会话的5901端口转发到5601端口

   ```shell
   ssh -fCNL *:5601:localhost:5901 <user>@localhost
   ```

3. 访问ssh转发的端口

   以上文为例，应该访问vnc服务器的5601端口。





# VNC客户端使用

连接虚拟会话，使用服务端的地址+端口即可，例如:`192.168.0.1:5901`（或者使用会话编号如`192.168.0.1::1`。

连接物理会话，使用5900端口，一些客户端不填写端口时默认使用5900。

# 相关问题

查看X日志和vnc日志。

## Warning: *****  is taken because of /tmp/.X1-lock

以前的会话临时文件仍然存在，删除`/tmp/.X1-lock`即可。

如果还提示`/tmp/.X11-unix/X1`，继续删除`/tmp/.X11-unix/X1`文件再测试



## 黑屏或桌面背景黑色

-  VNC协议基于X，不支持wayland

   关于wayland与vnc及其他远程控制协议问题参看[wayland FAQ](https://wayland.freedesktop.org/faq.html)

-  X服务未正常启动

- xstarup脚本问题（例如没有正确执行的应用/桌面/窗口管理器等等）

- 虚拟机中vnc黑屏，尝试调整虚拟软件的设置中图形相项

- 缺少xorg相关包（xorg-X11-xinit，xorg-x11-xauth等等）



## dbus冲突

> Could not make bus activated clients x  of XDG_CURRENT_DESKTOP=GNOME environment variable: Could not connect: Connection refused

安装了anaconda，其目录中带有一些比系统中已有的程序版本不一致的的程序，如dbus-daemon，如果用户为anaconda导出的环境变量优先级更高，vncserver将调用到ananconda中的dbus-daemon。  

解决思路是避免anaconda的dbus-daemon被vncserver调用：

- 默认不激活conda环境，需要时再调用

  安装anaconda时，其会在`.bashrc`或`.zshrc`（或其他shell的用户配置文件）中添加激活base环境的命令，执行`conda config --set auto_activate_base false`可禁止base环境自动激活，或者在conda配置文件`.condarc`中加入：

  ```shell
  auto_activate_base: false
  ```

  或者删掉anaconda安装时自动添加的内容，但为了方便使用，可以保留或手动添加载入conda环境的内容，以方便调用conda命令，例如：

  ```shell
  . "/opt/anaconda3/etc/profile.d/conda.sh"
  ```

  

- 降低ananconda环境变量优先级

  对于需要默认激活anaconda的base环境的情况，可以重新配置anaconda的环境变量，确保将ananconda的环境变量置于系统默认环境变之后，避免vncserver调用到anaconda中的程序：

  ```shell
  export PATH=$PATH:/path/to/conda/bin
  ```

  

  或者单独针对dbus-deamon，例如：

  ```shell
  cp /usr/bin/dbus-daemon /usr/local/bin/
  export PATH=/usr/local/bin:$PATH
  ```

  或者在xstartup文件中将/usr/bin/在PATH中的优先级提高：

  ```shell
  export PATH=/usr/bin:$PATH
  ```





