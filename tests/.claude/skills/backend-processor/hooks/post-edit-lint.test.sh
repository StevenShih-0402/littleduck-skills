#!/usr/bin/env bash
# tests/.claude/skills/backend-processor/hooks/post-edit-lint.test.sh
# 後端編輯後 lint hook 的測試：在離被編輯檔案最近的 lint 設定目錄（pants 或含 [tool.ruff] 的 pyproject.toml）跑 lint，找不到才退回 git 根目錄。
#
# 執行：bash tests/.claude/skills/backend-processor/hooks/post-edit-lint.test.sh
# 以假的 lint 指令（記錄執行目錄與參數）代替 pants／ruff。
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
HOOK="${REPO_DIR}/.claude/skills/backend-processor/hooks/post-edit-lint.sh"

PASSED=0
FAILED=0
CURRENT_OK=1

setup_sandbox() {
    WORK="$(mktemp -d)"
    PROJ="${WORK}/proj"
    LOG="${WORK}/lint.log"
    mkdir -p "${PROJ}/backend/app" "${PROJ}/frontend"
    git -C "${PROJ}" init -q
    printf 'x = 1\n' >"${PROJ}/backend/app/views.py"
    FAKE_LINT="${WORK}/fake-lint"
    printf '#!/usr/bin/env bash\nprintf "%%s|%%s\\n" "$PWD" "$*" >>"%s"\necho "lint 輸出"\nexit "${FAKE_EXIT:-0}"\n' "${LOG}" >"${FAKE_LINT}"
    chmod +x "${FAKE_LINT}"
    : >"${LOG}"
}

teardown_sandbox() {
    rm -rf "${WORK}"
}

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

test_subdir_ruff_config_runs_lint_in_subdir() {
    # Arrange：ruff 設定在後端子目錄
    printf '[tool.ruff]\nline-length = 100\n' >"${PROJ}/backend/pyproject.toml"
    # Act
    run_hook "${PROJ}/backend/app/views.py" LITTLEDUCK_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "${PROJ}/backend|app/views.py" "執行目錄與相對路徑"
}

test_pyproject_without_ruff_is_not_a_lint_root() {
    # Arrange：子目錄的 pyproject.toml 沒有 [tool.ruff]，根目錄有
    printf '[project]\nname = "x"\n' >"${PROJ}/backend/pyproject.toml"
    printf '[tool.ruff]\n' >"${PROJ}/pyproject.toml"
    # Act
    run_hook "${PROJ}/backend/app/views.py" LITTLEDUCK_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "$(cat "${LOG}")" "${PROJ}|backend/app/views.py" "應往上找到根目錄"
}

test_env_command_without_config_runs_in_repo_root() {
    run_hook "${PROJ}/backend/app/views.py" LITTLEDUCK_LINT_CMD="${FAKE_LINT}"
    assert_eq "$(cat "${LOG}")" "${PROJ}|backend/app/views.py" "退回 git 根目錄"
}

test_no_config_and_no_command_does_nothing() {
    run_hook "${PROJ}/backend/app/views.py"
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "" "不應執行 lint"
}

test_autodetect_uses_subdir_pants() {
    # Arrange：後端子目錄有可執行的 pants（假的）
    cp "${FAKE_LINT}" "${PROJ}/backend/pants"
    # Act
    run_hook "${PROJ}/backend/app/views.py"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${LOG}")" "${PROJ}/backend|lint app/views.py" "以子目錄的 ./pants lint 執行"
}

test_lint_failure_is_fed_back() {
    printf '[tool.ruff]\n' >"${PROJ}/backend/pyproject.toml"
    run_hook "${PROJ}/backend/app/views.py" LITTLEDUCK_LINT_CMD="${FAKE_LINT}" FAKE_EXIT=1
    assert_eq "${CODE}" 2 "結束碼"
    assert_contains "${OUT}" "未通過" "回饋失敗"
}

test_model_edit_prints_migration_reminder() {
    # Arrange
    printf '[tool.ruff]\n' >"${PROJ}/backend/pyproject.toml"
    printf 'class A: pass\n' >"${PROJ}/backend/app/models.py"
    # Act
    run_hook "${PROJ}/backend/app/models.py" LITTLEDUCK_LINT_CMD="${FAKE_LINT}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "migration" "提醒 migration"
}

test_non_python_file_is_ignored() {
    printf 'x\n' >"${PROJ}/backend/README.md"
    run_hook "${PROJ}/backend/README.md" LITTLEDUCK_LINT_CMD="${FAKE_LINT}"
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
