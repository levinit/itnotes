# conda

## conda简介



conda是一种**通用**包管理系统，旨在构建和管理任何语言和任何类型的软件。

[anaconda](https://www.anaconda.com)是一个适用于Linux发行版的免费开源系统安装程序，多用于Python/R数据科学和机器学习等；miniconda是anaonda的最小化版本，只有最基础的python环境。



## conda使用



## 激活conda环境

在shell环境文件中（如`~/.bashrc`）添加：

```shell
if [[ -d /share/apps/anaconda3/ ]]
then
__conda_setup="$('/share/apps/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/share/apps/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/share/apps/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/share/apps/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
fi
```

或者执行`conda init`将自动添加到用户shell配置文件。



如果登录后默认启动base环境，不希望登录shell时自动激活base环境，可以执行：

```shell
conda config --set auto_activate_base false
```

或者在conda配置文件`~/.condarc`中加入：

```shell
auto_activate_base: false
```



## 创建、复制和删除环境

默认情况下，普通用户创建的conda环境在`~/.conda`目录下，特权用户root创建的conda环境载安装目录下envs目录中。

```shell
#创建环境
#conda create --name <env_name> [package_names]
#--name和-n均表示指定新环境的名称
conda create -n ai

#可以在创建时指定python版本
conda create -n ai python=3.7

#可以在创建环境时安装上所需要的包 也可以创建后再安装
conda create -n ai tensorflow-gpu keras-gpu matplotlib

#使用-p或--prefix可指定安装目录 但不能和-n或--name同时使用
conda create -p ~/ai

#升级conda环境 -c指定chnel
conda update -n <env-name>
```

从已有环境复制：

```shell
#conda create -n <new_env_name> --clone <copied_env_name>
conda create -n new ai  --clone ai
```

删除环境：

```shell
#conda remove --name <env_name> --all
conda remove -n ai --all
```



## 查看、进入和退出环境

```shell
#查看已有可用的虚拟环境列表
conda env list #
conda info -e  #作用同上 -e也可以写成--envs

#激活虚拟环境
conda activate base   #激活虚拟环境ai
conda activte ~/test  #也可以指定虚拟环境路径激活

#退出虚拟环境
conda deactivate
```



### 迁移环境

本地迁移使用clone即可。

在具有相同操作系统 的计算机之间复制环境：

- Spec List

  在具有 **相同操作系统** 的计算机之间复制环境，需要网络。

  1. 生成 spec list 文件

     ```shell
     conda list --explicit > spec-list.txt
     ```

  2. 复制spec list 到其他系统

  3. 在其他系统中重现环境

     ```shell
     conda create  --name python-course --file spec-list.txt
     ```

  

- Environment.yml

  在**不同的平台和操作系统之间** 复现项目环境，需要网络。

  1. 导出 `environment.yml` 文件

     ```shell
     conda env export > environment.yml
     ```

  2. 复制`environment.yml` 文件到其他系统

  3. 在其他系统中重现环境

     ```shell
     conda env create -f environment.yml
     ```

     

- 复制env目录

  在具有 **相同操作系统** 的计算机之间复制环境

  将环境目录整个复制（可打包压缩后解压缩）

  

- Conda Pack

  `Conda-pack` 是一个命令行工具，用于打包 conda 环境，其中包括该环境中安装的软件包的所有二进制文件，可用于离线环境。

  仅支持在具有 **相同操作系统** 的计算机之间复制环境。

  需要安装`conda-pack`：

  ```shell
  conda install -c conda-forge conda-pack
  #或使用pypi
  pip install conda-pack
  ```

  1. 打包环境：

     ```shell
     # Pack environment my_env into my_env.tar.gz
     conda pack -n my_env
     
     # Pack environment my_env into out_name.tar.gz
     conda pack -n my_env -o out_name.tar.gz
     
     # Pack environment located at an explicit path into my_env.tar.gz
     conda pack -p /explicit/path/to/my_env
     ```

  2. 将打包的文件传输到其他系统

  3. 在其他系统中重现环境

     ```shell
     mkdir -p my_env
     tar -xzf my_env.tar.gz -C my_env
     
     # Use Python without activating or fixing the prefixes. Most Python libraries will work fine, but things that require prefix cleanups will fail.
     ./my_env/bin/python
     
     # Activate the environment. This adds `my_env/bin` to your path
     source my_env/bin/activate
     
     # Run Python from in the environment
     (my_env) $ python
     
     # Cleanup prefixes from in the active environment.
     # Note that this command can also be run without activating the environment as long as some version of Python is already installed on the machine.
     (my_env) $ conda-unpack
     ```




## 管理conda包

安装、删除、升级和查看包时，应当指定虚拟环境（使用`-n`或`—name`）或进入目标虚拟环境，否则该操作时针对全局的（base环境）。

在conda环境中，优先使用conda install安装，如果conda源中没有需要的版本的包，再考虑使用pip等安装需要的内容。



conda中国源：可以到各大镜像站查找并设置可用的国内镜像源，以加速conda的下载。如[清华大学镜像源](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/)。



使用示例：

```shell
#搜索包
conda search pkg-name  #pkg-name为包的名字，下同

#当前环境下已安装的包
conda list              #查看
#install/upgrade/remove均可以使用-n指定环境
coda list -n <env-name>  #env-name为环境的名字 

#安装
conda install <pkg-name>
conda install <pkg-name> -c <channel name>

#升级update或upgrade
conda upgrade <pkg-name>
conda upgrade --all  #升级所有

#移除
conda remove -n <pkg-name>
conda remove -n <pkg-name> --all  #--all，同时删除环境中所有包
```



# python venv

为特定需要创建虚拟环境（virtual enviroment），在虚拟环境安装有特定Python版本以及其他python包。

## venv虚拟环境管理

- 创建虚拟环境

  创建虚拟环境前先确定要放置它的目录，并将 [`venv`](https://docs.python.org/zh-cn/3/library/venv.html#module-venv) 模块作为脚本运行目录路径。

  ```shell
  mkdir -p ~/.virtualenvs
  python -m venv ~/.virtualenvs/ai  #创建虚拟环境到~/.venv/ai目录中
  ```

  虚拟环境存放目录下的pyvenv.cfg文件是该虚拟环境的配置文件，内容类似：

  ```shell
  home = /usr/local/bin
  include-system-site-packages = false
  version = 3.9.1
  ```

- 激活虚拟环境

  Linux、MacOS：

  ```shell
  source ~/.virtualenvs/ai/bin/activate
  ```

  Windows（cmd或powershell）：

  ```powershell
  ～.virtualenvs\ai\Scripts\activate.bat
  ```

  激活后，在命令行提示前面有该虚拟环境目录信息，类似：

  > (aii) [testuer@localhost ~]

## 在虚拟环境中使用pip管理包

激活虚拟环境后，在虚拟环境中使用pip来安装、升级和移除软件包即可。虚拟环境中通过pip安装到内容均存放在该虚拟环境所在的目录下。

```shell
which python
which pip
pip install numpy
pip list -v
```



pip国内镜像源（可到国内各大镜像站点获取设置方法）

pip config set命令设置：

```shell
# 清华源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# 阿里源
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
# 腾讯源
pip config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
# 豆瓣源
pip config set global.index-url http://pypi.douban.com/simple/
```

或新建/编辑pip配置文件，添加源相关内容。

MacOS或Linux的pip源配置内容一般为`~/.config/pip/pip.conf`。

windows打开文件管理器，在地址栏输入`%APPDATA%`，进入该目录，编辑或新建`pip.conf`文件。

例如：

```ini
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
```
