#!/usr/bin/env bash
# tests/agent-team-fullstack/guard-write-scope.test.sh
# fullstack kit 寫入範圍 hook 的測試：architect／integrator 的既有規則，以及 backend／frontend 依子目錄的限制。
#
# 執行：bash tests/agent-team-fullstack/guard-write-scope.test.sh
# 每個 test_* 在獨立的暫存專案執行：hook 複製到 <專案>/.claude/hooks/，worktree 建在 <專案>/wt/eng-1-x。
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK_SRC="${REPO_DIR}/agent-team-fullstack/.claude/hooks/guard-write-scope.sh"

PASSED=0
FAILED=0
CURRENT_OK=1

# ---------- 沙箱 ----------

# 寫入專案 CLAUDE.md；參數為「## agent-team 設定」段落內的欄位列
write_settings() {
    {
        printf '# 專案\n\n## agent-team 設定\n\n'
        printf '%s\n' "$@"
        printf '\n## 其他段落\n\n- **後端子目錄**：不應被讀到/\n'
    } >"${PROJECT}/CLAUDE.md"
}

setup_sandbox() {
    WORK="$(mktemp -d)"
    PROJECT="${WORK}/proj"
    WT="${PROJECT}/wt/eng-1-x"
    mkdir -p "${PROJECT}/.claude/hooks" "${WT}/backend" "${WT}/frontend" "${WT}/openspec/changes/eng-1-x"
    cp "${HOOK_SRC}" "${PROJECT}/.claude/hooks/guard-write-scope.sh"
    # worktree 根目錄以 .git 檔標示（git worktree 的實際形式）
    printf 'gitdir: %s/.git/worktrees/eng-1-x\n' "${PROJECT}" >"${WT}/.git"
    mkdir -p "${PROJECT}/.git"
    write_settings '- **結構**：fullstack' '- **後端子目錄**：`backend/`' '- **前端子目錄**：frontend/ <!-- 註解 -->'
}

teardown_sandbox() {
    rm -rf "${WORK}"
}

# 以模擬 hook JSON 執行；結果放在 OUT（stderr）與 CODE
run_hook() {
    local role="$1" path="$2"
    OUT="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "${path}" |
        bash "${PROJECT}/.claude/hooks/guard-write-scope.sh" "${role}" 2>&1 >/dev/null)"
    CODE=$?
}

# ---------- assert ----------

fail() {
    CURRENT_OK=0
    printf '    ✗ %s\n' "$1"
}
assert_eq() { [[ "$1" == "$2" ]] || fail "${3:-} 預期 [$2]，實際 [$1]"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "${3:-} 應包含 [$2]，實際：$1"; }

# ---------- architect ----------

test_architect_writes_code_is_denied() {
    # Arrange：無
    # Act
    run_hook architect "${WT}/backend/app/views.py"
    # Assert
    assert_eq "${CODE}" 2 "結束碼"
    assert_contains "${OUT}" "openspec/" "說明只能寫 openspec/"
}

test_architect_path_traversal_is_denied() {
    run_hook architect "${WT}/openspec/../backend/app.py"
    assert_eq "${CODE}" 2 "結束碼"
}

test_architect_writes_proposal() {
    run_hook architect "${WT}/openspec/changes/eng-1-x/proposal.md"
    assert_eq "${CODE}" 0 "結束碼"
}

# ---------- integrator ----------

test_integrator_edits_tasks_is_denied() {
    run_hook integrator "${WT}/openspec/changes/eng-1-x/tasks.md"
    assert_eq "${CODE}" 2 "結束碼"
}

test_integrator_updates_handoff() {
    run_hook integrator "${WT}/openspec/changes/eng-1-x/handoff.md"
    assert_eq "${CODE}" 0 "結束碼"
}

test_integrator_syncs_main_specs() {
    run_hook integrator "${WT}/openspec/specs/orders/spec.md"
    assert_eq "${CODE}" 0 "結束碼"
}

# ---------- backend／frontend ----------

test_backend_writes_backend_subdir() {
    run_hook backend "${WT}/backend/internal/order.go"
    assert_eq "${CODE}" 0 "結束碼"
}

test_backend_writes_change_dir() {
    run_hook backend "${WT}/openspec/changes/eng-1-x/specs/orders/spec.md"
    assert_eq "${CODE}" 0 "結束碼"
}

test_backend_writes_frontend_is_denied() {
    run_hook backend "${WT}/frontend/src/App.tsx"
    assert_eq "${CODE}" 2 "結束碼"
    assert_contains "${OUT}" "frontend" "說明屬於前端"
}

test_frontend_writes_frontend_subdir() {
    run_hook frontend "${WT}/frontend/src/App.tsx"
    assert_eq "${CODE}" 0 "結束碼"
}

