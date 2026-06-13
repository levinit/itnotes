[toc]

# 基本

- 使用通配符`*`

- 使用<kbd>Tab</kbd>补全

- 命令前加上`\`将使用该命令原始行为，令同名alias失效。

  例如设置了`alias rm=rm -i`，使用`\rm`则该alias无效。
  
  `unalias -a`可使该shell进程中所有alias失效。



# 光标相关操作

*以下快捷键多数在vim中依然适用。（编辑或普通模式）*

*某些终端应用中，可能不全部适用*。

Mac键盘中，将<kbd>Ctrl</kbd>替换成<kbd>control</kbd>，<kbd>Alt</kbd>替换成<kbd>⌥</kbd>(option)。

提示：mac中可能需要在终端程序的键盘设置中，勾选“将Option键用作Meta键”。

## 移动光标

- <kbd>Ctrl</kbd><kbd>a</kbd>  移动到开始（同<kbd>Home</kbd>键）
- <kbd>Ctrl</kbd><kbd>e</kbd>  移动到结尾（同<kbd>End</kbd>键）



- <kbd>Ctrl</kbd><kbd>f</kbd>  向前(front)移动一个字符（同左方向键）
- <kbd>Ctrl</kbd><kbd>b</kbd>  向后(back)移动一个字符（同右方向键）



- <kbd>Alt</kbd><kbd>f</kbd>  向前移动到下一个单词尾部
- <kbd>Alt</kbd><kbd>b</kbd>  向后移动到上一个单词头部



- <kbd>Ctrl</kbd><kbd>&leftarrow;</kbd>  移动到当前单词结尾
- <kbd>Ctrl</kbd><kbd>&rightarrow;</kbd>  移动到当前单词开头



- <kbd>Ctrl</kbd><kbd>xx</kbd>  在最后两次光标出现的位置间切换



## 复制和粘贴

- <kbd>Shift</kbd><kbd>Ctrl</kbd><kbd>c</kbd>  复制

  Mac：<kbd>⌘</kbd><kbd>c</kbd>

- <kbd>Shift</kbd><kbd>Ctrl</kbd><kbd>v</kbd>  粘贴

  Mac：<kbd>⌘</kbd><kbd>v</kbd>



## 删除内容

此处以从左到有的排版顺序，前指的是光标左侧，后指的光标是右侧。

- <kbd>Ctrl</kbd><kbd>h</kbd>  删除光标前一个字符（同<kbd>Back Space</kbd>键）
- <kbd>Ctrl</kbd><kbd>d</kbd>  删除光标后一个字符（同<kbd>Delete</kbd>键）



- <kbd>Ctrl</kbd><kbd>w</kbd>  删除光标前面一个单词
- <kbd>Alt</kbd><kbd>d</kbd>  删除光标后面一个单词



- <kbd>Ctrl</kbd><kbd>u</kbd> 删除光标前面所有内容
- <kbd>Ctrl</kbd><kbd>k</kbd> 删除光标后面所有内容



- <kbd>Ctrl</kbd><kbd>l</kbd> 或`clear`  清除屏幕内容

  Mac：<kbd>⌘</kbd><kbd>k</kbd>

## 替换和对调内容

### 大小写转换

*该单词即是光标坐在的单词*；Mac不适用。

- <kbd>Alt</kbd><kbd>u</kbd>  将**该单词中**光标所在位置及其后的字母变为大写(upper case)
- <kbd>Alt</kbd><kbd>l</kbd>  将**该单词中**光标所在位置及其后的字母变为小写(lower case)
- <kbd>Alt</kbd><kbd>c</kbd>  将**该单词中**光标所在位置变为大写 其后的字母变为小写——即首字母大写(captial)

### 位置对调

*终端可能能够选择光标样式，如方块光标会覆盖整个字符，下划线光标会标示在整个字符下面，而竖线光标则出现在两个字符中间。*

*下面是以竖线光标做的说明，方块光标和下划线光标以光标左侧边缘作为判定前后的参照位置。*

**空格和tab内容也算字符**。

- <kbd>Ctrl</kbd><kbd>t</kbd>

  - 当光标在字符间时，**对调光标前后两个字符的位置**且光标后移一位（transposition)
  - 当光标在所有字符末尾时，对调最后两个字符位置

  **注意**：在方块和下划线光标里，这句话中的1应该描述为：

  光标在字符上时，对调光标所在字符和光标前一个字符的位置

- <kbd>Alt</kbd><kbd>t</kbd>  对调单词，规则参照<kbd>Ctrl</kbd><kbd>t</kbd>

# 命令历史

## 历史管理

- 设定历史命令保存条数

  编辑`~/.bash_history`或`/etc/profile`，编辑或添加类似：

  ```shell
  HISTSIZE=10000  #10000即保存的历史命令数量
  ```

- `history`  查看历史命令

  常用参数：
  - -a  追加当前会话信息到历史文件

  - -c  清空历史命令

  - -w  把缓存中的历史命令立即保存

- 退出shell时不保存此次操作历史到history

  - `kill -9 $$`


## 历史复用

### 快捷键

- <kbd>Ctrl</kbd><kbd>r</kbd>  查找历史记录以供使用 （输入关键字即可查找 回车即执行）



- <kbd>⬆</kbd>或<kbd>Ctrl</kbd><kbd>p</kbd>  切换到上一条命令
- <kbd>⬇</kbd>或<kbd>Ctrl</kbd><kbd>n</kbd>  切换到下一条命令



- <kbd>Page Up</kbd>  切换到第一条命令
- <kbd>Page Down</kbd>  切换最后一条（最近一条）命令



- <kbd>Alt</kbd><kbd>.</kbd>  或 <kbd>esc</kbd><kbd>.</kbd>  粘贴上一条命令中的最后一部分参数

  一条命令以IFS（空白分隔符，一个或多个空格/tab）分割成若干部分。

  Mac使用后者

- <kbd>Alt</kbd>n<kbd>.</kbd>  粘贴上一条命令中第n（一个数字）部分参数

  Mac不适用

  

### 历史命令调用

- `!!`  执行上一次命令

- `!<n>`  执行历史中第n条命令

- `!-<n>`  执行倒数第n条命令

- `!<string>`  执行历史中最后一个以该字符串开头的命令

  例如`history`最后一部分内容如下：

  > 509  ls
  >
  > 510  ss -tulp
  >
  > 511  ssh root@localhost
  >
  > 512  history 

  ```shell
  !ss  #相当于执行第511条ssh root@localhost命令
  ```

### 复用前一条命令中的参数

上一条命令中的参数（以空格隔开的字段）

- `!*`  前一条命令中的所有参数

  ```shell
  echo a b
  touch !*  #等同于touch a b
  ```

- `!:<n>`  前一条命令中第n个参数（从1开始）

  ```shell
  ls /etc/hosts /etc/passwd 
  stat !:2  #等于执行stat /etc/passwd（上一条命令中的第2个参数）
  ```

- `!^`或`!:^`  前一条命令的第一个参数

  ```shell
  ls .bashrc .vimrc
  stat !^  #等于执行 stat .bashrc
  ```

- `!$`  前一条命令的最后一个参数

  ```shell
  ls .bashrc .vimrc
  stat !$  #等于执行 stat .vimrc
  ```

### 替换上一条命令中的字符

- `^old^new`  将上一条命令中**第一个**的old字符串替换为新的new字符串

  ```shell
  systemclt status NetworkManager
  ^lt^tl  #将上一条命令中的tl改成ctl再执行一次 等同systemctl status NetworkManager
  systemctl start sshd
  ^start^status    #等于执行systemctl status sshd
  ```

- `!!:gs/old/new`  将上一条命令中**所有**的old字符串替换为新的new字符串

  ```shell
  echo aaa aaa
  !!:gs/aaa/bbb   #将上一条命令aaa替换成bbb, 将执行 echo bbb bbb
  ```

# 魔法空格magic-space

magic-space 让和历史记录相关的特殊参数表达式（参看前文命令历史中特殊参数一节）立即“显出原形”，zsh默认启用该功能。

对于bash，在其配置文件中（如~/.bashrc）添加：

```shell
bind Space:magic-space
```

在键入下文的特殊符号或特殊参数后按下空格或回车，即可显示该符号或参数所代表的实际内容。例如

```shell
ls /etc/hosts
stat !:^  #在^后按下空格 该行就变成了 stat /etc/hostss
```

在第二条命令输入完特殊参数`!:^`后按下空格，该特殊参数就被替换显示成了实际对应的内容——`.bashrc`。

