#!/bin/bash
unalias -a
set -euo pipefail

curdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 软链接所有配置文件到 ~/.config/ibus/rime/
for file in "$curdir"/*.yaml; do
	ln -sfv "$file" ~/.config/ibus/rime/
done
