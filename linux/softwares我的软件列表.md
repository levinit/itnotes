[TOC]

个人在[archlinux](http://archlinux.org)下的日常使用经验列出，故而在archlinux及其衍生发行版中，以下所列软件**几乎**可以从archlinux官方源或者[aur](https://aur.archlinux.org)中搜索下载安装，所列出名字**一般**即是其包名，使用pacman或yaourt/pacaur等工具搜索即可。

**较少**包括这些类型的软件：

- 编程相关工具
- （主流发行版）系统安装后普遍自带的工具
- 常见窗口管理器（如i3wm）或桌面环境（如gnome）套件及相关自定义/美化/优化工具



# 软件资源站点
- [pkgs.org](https://pkgs.org/)    搜索各个发行版的软件包
- [launchpad.net](https://launchpad.net/)  软件协作开发平台（能下载到不少软件包）
- [fedora中文社区](https://www.fdzh.org/)  一些fedora的中文使用者相关软件包社区源
- [electron apps](https://electron.atom.io/apps/)  一些基于electron的软件
- [awesome linux softwares](https://github.com/LewisVo/Awesome-Linux-Software)  一些linux软件列表
- archlinux
  - [archinux.org-list of applications](https://wiki.archlinux.org/index.php/List_of_applications)    archlinux.org的软件列表页面
  - [archlinuxcn](https://github.com/archlinuxcn/mirrorlist-repo)   archlinux中文社区源
  - [aur](https://aur.archlinux.org/)    archlinux的用户社区源（也利用包管理工具如yaourt搜索和安装）
- [ocsstore](https://www.linux-apps.com)  下载各种linux资源，如软件、字体、桌面主题等等



# 模拟器/虚拟机
- virtualbox  下载[微软官方提供的vbox镜像](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/)（免费使用）
- 安卓模拟其
  - genymotion
  - android-emulator
- ppsspp    PSP模拟器
- dophin-emu    Wii模拟器
- wine相关
  - wine
  - crossover
  - playonlinux

游戏相关可参看后文[游戏](#游戏)。

# 字符终端环境

- shell prompt

  - [starship](https://starship.rs)

- fzf   终端模糊搜索工具

- 快速进入常用目录

  - [z](https://github.com/rupa/z)

  - [autojump](https://github.com/wting/autojump)

- 复制粘贴

  - xclip   在X11下的终端中复制粘贴的工具

  - wl-clipboard    在wayland下的终端中复制粘贴的工具

- bc    计算器
- lrzsz    使用zmodem传输协议，其包含rz（receive Zmodem）接受文件和sz（send Zmodem）传送文件
- tmux    多会话管理工具
- bat    语法高亮的文件查看工具（项目克隆自cat）
- 天气/日历

  - wego   终端天气
  - cal    自如界面月历
  - [ccal](https://ccal.chinesebay.com/ccal/index.html)   字符界面月历带有中国农历

# 输入法

主要介绍中文输入法相关插件

- fcitx5
  
  参看[archwiki-fcitx5](https://wiki.archlinuxcn.org/wiki/Fcitx5)
  
- ibus
  
  参看[archwiki-ibus](https://wiki.archlinuxcn.org/wiki/IBus)
  
  

# 网络沟通



## 浏览器

- firefox
- chromium
- microsoft edge
- epiphany    (webkit内核)

## 上传/下载/网络存储

### 下载工具

- 命令行
    - aria2（或aria2c） 多协议下载工具

    - axel  支持多线程和断点续传的HTTP/ftp下载工具

    - you-get  支持多个视频网站[github:you-git](https://github.com/soimort/you-get)。可使用you-get和本地播放器观看视频：

      ```shell
      you-get -p mpv url    #mpv是要调用的播放器，url是视频所在网页地址。
      #更多选项查看   you-get --help
      ```

- 图形化

    -   uget  可调用aria2和curl
    
    -   transmission     支持bt
    -   amule    支持ed2k
    -   moonplayer    调用you-get下载中国相关视频网站的视频
    -   clipgrab    从DailyMotion, MyVideo等下载视频的工具




### 网络硬盘

- [megasync](https:www.mega.nz)   历史版本、正则忽略功能
- [坚果云](https://www.jianguoyuan.com) 支持webDav，增量同步，支持历史版本
- [dropbox](https://www.dropbox.com/)
- [百度网盘](https://pan.baidu.com/download)
- google-drive  在gnome登录google账号，配合nautilus等文件管理器管理谷歌云盘
- nextcloud和seafile  私有云



### 同步工具

区别于“网络硬盘”，以下这些工具主要功能是同步，没有中心服务器概念。

- rsync
  - 图形界面grsync
- resilio sync   原bt sync
- syncthing　有web图形界面
- freefilesync  同步＋对比



### 远程桌面

- teamviewer
- anydesk
- todesk
- 向日葵sunlogin
- splashtop
- rustdesk
- vnc
  - 服务端
    - vino
    - tigervnc-server
    - realvnc-server
    - turbovnc    针对图形优化
  - 客户端
    - vinagre    支持vnc rdp spice等
    - realvnc-vncviewer
    - remina

## 网络代理

- clash

  基于clash的工具

  - shellclash

- [brook](https://github.com/txthinking/brook)

- 代理转发
  - proxychains    可TCP转发socks5/http，配置好代理后执行  `proxychains 程序名`
  - privoxy    可以转发socks5为http

## 通讯

### 电子邮件

- thunderbird
  - [birdtray](https://github.com/gyunaev/birdtray)  thunderbird的托盘图标及辅助工具
- geary  简洁风格（gnome系）
- gnome的evolution和kde的kmail
- mailspring
- kube

### 即时通讯

- [telegram](https://telegram.org/)   加密性强

  - [nchat](https://github.com/d99kris/nchat)

- [slack](https://slack.com/)    办公协作、工具聚合

- [discord](https://discordapp.com/)   可自建服务器

- polari   irc客户端(gnome系)

- [gitter](https://gitter.im/ )  github的开发者聊天工具

  

# 文件管理

- ncdu  文件大小统计

## 归档、压缩和解压

- p7zip  unrar  unzip tar xz gzip

- 图形前端  xarchiver  file-roller(gnome)  ark(plasma)

## 文件对比

- diffuse   文件内容对比
- meld　文件夹/文件内容对比

## 搜索

- regexxer   使用正则搜索（包含文本内容）
- gnome-search-tool   搜索档案（包含文本内容，可使用正则）
- catfish    搜索工具
- albert    综合性搜索工具及启动器，类似alfred

## 乱码处理

参看[archwiki:乱码问题](https://wiki.archlinux.org/index.php/Arch_Linux_Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)#.E4.B9.B1.E7.A0.81.E9.97.AE.E9.A2.98)

- 文件名乱码  convmv
  ```shell
  convmv -f GB2312 -t utf8 --notest --nosmart file
  ```
  `-f` 指定原始编码，`-t` 指定输出编码。使用 `convmv --list` 可查询所有支持的编码。

  `--notest` 表示非测试而是要进行转码（如果不使用该参数只会打印出转换结果而不会实际转码），`--smart `表示如果已经是 UTF-8 则忽略。 

- 文件内容乱码  iconv
  ```shell
  iconv -f GB2312 -t UTF-8 -o new-file origin-file
  ```

- zip乱码  unzip-natspec取代原版的unzip
  解压时使用`-O`指定编码格式，示例：
  ```shell
  unzip -O gb2312 file.zip
  ```

# 多媒体
## 图像

- gpick       取色工具

### 屏幕截图

*各个桌面环境一般都自带截屏工具，按下print sc键（或print）即可截屏。*

- scrot     命令行截屏
- shutter   功能强大

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

- freecad    开源cad工具

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

- [网易云音乐](https://music.163.com/#/download)   netease-cloud-music
- [spotify](https://www.spotify.com/us/download/linux/)
- [pithos](https://pithos.github.io/)  第三方的pandora客户端
- [QQ音乐](https://y.qq.com/download/download.html)  qqmusic



### 音频编辑

- audacity    音频编辑
- musescore    乐谱工具

## 视频

### 屏幕录制

- simplescreenrecorder   屏幕录制
- [obs-studio](https://obsproject.com/download)    录屏 支持直播视频流
- vokoscreen    可录制视频和gif
- peek    可录制视频和gif



### 视频播放器

- mpv       风格极简
- parole      风格简洁
- vlc和smplayer     功能全面
- kodi     多媒体平台（图片浏览、音乐、播客、视频等等）
- moonplayer    在线视频网站视频播放[github:moonplayer](https://github.com/coslyk/moonplayer)
  - 插件   [moonplayer-plugins](https://github.com/coslyk/moonplayer-plugins)



### 在线播放

- [腾讯视频](http://v.qq.com/download.html#Linux)
- [popcorntime](popcorntime https://popcorn-time.tw/linux.html)    具有torrent即时观看和下载功能



### 视频编辑

- 剪辑

  - [openshot](https://www.openshot.org)
  - [shotcut](https://shotcut.org)
  - [lightworks](https://www.lwks.com)  （高级功能收费）

- 转码

  - [handbrake](https://handbrake.fr)    视频格式转换
  - mencoder    命令行

- 字幕
  - aegisub
  - gnome-subtitles
  
  

## 建模

- [blender](https://www.blender.org)
- [openSCAD](https://openscad.org)
- [FreeCAD](https://www.freecadweb.org)
- [art of illusion](http://www.artofillusion.org)
- [Mesh Lab](https://www.meshlab.net)



# 记录写作/学习办公

## 阅读

### pdf工具

- okular  （plasma）
- evince  （gnome）
- 浏览器
- epdfview
- pdfshuffler    pdf裁剪
- [pdfsam](https://github.com/torakiki/pdfsam) 拆分合并旋转提取等处理
- poppler  提供一系列命令行工具可处理pdf，如：
  ```shell
  #将pdf文件按页拆分（可使用参数指定每几页一份）
  pdfseparate <source_pdf_file> <name>-%d.pdf
  #合并pdf，最后一个参数为要合成的pdf
  pdfunite in-1.pdf in-2.pdf in-n.pdf out.pdf
  ```

## 学习办公

- office套件
  - [libreoffice](https://www.libreoffice.org)
  - [wps-office](https://linux.wps.cn)
- pspp     统计软件（可看作开源版的spss）
- calibre    电子书制作编辑格式转换
- stellarium    天文软件
- [anki](https://apps.ankiweb.net/)  跨平台、多语言的词汇卡片学习工具
- ganttproject  甘特图项目管理工具



## 笔记

-  [workflowy](https://workflowy.com/downloads/linux/)   单页列表式层级笔记
-  [dynalist](https://dynalist.io/download)    类似workflowy
-  [laverna](https://laverna.cc/#download)    支持markdown的笔记
-  simplenote   支持markwon的简单笔记
-  tomboy    客扩展带便签功能的笔记（可借助其他工具同步数据库）
-  zim  使用wiki管理方式念的笔记
-  typora  markdown编辑器
-  remarkable  markdown编辑器
-  haroopad   markdown编辑器
-  [obsidian](https://obsidian.md)  笔记工具，支持mardown



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

## 词典/翻译

- [有道词典](https://cidian.youdao.com/multi.html)

- goldendict    功能丰富的支持多种格式词典库词典 youdao-dict 

- sdcv    星际译王（StartDict)的命令行版

- moedict    [萌典](https://racklin.github.io/moedict-desktop/download.html)   汉语词典（还包括客家话、闽南语，以及简单的中翻英法德语）

- 本地化翻译：
  - gtranslator    gnome的本地化翻译工具
  - lokalize    kde的本地化翻译工具
  - poedit  基于gettext/po-based的简单翻译工具
  
- [deepL](https://www.deepl.com/translator)

  

# 游戏

使用wine/crossover或虚拟机或模拟器进行游戏参考前文的[模拟器/虚拟机](#模拟器/虚拟机)。

- [steam平台上支持linux的游戏](http://store.steampowered.com/search/?sort_by=Reviews_DESC&category1=998&os=linux)

- [gog平台上支持linux的游戏](https://www.gog.com/games?system=lin_mint,lin_ubuntu&sort=bestselling&page=1)

- 围棋
  - gopanda  [熊猫围棋igs](http://pandanet-igs.com/communities/gopanda2)客户端
  - qgo  围棋客户端和sgf棋谱工具 可调用gnugo人机对弈
  - gnugo  围棋引擎
  - [leela](https://www.sjeng.org/leela.html?utm_source=org.mozilla.firefox&utm_medium=social)
  
- 一些著名的开源游戏
  - [帝国崛起0.a.d](https://play0ad.com/)  类似帝国时代的即时策略游戏
  
  - [nethack](http://www.nethack.org/)  单人角色扮演冒险探索游戏
  
  - [韦诺之战The Battle for Wesnoth](http://wesnoth.org/)  奇幻背景的回合制策略战棋游戏
  
  - cataclysm 大灾变系列
  
    末日幻想背景的探索生存游戏
  
    - [大灾变：黑暗之日Cataclysm: Dark Days Ahead](https://cataclysmdda.org)  cataclysm-dda
    - [大灾变：光明之夜Cataclysm: Bright Nights](https://docs.cataclysmbn.org)  cataclysm-bn
  
  - [Stunt Rally](http://stuntrally.tuxfamily.org/)   3D赛车游戏
  
  - [supertuxkart](https://supertuxkart.net/Main_Page)  卡丁车游戏
  
  

## 没什么用的趣味命令行工具

- [cmatrix](https://github.com/abishekvashok/cmatrix)    1999年电影《黑客帝国》（The Matrix）中的字符下落效果
- [no-more-secrets](https://github.com/bartobri/no-more-secrets)    1992年电影《通天神偷》(Sneakers)中的字符解密效果
- [hollywood](https://github.com/dustinkirkland/hollywood)    假装是好莱坞电影中的黑客
- `telnet towel.blinkenlights.nl`    文字版的《星球大战》电影
- [sl](https://github.com/mtoyoda/sl)    Stream Locomotive一辆蒸汽小火车奔驰而过的字符键盘动画
- [neofetch](https://github.com/dylanaraps/neofetch)    发行版logo及系统简要信息显示
- [fortune-mod](https://github.com/shlomif/fortune-mod)     输入随机格言/诗句等
  - 包含中文或中文版的fortune：fortune-zh或者fortune-mod-zh (包名在不同发行版有出入)
  - cowfortune    将fortune和cowsay配合
- [asciiquarium](https://github.com/cmatsuoka/asciiquarium)    ASCII水族馆（aquarium）
- [lolcat](https://github.com/busyloop/lolcat)    让输出的字符串彩虹色🌈



# 系统

- 系统盘制作
  
  对于支持UEFI启动的设备，直接复制iso镜像中的所有文件到安装介质（如U盘）中即可启动。
  
  - dd    `dd if=/path/system-image.iso of=/dev/sdb bs=10M`
  
  - [ventory](https://www.ventoy.net/cn/index.html)    可启动U盘的开源工具，无需反复地格式化U盘，只需要将各种镜像文件放入U盘即可在启动后选择某个系统进入。
  
    


- man-pages-zh_cn和man-pages-zh_tw  [中文man手册](https://github.com/man-pages-zh/manpages-zh)

- tldr　简版man pages 查询工具

- 电源节能
  - tlp   电源管理工具（默认配置已针对电池优化，安装后以systemctl enable tlp启用即可）
  - laptop-mode-tools    笔记本电源管理
  - powertop    针对intel的节电工具
  
  
  
- caffeine    在全屏播放时禁止系统挂起/锁屏/睡眠/休眠……

- htop    进程管理器

- displaycal   显示器色彩调整

- bleachbit    磁盘清理（清除缓存、清理缩略图、粉碎文件……）

- hotapd  无线热点

- cron计划任务
  - 命令行：cronie、dcron等等
  - 图形界面
    - gnome-schedule
    - fcronq
    - gcrontab
  
- 数据备份
  - 带图形界面
    - backintime  文件备份
    - timeshift    快照式备份，类似MacOS Time Machine，适合系统快照备份
    - etckeeper  使用版本控制工具备份`etc`目录
  - 纯cli
    - borg  具有版本保留策略，超强压缩+去重，可设置各种版本保留策略，适合x中大型数据的高级备份工具
    - restic  部署简单（单一二进制文件），支持各种云端协议，自动去重等
  
- 数据修复


  - extundelete
  - testdisk

- [微码](https://wiki.archlinux.org/index.php/Microcode_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
  - intel-ucode
  - amd-ucode
  
  
## 硬件控制

- xev 按键检测

- fancontrol   风扇控制（图形界面fancontrol-gui）

- psensor  温度监控

- setleds  键盘灯控制（num-lock caps-lock scroll-lock）

  ```shell
  #可以一次打开或关闭多个键盘灯
  setleds +num +caps +scroll  #打开numlock capslock scrolllock
  setleds -num -caps -scroll  #关闭numlock capslock scrolllock
  ```

## 信息安全

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
- git 图形界面git工具
  - github-desktop
  - gitg   查看为主，有简单操作功能 (gnome系)
  - [git-cola](http://git-cola.github.io/)  python编写(win/mac/linux)
  - [gitkraken](https://www.gitkraken.com/)  基于nodeGit(win/mac/linux)
- 终端操作记录
  - asciinema  记录终端操作（支持上传到asciinema.org并与他人共享）

- scrpcy  安卓投屏控制
- vscode
- Jetbrains系列
