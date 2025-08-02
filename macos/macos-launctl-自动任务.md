# launctld

> macOS 使用 `launchd` 进程来管理守护进程和代理

launchd是pid为1的超级进程（类似于linux中的init或systemd），其他所有的进程都是它产生的：

> ```shell
> $ ps -p 1 -o pid,ppid,user,command
> PID PPID USER COMMAND
> 1   0 root /sbin/launchd
> ```



# launctl 操作

使用 [launchctl](x-man-page://launchctl) 命令来载入或卸载 `launchd` 守护进程和代理。

```shell
# 查看所有的 plist 服务
launchctl list

# 禁用服务
launchctl disable <plist file path>

# 启用服务
launchctl disable <plist file path>

# 杀死进程（不优雅地杀，直接杀进程）并重启服务。对一些停止响应的服务有效。
launchctl kickstart -k <plist file path>

# 在不修改 Disabled 配置的前提下启动服务
launchctl start <plist file path>

# 在不修改 Disabled 配置的前提下停止服务
launchctl stop <plist file path>

# 加载配置
launchctl load -w <plist file path>

# 卸载配置
launchctl unload <plist file path>

# 修改配置后重载配置
launchctl unload <plist file path> && launchctl load -w <plist file path>
```



# plist文件

launchd的服务配置文件是后缀名为 `.plist` 的XML文件，这些文件存放于：

| 文件夹                        | 用途                                         |
| :---------------------------- | :------------------------------------------- |
| /System/Library/LaunchDaemons | Apple 提供的System守护进程                   |
| /System/Library/LaunchAgents  | Apple 提供的基于每个用户且所有用户适用的代理 |
| /Library/LaunchDaemons        | 第三方System守护进程                         |
| /Library/LaunchAgents         | 基于每个用户且所有用户适用的第三方代理       |
| ~/Library/LaunchAgents        | 仅适用于登录用户的第三方代理                 |

plist文件编写可以参考 [man launchd.plist](x-man-page://launchd.plist) 。

提示：使用xcode编辑plist文件比较方便。



# plist文件特别使用

### 系统配置相关文件

当一些系统事件触发时，`/Library/Preferences/SystemConfiguration/`下的对应的文件会发生变化，通过监听这些文件的变化，可以实现触发某些自定义操作。

>```shell
>$ ls /Library/Preferences/SystemConfiguration
>NetworkInterfaces-pre-upgrade-new-target.plist
>NetworkInterfaces-pre-upgrade-source.plist
>NetworkInterfaces.plist
>com.apple.AutoWake.plist
>com.apple.Boot.plist
>com.apple.accounts.exists.plist
>com.apple.airport.preferences.plist
>com.apple.airport.preferences.plist.backup
>com.apple.smb.server.plist
>com.apple.vmnet.plist
>com.apple.wifi.message-tracer.plist
>preferences-pre-upgrade-new-target.plist
>preferences-pre-upgrade-source.plist
>preferences.plist
>```



### 检测网络切换

`com.apple.airport.preferences.plist`（/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist）记录了macos的网络连接信息，使用以下命令可以获取当前活动的无线网络连接信息：

```shell
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I
```

当切换Wi-Fi网络时com.apple.airport.preferences.plist文件会发生改变，（可用md5检验）：

```shell
md5 /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
```

注意：网络关闭后，文件并不会变化。

利用 WatchPaths 属性即可监听该文件变化，定义，plist中监听示例：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>onnetworkchange</string>
	<key>ProgramArguments</key>
	<array>
		<string>/path/to/run/app/file</string>
	</array>
    <key>StandardOutPath</key>
    <string>%s</string>  
    <key>StandardErrorPath</key>  
    <string>%s</string>  
	<key>WatchPaths</key>
	<array>
		<string>/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist</string>
	</array>
</dict>
```



## 定时任务

定时运行任务示例

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Label唯一的标识 -->
  <key>Label</key>
  <string>autotask.plist</string>
  <!-- 指定要运行的脚本 -->
  <key>ProgramArguments</key>
  <array>
    <string>/Users/yourname/run.sh</string>
  </array>
  <!-- 指定要运行的时间 -->
  <key>StartCalendarInterval</key>
  <dict>
        <key>Minute</key>
        <integer>00</integer>
        <key>Hour</key>
        <integer>22</integer>
  </dict>
<!-- 标准输出文件 -->
<key>StandardOutPath</key>
<string>/Users/demo/run.log</string>
<!-- 标准错误输出文件，错误日志 -->
<key>StandardErrorPath</key>
<string>/Users/demo/run.err</string>
</dict>
</plist>
```

- StartCalendarInterval 可根据日期和时间设置周期任务，后面的dict中可指定五个key值，包括：分Minute 时Hour 日Day 月Month 周Weekday，写法参看上面的例子。

  在StartCalendarInterval后的`<dict>`未指定的key，则表示每一个时间单位均会运行（作用同crontab的`*`）。例如：只写了Minute这个key，值为0，则等价于crontab中的`0 * * * * `，表示每小时的0分均执行。

- StartInterval  设置固定的运行间隔，后面无需dict，只需要指定一个单位为秒的数字。示例指定间隔时间为300秒：

  ```xml
    <!-- 运行间隔，单位为秒 -->
      <key>StartInterval</key>
      <integer>300</integer>
  ```

  