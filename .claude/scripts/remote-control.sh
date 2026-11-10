#!/usr/bin/env bash
# .claude/scripts/remote-control.sh
# 在背景 tmux 啟動、查詢、停止與接回本 repo 的 Claude Code Remote Control server（SDP-112）。
#
# 用法：.claude/scripts/remote-control.sh [start|status|stop|attach]
#   start（預設）：前置檢查通過後，在 tmux session rc-<repo 名> 啟動 claude remote-control
#   status       ：server 執行中結束碼 0，否則 1
#   stop         ：送 Ctrl-C 讓 server 正常結束，逾時（RC_STOP_TIMEOUT 秒，預設 5）則強制結束 session
#   attach       ：接回 server 畫面（看 QR code、回答首次啟動的確認提示），以 Ctrl-b d 離開
#
# 本檔在 code_city、littleduck-skills、littleduck_website、luke、mygo_v2_anon 內容相同，修改時一起改。
set -euo pipefail

readonly SPAWN_MODE="same-dir"
readonly PERMISSION_MODE="auto"
readonly OFFICIAL_BASE_URL_PATTERN='^https://api\.anthropic\.com/?$'
readonly INCOMPATIBLE_ENV_VARS=(
    ANTHROPIC_API_KEY
    ANTHROPIC_AUTH_TOKEN
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
    DISABLE_GROWTHBOOK
)

usage() {
    # 只用 bash 內建指令輸出，不依賴 cat
    printf '%s\n' \
        "用法：.claude/scripts/remote-control.sh [start|status|stop|attach]" \
        "" \
        "  start   在背景 tmux 啟動 Remote Control server（不帶子命令時的預設）" \
        "  status  查詢 server 是否執行中（執行中結束碼 0）" \
        "  stop    停止 server" \
        "  attach  接回 server 畫面，以 Ctrl-b d 離開" \
        "" \
        "說明文件：docs/remote-control.md"
}

# 取得 repo 根目錄，設定 REPO_ROOT、REPO_NAME、SESSION_NAME
resolve_root() {
    if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        echo "錯誤：目前目錄不在 git repo 內，請在 repo 內執行。" >&2
        exit 1
    fi
    REPO_NAME="${REPO_ROOT##*/}"
    # tmux 的 session 名稱不接受 . 與 :
    local safe_name="${REPO_NAME//[.:]/_}"
    SESSION_NAME="rc-${safe_name}"
}

has_tmux() { command -v tmux >/dev/null 2>&1; }

is_running() {
    has_tmux && tmux has-session -t "=${SESSION_NAME}" 2>/dev/null
}

# 檢查 Remote Control 的必要條件，把所有不符的項目一次列出
preflight() {
    local problems=()

    has_tmux || problems+=("找不到 tmux：請先安裝（sudo apt install tmux）。")

    if ! command -v claude >/dev/null 2>&1; then
        problems+=("找不到 claude：請先安裝 Claude Code CLI。")
    else
        local auth_json
        auth_json="$(claude auth status 2>/dev/null || true)"
        if ! grep -Eq '"authMethod"[[:space:]]*:[[:space:]]*"claude\.ai"' <<<"${auth_json}"; then
            problems+=("未以 claude.ai 帳號登入：Remote Control 只支援 claude.ai 訂閱帳號，請執行 claude auth login。")
        fi
    fi

    local var
    for var in "${INCOMPATIBLE_ENV_VARS[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            problems+=("環境變數 ${var} 會讓 Remote Control 無法使用，請先 unset ${var}。")
        fi
    done

    local base_url="${ANTHROPIC_BASE_URL:-}"
    if [[ -n "${base_url}" ]] && ! [[ "${base_url}" =~ ${OFFICIAL_BASE_URL_PATTERN} ]]; then
        problems+=("環境變數 ANTHROPIC_BASE_URL 指向 ${base_url}，Remote Control 只支援官方 API，請先 unset ANTHROPIC_BASE_URL。")
    fi

    if [[ ${#problems[@]} -gt 0 ]]; then
        echo "無法啟動 Remote Control，請先修正以下問題：" >&2
        local problem
        for problem in "${problems[@]}"; do
            echo "  - ${problem}" >&2
        done
        exit 1
    fi
}

cmd_start() {
    if is_running; then
        echo "Remote Control server 已在執行（tmux session：${SESSION_NAME}）。"
        echo "接回畫面：.claude/scripts/remote-control.sh attach"
        return 0
    fi

    preflight

    tmux new-session -d -s "${SESSION_NAME}" -c "${REPO_ROOT}" \
        "claude remote-control --name ${REPO_NAME} --spawn ${SPAWN_MODE} --permission-mode ${PERMISSION_MODE}"

    echo "已在背景啟動 Remote Control server（tmux session：${SESSION_NAME}）。"
    echo "首次啟動請接回畫面回答確認提示，並用手機掃 QR code："
    echo "  .claude/scripts/remote-control.sh attach   （以 Ctrl-b d 離開，server 會繼續執行）"
}

cmd_status() {
    if is_running; then
        echo "Remote Control server 執行中（tmux session：${SESSION_NAME}）。"
        return 0
    fi
    echo "Remote Control server 未執行。"
    return 1
}

cmd_stop() {
    if ! is_running; then
        echo "Remote Control server 未執行，不需要停止。"
        return 0
    fi

    # 先送 Ctrl-C 讓 claude 正常結束（session 隨之消失），逾時才強制結束
    tmux send-keys -t "=${SESSION_NAME}:" C-c
    local timeout="${RC_STOP_TIMEOUT:-5}"
    local tries=$((timeout * 5))
    while ((tries > 0)) && is_running; do
        sleep 0.2
        tries=$((tries - 1))
    done
    if is_running; then
        tmux kill-session -t "=${SESSION_NAME}"
    fi
    echo "已停止 Remote Control server。"
}

cmd_attach() {
    if ! is_running; then
        echo "Remote Control server 未執行，請先執行：.claude/scripts/remote-control.sh start" >&2
        return 1
    fi
    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "=${SESSION_NAME}"
    else
        tmux attach-session -t "=${SESSION_NAME}"
    fi
}

main() {
    local subcommand="${1:-start}"
    case "${subcommand}" in
        start | status | stop | attach) ;;
        -h | --help | help)
            usage
            return 0
            ;;
        *)
            echo "未知的子命令：${subcommand}" >&2
            usage >&2
            return 2
            ;;
    esac

    resolve_root
    "cmd_${subcommand}"
}

main "$@"
