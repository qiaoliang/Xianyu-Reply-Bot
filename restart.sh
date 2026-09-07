#!/bin/bash
# 一键重启闲鱼自动回复服务
# 用法: bash restart.sh
#
# 说明：
# - 除重启服务外，还会清理仍占用 chrome-profile 的残留 Chrome 进程，
#   避免重新启动时报 "Failed to create a ProcessSingleton ... profile is already in use"。
# - 执行后需在管理面板点击「启动服务」才会开始自动回复。

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHROME_PROFILE_DIR="$PROJECT_DIR/chrome-profile"

echo "[restart] ===== 闲鱼自动回复服务重启 ====="

# 1) 停止占用管理端口 3456 的旧服务进程
#    注意：加 -sTCP:LISTEN 只杀服务监听进程，避免误杀正在访问面板的客户端连接
echo "[restart] 第 1 步：停止旧服务进程（端口 3456）..."
PIDS=$(lsof -ti:3456 -sTCP:LISTEN 2>/dev/null | tr '\n' ' ')
if [ -n "$PIDS" ]; then
  # 注意：不要给 PIDS 加引号，否则多个 PID 无法逐个传给 kill
  kill -9 $PIDS 2>/dev/null
  sleep 1
  REMAIN=$(lsof -ti:3456 -sTCP:LISTEN 2>/dev/null | tr '\n' ' ')
  if [ -n "$REMAIN" ]; then
    echo "[restart] 警告：端口 3456 仍被占用: $REMAIN，再次尝试终止..."
    kill -9 $REMAIN 2>/dev/null
    sleep 1
  else
    echo "[restart] 已终止旧服务进程: $PIDS"
  fi
else
  echo "[restart] 无旧服务进程（端口 3456 空闲）"
fi

# 2) 清理仍占用 chrome-profile 的残留 Chrome 进程
#    这些进程通常是上次停止服务时未能正常退出的浏览器实例，
#    若不清理，重新启动时会报
#    "Failed to create a ProcessSingleton ... profile is already in use"
echo "[restart] 第 2 步：清理占用 chrome-profile 的残留 Chrome 进程..."
STALE_PIDS=$(pgrep -f "$CHROME_PROFILE_DIR" 2>/dev/null | tr '\n' ' ')
if [ -n "$STALE_PIDS" ]; then
  echo "[restart] 发现残留 Chrome 进程: $STALE_PIDS"
  pkill -9 -f "$CHROME_PROFILE_DIR" 2>/dev/null
  sleep 1
  LEFT=$(pgrep -f "$CHROME_PROFILE_DIR" 2>/dev/null | tr '\n' ' ')
  if [ -n "$LEFT" ]; then
    echo "[restart] 警告：仍有进程未退出: $LEFT（可稍后手动关闭）"
  else
    echo "[restart] 残留 Chrome 进程已全部清理，profile 锁已释放"
  fi
else
  echo "[restart] 无残留 Chrome 进程，profile 未被占用"
fi

# 3) 启动服务
echo "[restart] 第 3 步：启动服务..."
cd "$PROJECT_DIR" || exit 1
nohup npm start > /dev/null 2>&1 &

NEW_PID=$!
echo "[restart] 服务已后台启动 (PID: $NEW_PID)"
echo "[restart] 管理面板: http://127.0.0.1:3456"
echo "[restart] 下一步：打开管理面板，点击顶部「启动服务」开始自动回复。"
echo "[restart] 提示：若面板仍提示 Chrome 配置文件被占用，请再次运行 bash restart.sh。"
