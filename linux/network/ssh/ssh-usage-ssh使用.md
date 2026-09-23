[TOC]

下文中：
- **客户端**：用户执行 `ssh`、`scp` 等命令或工具的主机。
- **SSH 服务端 / 目标主机 / 远程主机**：运行 `sshd` 监听服务的主机。

---



# 配置文件与加载规则

- **服务端**：`/etc/ssh/sshd_config`（启动服务时可通过 `sshd -f <config-file>` 指定配置文件）。
- **客户端**：
  - 系统级全局配置：`/etc/ssh/ssh_config`
  - 用户级个人配置：`$HOME/.ssh/config`（权限必须设置为 `600`）
  - 命令行指定配置：`ssh -F <config-file>`（使用大写 `-F` 参数指定用户配置文件）



# SSH 登录基础与核心参数

```shell
ssh [-p port] [user@]host
ssh -p 2333 root@host
ssh -l user host
ssh host
```

- `port`：远程主机端口，省略时默认为 `22`。  
- `user`：登录用户名，省略时默认采用当前本地系统的用户名；亦可用 `-l user` 指定。  
- `host`：目标主机 IP 地址或主机名/域名。  


### 常用参数速查

- `-p`：指定远程主机端口。  
- `-i`：指定私钥认证文件路径。
- `-4` / `-6`：强制使用 IPv4 或 IPv6 地址。  
- `-l`：指定登录用户名。  
- `-f`：连接转入后台运行（常与 `-N` 配合用于隧道搭建）。  
- `-N`：不执行远程命令（仅建立转发隧道，不打开交互式 Shell）。  
- `-n`：将标准输入重定向到 `/dev/null`，防止读取 stdin。  
- `-C`：启用数据压缩传输。  
- `-D`：动态端口转发（本地 SOCKS 代理）。  
- `-L`：本地端口转发。  
- `-R`：远程端口转发（反向隧道）。  
- `-g`：允许远程主机连接到建立的本地转发端口。  
- `-J`：指定跳板机（ProxyJump，OpenSSH 7.3+ 推荐方式）。
- `-t`：强制分配伪终端（用于执行远程全屏交互式程序）。  
- `-T`：禁用伪终端分配。  
- `-A` / `-a`：开启 / 显式禁用身份认证代理转发（Agent Forwarding）。  
- `-q`：安静模式，屏蔽大部分警告与提示。  
- `-v` / `-vvv`：输出详细调试信息（排查握手与认证错误的核心工具）。  
- `-G`：输出针对指定主机的最终有效配置并退出（静态求值，不发起真实网络连接）。  



# 密钥认证与本地管理

基于非对称加密算法实现免密登录。私钥留在本地，公钥上传部署至服务端。  


## 生成密钥对（`ssh-keygen`）

```shell
# 推荐：现代高效高安全算法 Ed25519
ssh-keygen -t ed25519 -C "admin@homelab"

# 传统算法：RSA 必须保证足够长度（建议 4096 位）
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

- `-t`：指定加密类型，推荐 `ed25519`，次选 `rsa`。注：`dsa` 已被彻底淘汰且不安全，`ecdsa` 在部分实现中存在隐患，均不推荐。  
- `-b`：指定密钥位数（仅针对 RSA 等支持变长密钥的算法）。  
- `-f`：指定私钥存储路径与文件名。  
- `-N`：设置密钥密码短语（Passphrase），留空 `""` 表示不设密码。  
- `-C`：添加注释文本（通常为邮箱或 `user@host`）。  


## 上传公钥（`ssh-copy-id`）

一键将公钥添加至目标主机的 `~/.ssh/authorized_keys` 中，并自动配置正确的目录与文件权限：  

```shell
# 上传默认公钥（~/.ssh/id_*.pub）
ssh-copy-id -p 2222 user@host

# 指定特定公钥文件路径（注意使用 .pub 公钥文件）
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 user@host
```


## 本地密钥代理（`ssh-agent`）

`ssh-agent` 是在本地操作系统后台运行的密钥管理器，将解密后的私钥缓存在内存中，避免重复输入密码短语。  

```shell
# 启动本地 agent 守护进程并注入当前环境
eval $(ssh-agent -s)

# 添加默认私钥至内存
ssh-add

# 添加指定私钥
ssh-add ~/.ssh/custom_id_ed25519