test_frontend_writes_backend_is_denied() {
    run_hook frontend "${WT}/backend/main.go"
    assert_eq "${CODE}" 2 "結束碼"
}

test_frontend_nested_dir_named_backend_is_denied() {
    # Arrange：前端子目錄底下有個叫 backend 的目錄，不可因名稱相同而放行後端角色
    mkdir -p "${WT}/frontend/node_modules/backend"
    # Act
    run_hook backend "${WT}/frontend/node_modules/backend/index.js"
    # Assert
    assert_eq "${CODE}" 2 "結束碼"
}

test_developer_writes_archived_change_is_denied() {
    run_hook backend "${WT}/openspec/changes/archive/2026-01-01-eng-0-y/handoff.md"
    assert_eq "${CODE}" 2 "結束碼"
}

test_developer_writes_root_file_is_denied() {
    run_hook backend "${WT}/README.md"
    assert_eq "${CODE}" 2 "結束碼"
}

test_developer_path_traversal_is_denied() {
    run_hook frontend "${WT}/frontend/../backend/main.go"
    assert_eq "${CODE}" 2 "結束碼"
}

test_developer_denied_when_subdir_not_declared() {
    # Arrange：CLAUDE.md 沒有前端子目錄
    write_settings '- **結構**：fullstack' '- **後端子目錄**：backend/'
    # Act
    run_hook frontend "${WT}/frontend/src/App.tsx"
    # Assert
    assert_eq "${CODE}" 2 "結束碼"
    assert_contains "${OUT}" "前端子目錄" "指出缺少的欄位"
}

test_developer_outside_any_worktree_is_denied() {
    run_hook backend "${WORK}/elsewhere/backend/x.go"
    assert_eq "${CODE}" 2 "結束碼"
}

test_settings_read_from_project_subdirs_like_crates() {
    # Arrange：luke 式的子目錄
    write_settings '- **結構**：fullstack' '- **後端子目錄**：crates/' '- **前端子目錄**：web/'
    mkdir -p "${WT}/crates/core" "${WT}/web/src"
    # Act
    run_hook backend "${WT}/crates/core/lib.rs"
    local backend_code="${CODE}"
    run_hook backend "${WT}/web/src/main.tsx"
    # Assert
    assert_eq "${backend_code}" 0 "後端寫 crates/"
    assert_eq "${CODE}" 2 "後端寫 web/"
}

test_multiple_backend_paths_allow_root_files() {
    # Arrange：後端子目錄列多個路徑（luke 式：crate 在 crates/，workspace 檔在根目錄）
    write_settings '- **結構**：fullstack' '- **後端子目錄**：`crates/`、`Cargo.toml`, Cargo.lock' '- **前端子目錄**：web/'
    mkdir -p "${WT}/crates/core" "${WT}/web"
    # Act
    run_hook backend "${WT}/Cargo.toml"
    local toml_code="${CODE}"
    run_hook backend "${WT}/Cargo.lock"
    local lock_code="${CODE}"
    run_hook backend "${WT}/crates/core/lib.rs"
    local crate_code="${CODE}"
    # Assert
    assert_eq "${toml_code}" 0 "後端寫 Cargo.toml"
    assert_eq "${lock_code}" 0 "後端寫 Cargo.lock"
    assert_eq "${crate_code}" 0 "後端寫 crates/"
}

test_multiple_paths_do_not_match_by_prefix_only() {
    # Arrange：列了 Cargo.toml，不代表 Cargo.toml.bak 或其他根目錄檔案也放行
    write_settings '- **結構**：fullstack' '- **後端子目錄**：crates/、Cargo.toml' '- **前端子目錄**：web/'
    # Act
    run_hook backend "${WT}/Cargo.toml.bak"
    local bak_code="${CODE}"
    run_hook frontend "${WT}/Cargo.toml"
    # Assert
    assert_eq "${bak_code}" 2 "後端寫 Cargo.toml.bak"
    assert_eq "${CODE}" 2 "前端寫 Cargo.toml"
}

# ---------- 共通 ----------

test_no_file_path_is_allowed() {
    OUT="$(printf '{"tool_name":"Edit","tool_input":{}}' |
        bash "${PROJECT}/.claude/hooks/guard-write-scope.sh" backend 2>&1 >/dev/null)"
    CODE=$?
    assert_eq "${CODE}" 0 "結束碼"
}

test_agent_name_as_role_is_denied() {
    run_hook hyuse "${WT}/openspec/changes/eng-1-x/proposal.md"
    assert_eq "${CODE}" 2 "結束碼"
    assert_contains "${OUT}" "未知角色" "說明角色無效"
}

# ---------- 執行 ----------

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
