在各个系统上设置文件类型关联的方式：



# 设置文件类型关联

## Windows

使用以下任意方式：

### 使用文件资源管理器

1. **右键单击文件**：
   找到你想要关联的文件类型，右键单击该文件，选择“打开方式”。

2. **选择默认程序**：
   在弹出的菜单中，选择“选择其他应用”。

3. **选择应用程序**：
   如果你看到要使用的应用程序，选择它。如果没有，点击“更多应用”以查找。若依然找不到，点击“在这台电脑上查找其他应用”。

4. **设置为默认**：
   确保勾选“始终使用此应用程序打开 .ext 文件”（其中 `.ext` 是文件扩展名），然后点击“确定”。



### 使用注册表

1. **打开注册表编辑器**：
   按下 `Win + R`，输入 `regedit`，然后按 Enter。

2. **导航到文件类型**：
   找到 `HKEY_CLASSES_ROOT` 下的文件扩展名（如 `.typeName`），并查看其默认值。

3. **设置程序**：
   查找与该扩展名关联的程序（通常在 `HKEY_CLASSES_ROOT\[file_extension]\OpenWithProgids` 中），然后设置相应的程序路径。



### 使用 PowerShell命令

执行：

```powershell
$ext = ".typeName"
$app = "C:\Path\To\YourApp.exe"
ftype MyApp="$app `%1"
assoc $ext=MyApp
```



## macOS

在 macOS 中，文件类型关联主要通过“获取信息”窗口进行设置。

### 使用“获取信息”

1. **选择文件**：
   找到你想要更改关联的文件，右键单击并选择“获取信息”或按下 `Command + I`。

2. **更改打开方式**：
   在“获取信息”窗口中，找到“打开方式”部分。点击下拉菜单，选择你想要关联的应用程序。如果没有在列表中，选择“其他”并找到你想要的应用程序。

3. **应用于所有**：
   如果你希望所有相同类型的文件都使用该应用程序打开，点击“更改全部…”按钮。确认更改后，所有相同类型的文件将使用所选的应用程序打开。



### 使用终端命令

可以使用 `duti` 工具来设置文件类型关联。首先需要安装 `duti`（可以通过 Homebrew 安装）。

```bash
brew install duti
```

然后使用以下命令设置文件类型关联：

```bash
duti -s com.example.YourApp .typeName all
```

这里的 `com.example.YourApp` 是你应用程序的 bundle identifier。



## Linux

首先要获取 MIME 类型，使用 `file` 命令。例如：

```bash
file --mime-type filename.ext
```



### 使用 `.desktop` 文件

确保你已经在 `.desktop` 文件中正确设置了 `MimeType` 字段。例如：

```ini
[Desktop Entry]
Name=App1
GenericName=App1
Comment=App1
TryExec=App1
Exec=App1
Terminal=false
Type=Application
Keywords=EDA
Icon=App1
Categories=Utility;TEDA;
StartupNotify=false
MimeType=binary/typeName;
```



修改 `.desktop` 文件后，运行以下命令以更新 MIME 数据库：

```bash
update-desktop-database ~/.local/share/applications/
```



可以使用以下命令验证 MIME 类型是否成功关联：

```bash
xdg-mime query default binary/typeName
```



### 使用 `xdg-mime` 命令

示例如下：

```bash
xdg-mime default your-desktop-file.desktop binary/typeName
```

将 `your-desktop-file.desktop` 替换为你的实际 `.desktop` 文件名。





# 自定义文件类型识别配置

自定义一个二进制文件，默认会被识别为：application/octet-stream类型，可使用以下方式让系统识别自定义的类型。

例如，需要设计一个类型名为binary/typ1，首先我们的二进制文件魔数（magic number）设置为`typ1`（写入二进制文件时，前几个byte的内容），要与程序MyApp关联，然后每个平台可进行如下设置。



## Linux

### 系统级别

1. 创建或编辑系统魔数规则文件，添加规则

   文件`/usr/share/misc/magic` 或 `/etc/magic`

   ```bash
   #添加规则
   #如果一个魔术占位4byte，而其实际只有3byte，使用了1byte补0，则在后面要补上对应数量的\0，如abc\0
   0       string    typ1            TYP1 my type
   >4      byte      x               \b, version %d.%d
   !:mime  binary/typ1
   ```

   

2. 系统级 MIME 类型配置

   编辑`/usr/share/mime/packages/binary-typ1.xml`

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
     <mime-type type="binary/typ1">
       <comment>ELA Waveform Data</comment>
       <glob pattern="*.typ1"/>
       <magic priority="50">
         <match type="string" offset="0" value="ELA\0"/>
       </magic>
     </mime-type>
   </mime-info>
   ```