# 列出当前已加载的私钥指纹
ssh-add -l

# 列出当前已加载的公钥字符串
ssh-add -L

# 从内存中移除指定私钥
ssh-add -d ~/.ssh/custom_id_ed25519

# 清空内存中所有的私钥身份
ssh-add -D

# 关闭当前 agent 守护进程
ssh-agent -k
```

> **提示（免脚本自动化加载）**：无需在 Shell 启动脚本中编写复杂的 `eval $(ssh-agent)`，现代客户端只需在 `~/.ssh/config` 全局块中配置 `AddKeysToAgent yes`，系统即可在首次用到私钥时自动解密并加入 Agent。



# 客户端配置（`~/.ssh/config`）

通过别名配置简化登录参数，文件权限必须设置为 `chmod 600 ~/.ssh/config`。

> **规则匹配原则（First Match Wins）**：对于同一个配置参数，先匹配到的规则优先生效。因此**特例主机配置应写在最前，通用全局配置（`Host \*`）兜底写在文末**。

```shell
# 1. 目标主机别名配置
Host srv1
    HostName 192.168.10.50
    Port 2222
    User deploy
    IdentityFile ~/.ssh/id_ed25519      # 注意：必须指定本地私钥路径，绝非 .pub 公钥
    IdentitiesOnly yes                 # 严格仅使用指定私钥，防止遍历尝试导致被防爆破服务封禁

# 2. 全局通用兜底配置
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    ForwardAgent no                    # 全局默认严禁代理转发，防止凭据泄露
```

配置后，直接执行 `ssh srv1` 即可连接。


## 验证与调试有效配置（`ssh -G`）

当配置了复杂的别名、多层 `Include`、通配符（`Host *` 或 `Match`）以及 `ProxyJump` 跳板时，很容易出现参数覆盖不符合预期的情况。

`ssh -G` 会在本地解析所有配置文件和命令行参数，**输出针对目标主机计算出的全量有效键值对，且完全不发起任何网络连接**：

```shell
# 1. 静态查看目标主机最终生效的所有配置项
ssh -G srv1

# 2. 结合 grep 快速确认关键参数（如最终解析的 IP、端口、用户、跳板机、密钥）
ssh -G srv1 | grep -E "^(hostname|user|port|proxyjump|identityfile)"

# 3. 调试指定的独立配置文件（配合 -F）
ssh -F ~/.ssh/config.test -G dev
```

> **与 `-v` / `-vvv` 的区别（动静结合）**：
> - **`ssh -G`（静诊）**：完全在本地离线运行，专门排查“配置写得对不对、谁覆盖了谁”。
> - **`ssh -vvv`（动诊）**：向网络发起真实连接，专门排查“握手卡在哪一步、密钥为什么被拒”。



# 跳板机穿透与网络中转

当目标机位于受限内网，无法直接与本地客户端建立 TCP 连接时，需要通过跳板机中转访问：

$$\text{客户端 (本地)} \longrightarrow \text{跳板机 (Bastion)} \longrightarrow \text{目标主机 (Target)}$$


## 现代标准方案：`ProxyJump`（推荐）

- **原理**：本地客户端让跳板机建立纯透明的 TCP 转发隧道，**本地客户端直接与目标主机进行端到端加密和鉴权**。  
- **安全性**：密钥自始至终在本地鉴权，跳板机无法窃听通信内容，也无需获取任何密钥。**无需也绝不应该开启代理转发（`-A`）**。  


### 命令行单次跳转（`-J`）

```shell
# 单跳穿透（跳板机端口直接用冒号拼接，最后为目标机参数）
ssh -J user_jump@10.10.1.2:22 user_target@10.10.10.1 -p 2222

# 多级跳板（逗号隔开：本地 -> jump1 -> jump2 -> target）
ssh -J user1@jump1:22,user2@jump2:2333 user_target@10.10.10.1 -p 2222
```


### 配置文件持久化

```shell
# 跳板机配置
Host jump
    HostName 10.10.1.2
    User user_at_proxy
    Port 22

# 目标主机配置
Host target
    HostName 10.10.10.1
    Port 2222
    User user_at_target
    ProxyJump jump                     # 直接指定跳板机别名
    ForwardAgent yes                   # 如果需要在target上使用客户端的ssh身份凭证
