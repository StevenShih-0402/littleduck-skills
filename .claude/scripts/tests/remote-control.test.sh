#!/usr/bin/env bash
# .claude/scripts/tests/remote-control.test.sh
# remote-control.sh 的測試：以假的 claude / tmux 驗證各子命令的結束碼、輸出與送給 tmux 的參數。
#
# 執行：bash .claude/scripts/tests/remote-control.test.sh
# 每個 test_* 在獨立的暫存目錄執行，PATH 只含沙箱 bin，因此不會碰到真的 tmux 或 claude。
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$(cd "${TEST_DIR}/.." && pwd)/remote-control.sh"
BASH_BIN="$(command -v bash)"

PASSED=0
FAILED=0
FAILED_NAMES=()
CURRENT_TEST=""
CURRENT_OK=1

# ---------- 沙箱 ----------

# 建立暫存 git repo（目錄名 myrepo）與沙箱 bin：只放 git、grep 與假的 claude、tmux
setup_sandbox() {
    WORK="$(mktemp -d)"
    REPO="${WORK}/myrepo"
    BIN="${WORK}/bin"
    STATE="${WORK}/state"
    LOG="${WORK}/tmux.log"
    mkdir -p "${REPO}/sub/dir" "${BIN}" "${STATE}"
    git -C "${REPO}" init -q
    : >"${LOG}"

    ln -s "$(command -v git)" "${BIN}/git"
    ln -s "$(command -v grep)" "${BIN}/grep"
    ln -s "$(command -v sleep)" "${BIN}/sleep"

    # 假 tmux：記錄參數；以 STATE/session 檔模擬 session 是否存在
    # 沙箱 PATH 找不到 env，shebang 改用 bash 的絕對路徑
    {
        printf '#!%s\n' "${BASH_BIN}"
        cat <<'EOF'
# 假執行檔自己需要 rm，PATH 補回系統路徑
PATH="/usr/bin:/bin"
printf '%s\n' "$*" >>"${FAKE_LOG}"
case "$1" in
    has-session) [[ -f "${FAKE_STATE}/session" ]] ;;
    new-session) : >"${FAKE_STATE}/session" ;;
    kill-session) rm -f "${FAKE_STATE}/session" ;;
    send-keys)
        # 模擬 claude 收到 Ctrl-C 後結束；FAKE_IGNORE_CTRL_C=1 時模擬卡住不結束
        [[ "${FAKE_IGNORE_CTRL_C:-0}" == "1" ]] || rm -f "${FAKE_STATE}/session" ;;
    attach-session | switch-client) exit 0 ;;
    *) exit 0 ;;
esac
EOF
    } >"${BIN}/tmux"
    # 假 claude：auth status 依 FAKE_AUTH_METHOD 回傳 JSON
    {
        printf '#!%s\n' "${BASH_BIN}"
        cat <<'EOF'
if [[ "$1 $2" == "auth status" ]]; then
    if [[ "${FAKE_AUTH_METHOD:-claude.ai}" == "none" ]]; then
        printf '{\n  "loggedIn": false\n}\n'
        exit 1
    fi
    printf '{\n  "loggedIn": true,\n  "authMethod": "%s"\n}\n' "${FAKE_AUTH_METHOD:-claude.ai}"
    exit 0
fi
exit 0
EOF
    } >"${BIN}/claude"
    chmod +x "${BIN}/tmux" "${BIN}/claude"
}

teardown_sandbox() {
    rm -rf "${WORK}"
}

# 在乾淨環境執行腳本；額外環境變數以 KEY=VALUE 形式放在 -- 之前
# 結果放在 OUT（stdout+stderr）與 CODE
run_script() {
    local cwd="$1"
    shift
    local envs=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do
        envs+=("$1")
        shift
    done
    [[ "${1:-}" == "--" ]] && shift
    OUT="$(cd "${cwd}" && env -i HOME="${WORK}" PATH="${BIN}" \
        FAKE_LOG="${LOG}" FAKE_STATE="${STATE}" RC_STOP_TIMEOUT=1 \
        "${envs[@]}" "${BASH_BIN}" "${SCRIPT}" "$@" 2>&1)"
    CODE=$?
}

