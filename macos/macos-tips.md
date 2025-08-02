# Finder

默认显示/不显示隐藏文件：

```shell
defaults write com.apple.finder AppleShowAllFiles -boolean true #false
```



## terminal打开慢

开机后首次打开terminal慢，删除log：

```shell
sudo rm -rf /private/var/log/asl/*.asl
```



# 命令行工具

## diskutil

图形界面的磁盘管理工具不能完成一些操作，可以通过diskutil实现：

```shell
diskutil list  #列出所有disk


#--删除disk2的所有分区 
#diskutil eraseDisk 文件系统格式 硬盘名字 硬盘标志符
#diskutil listFilesystems 可查看支持的文件系统格式 fee表示不创建文件系统
diskutil eraseDisk free usb disk2 #分区表将变为GPT类型，且自动创建EFI 分区
#可挂载该efi分区

#---挂载分区
#diskutil mount <disk>
diskutil mount disk2s1

#创建为mbr分区表
#diskutil eraseDisk 文件系统格式 硬盘名字 MBR 硬盘标志符
```



## homebrew相关

- [homebrew-rmtree](https://github.com/beeftornado/homebrew-rmtree) `brew rmtree` 删除安装自formula仓库的软件包及其依赖

  ```shell
  brew tap beeftornado/rmtree  #安装
  brew rmtree git #使用示例
  ```

- [brew-cask-upgrade](https://github.com/buo/homebrew-cask-upgrade) `brew cu` 检查和更新安装自cask仓库的应用

  ```shell
   brew tap buo/cask-upgrade  #安装
   brew cu    #检查 如有更新会提示
   brew cu -ay #检查并同意自动更新
  ```

- [mas](https://formulae.brew.sh/formula/mas) `mas`  通过命令行更新app store应用

  ```shell
  brew install mas  #安装
  mas upgrade
  ```



## 剪切板

- pbcopy 复制到剪切板
- pbpaste 从剪切板粘贴

```shell
cat file.txt |pbcopy
pbcopy < file.txt

pbpaste > newfile.txt
```



## 消息提示osascript

```shell
osascript -e 'display notification "text1" with title "title1"'
```

弹出消息的标题是title1，内容是text1。



## 获取文件路径

```shell
#!/bin/bash
path=$(cd $(dirname $0); pwd -P)
```