```

配置完成后，所有基于 SSH 的工具均可原生透明穿透：

```shell
ssh target                             # 一键登录目标机
scp local.txt target:/data/            # 透明传输文件至目标机
rsync -avz local/ target:/data/        # 透明同步文件
```


## 通用底层方案：`ProxyCommand`

当网络中间节点不是标准 SSH 主机（如企业 HTTP 代理、SOCKS5 代理网关），或处于极老版本的 OpenSSH 环境（< 7.3）时使用：

```shell
# 兼容旧版本 SSH 跳板机（-W 表示在 jump 上建立通往目标机 %h:%p 的 TCP 管道）
Host target-old
    HostName 10.10.10.1
    Port 2222
    User user_at_target
    ProxyCommand ssh -q -W %h:%p jump

# 穿透企业 SOCKS5 代理网关（配合 nc / netcat）
Host target-socks
    HostName 10.10.10.1
    User user_at_target
    ProxyCommand nc -X 5 -x 127.0.0.1:1080 %h %p
```



# 身份认证代理转发（Agent Forwarding）与安全规范

代理转发（`-A`）允许你在登录远程服务器后，**借用本地运行的 `ssh-agent`** 去向第三方服务器（如内部私有 Git 仓库）完成身份验证。  


## 核心安全风险

在远程机器开启代理转发后，远程主机会生成一个套接字文件（由环境变量 `$SSH_AUTH_SOCK` 标识）。**远程主机上的任何 root 用户均可直接劫持该套接字**，在你的连接保持期间，以你的身份向所有信任你本地密钥的主机发起连接认证。  


## 配置与参数规范

| **层面**          | **配置文件**           | **参数名称**           | **默认值** | **作用说明**                             |
| ----------------- | ---------------------- | ---------------------- | ---------- | ---------------------------------------- |
| **服务端 (sshd)** | `/etc/ssh/sshd_config` | `AllowAgentForwarding` | `yes`      | 控制是否允许客户端在此机器建立转发套接字 |
| **客户端全局**    | `/etc/ssh/ssh_config`  | `ForwardAgent`         | `no`       | 控制是否默认对所有外出连接启用代理转发   |
| **客户端个人**    | `~/.ssh/config`        | `ForwardAgent`         | `no`       | 针对特定别名主机控制是否借出本地 Agent   |

- **服务端配置**：如果维护公共运维跳板机，可在跳板机 `/etc/ssh/sshd_config` 中设置 `AllowAgentForwarding no`，强制杜绝此类安全隐患。

- **客户端规范**：

  - **绝不要**在 `~/.ssh/config` 的 `Host *` 全局块中配置 `ForwardAgent yes`。

  - **使用 ProxyJump 时完全不需要开启 Agent 转发**（纯 TCP 转发无需凭据委托）。

  - 仅在**高度受信的远程工作站**，且确实需要在远端执行 `git push` 等操作时，针对特定 Host 显式开启：

    ```shell
    Host trusted-dev
        HostName 10.1.1.200
        User levin
        ForwardAgent yes
    ```



# 端口转发与 SSH 隧道

通过 SSH 将一个网络端口的 TCP 流量加密封装后转发至另一端口。  

- 绑定 `1024` 以下的特权端口需本地/远程具有 `root` 权限。  
- 服务端控制开关位于 `/etc/ssh/sshd_config`：`AllowTcpForwarding yes/no`。  


### 常用组合参数

- `-N`：不执行远程命令（纯隧道模式）。  
- `-f`：后台异步运行。  
- `-C`：压缩隧道数据流。  


## 动态端口转发（本地 SOCKS5 代理）

在本地开启一个 SOCKS 侦听端口，客户端应用配置此代理后，所有外发网络流量经由远程 SSH 主机代为请求。  

```shell
# 建立本地 1080 端口的 SOCKS5 代理
ssh -fN -D 127.0.0.1:1080 user@proxy-host
```

若需允许局域网内其他主机使用该代理，绑定地址设为 `0.0.0.0`（或加 `-g` 参数）：  

```shell
ssh -fN -D 0.0.0.0:1080 user@proxy-host
```


## 本地端口转发（Local Forwarding，`-L`）

将**本地端口**收到的流量，经由 SSH 隧道转发至**目标远程网络内的某台主机的端口**。  

```shell
# 基础语法
ssh -fN -L [本地绑定地址:]<本地端口>:<目标主机>:<目标端口> user@ssh-server
应用请求 ---> 本地端口 (Local:8080) ===[加密 SSH 隧道]===> SSH 服务器 ---> 内部目标主机:端口 (10.0.0.2:80)
```

**典型应用：访问内网隔离的数据库或 Web 服务**

```shell
# 通过跳板机 jump-server，将内网 10.0.0.2 的 MySQL (3306) 映射到本地 13306 端口
ssh -fN -L 127.0.0.1:13306:10.0.0.2:3306 user@jump-server