session_exists() { [[ -f "${STATE}/session" ]]; }
mark_running() { : >"${STATE}/session"; }

# ---------- assert ----------

fail() {
    CURRENT_OK=0
    printf '    ✗ %s\n' "$1"
}
assert_eq() { [[ "$1" == "$2" ]] || fail "${3:-} 預期 [$2]，實際 [$1]"; }
assert_ne() { [[ "$1" != "$2" ]] || fail "${3:-} 不應為 [$2]"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "${3:-} 應包含 [$2]，實際：$1"; }
assert_not_contains() { [[ "$1" != *"$2"* ]] || fail "${3:-} 不應包含 [$2]"; }
tmux_log() { cat "${LOG}"; }

# ---------- start ----------

test_start_launches_server_in_background_tmux() {
    # Arrange：沙箱已就緒、server 未執行
    # Act
    run_script "${REPO}" -- start
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "new-session -d -s rc-myrepo -c ${REPO}" "tmux 參數"
    assert_contains "$(tmux_log)" "claude remote-control --name myrepo --spawn same-dir --permission-mode auto" "server 參數"
    assert_contains "${OUT}" "attach" "提示接回畫面"
}

test_no_subcommand_defaults_to_start() {
    # Arrange：server 未執行
    # Act
    run_script "${REPO}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "new-session" "應啟動 server"
}

test_start_from_subdirectory_uses_repo_root() {
    # Arrange：從子目錄執行
    # Act
    run_script "${REPO}/sub/dir" -- start
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "-c ${REPO} " "工作目錄應為 repo 根目錄"
}

test_start_when_already_running_does_not_launch_again() {
    # Arrange：server 已在執行
    mark_running
    # Act
    run_script "${REPO}" -- start
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "已在執行" "輸出"
    assert_not_contains "$(tmux_log)" "new-session" "不應再啟動"
}

test_start_outside_git_repo_fails() {
    # Arrange：在 git repo 以外執行
    local outside="${WORK}/outside"
    mkdir -p "${outside}"
    # Act
    run_script "${outside}" -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_not_contains "$(tmux_log)" "new-session" "不應啟動"
}

# ---------- 前置檢查 ----------

test_preflight_missing_tmux() {
    # Arrange
    rm "${BIN}/tmux"
    # Act
    run_script "${REPO}" -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "tmux" "應指出缺 tmux"
}

test_preflight_missing_claude() {
    # Arrange
    rm "${BIN}/claude"
    # Act
    run_script "${REPO}" -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "claude" "應指出缺 claude"
    assert_not_contains "$(tmux_log)" "new-session" "不應啟動"
}

test_preflight_not_logged_in() {
    # Arrange：未登入
    # Act
    run_script "${REPO}" FAKE_AUTH_METHOD=none -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "claude.ai" "應提示用 claude.ai 帳號登入"
    assert_not_contains "$(tmux_log)" "new-session" "不應啟動"
}

test_preflight_logged_in_with_api_key_method() {
    # Arrange：登入方式不是 claude.ai
    # Act
    run_script "${REPO}" FAKE_AUTH_METHOD=api_key -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "claude.ai" "應提示用 claude.ai 帳號登入"
    assert_not_contains "$(tmux_log)" "new-session" "不應啟動"
}

test_preflight_rejects_each_incompatible_env_var() {
    local var
    for var in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC DISABLE_GROWTHBOOK; do
        # Arrange：每輪清空 tmux 記錄
        : >"${LOG}"
        # Act
        run_script "${REPO}" "${var}=1" -- start
        # Assert
        assert_ne "${CODE}" 0 "${var} 結束碼"
        assert_contains "${OUT}" "${var}" "${var} 應列出變數名"
        assert_not_contains "$(tmux_log)" "new-session" "${var} 不應啟動"
    done
}

