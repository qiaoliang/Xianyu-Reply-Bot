#!/bin/bash
# 一键重启闲鱼自动回复服务
# 用法: bash restart.sh

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[restart] 停止旧进程..."

# 查找占用端口 3456 的进程并 kill
PID=$(lsof -ti:3456 2>/dev/null)
if [ -n "$PID" ]; then
  kill -9 "$PID" 2>/dev/null
  echo "[restart] 已 kill PID: $PID"
  sleep 1
else
  echo "[restart] 无运行中的进程"
fi

# 确保端口已释放
sleep 1

echo "[restart] 启动服务..."

# 后台启动，输出重定向到日志文件
cd "$PROJECT_DIR" || exit 1
nohup npm start > /dev/null 2>&1 &

NEW_PID=$!
echo "[restart] 服务已后台启动 (PID: $NEW_PID)"
echo "[restart] 管理面板: http://127.0.0.1:3456"