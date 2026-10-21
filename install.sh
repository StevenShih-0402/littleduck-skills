#!/usr/bin/env sh
# littleduck-skills 安裝/更新腳本
#
# 依選項把本 repo 的可散佈資產同步進目標專案：
#   <skill 名稱>  該 skill 與它在 install.deps 宣告的相依（其他 skill、指令、linear/ 模板）
#   all           除 agent-team 以外的全部 skills、commands、linear/ 模板
#   agent-team    多 Agent 協作中樞（team-hq）骨架；已存在的檔案一律略過
# 除 agent-team 外，目標專案沒有 CLAUDE.md 時會一併建立通用開發習慣的 CLAUDE.md（已存在則不覆寫）。
#
# 用法：
#   ./install.sh <選項> [目標專案路徑]
#   ./install.sh --list        列出可選項
#   ./install.sh --help
#
# 未給路徑時，預設安裝到目前工作目錄（$PWD）。
# 可重複執行：重跑即就地更新，不會產生重複或巢狀副本。
# tab 補齊：在 ~/.bashrc 加入 `source <本 repo>/completions/install.bash`。

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
DEPS_FILE="$REPO_DIR/install.deps"
KIT_DIR="$REPO_DIR/agent-team"

# --- 可選項：.claude/skills/ 下的目錄名 + all + agent-team ---
list_names() {
  for dir in "$REPO_DIR"/.claude/skills/*/; do
    [ -d "$dir" ] && basename "$dir"
  done
  echo all
  echo agent-team
}

usage() {
  echo "用法：$0 <選項> [目標專案路徑]"
  echo
  echo "選項（必填，擇一）："
  list_names | sed 's/^/  /'
  echo
  echo "  all        = 除 agent-team 以外全部"
  echo "  agent-team = 多 Agent 協作中樞骨架（已存在的檔案不覆寫）"
}

# --- 解析參數 ---
case ${1:-} in
  -h|--help) usage; exit 0 ;;
  --list) list_names; exit 0 ;;
  '')
    echo "錯誤：缺少必填的安裝選項。" >&2
    echo >&2
    usage >&2
    exit 1
    ;;
esac

SELECTION=$1

is_skill() {
  case $1 in
    *[!a-z0-9-]*|'') return 1 ;;
  esac
  [ -d "$REPO_DIR/.claude/skills/$1" ]
}

case $SELECTION in
  all|agent-team) ;;
  *)
    if ! is_skill "$SELECTION"; then
      echo "錯誤：未知的安裝選項：$SELECTION" >&2
      if [ -d "$SELECTION" ]; then
        echo "（第一個參數現在是安裝選項；要全部安裝到該目錄請用：$0 all $SELECTION）" >&2
      fi
      echo >&2
      usage >&2
      exit 1
    fi
    ;;
esac

# --- 解析目標專案路徑（第二個參數，預設 $PWD）---
TARGET=${2:-$PWD}
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
echo "安裝選項  : $SELECTION"
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

# install_claude_md：目標沒有 CLAUDE.md 才建立，已存在一律不動
install_claude_md() {
  if [ -e "$TARGET/CLAUDE.md" ]; then
    echo "  略過 CLAUDE.md（目標已存在，不覆寫；通用版本見 $REPO_DIR/CLAUDE.md）"
  else
    cp "$REPO_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
    echo "  已建立 CLAUDE.md"
  fi
}

# install_kit：逐檔複製 agent-team 骨架到目標根目錄，已存在的檔案略過
install_kit() {
  skipped=0
  # 檔名不含空白與換行（由本 repo 控制），可安全逐行讀取
  file_list=$(mktemp)
  (cd "$KIT_DIR" && find . -type f | sed 's|^\./||' | sort) > "$file_list"
  while IFS= read -r rel; do
    if [ -e "$TARGET/$rel" ]; then
      echo "  略過（已存在）：$rel"
      skipped=$((skipped + 1))
    else
      mkdir -p "$(dirname "$TARGET/$rel")"
      cp "$KIT_DIR/$rel" "$TARGET/$rel"
      echo "  已建立：$rel"
    fi
  done < "$file_list"
  rm -f "$file_list"
  echo
  echo "完成：agent-team 骨架已安裝到 $TARGET（略過 $skipped 個既有檔案）"
  echo "提示：範本更新不會覆寫已存在的檔案；要取新版請先移除或改名舊檔再重跑。"
}

# deps_of <skill>：印出 install.deps 中該 skill 宣告的資產，一行一個
deps_of() {
  [ -f "$DEPS_FILE" ] || return 0
  sed -n "s/^$1:[[:space:]]*//p" "$DEPS_FILE" | tr -s ' \t' '\n\n' | sed '/^$/d'
}

# install_selected：遞迴展開相依（去重）後逐項同步
install_selected() {
  queue=$1
  seen=' '
  commands=''
  dirs=''
  while [ -n "$queue" ]; do
    # 取出佇列第一個 skill
    name=${queue%% *}
    if [ "$name" = "$queue" ]; then queue=''; else queue=${queue#* }; fi
    case $seen in *" $name "*) continue ;; esac
    if ! is_skill "$name"; then
      echo "錯誤：install.deps 引用了不存在的 skill：$name" >&2
      exit 1
    fi
    seen="$seen$name "
    for asset in $(deps_of "$name"); do
      case $asset in
        skill:*) queue="${queue:+$queue }${asset#skill:}" ;;
        commands:*) commands="$commands ${asset#commands:}" ;;
        dir:*) dirs="$dirs ${asset#dir:}" ;;
        *) echo "錯誤：install.deps 格式錯誤：$name → $asset" >&2; exit 1 ;;
      esac
    done
  done

  for name in $(echo "$seen" | tr ' ' '\n' | sed '/^$/d' | sort); do
    copy_contents "$REPO_DIR/.claude/skills/$name" "$TARGET/.claude/skills/$name"
    echo "  已同步 .claude/skills/$name/"
  done
  for rel in $(echo "$commands" | tr ' ' '\n' | sed '/^$/d' | sort -u); do
    mkdir -p "$(dirname "$TARGET/.claude/commands/$rel")"
    cp "$REPO_DIR/.claude/commands/$rel" "$TARGET/.claude/commands/$rel"
    echo "  已同步 .claude/commands/$rel"
  done
  for dir in $(echo "$dirs" | tr ' ' '\n' | sed '/^$/d' | sort -u); do
    copy_contents "$REPO_DIR/$dir" "$TARGET/$dir"
    echo "  已同步 $dir/"
  done
}

case $SELECTION in
  agent-team)
    install_kit
    ;;
  all)
    copy_contents "$REPO_DIR/.claude/skills"   "$TARGET/.claude/skills"
    echo "  已同步 .claude/skills/"
    copy_contents "$REPO_DIR/.claude/commands" "$TARGET/.claude/commands"
    echo "  已同步 .claude/commands/"
    copy_contents "$REPO_DIR/linear"           "$TARGET/linear"
    echo "  已同步 linear/"
    install_claude_md
    echo
    echo "完成：全部 skills、commands、linear 模板已安裝/更新到 $TARGET"
    ;;
  *)
    install_selected "$SELECTION"
    install_claude_md
    echo
    echo "完成：$SELECTION 及其相依已安裝/更新到 $TARGET"
    ;;
esac
