# 命令行工具

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