# 本地直接连接本地端口即可访问内网数据库
mysql -h 127.0.0.1 -P 13306 -u dbuser -p
```


## 远程端口转发（Remote Forwarding / 反向隧道，`-R`）

在**远程 SSH 服务器**上开启一个监听端口，并将该端口收到的流量经由反向隧道带回**本地网络中的指定端口**。  

```shell
# 基础语法
ssh -fN -R [远程绑定地址:]<远程端口>:<本地目标主机>:<本地目标端口> user@remote-server
外部请求 ---> 远程服务器端口 (Remote:2222) ===[反向加密隧道]===> 本地 SSH 客户端 ---> 本机端口 (Local:22)
```

**典型应用：内网穿透**

```shell
# 将公网 VPS (vps.example.com) 的 2222 端口流量打回本地机器的 22 端口
ssh -fN -R 0.0.0.0:2222:localhost:22 user@vps.example.com
```

> **注意**：如果希望远程服务器的 `2222` 端口允许公网其他 IP 访问，必须在远程 VPS 的 `/etc/ssh/sshd_config` 中配置并启用：
>
> `GatewayPorts yes`（或 `GatewayPorts clientspecified`）。  



# X11 图形界面转发

用于在本地直接显示和交互运行在远程 Linux 上的图形化程序。  

- **服务端环境准备**：安装 `xorg-xauth`，并在 `/etc/ssh/sshd_config` 中设置：

  ```shell
  X11Forwarding yes
  ```

- **客户端要求**：本地拥有 X Server（Linux 自带；macOS 需安装 XQuartz；Windows 需安装 VcXsrv / Xming）。  

```shell
# -X：受限转发（不支持部分未授权调用，更安全）
ssh -X user@host gedit

# -Y：完全可信转发（兼容性更好，支持复杂图形与剪贴板完全交互）
ssh -Y user@host xterm
```



# 会话保持与连接复用


## 客户端连接复用（ControlMaster）

在高频发起 SSH / SCP / Rsync 调用的场景下，连接复用可以避免重复进行 TCP 握手和密钥交换，实现毫秒级快速接入。  

编辑 `~/.ssh/config`：  

```shell
Host *
    ControlMaster auto
    ControlPath /tmp/%u%r@%h:%p
    ControlPersist 600
```

- `ControlMaster auto`：自动寻找现有主会话，存在则直接复用通道，不存在则自动新建主会话。  
- `ControlPath`：指定 Unix 域套接字的存放路径（建议放置于权限严格的 `~/.ssh/sockets/` 或 `/run/user/<UID>/` 目录下）。  
- `ControlPersist 600`：主会话终端关闭后，隧道在后台驻留维持 600 秒；若设置为 `yes` 则无限期驻留后台。  

> **提示**：首次使用前请确保套接字目录存在并修正权限：`mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets`。


## 心跳存活检测（防止自动断开）

防止 NAT 超时或防火墙状态机静默切断连接。  

- **客户端配置（`~/.ssh/config`，推荐）**：

  ```shell
  Host *
      ServerAliveInterval 30
      ServerAliveCountMax 3
  ```

  每 30 秒向服务端发送一次探测包，连续 3 次无响应则主动切断重连。  

- **服务端配置（`/etc/ssh/sshd_config`）**：

  ```shell
  ClientAliveInterval 30
  ClientAliveCountMax 3
  ```

  服务端每 30 秒向客户端发送一次保活探测。  


## 使用 `autossh` 守护持久隧道

对于需要 24 小时保持的反向隧道（如内网穿透），推荐使用 `autossh` 进行进程守护与断线重拨。  

Systemd 服务单元文件示例（`/etc/systemd/system/autossh-tunnel.service`）：  

```shell
[Unit]
Description=AutoSSH Reverse Tunnel Service
After=network-online.target ssh.service
Wants=network-online.target

