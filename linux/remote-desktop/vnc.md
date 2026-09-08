# vnc简介

VNC 由AT&T 的剑桥研究实验室开发，可实现远程图像显示和控制。

VNC可以指一种通信协议——[Virtual Network Computing](https://en.wikipedia.org/wiki/Virtual_Network_Computing)，也代指实现这种协议的工具——Virtual Network Console（ 虚拟网络控制台）。

VNC的服务端目的是分享其所运行机器的屏幕，服务端被动的允许客户端控制它。VNC客户端（或Viewer）观察控制服务端，与服务端交互。



## 常见VNC实现

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

  

- [vino](https://wiki.gnome.org/Projects/Vino)及[vinagre](https://wiki.gnome.org/Apps/Vinagre)

  [GNOME](https://www.gnome.org)项目的子项目，vino为服务端，vinagre为客户端（还支持SPICE、RDP、SSH等协议）。

  GNOME 3.8.0后vino从GNOME包组中移除，GNOME设置中心的远程控制（remote access）中集成了远程控制服务端功能。

  

- x11vnc

  服务端实现，展示真实的X显示器（即与物理显示器）的画面。
  
  

# VNC服务端配置

VNC物理会话和虚拟会话：

> `Xserver` 是实现了X11服务端协议的进程，比如 `Xorg` 程序，它负责维护一个 `Display`（=显示器+鼠标+键盘+显卡），允许 `Xclient`程序使用这个 Display。

而

> [UNIX](https://zh.wikipedia.org/wiki/UNIX)上的VNC称为xvnc，同时扮演两种角色，对[X窗口系统](https://zh.wikipedia.org/wiki/X_Window系統)的应用程序来说它是X server，对于VNC客户端来说它是VNC伺服程序。

一般的，Linux连上显示器所看到的X的第0个display，称为X物理会话，VNC物理会话即控制的X物理会话，而VNC虚拟会话则与物理会话并行运行互不干扰，每个VNC虚拟会话对应启动一个X会话。



## 虚拟会话

使用`Xvnc`命令启动一个虚拟会话，另外有`vncserver`的脚本对`Xvnc`命令进行了封装，以便于简单使用。

- 启动vnc会话

  ```shell
  #vncserver [:display_port]  #display_port为一个数字
  #如果没有会话，一般从:1开始 端口5901=5900+1
  vncserver     #如果:1的display port没被占用，则启动:1
  
  vncserver :2  #指定会话为:2 端口为5902=5900+2
  
  vncserver :10  -rfbport 8081 #-rfbport指定端口 
  ```
  在不指定`-rfbport`的情况下，启动一个VNC会话（包括下文所说的物理会话）会遵循以下规则占用端口：

  - VNC会话的rfbport端口：5900+display_port

  - VNC会话对应的X会话端口：5900+display_port+100

  - VNC会话提供的http服务端口：5900+display_port-100

    *一些vnc服务会默认启用（可指定选项进行关闭），可使用`httpPort指定*

  *例如，display port为1，即会占用5901端口（=5900+1），6001端口（=5900+1+100），（可能占用）5801端口（=5900+1-100）*

  vncserver启动时会读取默认位置的`xstartup`文件，如果存在`~/.vnc/xstartup`则将使该文件。

  也可以使用`-xstartup`使用指定文件。参看下文会话配置文件章节。

  

- 管理vnc会话

  - `vncserver -list`参数查看会话列表

  - `vncserver -kill <会话编号>`参数终止某个会话

    ```shell
    vncserver -kill :1  #终止1号会话
    ```

  - `vncpassword`修改密码

  

- 相关增强功能

  - 在xstartup中启动`autocutsel` 以实现服务端和客户端的剪切板互通。

  查看`Xvnc`的man获取更多使用参数说明。



### 会话配置文件

用户的vnc配置文件在`~/.vnc`目录下，主要是`config`和`xstarup`。（也有配置文件为是`~/.vnc/vncserver-config-defaults`的）

一般首次执行vncserver相关命令会创建`~/.vnc`目录并生成这两个文件。

`config`文件中的配置可在`vncserver`命令参数中指定，`xstartup`中的配置只能写在一个文件中，可使用`vncserver`的`-xstartup`参数指定文件。



- config文件

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

  

- xstarup文件

  多数发行版默认的配置文件都直接可用，如无特别需要，无需更改。

  `~/.vnc/xstartup`文件供启动虚拟会话时使用，是一个shell文件，配置启动会话时的相关环境，最重要的是配置启动会话的桌面环境或窗口管理器，示例如下：

  ```shell
  #!/bin/sh
  ### 环境变量设置
  export XKL_XMODMAP_DISABLE=1 #禁用XKB Xmodmap扩展，可能用于解决键盘布局相关的问题
  
  #vnc config tool show at the top-left in vnc window 开启后连上vnc会再左上角看到一个配置窗口
  command -v vncconfig && vncconfig -iconic &
  
  #一些发行版安装vncserver后，调用执行/etc/X11/xinit/xinitrc文件即可
  #[[ -r /etc/X11/xinit/xinitrc ]] && source /etc/X11/xinit/xinitrc
  #/etc/X11/xinit/xinitrc文件中包含执行exec行，如果顺利执行，下面的内容并不会执行
  
  ### 加载资源配置，如果用户使用自定义的.xinitrc时执行：
  [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
  
  ### 指定使用什么桌面环境或窗口管理器
  session=gnome-session  #GNOME
  #session=startxfce4    #xfce
  #session=startlxde     #lxde
  #session='gnome-session --session=gnome-classic'
  #session=mate-session  #MATE
  #session=startdde      #DDE(Deepin桌面)
  #session=startkde      #KDE Plasma
  #session=i3            #i3wm
  
  # Copying clipboard content from the remote machine (need install autocutsel)
  command -v autocutsel && autocutsel -fork
      
  case $session in
      gnome             ) session=gnome-sesion;;  #gnome-session-classic
      i3|i3wm           ) session=i3;;
      kde               ) session=startplasma-x11;;
      xfce|xfce4        ) session=startxfce4;;
      *                 ) session=$1;;
  esac
  
  if [[ -z $(command -v $session) ]];
  then
    echo "$session not found" > ~/start-session.err
    exit 1
  fi
  
  echo "$session" >~/.xsession
  
  unset SESSION_MANAGER
  unset DBUS_SESSION_BUS_ADDRESS
  
  exec dbus-run-session -- "$session"
  # exec dbus-launch "$session"
  vncserver -kill $DISPLAY
  ```



### 超过99个虚拟会话限制

VNC并没有限制虚拟会话数量，只是**如果不指定端口**而使用默认端口占用规则，在启动了`:1` - `:99`个虚拟会话后，不对display port数字进行合理使用，可能会出现以下端口冲突情况。 

例如：

启动`vncserver :100`会使用6000端口（=5900+100），但如果已经启动了`:0`的X会话，则6000端口以及被其占用（=5900+0+100）；

启动`vncserver :101`会使用6001端口（=5901+101），但`:1`的VNC虚拟会话对应的X会话已经占用了6001端口（=5900+1+100）。

  

**规避端口冲突的方式是每99个display port间隔300个数字**（如果不考虑http服务的端口则间隔200个）。

*注：其实应当描述为每100个display port间隔300个数字，只是因为`:100` 与`:0`端口冲突，为保持一致每100个端口中都只使用0-99。*

例如：第`:99`VNC会话的下99个会话为`:301`到`:399`，再下99个会话使用`:601`到`:699`，

  `:301`占用端口为`6201`、`6301`和`6101`，不与`:1`的`5901`、`6001`和`5801`冲突*。

  

每个X会话在`/tmp`目录中都存在一个对应的lock文件，文件内容为该X会话的进程对应的PID信息，如果该X会话是通过vnc会话启动的，则该PID是这个VNC会话进程的PID。

假如X会话的display port为1，则对应的X会话锁文件`/tmp/.X1-lock`。




### turbovnc+virtualGL3D图形加速器

 [VNC](https://zh.wikiqube.net/wiki/Virtual_Network_Computing) 和其他用于Unix和Linux的瘦客户端环境都不支持运行 [的OpenGL](https://zh.wikiqube.net/wiki/OpenGL) 应用程序或强制渲染OpenGL应用程序。

> 传统上，通过硬件加速来远程显示3D应用程序需要使用“间接渲染”。间接渲染使用GLX 扩展到 [X Window系统](https://zh.wikiqube.net/wiki/X_Window_System) （“ X11”或“ X”）将OpenGL命令封装在 [X11协议流](https://zh.wikiqube.net/wiki/X_Window_System_protocols_and_architecture) 并将它们从应用程序发送到X显示器。

间接渲染的所有OpenGL命令都由vnc客户端计算机执行，因此对于3D程序，需要客户端必须具有快速的3D图形加速器；某些OpenGL扩展在间接渲染环境中不起作用，一些扩展要求具有直接访问3D图形硬件的能力。

使用Turbovnc+virtualGL：

- VirualGL 则能作为一个代理使用服务器的 OpenGL 在服务器端进行渲染，使用远程服务器的图形硬件进行渲染，并以交互方式将渲染的输出显示到客户端。

- Turbovnc为3D渲染提供了更好的性能



如果使用NVDIA显卡，参考[virtualGL headless-nv](https://virtualgl.org/Documentation/HeadlessNV)

1. 配置好服务器的nvidia驱动

1. 执行`nvidia-xconfig --query-gpu-info` 获取GPU bus ID

1. 配置xorg.conf文件

   ```shell
   resolution=1920x1200
   busid=$(nvidia-xconfig --query-gpu-info | grep BusID|grep -Eo "[0-9]+[0-9:]+"|head -n 1)
   nvidia-xconfig -a --allow-empty-initial-configuration --use-display-device=None \
   --virtual=1920x1200 --busid $busid
   
   #for driver ver 440+ | add Option "HardDPMS" under Device or Screen section
   sed -i -E '/Section "Device"/a Option "HardDPMS" "false"' /etc/X11/xorg.conf
   ```

   重启X服务器：

   ```shell
   systemctl isolate multi-user  #init 3
   systemctl isolate graphical   #init 5
   
   #也可重启dm实现该目的，如：
   #systemctl restart gdm
   ```

2. 安装virtualGL 、turbovnc及其依赖turbojpeg

3. 配置virutualgl

   ```shell
   systemctl isolate multi-user  #init 3
   
   #可能需要先rmmod nvidia的模块
   /opt/VirtualGL/bin/vglserver_config
   #1 Configure server for use with VirtualGL in GLX mode
   #2 Restrict 3D X server access to vglusers group (recommended)? y/n
   #3 Restrict framebuffer device access to vglusers group (recommended)? y/n
   #4 Disable XTEST extension (recommended)? y/n
   #x11vnc and x0vncserver both require XTEST, if you need to attach a VNC server to the 3D X server, then it is necessary to answer “No” 
   
   systemctl isolate graphical   #init 5
   ```
   
   
   
3. 使用TurboVNC启动vnc

   ```shell
   /opt/TurboVNC/bin/vncserver -vgl
   ```



## 物理会话

直接转发服务端本地物理画面（物理显示器展示的画面）。

TigerVNC使用`x0vncserver`，RealVNC有自己的实现，还可以使用`x11vnc`。

`x0vncserver`实现更为低效，较之更推荐`x11vnc`。

VNC物理会话对应display port为`:0`的X会话，X会话的锁文件为`/tmp/X0-lock`，该X会话占用6000端口，该VNC服务占用5900端口（即是rfbport），（如果有）http服务占用5800端口。



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





# VNC安全

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

以前的会话临时文件仍然存在，删除`/tmp/.X1-lock`。

如果还提示`/tmp/.X11-unix/X1`，继续删除`/tmp/.X11-unix/X1`文件再测试。



## 黑屏或桌面背景黑色

常见问题：

- 查看.vnc目录中对应的log文件进行排查

- 类似错误：`unable to create directory '/run/user/1001/dconf`
  参看[redhat bug753882](https://bugzilla.redhat.com/show_bug.cgi?id=753882)，可修改默认的`XDG_RUNTIME_DIR`权限，或者更改其路径到有读写权限的目录。
  
  ```shell
  #设置XDG_RUNTIME_DIR避免错误地将root的运行时目录用于该用户
  user=xxx #替换成实际的用户名
  export XDG_RUNTIME_DIR=/run/user/$(id -u $user)
  mkdir -p $XDG_RUNTIME_DIR && chown $user $XDG_RUNTIME_DIR
  ```
  
- 可能是nvidia显卡驱动xorg未能正确配置

- VNC协议基于X，不支持wayland

  关于wayland与vnc及其他远程控制协议问题参看[wayland FAQ](https://wayland.freedesktop.org/faq.html)

- X服务未正常启动

- xstarup脚本问题（例如没有正确执行的应用/桌面/窗口管理器等等），查看`~/.vnc`下的`xstartup`文件或`-xstartup`指定的文件进行排查。

  -  没有安装xstartup脚本中执行的图形程序/窗口管理器/桌面

- 缺少xorg相关包（xorg-X11-xinit，xorg-x11-xauth等等）

- 连接虚拟机中的vnc黑屏，尝试调整虚拟软件的设置中图形设置相关选项，可以关掉3D渲染

- tigervnc viewer或不支持同一用户开启多个gnome3桌面的vnc会话，如果用户在本地已经登录了gnome会话，用户在vnc会话中登录gnome会使得该用户其他gnome会话黑屏



## gnome3无法解锁屏幕

一些版本的gnome3桌面锁屏后可能无法解锁屏幕——无法输入密码或输入密码后卡死，参看[gnome-shell-issue](https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/2196)。

升级新版本解决，如不可升级，暂定解决方案是关闭锁屏（对已经锁定的会话无效，或可`loginctl unlock-sessions`解锁会话）。



用户可在设置（settings）--隐私（privacy）中将锁屏（ScreenLock）设置为关闭，也使用命令设置：

```shell
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
```

禁止系统所有用户锁屏：

1. 在`/etc/dconf/db/local.d/default-settings`添加：

   ```shell
   #---screensaver | lock-enabled=false -> disable automatic screen lock 
   [org/gnome/desktop/screensaver]
   lock-enabled=false
   idle-activation-enabled=false
   
   #---lockdown | lock value
   [org/gnome/desktop/lockdown]
   disable-lock-screen=true
   
   #---power policy
   [org/gnome/settings-daemon/plugins/power]
   idle-dim=false
   sleep-inactive-ac-type='nothing'
   ```
   
2. 在`/etc/dconf/db/local.d/locks/default-lock`添加：

   ```shell
   /org/gnome/desktop/screensaver/lock-enabled
   /org/gnome/desktop/screensaver/idle-activation-enabled
   /org/gnome/desktop/lockdown/disable-lock-screen
   ```
   
3. 立即更新生效：

   ```shell
   dconf update
   ```

   

## 启动失败

### xstartup: line * Trace/breakpoint trap   /etc/X11/xinit/xinitrc

vnc日志提示类似：

> ```shell
> xstartup: line 5: 28820 Trace/breakpoint trap   /etc/X11/xinit/xinitrc
> ```



如果检查`abrt-cli list`或者`cat /var/log/messages`或者`journalctl -xe`等能看到关于gdm的类似报错：

> ```shell
> ERROR: Failed to connect to system bus: GDBus.Error:org.freedesktop.DBus.Error.LimitsExceeded: The maximum number of active connections for UID <user id> has been reached
> ```

原因是当前用户的登录连接数量和启动的应用程序数量已经达到设定的最大值，DBUS拒绝了连接。

可关闭一些当前用户登录的会话（如果开启来很多vnc会话，可以关闭一些vnc会话），再测试。

或者修改默认的gdm登录连结数量限制，

在 `/etc/dbus-1/system.conf` 中配置 `max_connections_per_user` 参数：

```xml
<busconfig>
  <limit name="max_connections_per_user">100000</limit>
</busconfig>
```



重启dbus服务，但是`restart`会造成现有的dbus全部中断！也就是其他X会话、wayland会话等中断，而且还是可能需要重启才能解决问题，因此建议直接重启。

```shell
systemctl reload dbus  #如果依然无效再考虑restart
systemctl restart dbus
```



### dbus冲突

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
