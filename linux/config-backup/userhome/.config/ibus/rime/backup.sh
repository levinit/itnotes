#!/bin/bash
unalias -a

set -u

BACKUP_DIR="~/Documents/Rime_Backup" # 你的备份目标目录
mkdir -p $BACKUP_DIR

echo "======= RIME 备份 ========"
echo "备份到 $BACKUP_DIR"
echo

echo "备份个人配置..."
# 1. 只备份你自己写的自定义补丁
cp ~/.config/ibus/rime/*.custom.yaml $BACKUP_DIR/

echo
echo "备份个人词库..."
# 2. 只备份 Rime 导出的个人词库纯文本快照
cp ~/.config/ibus/rime/sync/*/*.userdb.txt $BACKUP_DIR/

echo
echo "========================="
echo "Rime 备份完成！"
