#!/usr/bin/env sh
# littleduck-skills 安裝/更新腳本
#
# 把本 repo 的可散佈資產同步進目標專案：
#   - .claude/skills/    （所有 skill）
#   - .claude/commands/  （opsx 等指令）
#   - linear/            （Linear 回填模板）
#
# 用法：
#   ./install.sh [目標專案路徑]
#   curl -fsSL <raw-url>/install.sh | sh -s -- /path/to/project
#
# 未給路徑時，預設安裝到目前工作目錄（$PWD）。
# 可重複執行：重跑即就地更新，不會產生重複或巢狀副本。

set -eu

# --- 解析本腳本（即本 repo）所在目錄，確保複製來源是 repo 本身而非 $PWD ---
script_path=$0
# 解析符號連結，取得真實路徑
while [ -L "$script_path" ]; do
  link_target=$(readlink "$script_path")
  case $link_target in
    /*) script_path=$link_target ;;
    *) script_path=$(dirname "$script_path")/$link_target ;;
  esac
done
REPO_DIR=$(cd "$(dirname "$script_path")" && pwd)

# --- 解析目標專案路徑（第一個參數，預設 $PWD）---
TARGET=${1:-$PWD}
if [ ! -d "$TARGET" ]; then
  echo "錯誤：目標目錄不存在：$TARGET" >&2
  exit 1
fi
TARGET=$(cd "$TARGET" && pwd)

if [ "$TARGET" = "$REPO_DIR" ]; then
  echo "錯誤：目標與來源 repo 相同（$REPO_DIR），無須安裝。" >&2
  exit 1
fi

echo "來源 repo : $REPO_DIR"
echo "安裝目標  : $TARGET"
echo

# --- 複製工具：優先 rsync，否則退回 cp -R ---
# copy_contents <來源目錄> <目標目錄>
# 複製「來源目錄的內容」到目標目錄（非目錄本身），避免 dest/src/src 的巢狀副本。
copy_contents() {
  src=$1
  dest=$2
  if [ ! -d "$src" ]; then
    echo "  略過（來源不存在）：$src"
    return 0
  fi
  mkdir -p "$dest"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src/" "$dest/"
  else
    # cp -R src/. dest/ 會複製內容而非 src 目錄本身
    cp -R "$src/." "$dest/"
  fi
}

copy_contents "$REPO_DIR/.claude/skills"   "$TARGET/.claude/skills"
echo "  已同步 .claude/skills/"
copy_contents "$REPO_DIR/.claude/commands" "$TARGET/.claude/commands"
echo "  已同步 .claude/commands/"
copy_contents "$REPO_DIR/linear"           "$TARGET/linear"
echo "  已同步 linear/"

echo
echo "完成：skills、commands、linear 模板已安裝/更新到 $TARGET"
