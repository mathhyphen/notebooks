#!/usr/bin/env bash
set -euo pipefail

REMOTE="${1:-}"
MSG="${2:-}"

# 进入脚本所在仓库根目录（兼容直接在仓库中运行）
cd "$(dirname "$0")/.."

# 初始化仓库（若未初始化）
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[info] 初始化 git 仓库"
  git init
fi

# 确定/创建分支
branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo main)
if ! git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "[info] 切换到分支：$branch"
  git checkout -B "$branch"
fi

# 暂存并提交
git add -A
if ! git diff --cached --quiet; then
  if [[ -z "$MSG" ]]; then
    MSG="chore: update articles and scripts ($(date '+%Y-%m-%d %H:%M'))"
  fi
  echo "[info] 提交：$MSG"
  git commit -m "$MSG"
else
  echo "[info] 无变更需要提交"
fi

# 配置 remote（如提供）
if [[ -n "$REMOTE" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    echo "[info] 更新远程 origin=$REMOTE"
    git remote set-url origin "$REMOTE"
  else
    echo "[info] 添加远程 origin=$REMOTE"
    git remote add origin "$REMOTE"
  fi
fi

# 推送到远程
if git remote get-url origin >/dev/null 2>&1; then
  echo "[info] 推送到 origin/$branch"
  git push -u origin "$branch"
else
  echo "[error] 未配置远程 origin。请提供远程地址，例如：\n  ./scripts/push.sh git@github.com:<user>/<repo>.git 'commit message'"
  exit 2
fi