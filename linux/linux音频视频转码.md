
# mencoder
## 转码

```shell
mencoder original.mpg -o new.avi -ovc lavc -oac lavc
```
## 合并

```shell
mencoder file1 file2 fileN -oac pcm -ovc copy -o output.mp4
```
- -ovc指定视频编码格式  可使用`mencoder -ovc help`查看支持的视频编码

  copy表示使用原来的编码格式（音频也可使用copy）

- -oac指定音频编码格式  可使用`mencoder -oac help`查看支持的音频编码

- -o指定输出文件

