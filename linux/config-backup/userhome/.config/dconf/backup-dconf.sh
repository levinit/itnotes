#!/bin/bash

BACKUP_DIR="$HOME/.config/dconf"
RAW_FILE="$BACKUP_DIR/raw-dconf.conf"
SAFE_FILE="$BACKUP_DIR/dconf.conf"

mkdir -p "$BACKUP_DIR"

echo "[*] 正在导出 GNOME dconf 配置到 $RAW_FILE..."
dconf dump / > "$RAW_FILE"

echo "[*] 正在生成 Git-safe 安全版本（敏感字段将被屏蔽）..."

# 屏蔽敏感信息
sed -E \
    -e 's/(password\s*=\s*).*/\1<REDACTED>/I' \
    -e 's/(psk\s*=\s*).*/\1<REDACTED>/I' \
    -e 's/(token\s*=\s*).*/\1<REDACTED>/I' \
    -e 's/(authorization\s*=\s*).*/\1<REDACTED>/I' \
    -e 's/((user(name)?|email|ssid)\s*=\s*).*/\1<REDACTED>/I' \
    -e 's|(=/home/)[^/]+|\1<USERNAME>|g' \
    "$RAW_FILE" > "$SAFE_FILE"

echo "[✓] 备份完成："
echo " - 完整原始配置：$RAW_FILE"
echo " - 可公开上传版本：$SAFE_FILE"
