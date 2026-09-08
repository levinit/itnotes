# 调度器简介

## PBS系列变迁

### PBS

[PBS](https://en.wikipedia.org/wiki/Portable_Batch_System)，即Portable Batch System。

- 1991年6月17日开始：NASA合同项目，开发源代码的主要承包商是MRJ Technology Solutions公司。

- 20世纪90年代末：Veridian收购MRJ。

- 2003年：Altair Engineering于从Veridian获得了所有PBS技术和知识产权的权利，并雇佣了NASA的原始开发团队。

  

  NASA项目PBS，MRJ承接开发PBS ---> Verdidian收购MRJ ---> Altair从Verdidian获得PBS



### PBS Pro

即PBS Professional，Altair公司提供的PBS版本，具有开源（PBS许可）和商业双重许可。



### openPBS

- 1998年：从MRJ开源的PBS版本上进行开发，后开发不活跃，而其分支[torque](#torque)活跃开发，被广泛使用。
- 2018年5月起：Altair将开源许可的PBS pro命名为[openPBS](https://www.openpbs.org)。



### torque--从开源走向闭源

[torque](https://en.wikipedia.org/wiki/TORQUE)，即Terascale Open-source Resource and QUEue Manager，AdaptiveComputing Enterprises Inc.（原Cluster Resources，Inc.）维护的openPBS分支。

- 2003年到2018年6月期间维护的OpenPBS的分支为开源软件
- 2018年6月起：转为非自由软（none-free software）。





## LSF系列--LSF变更与openlava的终结

[LSF](https://en.wikipedia.org/wiki/Platform_LSF)，即Load Sharing Facility。

- 1993年：加拿大多伦多大学[Utopia](https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.121.1434)（乌托邦）项目为LSF前身，Platform Computing公司（由Utopia的几个开发者成立）发布LSF。

- 2007年-2011年：2007年，Platform Computing公司发布LSF的简化开源版本——Plaform Lava 1.0（基于老版本的LSF 4.2，使用GPL v2），无后续发布。

- 2011年6月：[openLava](https://en.wikipedia.org/wiki/OpenLava) 1.0发布到github，其由Platform Computing员工David Bigagli基于Platform Lava派生，使用GPL v2。

- 2012年1月：IBM收购Platform Computing公司，LSF更名为IBM Platform LSF，为商业授权，9.1.3版本后停止更新以维护为主。IBM后推出10.x的LSF，商业名称为[IBM Spectrum LSF](https://www.ibm.com/products/hpc-workload-management)。

- 2014年：Teraproc Inc.（由Platform Computing公司的一些前员工成立）为openLava提供开源支持，并基于开源openlava提供商业支持业务（附加一些开源版本的openlava没有的特性）。

- 2018年9月18日：IBM取得对Teraproc Inc.的胜诉（2016年10月IBM提起版权诉讼），openlava被禁止，导致openlava 3.0和4.0版本（最新版本）源码从github下架，[openlava](https://github.com/shapovalovts/openlava) 2.2版本仍向开源社区提供。

  

Utopia ---> Platform LSF ---> IBM Platform LSF ---> IBM Spectrum LSF

Platform LSF---> Platform Lava ---> openLava

openlava只支持Linux，LSF（指当前的IBM商业版）支持Linux和Windows。



## SGE系列更迭—OGE--UGE

SGE，即Sun Grid Engine。

- 1999年：Genias Software推出Grid Engine ，而后Genias Software和Gridware Inc.合并。

  Grid Engine可追溯到1993年，使用过**CODINE**（Computing in Distributed Networked Environments）和**GRD**（Global Resource Director）作为名称。

- 2000年：SUN收购Gridware，之后正式改名**Sun Grid Engine**，SGE之名来源于此。

- 2001年：SUN发布开源版SGE。

- 2010年：Oracle收购SUN，改名为Oracle Grid Engine（OGE），OGE自6.2u6版本改为闭源，不提供源代码。原来开源项目的资料库禁止用户修改。

  Grid Engine社区开始开源版本的SGE（Son of Grid Engine）项目。由于存在版权风险，SGE已长期无维护和更新。

- 2011年1月18日：Univa宣布已经聘用了SUN公司开发Grid Engine的主要工程师，Univa公司内部称该派生自Grid Engine的项目为Univa Grid Engine （UGE），与Oracle Grid Engine展开商业竞争。

- 2013年10月22日：Univa宣布其已获得 Grid Engine的知识产权和商标所有权，接管对Oracle Grid Engine的客户支持，成为Grid Engine（UGE）唯一供应商。

- 2020年9月14日：Altair Engineering公司宣布已收购Univa，获得Grid Engine。



​	Grid Engine ---> SUN Grid Engine ---> Oracle Grid Engine

​	SUN Grid Engine ---> opensource SUN Grid Engine ---> Son of Grid Engine

​	SUN Grid Engine ---> Univa Grid Engine ---> Univa Grid Engine (Altair)



## Slurm--保持开源

[Slurm](https://slurm.schedmd.com/documentation.html)，即Simple Linux Utility for Resource Management。

前期主要由劳伦斯利弗莫尔国家实验室、SchedMD、Linux NetworX、Hewlett-Packard 和 Groupe Bull 负责开发，受到闭源软件Quadrics RMS的启发。

Slurm目前由社区和SchedMD公司共同维护，使用GPL协议。SchedMD公司提供商业支持。

