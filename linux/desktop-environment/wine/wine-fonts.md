几种解决linux中wine/crossover字体问题的方法。

# 字体链接

Windows支持字体链接：当一种字体中不存在某个字时，可以尝试从另一个字体文件中寻找相应的字形。

通过注册表指定代替的字体以达到wine程序使用linux已经安装的字体的目录（可在`/usr/share/fonts`或`~/.local/fonts`找到已经安装的字体）。

1. 编写注册表文件，假如该文件为fonts.reg。

2. `wine regedit`启动注册表程序，点击注册表-导入注册表文件，选择fonts.reg文件导入。

   如使用crossover，在其界面中打开**运行命令**，运行regedit（或者选中容器后在右键菜单中选择“运行命令“)即可打开注册表程序。

如果仍有部分字体出现方块，尝试在wine配置（winecfg程序）中将系统改为其他版本（如xp）。

---

fonts.reg文件示例——使用SourceHanSansCN-Medium.otf代替windows字体。

如要使用其他字体自行更换为具体字体文件名（例如文泉驿微米黑`wqy-microhei.ttc`），提示：在`/usr/share/fonts`下可找到该字体文件。

```shell
REGEDIT4

 [HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontLink\SystemLink]
 "System"="SourceHanSansCN-Medium.otf"
 "Sans Serif"="SourceHanSansCN-Medium.otf"
 "Arial"="SourceHanSansCN-Medium.otf"
 "Arial Black"="SourceHanSansCN-Medium.otf"
 "Arial CE,238"="SourceHanSansCN-Medium.otf"
 "Arial CYR,204"="SourceHanSansCN-Medium.otf"
 "Arial Greek,161"="SourceHanSansCN-Medium.otf"
 "Arial TUR,162"="SourceHanSansCN-Medium.otf"
 "Microsoft Sans Serif"="SourceHanSansCN-Medium.otf"
 "Microsoft YaHei"="SourceHanSansCN-Medium.otf"
 "微软雅黑"="SourceHanSansCN-Medium.otf"
 "MS Sans Serif"="SourceHanSansCN-Medium.otf"
 "MS Shell Dlg"="SourceHanSansCN-Medium.otf"
 "MS Shell Dlg 2"="SourceHanSansCN-Medium.otf"
 "Tahoma"="SourceHanSansCN-Medium.otf"
 "Tahoma Bold"="SourceHanSansCN-Medium.otf"
 "SimSun"="SourceHanSansCN-Medium.otf"
 "SimHei"="SourceHanSansCN-Medium.otf"
 "SimKai"="SourceHanSansCN-Medium.otf"
 "SimFang"="SourceHanSansCN-Medium.otf"
 "宋体"="SourceHanSansCN-Medium.otf"
 "新細明體"="SourceHanSansCN-Medium.otf"
 "MingLiU"="SourceHanSansCN-Medium.otf"
 "PMingLiU"="SourceHanSansCN-Medium.otf"
 "DFKai-SB"="SourceHanSansCN-Medium.otf"
 "FangSong"="SourceHanSansCN-Medium.otf" "KaiTi"="SourceHanSansCN-Medium.otf"
 "Microsoft JhengHei"="SourceHanSansCN-Medium.otf"
 "NSimSun"="SourceHanSansCN-Medium.otf"
 "Lucida Sans Unicode"="SourceHanSansCN-Medium.otf"
 "Courier New"="SourceHanSansCN-Medium.otf"
 "Courier New CE,238"="SourceHanSansCN-Medium.otf"
 "Courier New CYR,204"="SourceHanSansCN-Medium.otf"
 "Courier New Greek,161"="SourceHanSansCN-Medium.otf"
 "Courier New TUR,162"="SourceHanSansCN-Medium.otf"
 "FixedSys"="SourceHanSansCN-Medium.otf"
 "Helv"="SourceHanSansCN-Medium.otf"
 "Helvetica"="SourceHanSansCN-Medium.otf"
 "Times"="SourceHanSansCN-Medium.otf"
 "Times New Roman CE,238"="SourceHanSansCN-Medium.otf"
 "Times New Roman CYR,204"="SourceHanSansCN-Medium.otf"
 "Times New Roman Greek,161"="SourceHanSansCN-Medium.otf"
 "Times New Roman TUR,162"="SourceHanSansCN-Medium.otf"
 "Tms Rmn"="SourceHanSansCN-Medium.otf"
```

微调字体渲染的注册表文件adjust-fonts.reg（同样按上面的方法导入注册表即可）：

```shell
REGEDIT4 [HKEY_CURRENT_USER\Software\Wine\X11 Driver] "ClientSideAntiAliasWithCore"="Y" "ClientSideAntiAliasWithRender"="Y" "ClientSideWithRender"="Y" [HKEY_CURRENT_USER\Control Panel\Desktop] "FontSmoothing"="2" "FontSmoothingType"=dword:00000002 "FontSmoothingGamma"=dword:00000578 "FontSmoothingOrientation"=dword:00000001
```

# 使用Windows字体

## 硬盘中存在一个windows系统

挂载windows的C:\盘，例如其被挂载在`/windows`

```
ln -s /windows/Windows/Fonts /usr/share/fonts/WindowsFonts
```

 然后重新生成字体缓存：

```
fc-cache
```

 或者,将Windows的字体复制到`/usr/share/fonts`:

```
mkdir /usr/share/fonts/WindowsFonts
cp /windows/Windows/Fonts/* /usr/share/fonts/WindowsFonts
chmod 755 /usr/share/fonts/WindowsFonts/*
```

 然后重新生成字体缓存：

```
fc-cache
```

## 提供相应的windows字体

把相关字体（如simsun.ttc）放到`~/.wine/drive_c/windows/Fonts/`目录。