#!/usr/bin/env sh
# littleduck-skills 安裝/更新腳本
#
# 依選項把本 repo 的可散佈資產同步進目標專案：
#   <skill 名稱>  該 skill 與它在 install.deps 宣告的相依（其他 skill、指令、linear/ 模板、spec-sync/ 說明）
#   all           除 agent-team 以外的全部 skills、commands、linear/ 模板、spec-sync/ 說明
#   agent-team    多 Agent 協作中樞（team-hq）骨架（已存在的檔案一律略過），
#                 加上 install.deps 的 agent-team 列宣告的角色 skill 及其相依（每次覆寫更新）
# 除 agent-team 外，目標專案沒有 CLAUDE.md 時會一併建立通用開發習慣的 CLAUDE.md（已存在則不覆寫）。
#
# 用法（遠端，免 clone）：
#   curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- <選項> [目標專案路徑]
#   以環境變數 LITTLEDUCK_REF 指定要下載的分支或 tag（預設 main），例：
#   curl -fsSL <同上> | LITTLEDUCK_REF=<tag> sh -s -- all
#
# 用法（本地 clone）：
#   ./install.sh <選項> [目標專案路徑]
#   ./install.sh --list        列出可選項
#   ./install.sh --help
#
# 腳本旁找不到本 repo 的資產時（例：以 curl | sh 執行）即進入遠端模式：
# 從 GitHub 下載 repo 壓縮檔到暫存目錄作為來源，結束時清除；需要 curl 或 wget，以及 tar。
# 未給路徑時，預設安裝到目前工作目錄（$PWD）。
# 可重複執行：重跑即就地更新，不會產生重複或巢狀副本。
# tab 補齊（僅本地 clone）：在 ~/.bashrc 加入 `source <本 repo>/completions/install.bash`。

set -eu

GITHUB_REPO=StevenShih-0402/littleduck-skills
REMOTE_REF=${LITTLEDUCK_REF:-main}
RAW_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/install.sh"

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

# is_repo <目錄>：同時有 install.deps 與 .claude/skills/ 才視為本 repo（只看其一會把目標專案誤判為來源）
is_repo() {
  [ -f "$1/install.deps" ] && [ -d "$1/.claude/skills" ]
}

if is_repo "$REPO_DIR"; then
  REMOTE=0
  INVOKE=$0
else
  REMOTE=1
  INVOKE="curl -fsSL $RAW_URL | sh -s --"
fi

# --- 下載前就能做的檢查：目標目錄存在（缺選項／--help／--list 需要可選清單，留到取得來源後）---
case ${1:-} in
  -h|--help|--list|'') ;;
  *)
    if [ ! -d "${2:-$PWD}" ]; then
      echo "錯誤：目標目錄不存在：${2:-$PWD}" >&2
      exit 1
    fi
    ;;
esac

