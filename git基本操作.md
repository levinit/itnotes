Git 是 Linus Torvalds 在 2002 年用 C 语言编写的一个**分布式版本控制系统**。

---

[TOC]

如未说明，尖括号 <> 内的内容表示其并非 git 命令参数，而是用户定义的内容（如具体
仓库名、分支名、文件名等等）。

参考：[git-scm](https://git-scm.com/book/zh/v2)
[git 简明指南](https://rogerdudler.github.io/git-guide/index.zh.html)
[图解 git](https://marklodato.github.io/visual-git-guide/index-zh-cn.html)
[git 参考手册](http://gitref.org/zh/creating/)
[archlinux-wiki:git](https://wiki.archlinux.org/index.php/Git_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87))
[猴子都能看懂的 git 入门](http://backlogtool.com/git-guide/cn/)

---

# 安装和初始设定

* 安装 git

  Linux：根据发行版不同，使用安装命令安装`git`包。

  Mac OS X ：安装 Xcode，自带 git，或 `brew install git`。

  Windows ：[Git for Windows](https://git-for-windows.github.io/)

  * 图形化 git 例如：

    * gitk 命令行自带图形界面，在 git 仓库中执行`gitk`或在任何地方执行`git gui`启动。
    * [gitkraken](https://www.gitkraken.com/)
    * [source tree](https://www.sourcetreeapp.com/)
    * [github desktop](https://desktop.github.com/)
    * [git-cola](https://git-cola.github.io/)

- 初始设定

  设置用户名和邮箱，图形界面到其相关设置选项里设置，命令行：

  ```shell
  git config --global user.name "Your Name"
  git config --global user.email "email@example.com"
  ```

  更多设置见后文 --git[配置](#配置)

  从本地仓库向远程仓库推送的基本操作流程：

  在本地仓库内进行操作 - > 在[本地仓库创建快照版本](#提交快照)-> 将本地仓库快
  照[推送到远程仓库](#推送和下载分支)

# 仓库创建和远程关联

## 创建本地仓库

* 创建（/ 初始化）仓库 :`git init`

* 仓库空间划分概念：

  * **工作区**（working directory ）：存放当前工作文件

  * **暂存区**(stage)：存放通过`git add`添加的文件。

  * **版本库**（repository ）：项目的各个版本（快照）。

## 关联远程仓库

将本仓库与其他仓库关联（例如远程服务器上的仓库），以推送本地仓库数据到关联的仓库中。

- 添加关联

  可以克隆远程仓库或者直接添加远程仓库信息以进行关联：
  - 克隆仓库：`git clone <url/repo-name>` 

    几种不同的协议示例：

    ```shell
    git clone https://example.com/path/to/repo-nam.git
    git clone git@example.com:someone/path/to/repo-name.git
    git clone ssh://example.com/path/to/repo-name.git
    git clone git://example.com/path/to/repo-name.git
    ```

    此外还支持 ftp、git 、 rsync 等协议。
    - 克隆远程仓库的某个分支

      ```shell
      git clone <remote_repo> -b <branch>
      ```

      分支相关信息参看[分支管理](#分支管理)

  - 直接添加远程仓库信息

    ```shell
    git remote add [<option>] <host-name> <url>
    ```

    host-name是远程主机名，改名字由用户自定义，如按一般习惯将其命名为`origin` 。

- 删除关联：`git remote remove <repo-name>`

- 查看远程仓库信息：`git remote`

  * 查看远程仓库地址：`git remote -v`

- 远程仓库更名：

  ```shell
  git remote rename <oldname> <newname>
  ```

- 修改远程仓库地址（以origin为例）：

  ```shell
  git remote set-url origin <new-url>
  ```

- 添加远程仓库地址（以origin为例）：

  ```shell
  git remote add-url --add origin <another-url>
  ```

  也可以修改仓库目录中.git下的config文件的相关信息进行仓库更名和地址修改。config文件部分内容示例（该origin远程仓库对应三个地址）：

  ```shell
  [remote "origin"]
  	url = git@github.com:levinit/itnotes.git
  	url = git@git.coding.net:levinit/itnotes.git
  	url = https://github.com/levinit/itnotes.wiki.git
  	fetch = +refs/heads/*:refs/remotes/origin/*
  ```

  提示：向origin推送（push）时将依次推送到三个url地址，但拉取（pull）时仅拉取第一个url地址的仓库内容。

`git remote -h`可获取更多 remote 相关命令帮助。更多远程仓库相关内容参看下
文[推送和获取分支](#推送和获取分支)

# 快照基本操作

Git 保存数据是对文件系统的一组快照。 每次提交更新时，它主要对当时的全部文件制作
一个**快照**。如果文件没有修改，Git 只保留一个链接指向之前存储的文件。一份快照就是备份的一个文件版本，Git 的工作就是创建和保存项目的快照及与之后的快照进行对比。

一个简单的快照生成流程：

工作区文件 --add--> 进入暂存区 --commit--> 加入版本快照

## 仓库状态

* 查看当前仓库状态：`git status`
  * 简略地显示：`git status -s`
* 查看仓库变动内容：`git diff`
  * 显示变动内容摘要：`git diff --stat`
    * 查看已暂存的改动：`git diff --cached`
  * 显示**最近**快照和工作区内容的差异：`git diff HEAD`
    * 显示指定文件的差异`git diff HEAD --<filename>`
* 查看历史提交：`git reflog`

## 提交快照

提交一个快照需要两步操作：

1. 添加文件到暂存区：`git add <file-name>`

2. 提交快照：`git commit`

每次提交都会生成一个哈希码，即是 commit id。修改过的文件如果不添加到暂存区，就不
会加入到快照中。

---

* 将**所有变动**添加到暂存区：`git add -A`

  变动包括（对文件的）新建、修改和删除，A 是 --all 的缩写，相当于以下两条命令：

  * `git add .` 将所有**新建和修改（但不包括删除）**提交到暂存区
  * `git add -u` 将所有**修改和删除（但不包括新建）**提交到暂存区（u--update ，
    只标记本地有改动的已追踪文件）
  * **撤销暂存区**修改：`get reset HEAD <file-name>`

- 提交快照并添加注解：`git commit -m "about"` about 是注解内容

  `-m "about"`还可和其他操作（如 merge 和 tag 等）合用。

- 将**工作区变动直接添加到快照**并增加注解：`git commit -am "about"`

- 将**暂存区**的变动**追加**到上一份快照：`git commit --amend`

  在提交一个快照后又变动了部分内容，但是想把新的变动追加到这个快照中时使用。

  1. 将这些变动添加到暂存区 (git add)

  2. 执行`git commit --amend` 追加

     该命令会**生成的新的 commit id 并替换掉原 commit id**； 如果暂存区没有内容
     , 可以利用该命令修改上一次提交的注解。

## 回退快照

- 回退文件版本

  使用该文件在版本库里的版本替换工作区中的版本，需要**先撤销暂存区修改，再撤销工作区修改**：

  1. **撤销暂存区**修改：`get reset HEAD <file-name>`
  2. **撤销工作区**修改：`git checkout -- <file-name>`

- 删除快照中的文件

  1. git rm <file-name>`
  - `git commit`

  移动或改名版本库中的文件`git mv <file-name> <new-file-name>`同理，需要进行`git commit`快照提交才能生效。

  默认情况下`git rm <file-name>`也会将文件从暂存区和硬盘中（工作目录）删除。如果
  要在工作目录中留存该文件，可以使用`git rm --cached <file-name>`保留。

- 版本回退——回退到某个指定的版本

  * `git reset --hard <commit-id>`   回到指定版本并抛弃该版本之后的所有提交
  * `git revert --hard <commit-id>`  回到指定版本并提交一次

  commit id 可以使用前文的`git reflog`命令在历史操作记录中查找。

  回退之后要推送到远程仓库使用`git push origin HEAD --force`

  * 回退到上一个版本：`git reset --hard HEAD^`

    关于`HEAD`、`^`和`~`

    * `HEAD`表示**当前分支的当前版本**；

    * `^`（ caret）表示父提交，当一个提交有多个父提交时，可以通过在`^`后面跟一
      个**数字**，该数字表示第几个父提交，`HEAD^`相当于`HEAD^1`（第一个父提交）
      ；

      上一个版本就是`HEAD^`或`HEAD^`，上两个版本就是`HEAD^^`。

    * `～`（tilde ）后跟一个数字 n 相当于**前面连续的**n 个`^`，`HEAD ～ 2`就相
      当于`HEAD^^`或`HEA^1^1` 。

## 快照信息

```shell
git rev-list --count HEAD #最近一次提交快照的版本号（即第几次快照）
git rev-parse HEAD #最近一次提交快照的hash值
git rev-parse --short HEAD #最近一次提交快照的前面部分（7位）hash值
```

# 分支管理

分支管理经验示例：

* master 分支 -- 用于稳定更新，同步到远程仓库；
* dev 分支 -- 用于开发，同步到远程仓库；
* bug 分支 -- 用于修复问题，不必同步 ;
* feature 分支 -- 用于添加新特性，根据情况同步；

……

## 分支查看

* 列出所有分支：`git branch`

  ```shell
  #查看包含指定版本的分支
  git branch --contains <commmit-id>
  #查看本地分支与远程分支对应关系
  git branch -vv
  ```

* 列出**当前**分支历史记录：`git log`

  * 查看指定的分支：`git log <branch-name>`
  * 显示拓扑图：`git log -- graph`
  * 简洁模式查看：`git log --oneline`
  * 显示所有的提交信息：`git --decorate`
  * 特定过滤：

    * 查找有特定内容的注释的分支：`git log --grep=<content>`

    * 查找特定作者提交的分支：`git log --author="name"`（ name 是作者名字）

    * 按时间范围查看分支：`git log --since/befor/until/after={time-discription}`
      示例：`git log --oneline --before={3.weeks.ago} --after={2016-06-06} --no-merges`

      `--no-merges`作用是隐藏合并提交的分支，`--oneline`是每个提交显示一行

## 创建、切换、合并和删除分支

* 创建和切换

  * 创建并切换分支：`git checkout -b <branch-name>` 也可以先创建分支再切换分支

    * 创建分支：`git branch <branch-name>`
      * 创建一个空分支：`git checkout --orphan <branch-name>`
    * 切换分支：`git checkout <branch-name>`

  * 创建并切换分支，同时关联远程分支：`git checkout -b <branch-name> origin/<branch-name>`

  * 重命名分支：`git branch -m <old-branch-name> <new-branch-name>`

    这只是将本地分支重命名，如果要将远程分支也重命名，只需要将本地重命名后的分支推送给原来已经关联的远程分支即可，参看[# 推送和下载分支](推送和下载分支)有关推送的说明。

- 合并

  合并是将指定分支合并到**到当前分支**：`git merge <branch-name>`

  如果合并分支时存在冲突则需要先解决冲突。

  合并分支时可在命令后面加上`-m "info"`来添加一个合并说明。

  * 普通方式合并分支：`git merge --no-off <branch-name>`

    通常合并分支时，如果可能，Git 会用 Fast forward 模式，但这种模式下，删除分支
    后，会丢掉分支信息。加`--no-off`参数，可以用普通模式合并。

  * 合并指定分支到当前分支并**丢弃当前分支的历史快照**：`git rebase <branch-name>`

    将指定分支（branch-name ）合并到**当前分支**，**合并后的版本**将 “ 嫁接 ” 到
    该指定分支上并取代该分支。而**当前分支的其余历史快照将会被丢弃**，这些历史快
    照将会**临时**保存为补丁 (patch，补丁在`.git/rebase`目录中 )。

  

- 删除分支：`git branch -d <branch-name>` 强行删除**未被合并过**的分支：`git branch -D <branch-name>`

  这只是删除了本地的分支，如果要删除远程仓库的分支，参看下文。

## 推送和获取分支

* 分支追踪：设置远程某分支与本地某分支的关联（远程某分支和本地某分支建立起一一对应的关系）
  * `git branch --track <branch-name> <origin/branch-name>`
  * `git branch --set-upstream-to=origin/<branch-name> master`

- 推送分支：`git push <repo-name> <local-branch-name>:<remote-branch-name>`

  * 如果省略远程分支名，则表示远程分支名和本地当前分支名一致，如此远程分支名不存在，则会在远程仓库新建该分支。

    示例：`git push origin master`

  * 如果省略本地分支名，则表示删除指定的远程分支，因为这等同于推送一个空的本地分支到远程分支。

    示例：`git push origin :dev`

  * 如果本地分支名和远程分支名都省略，则表示将当前分支推送到追踪的远程分支。

    示例：`git push origin`

  push 命令最后加上`--tags`会推送未曾推送过的标签，参看[标签管理](#标签管理)。

  * 只推送当前分支：`git push`（如果当前分支**只有一个追踪分支**时可以使用）
  * 推送全部分支：`git push -all origin`
  * 推送并指定默认远程跟踪分支：`git push -u <repo-name> <branch-name>`
  * 强制推送：`git push --force origin` （使用本地快照版本强制覆盖到远程仓库）

- 获取分支

  * 获取当前分支新内容：`git fetch <repo-name>` 从远程仓库下载新内容
  * 拉取并合并到当前分支：`git pull <repo-name>` 从远程仓库下载新内容并尝试合并
    到本地当前分支（相当于先 fetch 获取新内容，然后 merge）

## 工作区存储

可**暂存当前工作区**以操作新分支。

* 存储工作区：`git stash`
* 列出存储的工作区：`git stash list`
* 恢复存储的工作区

  * 恢复工作区且**保留**工作区内容：`git stash apply`

    * 恢复指定指定编号的工作区：`git stash apply stash@{number}`（ number 是一个
      数字）

      编号可用`git stash list`命令查看。

  * 恢复工作区并**删除**工作区内容：`git stash pop`

* 删除工作区：`git stash drop`

# 标签管理

提交快照时的 commit id 是一串数字 + 字母（hash code ），难以记忆，使用相对不变
，tag 可以对提交打上容易记住的标签。

* 查看标签：

  * 列出所有标签：`git tag`
  * 查看指定标签信息：`git show <tag-name>`

* 添加标签

  可以在打标签命令后添加 `-m "about"`(about 是标签注解 ) 给标签添加注解。

  * 给当前分支打标签：`git tag <tag-name>`
  * 给指定快照打标签：`git tag <tag-name> <commit-id>`
  * 使用 GPG 签名打标签：`git tag -s <tag-name>`

* 推送标签

  创建的标签都只存储在本地，**不会自动推送**到远程仓库。

  * 推送一个本地标签：`git push <repository-name> <tag-name>`
  * 推送全部未推送过的本地标签：`git push <repository-name> --tags`

* 删除标签

  * 删除一个本地标签：`git tag -d <tag-name>`
  * 删除一个远程标签：`git push <repository-name> :refs/tags/<tag-name>`

# git 配置

## 忽略规则

创建 .gitignore 文件，添加特定匹配规则就可以禁止相应的文件推送到远程仓库。
[github 提供的 .gitingore 文件](https://github.com/github/gitignore)

windows 下：在资源管理器里新建一个 .gitignore 文件，系统会提示必须输入文件名，可
在文本编辑器里 “ 保存 ” 或者 “ 另存为 ” 就可以把文件保存为 .gitignore 了。

* 校验 .gitingore 文件：`git check-ignore`

* 校验指定规则：`git check-ignore -v <rule>`

* 强制添加被忽略的文件：`git add -f <file-name>`

* .gitingore 编写规则：
  * `#`注释
  * 一行一条
  * 同名匹配
  * 可使用通配符
  
  ```shell
  *.a       # 忽略所有 .a 结尾的文件
  !lib.a    # 但 lib.a 除外
  /TODO     # 仅忽略项目根目录下的 TODO 文件，不包括非根目录下的TODO，例如 subdir/TODO
  build/    # 忽略 build/ 目录下的所有文件
  doc/*.txt # 忽略 doc/notes.txt 但不包括 doc/server/arch.txt
  ```
  
  如果一个项目中仅有很少部分不被忽略，可以先使用`*`忽略所有，再使用`!`取反添加不被忽略的匹配模式：
  
  ```shell
  #先忽略所有
  *
  #添加白名单
  !config
  !install.sh
  ```

## 配置

git 的配置文件在`~/.gitconfig`，仓库的配置文件是仓库内的`.git/config`。

可运行`git help` `git config`和`man git`查看更多帮助信息。

官方文
档[git-config Manual Page](https://www.kernel.org/pub/software/scm/git/docs/git-config.html)e

部分设置命令：

加上`--global`参数，则设置内容对当前用户生效，不加`--global`则对当前仓库生效。

* 检查配置情况

  ```shell
  git config --list
  ```

* 设置编辑器

  ```shell
  git config --global nano  #使用nano
  git config --global core.editor vim  #linux下使用vim
  git config --global core.editor "vim -u NONE"  #macos下使用vim
  ```

- 设置差异对比工具

  ```shell
  git config --global merge.tool meld  #使用meld
  ```

* 彩色输出

  ```shell
  git config --global color.ui true
  ```

* 中文文件名显示（避免中文显示成八进制数字）
  
```shell
  git config --global core.quotepath false
  ```
  
* 显示历史记录时每个提交的信息显示一行

  ```shell
  git config --global format.pretty oneline
  ```

* 设置用户名和电子邮箱

  ```shell
  git config --global user.name "your name"
  git config --global user.email "email@example.com
  ```

* 协议更换

  如 https 替代 git 协议

  ```shell
  git config --global url."https://".insteadof "git://"
  git config --global url."https://github.com/".insteadof "git@github.com:"
  ```

* 设置代理

  如使用 socks5，本地 ip 和端口是 127.0.0.1:1080

  ```shell
  git config --global http.proxy socks5://127.0.0.1:1080
  git config --global https.proxy socks5://127.0.0.1:1080
  #取消设置的代理
  git config --global --unset http.proxy
  git config --global --unset https.proxy
  ```

* 设置命令别名：`git config --global alias.<another name> status`

  ```shell
  git config --global alias.ci commit
  git config --global alias.br branch
  git config --global alias.unstage 'reset HEAD'
git config --global alias.graph 'log --graph --oneline --decorate'
  ```
  
  # git 服务简易搭建

1. 安装 git、openssh ，开启 ssh 服务

   ```shell
   systemctl enable --now sshd
   ```

2. 创建运行 git 服务的用户（或使用已有的用户）

   ```shell
   useradd git
   #设置密码等。。。
   ```

3. 初始化 Git 仓库

   ```shell
   #完全创建一个新的仓库
   git init --bare <name.git>  #服务器上的 Git 仓库通常以.git结尾
   
   #如果要从已经存在的仓库克隆一份作为新的仓库
   #使用gitclone
   git clone --bare <repo-name> <new-repo-name>.git
   #或者使用cp、rsync等直接复制
   cp -av <repo-name>/.git <new-repo-name>.git
   
   #确保git用户对仓库有权限（至少700）
   ```

   如果服务器的 ssh 服务更改了默认使用端口，参照前文 “ 远程关联 - 从远程仓库克隆
   ” 中的使用方法。

4. 上传用户公钥（可选）

   收集所有需要登录的用户的公钥（公钥一般位于`$HOME/.ssh/id_rsa.pub`），导入到git服务器上云运行git服务的用户的`~/.ssh/authorized_keys`文件中（一行一个）。

   注意：`.ssh`目录权限为`600`，`.ssh/authorized_keys`权限为`644`。

   客户端生成密钥的方法：`ssh-keygen`

   也可以使用`ssh-copy-id`上传公钥： `ssh-copy-id <git-user>@<git-host>`

5. 客户端使用仓库

   ```shell
    git clone <git-user>@<git-host>:<git-path>
   ```

   



