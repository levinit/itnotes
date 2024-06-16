- DE, desktop environment 桌面环境

  如gnome、kde plasma、xfce、lxde

- WM, window manager  窗口管理器

  如i3wm、twm、awesome、openbox

  各个桌面环境也有自己的wm，如gnome的mutter、kde的kwin

- dm，display manager 显示管理器

  登陆DE或WM（非必须）的图形界面工具，如gdm、sddm、lightdm
  
  

# XDG目录规范

> 该规范定义了一套指向应用程序的环境变量，这些变量指明的就是这些程序应该存储的基准目录。而变量的具体值取决于用户，若用户未指定，将由程序本身指向一个默认目录，该默认目录也应该遵从标准，而不是用户主目录。

| XDG环境变量     | 默认值                        | 目录说明                     |
| --------------- | ----------------------------- | ---------------------------- |
| XDG_DATA_HOME   | $HOME/.local/share            | 用户数据文件                 |
| XDG_CONFIG_HOME | $HOME/.config                 | 用户配置文件                 |
| XDG_CACHE_HOME  | $HOME/.cache                  | 非必要（缓存）数据           |
| XDG_RUNTIME_DIR | /run/user/`<userid>`          | 用户特定的非重要性运行时文件 |
| XDG_DATA_DIRS   | /usr/local/share/:/usr/share/ | 首选的基本数据               |
| XDG_CONFIG_DIRS | /etc/xdg                      | 首选的基本配置               |

备注：

- `XDG_RUNTIME_DIR`目录**必须仅为用户所有**，Unix权限为700，套接字 (socket)、命名管道 (named pipes) 等可存放于此。
- 定义多个变量，使用`:`分隔。



与以上目录相关的一些子目录信息：

- `$XDG_CONFIG_HOME/autostart`         登录桌面后自启动的程序的[desktop entry](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys)文件存放目录。
- `$XDG_DATA_DIRS/applications`   将程序的[desktop entry](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys)文件存放于此，可以出现在桌面的程序启动器中。
- `$XDG_DATA_DIRS/icons`                 存放程序的[desktop entry](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#recognized-keys)文件使用的icon图标，用户自定义的图标也可以存放于`$HOME/.icons`。



`~/.config/users-dir.dirs`文件可以用户的一些XDG目录的映射位置，如DESKTOP、TEMPLATES等，这样目录在不同桌面环境中可能有差异。

示例：

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



一些发行版中，用户登录系统后，会使用`xdg-user-dirs-update `将模板文件`/etc/xdg/users-dirs.defaults`覆盖用户的`~/.config/users-dir.dirs`文件，可修改`/etc/xdg/users-dir.conf`文件中的enabled值为False禁止该行为。

```shell
#This controls the behaviour of xdg-user-dirs-update which is run on user login
# You can also have per-user config in ~/.config/user-dirs.conf, or specify
# the XDG_CONFIG_HOME and/or XDG_CONFIG_DIRS to override this
enabled=True  #该值若为True将遵循以上注释中的行为
```

`xdg-user-dirs-update`也可以设置新的默认目录，如：

```shell
xdg-user-dirs-update --set DESKTOP ~/dir1
```



# redhat 设置默认桌面

除了在gdm（或其他dm）登陆界面选择不同桌面的session，还可以：

- `/usr/share/xsessions`文件，dm会读取该目录下的`.desktop`文件，可以选择一下方式

  - 将除了要设置为默认登陆的桌面session的`.desktop`文件外的其他文件移走

  - 修改的`.desktop`文件的前缀名，使要设置为默认的`.desktop`文件在`ls -l`中位于最前面

    例如，存在`gnome.desktop`和`xfce.desktop`，因为字母`g`排在`x`前，所以gdm的session列表中gnome排在xfce前面。

- 新建或编辑`/etc/sysconfig/desktop`

  redhat的gdm实际会读取`/etc/gdm/Xsession`（该文件指向`/etc/X11/xinit/Xsession`），Xsession文件中会读取`/etc/sysconfig/desktop`中的`DESKTOP`变量的值：

  > ```shell
  > GSESSION="$(type -p gnome-session)"
  > STARTKDE="$(type -p startkde)"
  > 
  > # check to see if the user has a preferred desktop
  > PREFERRED=
  > if [ -f /etc/sysconfig/desktop ]; then
  >     . /etc/sysconfig/desktop
  >     if [ "$DESKTOP" = "GNOME" ]; then
  >         PREFERRED="$GSESSION"
  >     elif [ "$DESKTOP" = "KDE" ]; then
  >         PREFERRED="$STARTKDE"
  >     fi
  > fi
  > ```

  该文件只为gnome和kde做了判定，可根据需要修改.

  
