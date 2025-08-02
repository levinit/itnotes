[TOC]

提示：archlinux及其衍生版本用户可使用aur helper工具搜索关键字进行下载安装以下扩展、主题、图标等。

# shell附加组件

注：**需先安装有gnome-tweaks。**

shell扩展安装来源：

-  https://extensions.gnome.org/ 中下载安装注册该网站，浏览器会提示安装相应扩展。
- 发行版的一些社区源中可能含有某些扩展。*如archlinux可以在aur搜寻到[gnome-shell-extension](https://aur.archlinux.org/packages/?O=0&K=gnome-shell-extension)。
- 使用gnome-software（gnome软件中心），在其”附加组件“分类中搜寻和安装。

---

扩展推荐：

- dash to pannel  可融合顶部pannel和dash，自定义panel界面和行为

- appindicator  在panel上显示app的tray icon

- user-theme    启用后可自定义shell主题

- drop down terminal    下拉式终端

- desktop icons  放置桌面图标

- hide top bar  定义顶部栏隐藏策略

- gpaste  剪切板工具

- gsconnect  与手机kdeconnect连接协作

- caffeine     阻止桌面锁屏和系统暂停

- desk changer  桌面及锁屏壁纸切换

- media player  媒体播放信息显示及快捷控制（部分播放器可能不支持）

   附 media player indicator设置中l展示播放信息的pango设置示例：

   ```html
   <span foreground="#eb3f2f">{trackTitle}</span> --> <span foreground="#81c2d6">{trackAlbum}</span> @ <span foreground="#c3bed4">{trackArtist}</span>
   ```



# 主题外观

[gnome-look](gnome-look.org)或源中可下载一些主题图标，也可使用[ocsstore](https://www.linux-apps.com/p/1175480/)下载，一些主题如：

- gtk界面主题：arc materia canta paper vertex  vimix
- icon图标主题：numix-circle papirus paoranchelo zafiro flat-remix paper luv moka
- cursor鼠标主题：osx-elcap capitaine numix breeze

查找以上资源时，以提供的关键字加类型名称进行搜寻，例如鼠标主题numix则搜索`numix cursor`，界面主题arc则搜索`gtk arc`。



# 相关配置

## 桌面登录

### 自动登录

编辑`/etc/gdm/custom.conf`，添加：

```shell
[daemon]
AutomaticLogin=username  #username为要自动登录的用户名
AutomaticLoginEnable=True
#如该要延时自动登录添加以下行
#TimedLoginEnable=true
#TimedLogin=username
#TimedLoginDelay=1
```

如果要设置某个用户登录时选用的session，编辑`/var/lib/AccountsService/users/username`（username为该用户的用户名），修改该行：

```shell
XSession=gnome-xorg
```

### 登录列表

- 将用户从登录列表隐藏

  编辑`/var/lib/AccountsService/users/username`（username为要设置的用户）：

  ```shell
  [User]
  SystemAccount=true
  ```

- 隐藏登录界面用户列表

  通过dconf-editor修改/ogr/gnome/login-screen/disable-user-list，将其开启即可（值为true）。

  或者使用：

  ```shell
  sudo su gdm -s /bin/bash
  gsettings set org.gnome.login-screen disable-user-list true
  ```

## 锁屏管理

在桌面的设置-隐私(Privacy)中可设置自动锁屏（对当前用户生效）。或者使用dconf-editor设置。

或使用命令行设置（全局生效）：

```shell
#false表示关闭自动锁屏，true则为开启
gsettings set org.gnome.desktop.screensaver lock-enabled 'false'
#延迟120秒锁屏，为0则表示
gsettings set org.gnome.desktop.screensaver lock-delay 'uint32 0'

#检查
gsettings get org.gnome.desktop.screensaver lock-enabled 
```

如果执行不成功，在命令前加上`dbus-run-session`（比较旧的系统使用`dbus-launch`）。



## nautilus鹦鹉螺文件管理器

### 右键菜单添加新建文件

在Templates（模板）文件夹中建立文件模板。示例：

```shell
touch ~/Templates/text
touch ~/Templates/sh.sh && echo '#!/bin/sh' > ~/Templates/sh.sh && chmod +x ~/Templates/sh.sh
```

在右键菜单中便添加了创建文件菜单，创建文件的子菜单中可创建示例中的text和sh.sh文件，创建的文件内容和属性与模板一样。

### 已汉化文件夹恢复英文名

图片、视频、文档等文件夹恢复为英文名。可以使用以下方法：

- 修改`$HOME/.config/user-dirs`文件内容。示例：

  ```shell
  XDG_DESKTOP_DIR="$HOME/Desktop"
  XDG_DOWNLOAD_DIR="$HOME/Downloads"
  XDG_TEMPLATES_DIR="$HOME/Templates"
  XDG_PUBLICSHARE_DIR="$HOME/Public"
  XDG_DOCUMENTS_DIR="$HOME/Documents"
  XDG_MUSIC_DIR="$HOME/Music"
  XDG_PICTURES_DIR="$HOME/Pictures"
  XDG_VIDEOS_DIR="$HOME/Videos"
  ```

- 自动生成

  1. 设置中更改语言为英文。
  2. 注销桌面后登录桌面，按提示将目录更名为英文。
  3. 设置中更改语言为中文，注销桌面再次登录，提示对目录更名为中文时不要进行更改即可。

### 网络存储

- webDav
  nautilus可添加webDav服务。[坚果云nutstore](http://www.jianguoyun.com)支持webDav。
- google云盘，安装有gvfs-google，且在设置--在线帐号中登录谷歌即可。
- nextcloud，在设置--在线帐号中登录即可。
- 网盘插件
  - natilus-nutstore  坚果云的nautilus插件
  - nautilus-megasync  [Megasync](https://mega.nz/)的nautilus插件
  - nautilus-dropbox  [dropbox](https://www.dropbox.com/)的nautilus插件

## gnome terminal透明

- 使用gnome-terminal-transparency替代gnome-terminal

- 在/.bashrc（zsh用户在/.zshrc）中写入：

  ```shell
  if [ -n "$WINDOWID" ]; then
    TRANSPARENCY_HEX=$(printf 0x%x $((0xffffffff * 77/100)))
    xprop -id "$WINDOWID" -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$TRANSPARENCY_HEX"
  fi
  ```

  65/100是透明系数（65%），根据需求调整。注意：wayland中无效。

## gnome屏幕录制时间上限

`ctrl`-`alt`-`shift`-`r`仅能可录制不超过30秒的短视频。

使用dconf-editor修改`/org/gnome/settings-daemon/plugins/media-keys/max-screencast-length`的数值（秒数）。

## networkmanager网络热点（AP)密码

1. 在网络设置中开启热点，会随机生成一串密码。
2. 修改`etc/NetworkManager/system-connections/Hotspot.nmconnection`文件中`psk=`后面的内容为想要修改的新密码。
3. 重启networkmanager，再开启热点，修改的密码就会生效。

## 其他gnome相关软件

一些gnome系相关软件

- gnome-software   软件商店 (gnome-software-packagekit-plugin)
- gedit文件编辑器的插件：gedit-code-assistance和gedit-plugins。
- file-roller  压缩解压打包工具的图形前端
- geary   风格简洁的邮箱客户端
- gpaste  剪切板
- gvfs-google  登录google账户后 可在nautilus 挂载GoogleDrive
- gitg    图形界面的git工具
- polari    IRC客户端
- vinagre   远程连接客户端（支持ssh、vnc、rdp和spice）
- epipthany gnome浏览器（webkit内核，支持登录firefox帐号并同步相关内容）
- totem   视频播放器
- gnome-music   音乐播放器
- shotwell   数码相片管理工具
- gnome-schedule   计划任务（cron图形端）
- gnome-search-tool  搜索工具（可所搜文件中的文字）
- gnome-todo  待办事项清单（可连接到todoist）
- alacarte  gnome的菜单编辑器

## 快捷键

在 设置--设备--键盘

一些常用的快捷键：

- 窗口管理

  - Super+h  隐藏当前窗口

  - 最大化最小化

    - Super+⬆  最大化窗口
    - Super+⬇  还原最大化窗口为之前状态

  - 窗口平铺

    拖动窗口到屏幕左/右边缘会平铺该窗口到屏幕左/右

    - Super+⬅  平铺窗口到左侧
    - Super+➡  平铺窗口到右侧

- 工作区

  - 移动窗口到指定工作区
    - Super+shift+Home 移动窗口到第一个工作区
    - Super+shift+End 移动窗口到最后一个工作区
    - Super+Shift+PageDown  移动窗口到下一个工作区
    - Super+Shift+PageUp  移动窗口到下一个工作区
  - 切换工作区
    - Super+End  切换到最后一个工作区
    - Super+Home  切换到第一个工作区

- Super+v  显示通知清单

- 截图

  - PrtScn  截取屏幕为图片（建议设为super+print避免误按）
  - Shift+PrtScn  截取选择区域为图片（按下后用鼠标拉选）
  - Alt+PrtScn  截取当前窗口为图片
  - Shift+Ctrl+Alt+r  录制屏幕/停止录制

  三种截图快捷键在加上`Ctrl`后，则是截取图片到剪切板

  

- Alt+F2    快速使用命令(`r`命令重启shell，`rt`命令重载shell主题）。

- Alt+Space    可以弹出标题栏右键菜单。

- 根据个人喜好设置的一些快捷键：

  在快捷键设置界面按下退格(backspace)可消除设定的快捷键。
  
  - Super+f1/f2/f3/f4  切换到不同工作区
  - Ctrl+f1/f2/f3/f4  移动窗口到不同工作区
  - Shift+Super+h  隐藏所有正常窗
  - Super+e  nautilus文件管理
  - Super+Return  gnome-terminal终端
  - Super+g  gedit文件编辑器
## 电源管理

可参看[laptop笔记本相关](../laptop笔记本相关.md)

- 按下alt后，电池图标中的关机/重启按钮会变成暂停按钮。

- hibernate-status   扩展可以增加休眠等按钮。

- systemctl hybrid-sleep/hibernate/supend 命令分别是：混合睡眠（通电状态，保存到硬盘和内存）、休眠（关机状态，保存到硬盘）和睡眠（通电状态，保存到内存）。

  为了方便使用可将他们设置别名，在~/.bashrc中写入：

  ```shell
  alias hs='systemctl hybrid-sleep'  #混合睡眠
  alias hn='systemctl hibernate'    #休眠
  alias sp='systemctl suspend'  #暂停（挂起)
  ```


- 笔记本用户推荐安装[tlp](https://wiki.archlinux.org/index.php/TLP)或者[laptop-mode-tools]()

- intel可安装[powertop](https://wiki.archlinux.org/index.php/Powertop)

- 息屏时间，默认为空闲五分钟，可在设置(gnome-control-center)--电源(Prower)--息屏中设置。

  使用命令设置：

  ```shell
  #300为空闲时间，单位为秒，如果设置为0则表示不息屏
  gsettings set org.gnome.desktop.session idle-delay 'uint32 300'
  ```



## 其他

- 恢复当前用户所有gnome相关软件的初始设置`dconf reset -f /`。
- 关闭部分软件启动时提示输入密码：删除`~/.local/share/keyrings/login.keyring`
- gsettings所有的scemas都存储在`/usr/share/glib-2.0/schemas`下，均为xml文件。