# fetch_remote：下載 REMOTE_REF 的 repo 壓縮檔並解壓到暫存目錄，將 REPO_DIR 指向解壓結果
fetch_remote() {
  if command -v curl >/dev/null 2>&1; then
    downloader=curl
  elif command -v wget >/dev/null 2>&1; then
    downloader=wget
  else
    echo "錯誤：遠端安裝需要 curl 或 wget，兩者皆找不到。" >&2
    exit 1
  fi
  if ! command -v tar >/dev/null 2>&1; then
    echo "錯誤：遠端安裝需要 tar 解壓下載的檔案。" >&2
    exit 1
  fi

  # 先設 trap 再建目錄，避免兩者之間被中斷而留下暫存目錄
  # 被訊號中斷時 EXIT trap 不會執行，需逐一攔截（PIPE：輸出被 head 等提前關閉；HUP：關閉終端機）
  TMP_DIR=
  trap 'cleanup' EXIT
  trap 'cleanup; exit 129' HUP
  trap 'cleanup; exit 130' INT
  trap 'cleanup; exit 141' PIPE
  trap 'cleanup; exit 143' TERM
  TMP_DIR=$(mktemp -d)

  url="https://codeload.github.com/$GITHUB_REPO/tar.gz/$REMOTE_REF"
  echo "下載 github.com/$GITHUB_REPO@$REMOTE_REF ..." >&2
  # 先存檔再解壓，兩步各自檢查退出碼（POSIX sh 沒有 pipefail，pipe 會吞掉下載失敗）
  if [ "$downloader" = curl ]; then
    curl -fsSL "$url" -o "$TMP_DIR/src.tar.gz" || download_failed
  else
    wget -q -O "$TMP_DIR/src.tar.gz" "$url" || download_failed
  fi
  mkdir "$TMP_DIR/src"
  tar -xzf "$TMP_DIR/src.tar.gz" -C "$TMP_DIR/src" || download_failed

  # 頂層目錄名隨 ref 而變（ref 中的 / 會被換成 -），不猜名稱，取唯一的子目錄
  set -- "$TMP_DIR"/src/*/
  if [ $# -ne 1 ] || ! is_repo "${1%/}"; then
    download_failed
  fi
  REPO_DIR=${1%/}
}

cleanup() {
  if [ -n "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}

download_failed() {
  echo "錯誤：無法取得 github.com/$GITHUB_REPO@$REMOTE_REF（網路問題，或分支／tag 不存在）。" >&2
  echo "可改用本地 clone：git clone https://github.com/$GITHUB_REPO.git 後執行 <clone 路徑>/install.sh <選項> [目標專案路徑]" >&2
  exit 1
}

if [ "$REMOTE" = 1 ]; then
  fetch_remote
  SOURCE_DESC="github.com/$GITHUB_REPO@$REMOTE_REF"
else
  SOURCE_DESC=$REPO_DIR
fi
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
  echo "用法：$INVOKE <選項> [目標專案路徑]"
  if [ "$REMOTE" = 1 ]; then
    echo "      以 LITTLEDUCK_REF=<分支或 tag> 指定下載版本（預設 main）"
  fi
  echo
  echo "選項（必填，擇一）："
  list_names | sed 's/^/  /'
  echo
  echo "  all        = 除 agent-team 以外全部"
  echo "  agent-team = 多 Agent 協作中樞骨架（已存在的檔案不覆寫）＋角色 skill"
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
        echo "（第一個參數現在是安裝選項；要全部安裝到該目錄請用：$INVOKE all $SELECTION）" >&2
      fi
      echo >&2
      usage >&2
      exit 1
    fi
    ;;
esac

# --- 解析目標專案路徑（第二個參數，預設 $PWD；存在與否已在取得來源前檢查）---
TARGET=$(cd "${2:-$PWD}" && pwd)

if [ "$TARGET" = "$REPO_DIR" ]; then
  echo "錯誤：目標與來源 repo 相同（$REPO_DIR），無須安裝。" >&2
  exit 1
fi

echo "來源 repo : $SOURCE_DESC"
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

# kit_skills：印出 install.deps 中 agent-team 列宣告的角色 skill，一行一個；該列只能寫 skill:
kit_skills() {
  for asset in $(deps_of agent-team); do
    case $asset in
      skill:*) echo "${asset#skill:}" ;;
      *) echo "錯誤：install.deps 的 agent-team 列只能寫 skill:，發現：$asset" >&2; exit 1 ;;
    esac
  done
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
    # 先讀清單再裝骨架：agent-team 列格式錯誤時，指令替換失敗會讓 set -e 在寫入任何檔案前中止
    role_skills=$(kit_skills)
    install_kit
    if [ -n "$role_skills" ]; then
      echo
      echo "安裝角色 skill（每次覆寫更新）："
      install_selected "$(echo "$role_skills" | tr '\n' ' ' | sed 's/ *$//')"
      echo
      echo "完成：角色 skill 及其相依已安裝/更新到 $TARGET"
    fi
    ;;
  all)
    copy_contents "$REPO_DIR/.claude/skills"   "$TARGET/.claude/skills"
    echo "  已同步 .claude/skills/"
    copy_contents "$REPO_DIR/.claude/commands" "$TARGET/.claude/commands"
    echo "  已同步 .claude/commands/"
    copy_contents "$REPO_DIR/linear"           "$TARGET/linear"
    echo "  已同步 linear/"
    copy_contents "$REPO_DIR/spec-sync"        "$TARGET/spec-sync"
    echo "  已同步 spec-sync/"
    install_claude_md
    echo
    echo "完成：全部 skills、commands、linear 模板、spec-sync 說明已安裝/更新到 $TARGET"
    ;;
  *)
    install_selected "$SELECTION"
    install_claude_md
    echo
    echo "完成：$SELECTION 及其相依已安裝/更新到 $TARGET"
    ;;
esac
