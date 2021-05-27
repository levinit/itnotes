[TOC]

个人在[archlinux](http://archlinux.org)下的日常使用经验列出，故而在archlinux及其衍生发行版中，以下所列软件**几乎**可以从archlinux官方源或者[aur](https://aur.archlinux.org)中搜索下载安装，所列出名字**一般**即是其包名，使用pacman或yaourt/pacaur等工具搜索即可。

**较少**包括这些类型的软件：

- 编程相关工具
- （主流发行版）系统安装后普遍自带的工具
- 常见窗口管理器（如i3wm）或桌面环境（如gnome）套件及相关自定义/美化/优化工具

# 软件资源
- [pkgs.org](https://pkgs.org/)    搜索各个发行版的软件包
- [launchpad.net](https://launchpad.net/)  软件协作开发平台（能下载到不少软件包）
- [fedora中文社区](https://www.fdzh.org/)  一些fedora的中文使用者相关软件包社区源
- [electron apps](https://electron.atom.io/apps/)  一些基于electron的软件
- [awesome linux softwares](https://github.com/LewisVo/Awesome-Linux-Software)  一些linux软件列表
- [archinux.org-list of applications](https://wiki.archlinux.org/index.php/List_of_applications)    archlinux.org的软件列表页面
- [aur](https://aur.archlinux.org/)   archlinux的用户社区源（也利用包管理工具如yaourt搜索和安装）
- [ocsstore](https://www.linux-apps.com)  下载各种linux资源，如软件、字体、桌面主题等等

# 模拟器/虚拟机/wine
- virtualbox  下载[微软官方提供的vbox镜像](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/)（免费使用）
- genymotion   安卓模拟器（需安装virtualbox）
- android-emulator   安卓模拟器
- ppsspp    PSP模拟器
- dophin-emu    Wii模拟器
- wine相关
  - wine
  - crossover
  - playonlinux

游戏相关可参看后文[游戏](#游戏)。

# 输入法

主要介绍中文输入法相关插件

- fcitx
  - fcitx-cloudpinyin  fcitx的云拼音插件（不支持fcitx-rime）
  - fcitx-libpinyin   智能拼音  可导入词库（内置下载导入搜狗词库的功能）
  - fcitx-sogoupinyin  搜狗拼音（支持全拼双拼下载词库以云词库支持）
  - fcitx-trime    中州韵（即小狼豪/鼠须管），跨平台的中文输入工具
- ibus
  - ibus-libpinyin   智能拼音 自带多个词库
  - ibus-rime   中州韵（即小狼豪/鼠须管），跨平台的中文输入工具

# 网络沟通

- feedreader     RSS阅读器
- [pushbullet]([https://www.**pushbullet**.com/ )相关（pushbullet是用于不同设备的消息和文件推送的工具）    第三方工具：pb-for-desktop、bashbullet2  pushbullet-nautilus（配套nautilus文件管理器使用的插件)

## 浏览器

- firefox   (gecko内核)
- chromium    （blink内核）
- epiphany    (webkit内核)

## 上传/下载/网络存储

### 下载工具

- 命令行
    - aria2（或aria2c） 多协议下载工具

    - axel  支持多线程和断点续传的HTTP/ftp下载工具

    - you-get  支持多个视频网站（youku、iqiyi、bilibili、qq……等网站），相关介绍查看[github:you-git](https://github.com/soimort/you-get)。可使用you-get和本地播放器观看视频：

      ```shell
      you-get -p mpv url    #mpv是要调用的播放器，url是视频所在网页地址。
      #更多选项查看   you-get --help
      ```

- 图形化

    -   uget  可调用aria2和curl
-   ariang-allinone  基于web界面的aria2工具
    -   transmission     支持bt
    -   amule    支持ed2k
    -   pointdownload   支持http, ftp, bt, magnet ,thunder 协议
    -   moonplayer    调用you-get下载中国相关视频网站的视频
    -   clipgrab    从DailyMotion, MyVideo等下载视频的工具


### 网络硬盘

- megasync   [mega](https:www.mega.nz)（在存储空间限制大小内的无限份历史版本）
- nutstore  [坚果云](https://www.jianguoyuan.com) （支持webDav，增量同步，支持历史版本）
- dropbox  [dropbox](https://www.dropbox.com/)
- [百度云](https://pan.baidu.com/download)
- google-drive  配合nautilus等文件管理器管理谷歌云盘
- nextcloud和seafile  私有云

### 同步工具

区别于“网络硬盘”，以下这些工具主要功能是同步，没有中心服务器概念。

- rsync  （图形界面grsync）
- resilio sync   原bt sync
- syncthing　同步工具   （图形界面 syncthing-gtk）
- freefilesync  同步＋对比

### 远程桌面

- teamviewer    有客户端和服务端
- splashtop    有客户端和服务端
- todesk
- sunlogin 向日葵
- vnc
  - 服务端
    - vino
    - tigervnc
  - 客户端
    - vinagre    支持vnc rdp spice
    - realvnc-vnc-viewer （vncviewer）

## 网络代理

- shadowsocks    影梭
  - shadowsocks-qt5    shadowsocks的图形前端工具
- brook
- v2ray
- xx-net    基于goagent的项目>>[github:xx-net](https://github.com/XX-net/XX-Net)
- lantern    [蓝灯项目](https://github.com/getlantern/lantern)
- hosts

  - [github-googlehosts/hosts](https://github.com/googlehosts/hosts)

  - adhost    [github-levinit/adhosts](https://github.com/levinit/adhosts)    科学上网+屏蔽广告

  - [switchhosts](https://github.com/oldj/SwitchHosts)  快速切换hosts
- 代理转发
  - proxychains    可TCP转发socks5/http，配置好代理后执行  `proxychains 程序名`
  - privoxy    可以转发socks5为http（可用于屏蔽广告等）
- 桌面设置的网络选项中代理一项可以使用自动模式，使用pac文件。

## 通讯

### 电子邮件

- thunderbird
  - [birdtray](https://github.com/gyunaev/birdtray)  thunderbird的托盘图标及辅助工具
- geary  简洁风格（gnome系）
- gnome的evolution和kde的kmail
- mailspring
- kube

### 即时通讯

- [telegram](https://telegram.org/)  （特色：安全加密）
- [slack](https://slack.com/)    （特色：办公协作、工具聚合）
- [discord](https://discordapp.com/)   （特色：游戏互动、可自建服务器）
- skypeforlinux     官方的skype
- polari   irc客户端(gnome系)
- electronic-wechat   微信electronic版
- [gitter](https://gitter.im/ )  （特色：配合github的开发者聊天工具）
- 多种协议聚合
  - franz
  - pidgin
  - empathy

# 文件管理

- udftools   UDF 文件系统和DVD/CD-R(W)驱动
- ncdu  文件大小统计

## 打包、压缩和解压

- 后端 p7zip  unrar  unzip tar xz gzip

- 图形前端  xarchiver  file-roller(gnome)  ark(plasma)

## 对比

- diffuse   文件内容对比
- meld　文件夹/文件内容对比

## 搜索

- regexxer  使用正则搜索（包含文本内容）
- gnome-search-tool   搜索档案（包含文本内容，可使用正则）
- catfish    搜索工具
- albert    综合性搜索工具及启动器

## 乱码处理

参看[archwiki:乱码问题](https://wiki.archlinux.org/index.php/Arch_Linux_Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E4.B9.B1.E7.A0.81.E9.97.AE.E9.A2.98)

- 文件名乱码  convmv


   - 文件内容乱码  iconv


   - zip乱码  unzip-natspec 或者unzip-iconv 取代原版的unzip

# 多媒体
## 图像

- gpick       取色工具

### 屏幕截图

*各个桌面环境一般都自带截屏工具，按下print sc键（或print）即可截屏。*

- scrot     命令行截屏工具
- shutter   功能强大的截图工具

### 绘画

- pinta   画图板及图片处理
- krita    图像处理和绘图

### 图像处理

- gimp    图像处理

  - [gimp-gap](https://github.com/GNOME/gimp-gap)（gap, GIMP Animation Package）GIMP 动画包

    支持逐帧动画（如 AVI 格式或者 GIF 格式的视频或者动画）的读取、创建和编辑。

  - [export-layers](https://github.com/khalim19/gimp-plugin-export-layers)    图层导出

  - [resynthesizer](https://github.com/bootchk/resynthesizer)  内容动态感知 纹理合成

  - [UFRaw](http://ufraw.sourceforge.net/)  RAW文件支持

- krita    图像处理和绘图

- Inkscape   矢量图形制作和处理

- opentoonz     2D制作

- blender    3D制作

- freecad

### 格式转换

- imagemagick    命令行的图像处理和图片格式转换
- XnConvert    图片格式转换

### 相片管理和处理

- [polarr](https://snapcraft.io/polarr) 相片处理
- digikam  （plasma）
- shotwell
- darktable  组织和管理raw格式照片

## 音频

- pulseeffects  音效（Pulseaudio）

### 音乐播放

- rhythmbox    支持podcast和一些在线音乐服务
- clementine    支持podcast和许多在线音乐服务
- deadbeef    良好支持cue
- osdlyrics    自动下载和显示歌词
- anoise    环境背景声音(雨声、鸟鸣、街市……此外有图形界面anoise-gui以及一些音频扩展anoise-media、anoise-community-extesion)

### 在线音乐

- netease-cloud-music    网易云音乐
- spotify     音乐流媒体服务[spotify](https://www.spotify.com/)（注册帐号和**有时候登录时**需翻越gfw）
- pithos      第三方的pandora客户端  [pithos](https://pithos.github.io/)

### 音频编辑

- audacity    音频编辑
- musescore    乐谱工具

## 视频

### 屏幕录制

- simplescreenrecorder   屏幕录制
- obs-studio    录屏 支持直播视频流
- vokoscreen    可录制视频和gif
- peek    可录制视频和gif

### 视频播放器

- mpv       风格极简
- parole      风格简洁
- vlc和smplayer     功能全面
- kodi     多媒体平台（图片浏览、音乐、播客、视频等等）
- popcorntime    在线视频观看（具有torrent即时观看和下载功能）
- moonplayer    在线视频网站视频播放[github:moonplayer](https://github.com/coslyk/moonplayer)
  - 插件   [moonplayer-plugins](https://github.com/coslyk/moonplayer-plugins)
- yout-get   下载在线视频网站的视频（可配合视频播放器播放在线视频）

### 视频编辑

- mencoder    命令行的视频编码处理工具
- handbrake    视频格式转换
- openshot    功能强大的视频编辑工具
- lightworks   专业的视频剪辑工具
- shotcut    视频剪辑工具
- 字幕
  - aegisub
  - gnome-subtitles

# 记录写作/学习办公

## 阅读

### pdf工具

- okular  （plasma）
- evince  （gnome）
- 浏览器
- epdfview
- pdfshuffler    pdf裁剪

## 学习办公

- office套件
  - libreoffice
  - wps-office
- pspp     统计软件（可看作开源版的spss）
- gitbook-editor   [gitbook](https://gitbook.com)书籍制作工具
- calibre    电子书制作编辑格式转换
- stellarium    天文软件
- [anki](https://apps.ankiweb.net/)  跨平台、多语言的词汇卡片学习工具
- ganttproject  甘特图项目管理工具

## 笔记

-  nixnote  第三方的evernote（印象笔记）
-  wiznote    为知笔记（同步需要收费）多层级笔记
-  workflowy   单页列表式层级笔记
-  dynalist    模仿workflowy(增加部分功能)
-  laverna    支持markdown的笔记
-  simplenote   支持markwon的简单笔记
-  leanote    蚂蚁笔记  markdown为主 可发布博客(使用官方服务收费，也可免费自建笔记服务)
-  tomboy    客扩展带便签功能的笔记（可借助其他工具同步数据库）
-  zim  使用wiki管理方式念的笔记


## 思维图/流程图/设计稿

- scribus     出版物设计软件（设计杂志、海报、演示稿件等等）
- mockingbot   [墨刀](http://modao.cc) 原型设计工具
- xournal  支持手写的笔记本
- pencil     设计稿制作（web页面、桌面程序界面、移动应用界面……）
- dia    示意图制作（丰富的类型：流程图、UML、气象、地理、工程……）
- [draw.io](https://www.draw.io/)  流程图设计
- 思维图
  - vym
  - labyrinth
  - freemind
  - xmind


## markdown编辑器
- typora
- remarkable
- haroopad

## 词典/翻译

- goldendict    功能丰富的支持多种格式词典库词典
- sdcv    星际译王（StartDict)的命令行版
- moedict    [萌典](https://racklin.github.io/moedict-desktop/download.html)   汉语词典（还包括客家话、闽南语，以及简单的中翻英法德语）
- ydcv    命令行的有道在线词典
- youdao-dict    有道词典
- 本地化翻译：
  - gtranslator    gnome的本地化翻译工具
  - lokalize    kde的本地化翻译工具
  - poedit  基于gettext/po-based的简单翻译工具

# 游戏

使用wine/crossover或虚拟机或模拟器进行游戏参考前文的[模拟器/虚拟机/wine](#模拟器/虚拟机/wine)。

- steam    [steam平台上支持linux的游戏](http://store.steampowered.com/search/?sort_by=Reviews_DESC&category1=998&os=linux)
- gog    [gog平台上支持linux的游戏](https://www.gog.com/games?system=lin_mint,lin_ubuntu&sort=bestselling&page=1)
  - lgogdownloader   下载gog平台上支持linux游戏的命令行工具
- 围棋
  - gopanda  [熊猫围棋igs](http://pandanet-igs.com/communities/gopanda2)客户端
  - qgo  围棋客户端和sgf棋谱工具 可调用gnugo人机对弈
  - gnugo  围棋引擎
  - [leela](https://www.sjeng.org/leela.html?utm_source=org.mozilla.firefox&utm_medium=social)
- 一些著名的开源游戏
  - 0.a.d   类似帝国时代的即时策略游戏  [帝国崛起0.a.d](https://play0ad.com/)
  - nethack   单人角色扮演冒险探索游戏  [nethack](http://www.nethack.org/)
  - wesnoth    奇幻背景的回合制策略战棋游戏  [韦诺之战The Battle for Wesnoth](http://wesnoth.org/)
  - cataclysm-dda    末日幻想背景的探索生存游戏  [大灾变：黑暗之日Cataclysm: Dark Days Ahead](http://cn.cataclysmdda.com/)
  - stuntrally  3D赛车游戏[Stunt Rally](http://stuntrally.tuxfamily.org/)
  - supertuxkart    卡丁车游戏[supertuxkart](https://supertuxkart.net/Main_Page)

## 可能没什么用的趣味命令行

- cmatrix     黑客帝国风格的字符下落
- [hollywood](https://github.com/dustinkirkland/hollywood)    假装是好莱坞电影中的黑客
- `telnet towel.blinkenlights.nl`    运行该命令可欣赏《星球大战》电影
- sl    一辆小火车奔驰而过的画面
- screenfetch  或 neofetch    发行版logo及系统简要信息显示
- fortune     输入随机格言/诗句等
  - 包含中文或中文版的fortune：fortune-zh或者fortune-mod-zh (包名在不同发行版有出入)
  - cowfortune    将fortune和cowsay配合
- asciiquarium    水族馆

# 系统配置

- 系统盘制作
  
  对于支持UEFI启动的设备，直接复制iso镜像中的所有文件到安装介质（如U盘）中即可启动。
  
  - dd    `dd if=/path/system-image.iso of=/dev/sdb bs=10M`
  
  - multibootusb    在一个U盘安装多个系统的工具
  
  - woeusb  制作windows启动盘
  
    ```shell
    sudo woeusb --device /path/to/filename.iso /dev/sdx --target-filesystem NTFS
    ```


- man-pages-zh_cn和man-pages-zh_tw  [中文man手册](https://github.com/man-pages-zh/manpages-zh)

- tldr　简版man pages 查询工具

- 电源节能
  - tlp   电源管理工具（默认配置已针对电池优化，安装后以systemctl enable tlp启用即可）
  - laptop-mode-tools    笔记本电源管理
  - powertop    针对intel的节电工具
  
- fancontrol   风扇控制（图形界面fancontrol-gui）

- psensor  温度监控

- setleds  键盘灯控制（num-lock caps-lock scroll-lock）

  ```shell
  #可以一次打开或关闭多个键盘灯
  setleds +num +caps +scroll  #打开numlock capslock scrolllock
  setleds -num -caps -scroll  #关闭numlock capslock scrolllock
  ```

- caffeine    在全屏播放时禁止系统挂起/锁屏/睡眠/休眠……

- htop    进程管理器

- displaycal   显示器色彩调整

- bleachbit    磁盘清理（清除缓存、清理缩略图、粉碎文件……）

- xev 按键检测

- hotapd  无线热点

- cron计划任务
  - 命令行：cronie、dcron等等
  - 图形界面
    - gnome-schedule
    - fcronq
    - gcrontab
  
- 数据备份
  - backintime
  - timeshift
  - etckeeper  使用版本控制工具备份etc目录
  
- [微码](https://wiki.archlinux.org/index.php/Microcode_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
  - intel-ucode
  - amd-ucode
##  安全

- 反病毒
  - clamav  病毒扫描
    - clamtk    图形界面的clamav
- 数据安全
  - extundelete  恢复删除的ext分区中的文件
  - 加密
    - truecrypt    跨平台的硬盘加密工具
    - veracrypt    加密硬盘 基于TrueCrypt
    - cryptsetup    加密硬盘（命令行）

## 个性化设置

- lolcat    彩色输出
- grub-customizer   grub管理
- 显示器色温调节
  - gnome桌面自带（设置-显示器-夜光）
  - redshift
  - xflux
- 更换壁纸
  - wallch
  - variety

# 开发工具

- zeal 类似dash（mac软件）的api查询工具
- mycli   支持语法高亮和命令提示的mysql客户端
- git  字符界面的git管理工具
  - [gisto](http://www.gistoapp.com/)    gist管理工具
  - tig
  - 图形界面git工具
    - github-desktop
    - gitg   查看为主，有简单操作功能 (gnome系)
    - [git-cola](http://git-cola.github.io/)  python编写(win/mac/linux)
    - [gitkraken](https://www.gitkraken.com/)  基于nodeGit(win/mac/linux)
- 终端美化
  - [powerline-shell](https://github.com/banga/powerline-shell)
  - [bash-powerline](https://github.com/riobard/bash-powerline)
  - [zsh-powerline](https://github.com/riobard/zsh-powerline)
- script  终端操作记录
- asciinema  记录终端操作（支持上传到asciinema.org并与他人共享）

# 终端工具

- [autojump](https://github.com/wting/autojump)或[fasd](https://github.com/clvv/fasd)或[z](https://github.com/rupa/z)或[z.lua](https://github.com/skywind3000/z.lua) 快速进入到某个目录
- fzf   终端模糊搜索工具
- bc    的计算器
- lrzsz  使用zmodem传输协议，其包含rz（receive Zmodem）接受文件和sz（send Zmodem）传送文件
- tmux  多会话管理工具
- htop  任务管理器 更好的top
- bat  语法高亮的文件查看工具（项目克隆自cat）
- 天气/日历

  - wego   终端天气
  - cal    自如界面月历
  - ccal   字符界面中国日历