[Service]
Type=simple
User=tunneluser
# -M 0 表示禁用旧式 echo 端口，完全依赖 ServerAlive 心跳探测判断健康
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "ExitOnForwardFailure yes" -R 0.0.0.0:2222:localhost:22 user@vps.example.com -i /home/tunneluser/.ssh/id_ed25519
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
```



# 远程非交互式命令执行

无需进入交互式 Shell，直接在本地触发远端执行并返回标准输出：

```shell
# 1. 基础单命令执行
ssh user@host "uptime"

# 2. 传递多条指令
ssh user@host "cd /var/log && tar -czf nginx-log.tar.gz nginx/*.log"

# 3. 本地输入重定向到远端（将本地配置写入远端文件）
ssh user@host "cat > ~/.bashrc_custom" < ~/.bashrc_local

# 4. 执行需要 TTY/伪终端的程序（如 sudo、top、vim）必须加 -t
ssh -t user@host "sudo systemctl restart nginx"

# 5. 执行完成后保留在远程 Shell
ssh -t user@host "cd /data/project; bash --login"
```



自动化常用参数：`BatchMode` 与 `ConnectTimeout`：

```shell
ssh -o BatchMode=yes -o ConnectTimeout=5 user@host "echo OK"
```

- **`BatchMode=yes`**：禁用所有交互式输入提示（密码、私钥口令、主机指纹确认等）。若凭证不可用，立即报错退出，而不是挂起等待。认证须依赖完全免密凭证（无口令私钥 / `ssh-agent` 已加载的私钥 / GSSAPI Kerberos 票据等）。
- **`ConnectTimeout=5`**：限制 TCP 连接的最长等待秒数，避免目标主机不可达时脚本长时间阻塞。

另外，可信内网下可配合 `-o StrictHostKeyChecking=accept-new` 解决（注意中间人攻击风险）首次连接或指纹变更造成的交互阻塞。



**常见场景**：

- 批量健康检查：探测一批主机 SSH 服务是否存活，跳过超时或鉴权失败的节点并捕获非零退出码；
- Ansible / pdsh / Shell 循环脚本：避免因某台主机需要密码输入而导致整批任务挂起。

也可在 `~/.ssh/config` 中针对特定 Host 持久化配置：

```ssh-config
Host deploy-*
    BatchMode yes
    ConnectTimeout 5
    StrictHostKeyChecking accept-new
```



# 文件传输实用工具


## `scp`（基础安全复制）

基于 SSH 协议的文件复制，用法与本地 `cp` 类似：  

```shell
# 本地拷贝到远程
scp -P 2222 local_file.txt user@host:/remote/dir/

# 递归拷贝目录（-r）并保留文件元数据（-p）
scp -r -p local_dir/ user@host:/remote/dir/

# 远程拷贝到本地
scp user@host:/remote/dir/file.txt ./
```

> **注意**：`scp` 处理符号链接时默认会跟随并复制源文件本身；复杂生产环境中更推荐使用 `rsync -avz -e "ssh -p 2222"`。


## `sshfs`（基于 FUSE 的挂载工具）

将远程服务器的目录直接挂载为本地文件系统：  

```shell
# 挂载远程目录到本地 /mnt/remote_share
sshfs user@host:/data/share /mnt/remote_share -p 2222 -C -o allow_other,reconnect

# 卸载挂载点
fusermount -u /mnt/remote_share
```



# 服务端安全加固策略

建议对生产环境服务器的 `/etc/ssh/sshd_config` 进行针对性安全强化（修改后需执行 `systemctl restart sshd` 生效）：  


## 核心加固配置项

```shell
# 1. 更改默认端口，避免扫描器批量探测
Port 2222

# 2. 严禁 Root 用户直接通过密码登录（强制密钥登录或完全禁用）
PermitRootLogin prohibit-password

# 3. 彻底禁用密码认证，推行纯公钥鉴权
PasswordAuthentication no
PubkeyAuthentication yes

# 4. 禁用空密码与空凭证
PermitEmptyPasswords no

# 5. 禁用过时的弱加密算法（指定现代安全算法套件）
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# 6. 关闭 DNS 反向解析与无用的认证协议
UseDNS no
GSSAPIAuthentication no

