.src.rpm包是包含了源代码的rpm包，在安装时需要进行编译。这类软件包有多种安装方法。

需要安装rpmbuild及其他相关依赖（如果缺少，rpmbuild操作会中断并提示）。

以下示例在x8_64的centos中构建test.src.rpm。

- `rpmbuild -bb`构建

  ```shell
  pkg=test
  rpm -i $test*.src.rpm
  cd ~/rpmbuild/SPECS
  rpmbuild -bb $test*.spec
  cd ../RPM/x86_64
  yum install *.rpm
  ```

- `rpmbuild -bp` 编译

  ```shell
  pkg=test
  rpm -i $test.*src.rpm
  cd ~/rpmbuild/SPECS
  rpmbuild -bp $test*.spec
  cd ../BUILD/
  #根据需求自行编译
  ./configure
  make
  make install
  ```

  `rpmbuild -bp`及以后步骤不同于`rpmbuild -bb`方法，这里的p是patch，b是binary，bp方式自行编译可以在configure中添加各种参数以自定义相关安装选项。

- 解开源码包直接编译

  ```shell
  pkg=test
  #1. rpm2cpio解开
  rpm2cpio $pkg.src.rpm  | cpio -id
  
  #2.根据不同压缩包类型解开
  #tarx zjvf $pkg.tar.gz
  
  #3.进入到解压的文件夹中进行编译#
  cd $test
  ./cofigure
  make && make install
  ```

  

