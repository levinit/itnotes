# 安装环境

1. 安装flatpak和flatpak-builder

2. 安装SDK和基本运行库

   `//` 后的数字为要安装的sdk版本，也可以不使用`//`及后面的数字指定版本，而是根据交互提示选择安装。

   ```shell
   sudo flatpak install flathub org.gnome.Sdk//47
   sudo flatpak install flathub org.gnome.Platform//47
   
   sudo flatpak install flathub org.freedesktop.Sdk
   sudo flatpak install flathub org.freedesktop.Platform
   ```



# 构建flatpak程序

## 创建应用程序清单manifest

参看https://docs.flatpak.org/en/latest/dependencies.html

假如工作目录为`test-myapp`，app名字为`com.example.myapp`（参看官方文件的建议命名方式）：

```shell
mkdir test-myapp
cd test-myapp
touch com.example.myapp.yml #清单文件
```

编辑清单文件，内容示例：

```yaml
app-id: com.example.MyApp
runtime: org.freedesktop.Platform
runtime-version: '24.08'  #flatpak list --runtime查看运行时
sdk: org.freedesktop.Sdk
command: myapp

sdk-extensions:
  - org.freedesktop.Sdk.Extension.golang
  
build-options:
  env:
    - GOBIN=/app/bin
    - GOROOT=/usr/lib/sdk/golang
    - PATH=/usr/lib/sdk/golang/bin:/usr/bin:/bin
    - GOPATH=/run/build/myapp/go

finish-args:
  # 网络访问
  - --share=network
  - --share=ipc
  # 图形界面
  - --socket=x11
  - --socket=wayland
  # 音频
  - --socket=pulseaudio
  # 文件系统访问
  - --filesystem=home
  - --filesystem=xdg-documents
  # D-Bus 访问
  - --system-talk-name=org.freedesktop.NetworkManager

modules:
  - name: myapp
    buildsystem: simple
    build-commands:
      #按实际构建程序的方式一行行编写命令
      #- cd $FLATPAK_BUILD_DIR/myapp
      #- go build
       # ... 其他命令
      # 添加桌面文件
      - install -Dm644 com.example.myapp.desktop /app/share/applications/com.example.myapp.desktop
      # 添加图标
      - install -Dm644 icon.png /app/share/icons/hicolor/256x256/apps/com.example.MyWailsApp.png
    sources:
      - type: dir
        path: /path/to/your/source/directory
        dest: myapp
      - type: file
        path: com.example.myapp.desktop
      - type: file
        path: icon.png
    #  - type: git   #如果使用git
    #    url: https://github.com/example/myapp.git
    #    tag: v1.0.0
```



## 构建程序

```shell
# 首次构建
flatpak-builder build-dir /path/to/test-myapp --force-clean

# 测试运行
flatpak-builder --user --install --force-clean build-dir com.example.MyApp.yml
flatpak run com.example.MyApp

# 安装并测试
flatpak-builder --user --install --force-clean build-dir com.example.MyApp.yml
flatpak run com.example.MyApp

# 验证包内容
flatpak info com.example.MyApp
```