test_preflight_rejects_custom_base_url() {
    # Arrange：指向代理
    # Act
    run_script "${REPO}" ANTHROPIC_BASE_URL=https://proxy.example.com -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "ANTHROPIC_BASE_URL" "應列出變數名"
    assert_not_contains "$(tmux_log)" "new-session" "不應啟動"
}

test_preflight_accepts_official_base_url() {
    # Arrange：指向官方 API
    # Act
    run_script "${REPO}" ANTHROPIC_BASE_URL=https://api.anthropic.com -- start
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "new-session" "應啟動"
}

test_preflight_lists_all_problems_at_once() {
    # Arrange：同時缺 tmux 又設了 API key
    rm "${BIN}/tmux"
    # Act
    run_script "${REPO}" ANTHROPIC_API_KEY=x -- start
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "tmux" "應列出缺 tmux"
    assert_contains "${OUT}" "ANTHROPIC_API_KEY" "應列出 API key"
}

# ---------- status ----------

test_status_running() {
    # Arrange
    mark_running
    # Act
    run_script "${REPO}" -- status
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "執行中" "輸出"
}

test_status_not_running() {
    # Arrange：server 未執行
    # Act
    run_script "${REPO}" -- status
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "未執行" "輸出"
}

# ---------- stop ----------

test_stop_running_server() {
    # Arrange
    mark_running
    # Act
    run_script "${REPO}" -- stop
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "send-keys" "應先送 Ctrl-C 讓 claude 正常結束"
    run_script "${REPO}" -- status
    assert_ne "${CODE}" 0 "停止後 status 應回報未執行"
}

test_stop_kills_session_when_claude_ignores_ctrl_c() {
    # Arrange：claude 收到 Ctrl-C 卻沒結束
    mark_running
    # Act
    run_script "${REPO}" FAKE_IGNORE_CTRL_C=1 -- stop
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "kill-session" "逾時後應強制結束"
    if session_exists; then fail "session 應已結束"; fi
}

test_stop_when_not_running_succeeds() {
    # Arrange：server 未執行
    # Act
    run_script "${REPO}" -- stop
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "未執行" "輸出"
    assert_not_contains "$(tmux_log)" "kill-session" "不應呼叫 kill-session"
}

# ---------- attach ----------

test_attach_running_server() {
    # Arrange
    mark_running
    # Act
    run_script "${REPO}" -- attach
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "attach-session -t =rc-myrepo" "應接回 session"
}

test_attach_inside_tmux_switches_client() {
    # Arrange：已在 tmux 裡
    mark_running
    # Act
    run_script "${REPO}" TMUX=/tmp/fake,1,0 -- attach
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "$(tmux_log)" "switch-client -t =rc-myrepo" "tmux 內應改用 switch-client"
}

test_attach_when_not_running_fails() {
    # Arrange：server 未執行
    # Act
    run_script "${REPO}" -- attach
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "start" "應提示先啟動"
    assert_not_contains "$(tmux_log)" "attach-session" "不應接回"
}

# ---------- 未知子命令 ----------

test_unknown_subcommand_prints_usage() {
    # Arrange
    mark_running
    # Act
    run_script "${REPO}" -- strat
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "用法" "應印出用法"
    assert_not_contains "$(tmux_log)" "new-session" "不應啟動"
    assert_not_contains "$(tmux_log)" "kill-session" "不應停止"
    session_exists || fail "server 狀態不應改變"
}

# ---------- 執行 ----------

main() {
    local fn
    for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
        CURRENT_TEST="${fn}"
        CURRENT_OK=1
        setup_sandbox
        "${fn}"
        teardown_sandbox
        if [[ "${CURRENT_OK}" == "1" ]]; then
            PASSED=$((PASSED + 1))
            printf '  ✓ %s\n' "${fn}"
        else
            FAILED=$((FAILED + 1))
            FAILED_NAMES+=("${fn}")
            printf '  ✗ %s\n' "${fn}"
        fi
    done
    printf '\n%d passed, %d failed\n' "${PASSED}" "${FAILED}"
    [[ "${FAILED}" == "0" ]]
}

main "$@"
