# 可变类型的赋值、浅拷贝和深拷贝

对于list和dict等可变的数据类型，

- **直接赋值：**其实就是对象的引用（别名）。
- **浅拷贝(copy)：**拷贝父对象，不会拷贝对象的内部的子对象。
- **深拷贝(deepcopy)：** copy 模块的 deepcopy 方法，完全拷贝了父对象及其子对象。

因此，在函数中将一个list或dict的全局变量赋值或浅拷贝给一个局部变量后，如果对局部变量进行更改，会影响全局变量的值。

多线程中，在任意线程中更改模块中的全局变量都会影响到其他所有线程（造成线程不安全），良好的实践是尽量减少全局变量的使用，对于在函数中使用的要更改的list和dict，如需要避免更改全局变量引起的问题，应当使用深拷贝复制变量的值。



# pip相关

- 更新当前环境中所有可更新的包

  ```shell
  pip install --upgrade $(pip list --outdate 2>/dev/null |sed -n "3,$ p"|awk '{print $1}')
  ```

  

- 导出当前环境中所有包信息

  ```shell
  pip freeze | tee pip.list
  ```

  

- 下载当前环境中所有包及其依赖

  ```shell
  pip list 2>/dev/null | sed -n '3,$ p' | while read line; do
      package=$(echo $line | awk '{print $1}')
      pip download $package
  done
  ```

  

- 从指定目录安装pip包

  ```shell
  #可使用-r读取指定文件以实现仅安装该文件内指定的软件包
  pip install -r pip.list --no-index --find-links=$PWD
  ```

  

# list去重

- 遍历元素逐一处理

  ```python
  old_list = [2, 3, 4, 5, 1, 2, 3]
  new_list = []
  for i in old_list:
      if i not in new_list:
          new_list.append(i)
  ```

  

- 字典dict去重

  使用`dict.fromkeys()`方法将list的元素作为新dict的key（，利用key不能重复的特性去重，再转换为list：

  ```python
  old_list = [2, 3, 4, 5, 1, 2, 3]
  new_list = list(dict.fromkeys(old_list)
  ```
  `dict.fromkeys(key[,value])`返回一个dict，如果value不指定则为`None`，value将作为这个dict所有key的值。

  

- 用集合set去重

  转换为set，再转换为list，但不能保证元素的顺序：

  ```python
  old_list = [2, 3, 4, 5, 1, 2, 3]
  new_list = list(set(old_list))
  ```

  可加上列表中索引（index）的方法保证去重后的顺序不变：

  ```python
  old_list = [2, 3, 4, 5, 1, 2, 3]
  new_list = list(set(old_list))
  new_list.sort(key=old_list.index)
  ```

  