3. 更新系统 MIME 数据库

   ```shell
   update-mime-database /usr/share/mime
   ```

   

4. 系统级应用程序关联
   文件`/usr/share/applications/myApp.desktop`

   ```ini
   [Desktop Entry]
   Type=Application
   Name=myApp
   Exec=myApp %f
   MimeType=binary/typ1;
   Terminal=false
   Categories=Development;
   ```

   

### 用户级别

方法同系统级别的，只是文件都是在用户目录级别，以下仅列出文件位置：

1. 创建魔数规则文件 `~/.local/share/magic/typ1.magic`

2. 编译用户魔数文件

   ```shell
   file -C -m ~/.local/share/magic/typ1.magic
   ```

3. 创建用户 MIME 类型配置 `~/.local/share/mime/packages/binary-typ1.xml`

4. 更新用户 MIME 数据库

   ```shell
   update-mime-database ~/.local/share/mime
   ```

5. 用户级应用程序关联，文件`~/.local/share/applications/myApp.desktop`



## macOS 配置

### 系统级别

1. 创建系统魔数规则文件`/usr/local/share/misc/magic.typ1`，并添参照Linux的方法添加内容。

2. 编译魔数文件

   ```shell
   sudo file -C -m /usr/local/share/misc/magic.typ1
   ```

3. 创建系统级 UTI 定义文件

   文件`/Library/UTIs/com.yourcompany.typ1.utis`，内容：

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>UTExportedTypeDeclarations</key>
       <array>
           <dict>
               <key>UTTypeIdentifier</key>
               <string>com.yourcompany.typ1</string>
               <key>UTTypeDescription</key>
               <string>ELA Waveform Data</string>
               <key>UTTypeConformsTo</key>
               <array>
                   <string>public.data</string>
               </array>
               <key>UTTypeTagSpecification</key>
               <dict>
                   <key>public.filename-extension</key>
                   <array>
                       <string>typ1</string>
                   </array>
                   <key>public.mime-type</key>
                   <array>
                       <string>binary/typ1</string>
                   </array>
               </dict>
           </dict>
       </array>
   </dict>
   </plist>
   ```

   

### 用户级别

同系统级别方法，只是文件位置在用户目录级别：

1. 用户魔数规则文件 `~/Library/Application\ Support/file/magic/typ1.magic`
2. 用户级 UTI 定义 `~/Library/Application\ Support/UTIs/com.yourcompany.typ1.utis`



## Windows 配置

### 系统级别

创建并执行注册表文件 `typ1_system.reg`：
```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\.typ1]
@="ELA.WaveformData"

[HKEY_CLASSES_ROOT\ELA.WaveformData]
@="ELA Waveform Data"

[HKEY_CLASSES_ROOT\ELA.WaveformData\DefaultIcon]
@="C:\\Program Files\\myApp\\typ1.ico"

[HKEY_CLASSES_ROOT\ELA.WaveformData\shell\open\command]
@="\"C:\\Program Files\\myApp\\typ1viewer.exe\" \"%1\""

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MIME\Database\Content Type\binary/typ1]
"Extension"=".typ1"
```



### 用户级别

创建并注册表文件 `typ1_user.reg`：
```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Classes\.typ1]
@="ELA.WaveformData"

[HKEY_CURRENT_USER\Software\Classes\ELA.WaveformData]
@="ELA Waveform Data"

[HKEY_CURRENT_USER\Software\Classes\ELA.WaveformData\DefaultIcon]
@="%USERPROFILE%\\AppData\\Local\\myApp\\typ1.ico"

[HKEY_CURRENT_USER\Software\Classes\ELA.WaveformData\shell\open\command]
@="\"%USERPROFILE%\\AppData\\Local\\myApp\\typ1viewer.exe\" \"%1\""
```



## 验证配置

- Linux/macOS

  ```shell
  # 系统级验证
  file test.typ1
  xdg-mime query filetype test.typ1  # Linux
  mdls -name kMDItemContentType test.typ1  # macOS
  
  # 用户级验证
  file --magic-file ~/.local/share/magic/typ1.mgc test.typ1
  ```

  

- Windows

  ```shell
  # 检查系统级关联
  Get-ItemProperty -Path "HKLM:\SOFTWARE\Classes\.typ1"
  
  # 检查用户级关联
  Get-ItemProperty -Path "HKCU:\Software\Classes\.typ1"
  ```



