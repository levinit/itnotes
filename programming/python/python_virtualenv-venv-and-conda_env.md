[TOC]

# Python 虚拟环境与包管理核心心智模型

## 环境隔离本质与选型矩阵

Python 虚拟环境的本质并非完整复制解释器，而是**通过环境变量 `PATH` 的劫持与 `sys.prefix` 重定向**，让解释器优先在独立的 `site-packages` 目录下查找第三方依赖包，从而实现项目间包版本冲突隔离。

| 工具方案 | 适用场景 | 核心优势 | 注意事项 |
| :--- | :--- | :--- | :--- |
| **`uv` (推荐工程首选)** | 现代生产开发、CI/CD 构建、日常脚本执行 | 基于 Rust 构建，依赖解析与安装速度比 pip 快 10~100 倍；内置 Python 多版本管理；无缝兼容 pip 与 venv 命令 | 需单独安装单个二进制 |
| **`venv` + `pip`** | 纯 Python 轻量开发、零外部工具依赖场景 | Python 标准库内置，通用性最好 | 依赖解析速度一般，无依赖锁定校验机制 |
| **`conda` / `micromamba`** | 科学计算、数据分析、深度学习（含 CUDA/C++ 动态链接库依赖） | 不仅管理 Python 包，还跨平台管理系统级二进制动态库（如 cudatoolkit, blas, gdal） | 环境体积庞大；推荐采用内置 `libmamba` 求解器的现代版本或轻量 `micromamba` 避免依赖解析卡死 |

> **生产绝对红线**：严禁在宿主机直接使用 `sudo pip install`！这会污染系统级 Python 环境，破坏系统的包管理器（apt / dnf / pacman 等）。

---

# 现代首选：uv 极速工作流

```shell
# 1. 独立单二进制安装
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. 一键创建虚拟环境（自动下载或匹配指定 Python 版本）
uv venv .venv --python 3.12

# 3. 激活环境
source .venv/bin/activate        # Linux / macOS
.venv\Scripts\Activate.ps1       # Windows PowerShell

# 4. 极速安装依赖（全面兼容 pip 语法）
uv pip install fastapi "uvicorn[standard]" pydantic

# 5. 依赖锁定与确定性部署
uv pip compile pyproject.toml -o requirements.txt  # 解析并生成精确锁定清单
uv pip sync requirements.txt                       # 严格按照清单对齐当前环境（多退少补）

# 6. 免激活即时执行（在隔离环境中运行脚本或 CLI）
uv run python train.py
uv run pytest
```

---

# 标准原生：venv 工作流

```shell
# 1. 创建虚拟环境
python3 -m venv ~/.virtualenvs/myproject

# 2. 激活虚拟环境
source ~/.virtualenvs/myproject/bin/activate       # Linux / macOS
~/.virtualenvs/myproject\Scripts\Activate.ps1      # Windows

# 3. 依赖固化与还原
pip freeze > requirements.txt
pip install -r requirements.txt
```

---

# 科学计算与二进制分发：Conda / Micromamba

## 1. 常用命令规范
```shell
# 创建指定 Python 版本的独立环境
conda create -n ai_env python=3.12 -y

# 激活与退出
conda activate ai_env
conda deactivate

# 导出与还原环境
conda env export --no-builds > environment.yml
conda env create -f environment.yml

# 删除环境
conda remove -n ai_env --all -y
```

## 2. 离线节点打包迁移 (conda-pack)
在相同操作系统与架构集群（如离线 HPC 节点）之间快速分发环境：
```shell
# 在联网机器打包
pip install conda-pack
conda pack -n ai_env -o ai_env.tar.gz

# 在目标机器部署解压
mkdir -p /opt/envs/ai_env
tar -xzf ai_env.tar.gz -C /opt/envs/ai_env
source /opt/envs/ai_env/bin/activate
conda-unpack  # 修复环境内部硬编码路径前缀
```

---

# 生产级镜像源配置规范

建议在用户级配置文件中指定国内 HTTPS 镜像源（禁止使用不安全的 HTTP 源）：

```shell
# pip 全局镜像源设置（清华源）
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# 常用备选：
# 阿里云：https://mirrors.aliyun.com/pypi/simple/
# 腾讯云：https://mirrors.cloud.tencent.com/pypi/simple/
```
