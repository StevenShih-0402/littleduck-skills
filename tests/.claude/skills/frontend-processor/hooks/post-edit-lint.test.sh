#!/usr/bin/env bash
# tests/.claude/skills/frontend-processor/hooks/post-edit-lint.test.sh
# 前端編輯後 lint hook 的測試：在離被編輯檔案最近的 eslint 設定目錄跑 lint（fullstack 的前端子目錄），找不到才退回 git 根目錄。
#
# 執行：bash tests/.claude/skills/frontend-processor/hooks/post-edit-lint.test.sh
# 以假的 lint 指令（記錄執行目錄與參數）代替 eslint，不需要安裝 node 套件。
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
HOOK="${REPO_DIR}/.claude/skills/frontend-processor/hooks/post-edit-lint.sh"

PASSED=0
FAILED=0
CURRENT_OK=1

setup_sandbox() {
    WORK="$(mktemp -d)"
    PROJ="${WORK}/proj"
    LOG="${WORK}/lint.log"
    mkdir -p "${PROJ}/frontend/src" "${PROJ}/backend"
    git -C "${PROJ}" init -q
    printf 'export default 1\n' >"${PROJ}/frontend/src/App.tsx"
    # 假 lint：記錄「執行目錄|參數」，FAKE_EXIT 決定結束碼
    FAKE_LINT="${WORK}/fake-lint"
    printf '#!/usr/bin/env bash\nprintf "%%s|%%s\\n" "$PWD" "$*" >>"%s"\necho "lint 輸出"\nexit "${FAKE_EXIT:-0}"\n' "${LOG}" >"${FAKE_LINT}"
    chmod +x "${FAKE_LINT}"
    : >"${LOG}"
}

teardown_sandbox() {
    rm -rf "${WORK}"
}

# run_hook <檔案路徑> [環境變數…]：結果放在 OUT（stderr）與 CODE
run_hook() {
    local path="$1"
    shift
    OUT="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "${path}" |
        env "$@" bash "${HOOK}" 2>&1 >/dev/null)"
    CODE=$?
}

fail() {
    CURRENT_OK=0
    printf '    ✗ %s\n' "$1"
}
assert_eq() { [[ "$1" == "$2" ]] || fail "${3:-} 預期 [$2]，實際 [$1]"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "${3:-} 應包含 [$2]，實際：$1"; }

test_subdir_config_runs_lint_in_subdir() {
    # Arrange：eslint 設定在前端子目錄
    : >"${PROJ}/frontend/eslint.config.js"
    # Act
    run_hook "${PROJ}/frontend/src/App.tsx" LITTLEDUCK_FE_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "${PROJ}/frontend|src/App.tsx" "執行目錄與相對路徑"
}

test_root_config_runs_lint_in_repo_root() {
    # Arrange：eslint 設定在 repo 根目錄
    : >"${PROJ}/.eslintrc.json"
    # Act
    run_hook "${PROJ}/frontend/src/App.tsx" LITTLEDUCK_FE_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "$(cat "${LOG}")" "${PROJ}|frontend/src/App.tsx" "執行目錄與相對路徑"
}

test_env_command_without_config_runs_in_repo_root() {
    # Arrange：沒有任何 eslint 設定，但指定了指令
    # Act
    run_hook "${PROJ}/frontend/src/App.tsx" LITTLEDUCK_FE_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "$(cat "${LOG}")" "${PROJ}|frontend/src/App.tsx" "退回 git 根目錄"
}

test_no_config_and_no_command_does_nothing() {
    # Arrange：沒有設定、沒有指定指令
    # Act
    run_hook "${PROJ}/frontend/src/App.tsx"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "" "不應執行 lint"
}

test_autodetect_uses_subdir_local_eslint() {
    # Arrange：前端子目錄有設定與本地 eslint（假的）
    : >"${PROJ}/frontend/eslint.config.js"
    mkdir -p "${PROJ}/frontend/node_modules/.bin"
    cp "${FAKE_LINT}" "${PROJ}/frontend/node_modules/.bin/eslint"
    # Act
    run_hook "${PROJ}/frontend/src/App.tsx"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "${PROJ}/frontend|src/App.tsx" "以子目錄的本地 eslint 執行"
}

test_lint_failure_is_fed_back() {
    # Arrange
    : >"${PROJ}/frontend/eslint.config.js"
    # Act
    run_hook "${PROJ}/frontend/src/App.tsx" LITTLEDUCK_FE_LINT_CMD="${FAKE_LINT}" FAKE_EXIT=1
    # Assert
    assert_eq "${CODE}" 2 "結束碼"
    assert_contains "${OUT}" "未通過" "回饋失敗"
    assert_contains "${OUT}" "lint 輸出" "附上 lint 輸出"
}

test_unsupported_file_is_ignored() {
    # Arrange
    : >"${PROJ}/frontend/eslint.config.js"
    printf 'x\n' >"${PROJ}/frontend/README.md"
    # Act
    run_hook "${PROJ}/frontend/README.md" LITTLEDUCK_FE_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "" "不應執行 lint"
}

main() {
    local fn
    for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
        CURRENT_OK=1
        setup_sandbox
        "${fn}"
        teardown_sandbox
        if [[ "${CURRENT_OK}" == "1" ]]; then
            PASSED=$((PASSED + 1))
            printf '  ✓ %s\n' "${fn}"
        else
            FAILED=$((FAILED + 1))
            printf '  ✗ %s\n' "${fn}"
        fi
    done
    printf '\n%d passed, %d failed\n' "${PASSED}" "${FAILED}"
    [[ "${FAILED}" == "0" ]]
}

main "$@"
