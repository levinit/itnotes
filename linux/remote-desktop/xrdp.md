[xrdp](https://www.xrdp.org)

> xrdp provides a graphical login to remote machines using RDP (Microsoft  Remote Desktop Protocol). xrdp accepts connections from variety of RDP  clients: FreeRDP, rdesktop, NeutrinoRDP and Microsoft Remote Desktop  Client (for Windows, macOS, iOS and Android).

**xrdp**是一个守护进程，支持 Microsoft 的RDP协议，使用 Xvnc 或 xorgxrdp 作为其后端。

参考[archlinux-wiki:xrdp](https://wiki.archlinuxcn.org/wiki/Xrdp)



# 安装

安装xrdp，启动xrdp守护进程。

xrdp默认使用TCP 3389端口。



另外还必须安装以下之一作为后端：

## Xvnc后端

xrdp将启动一个Xvnc会话，需要安装一种VNC的server端实现，例如tigervnc，turbovnc。



## xrdp后端

[xorgxrdp](https://www.xrdp.org/)是xrdp项目的一部分，一般在Linux发行版中包名即为xorgxrdp。

另外如果希望使用显卡进行渲染，安装以下特定的xrdp后端代替通用的xorgxrdp（使用CPU渲染）：

- 英特尔和AMD GPU：xorgxrdp-glamor
- Nvidia GPU：xorgxrdp-nvidia



xrdp将启动一个X11会话，相比vnc后端，其支撑声音传输，如果要启用声音支持，安装pulseAudio和[pulseaudio-module-xrdp](https://github.com/neutrinolabs/pulseaudio-module-xrdp)。

一些Linux发行版中可能需要额外安装xinit程序，其包名类似`xorg-xinit`，因为该包可能不是桌面或窗口管理器的必要依赖，并未随前者一并安装。

> The **xinit** program allows a user to manually start an [Xorg](https://wiki.archlinux.org/title/Xorg) display server. 



# 配置

以从Linux的包管理器安装xrdp为例，其配置文件目录一般为`/etc/xrdp`，

- 主要配置文件

  - `xrdp.ini`

    xrdp sever的配置文件。

    提示：一些发行版安装xrdp后默认使用Xvnc后端，配置文件中`[Xorg]`配置内容被注释，使用xorgxrdp后端需要将这些行的注释符去掉。

    

  - `sesman.ini`

    xrdp-sesman（xrdp session manager）的配置文件，定义xrdp会话的相关参数。
    
    可在根据需要修改指定的VNC/Xorg后端程序路径及它们的运行参数：
    
    ```shell
    param=Xorg
    ; Leave the rest parameters as-is unless you understand what will happen.
    param=-config
    param=xrdp/xorg.conf
    param=-noreset
    param=-nolisten
    param=tcp
    param=-logfile
    param=.xorgxrdp.%s.log
    
    [Xvnc]
    param=/opt/TurboVNC/bin/Xvnc
    param=-bs
    param=-nolisten
    param=tcp
    param=-localhost
    param=-dpi
    param=96
    
    [Security]
    ; forbid root login
    AllowRootLogin=false
    ```
    
    

- 允许任何人启动X服务器

  在一些发行版中如果普通用户使用xorg模式连接后无法启动桌面环境，在 `/etc/X11/Xwrapper.config` 添加：

  ```shell
  allowed_users=anybody
  needs_root_rights=no
  ```

  

- xinit配置

  成功启动显示服务器后，*xrdp* 将默认执行`sesman.ini`中的`[globals]`小节定义的`DefaultWindowManager`对应的脚本，一般为 `startwm.sh`（具体路径查看包安装详情）。

  该脚本使用xinit启动Xorg 显示服务，该脚本一般会读取尝试先用户家目录的xinit脚本`~/.xinitrc`，如果找不到就读取一些全局xinit脚本（例如` /etc/X11/xinit/Xsession`，` /etc/X11/xinit/xinitrc`）和，具体可以查看该脚步的`wm_start()`函数。

  

  由于不同Linux发行版可能有不同的xinit启动脚本实现，具体需要阅读`startwm.sh`脚本内容。

  

  另可参考[archlinux-wiki: xinit](https://wiki.archlinux.org/title/xinit)自行编写启动脚本启动Xorg服务，容示例：

  ```shell
  #!/bin/bash
  session=${1:-xfce}
  
  case $session in
  xfce | xfce4)
      # which xrdb &>/dev/null && xrdb -merge ~/.Xresources
      session=startxfce4
      ;;
  gnome)
      export XDG_SESSION_TYPE=x11
      export GDK_BACKEND=x11
      session=gnome-session #gnome-session-classic
      ;;
  kde* | plasma*)
      export DESKTOP_SESSION=plasma
      session=startplasma-x11
      ;;
  i3 | i3wm)
      session=i3
      ;;
  *) session=$1 ;;
  esac
  
  if [[ -z $(command -v $session) ]];
  then
    echo "$session not found" > ~/start-xrdp.err
    exit 1
  fi
  
  echo "$session" >~/.xsession
  
  unset SESSION_MANAGER
  unset DBUS_SESSION_BUS_ADDRESS
  
  exec dbus-run-session -- "$session"
  #exec dbus-launch "$session"
  ```



# 连接

使用RDP客户端连接即可，如：

- windows：mstsc即系统内置的远程桌面连接程序
- MacOS：[windows remote desktop](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-mac)
- Linux：Remmina  vinagre

提示：RDP默认端口为3389，默认端口一般无需额外指定。



# 问题解决

- 如果连接xrdp失败，可以查看用户家目录下的` .xorgxrdp.10.log`日志文件
- 连接成功但是黑屏
  - 缺少xorg相关包（xorg-X11-xinit，xorg-x11-xauth等等）
  - 连接虚拟机中的vnc黑屏，尝试调整虚拟软件的设置中图形设置相关选项，可以关掉3D渲染