# 7. 限制最大认证尝试次数
MaxAuthTries 3
```


## 用户与组访问控制列表（ACL）

```shell
# 白名单（仅允许特定用户/组登录，推荐）
AllowUsers deployer admin devuser@192.168.10.*
AllowGroups ssh-users

# 黑名单（禁止匹配的用户/组）
# DenyUsers baduser
```


## Match 块精细化按需授权

```shell
# 对内网 IP 段放宽登录策略，外网连接强制最高安全等级
Match Address 192.168.10.0/24
    PasswordAuthentication yes

# 限制 sftp 专用账户的运行环境（Chroot 监狱隔离）
Match Group sftp-only
    ChrootDirectory /data/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

> **安全注意（ChrootDirectory 权限铁律）**：OpenSSH 要求 `ChrootDirectory` 指定的路径以及该路径向上的所有父目录，**所有者必须是 root，且其他任何用户和组严禁具备写权限（权限最高为 755）**。否则登录时将直接报错 `fatal: bad ownership or modes for chroot directory` 拒绝连接。若用户需上传文件，应在 chroot 目录内另建属主为该用户的子目录（如 `/data/sftp/%u/upload`）。



# 故障排查与常见报错速查

排查 SSH 连接问题时，推荐遵循**“先静态预检配置，后动态追踪日志”**的思路：

```shell
# 1. 静态预检：核查客户端对目标主机的最终求值配置（确认是否匹配了预期的端口、用户、密钥或跳板）
ssh -G host | grep -E "^(hostname|user|port|proxyjump|identityfile)"

# 2. 动态追踪：打印客户端与服务端完整的握手与认证交互过程
ssh -vvv user@host

# 3. 服务端排查：查看 sshd 守护进程的实时系统日志（systemd）
journalctl -u sshd -f -e
```


## 常见报错及应对方案


### Permissions 0644 for '~/.ssh/id_ed25519' are too open.

- **原因**：本地私钥文件权限过于宽松。  

- **解决**：修正客户端目录与密钥权限：

  ```shell
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*
  chmod 644 ~/.ssh/*.pub
  chmod 600 ~/.ssh/config
  ```


### 已经上传公钥，但仍然提示输入密码

- **原因 1：服务端文件与目录权限错误**。SSH 默认启用了 `StrictModes yes`，若远程用户的家目录或 `.ssh` 存在组写权限将直接拒绝认证。  

  - 修复远程机器权限：  

    ```shell
    chmod 755 ~                          # 严禁家目录对组或其他用户开放 w 权限
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    ```

- **原因 2：SELinux 上下文丢失**。

  - 修复 SELinux 文件标签：

    ```shell
    restorecon -R -v ~/.ssh
    ```


### WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!

- **原因**：远程主机重装了系统、更换了主机密钥，或网络遭遇中间人攻击（MITM）。  

- **解决**：在核实远程机器安全的前提下，从本地清除旧指纹记录：  

  ```shell
  ssh-keygen -R <host-or-ip>
  ```


### 连接时卡顿，数秒甚至几十秒后才显示登录提示

- **原因 1：服务端启用了 DNS 反向解析**。  
  - 修复：服务端 `/etc/ssh/sshd_config` 中配置 `UseDNS no` 并重启 `sshd`。  
- **原因 2：服务端 GSSAPI 认证超时**。  
  - 修复：服务端 `/etc/ssh/sshd_config` 中配置 `GSSAPIAuthentication no` 并重启 `sshd`。  


### Connection reset by peer 或握手卡在 session 阶段

- **原因**：服务端的 `systemd-logind` 或 PAM 模块异常，导致会话分配失败。
- **排查**：在服务端检查 `systemctl status systemd-logind` 与 `/var/log/secure`（或 `journalctl -u sshd`），必要时重启 `systemd-logind`。


### 非交互式远程执行命令报错 command not found

- **原因**：SSH 执行远程单命令时启动的是非登录 Shell（Non-login Shell），不会加载 `/etc/profile` 或 `~/.bash_profile`，导致 `$PATH` 变量不完整。
- **解决**：
  1. 使用命令的绝对路径（如 `/usr/local/bin/mycmd`）。
  2. 或显式包装为登录 Shell：`ssh user@host "bash -lc 'mycmd'"`。
