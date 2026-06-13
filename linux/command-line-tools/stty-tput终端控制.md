# 终端相关全局变量

- `LINES`  行数（高度）
- `COLUMNS`  列数（宽度）

- `LINENO`  当前行号

# stty终端设置

## 终端信息

```shell
stty -a  #以容易阅读的方式打印当前的所有配置
stty size  #打印终端行数和列数
```

## 终端输出控制

- 改变 Ctrl D 按键作用(默认表示文件结束)

  ```shell
  stty eof "string"
  ```

- 屏蔽和恢复回显（echo）

  ```shell
  stty -echo  #此后输入内容均不会显示
  stty echo  #恢复回显
  
  #示例，禁止密码回显  #当然也能通过read -s 实现
  echo "input password (will not echo anything)"
  stty -echo
  read password
  stty echo
  echo "set password done."
  ```

- 忽略和恢复回车符

  ```shell
  stty igncr     #开启
  stty -igncr    #恢复
  ```

- 小写字母转大写

  ```shell
  stty olcuc #开启
  stty -olcuc#恢复
  ```

# tput操纵终端显示

>  **tput命令**将通过 terminfo 数据库对您的终端会话进行初始化和操作。通过使用 tput，您可以更改几项终端功能，如移动或更改光标、更改文本属性，以及清除终端屏幕的特定区域。

## 终端信息

```shell
tput lines  #获取终端行数(高)
tput cols  #获取终端列数(宽)
```

## 设置终端

```shell
tput init  #初始化终端
tput reset #重置终端
```

### 光标控制

- 位置存储

  ```shell
  tput sc # 保存当前光标位置 save cursor
  tput rc # 恢复保存的光标位置 restore cursor
  ```

- 光标移动

  使用 cup 选项，在各行和各列中将光标移动到任意 X 或 Y 坐标（以左上光标提示符后为坐标原点0,0）。

  ```shell
  tput cup 10 13 # 将光标移动到指定行列位置 10列 13行
  ```

  示例，定位光标到指定位置输出提示信息后，再将光标恢复到原来的位置等待用户输入内容：

  ```shell
  #最终看到右下角部分有一句提示信息，而光标在原来位置等待输入
  (tput sc ; tput cup 23 45 ; echo “Input from tput/echo at 23/45” ; tput rc)
  ```

  保存光标位置--->移动光标到指定位置--->输出提示内容--->恢复保存的光标位置。

  另，清除屏幕内容（作用同clear)

  ```shell
  tput clear # 清屏
  ```

- 光标属性

  ```shell
  tput civis # 光标不可见 invisiable
  tput cnorm # 光标可见 normal
  ```

### 文本显示

更改文本的显示属性（如颜色、字体等）

```shell
tput rev ;echo "hello ukelele";tput sgr0  #hello ukelele会反色显示
echo -e "$(tput bold) Bold Texts$(tput sgr0)"  #粗体显示Bold Texts文字 
```

各种文本属性均可使用`tput sgr0`取消（还原成为设置状态），其中下划线也可以使用单独的`rmul`取消。

- 配色

  ```shell
  tput setf <n>  #前景色foreground
  tput setb <n>  #背景色background
  tput rev  #反色 反显当前配色方案，即对调前景色和背景色
  ```

  n为代指颜色的数值（可能会因 UNIX 系统的不同而异）：

  >0：黑色
  >
  >1：蓝色
  >
  >2：绿色
  >
  >3：青色
  >
  >4：红色
  >
  >5：洋红色
  >
  >6：黄色
  >
  >7：白色

- 样式

  ```shell
  tput bold  #粗体
  tput dim   #半透明
  tput smul  #设置下划线（下划线起点）
  tput rmul  #取消下划线（下划线终点）
  ```

- 其他

  ```shell
  tput ed  #删除从当前光标到行尾所有内容
  tput smso  #开启标准输出模式
  tput rmso  #取消标准输出模式
  ```