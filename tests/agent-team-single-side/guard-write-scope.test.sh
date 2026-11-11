#!/usr/bin/env bash
# tests/agent-team-single-side/guard-write-scope.test.sh
# single-side kit 寫入範圍 hook 的測試：只有 architect／integrator 兩個角色，開發 Agent 不掛 hook，傳入開發角色要被拒。
#
# 執行：bash tests/agent-team-single-side/guard-write-scope.test.sh
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="${REPO_DIR}/agent-team-single-side/.claude/hooks/guard-write-scope.sh"

PASSED=0
FAILED=0
CURRENT_OK=1

setup_sandbox() {
    WORK="$(mktemp -d)"
    WT="${WORK}/proj/wt/eng-1-x"
    mkdir -p "${WT}/src" "${WT}/openspec/changes/eng-1-x"
}

teardown_sandbox() {
    rm -rf "${WORK}"
}

# 以模擬 hook JSON 執行；結果放在 OUT（stderr）與 CODE
run_hook() {
    OUT="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$2" |
        bash "${HOOK}" "$1" 2>&1 >/dev/null)"
    CODE=$?
}

fail() {
    CURRENT_OK=0
    printf '    ✗ %s\n' "$1"
}
assert_eq() { [[ "$1" == "$2" ]] || fail "${3:-} 預期 [$2]，實際 [$1]"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "${3:-} 應包含 [$2]，實際：$1"; }

test_architect_writes_code_is_denied() {
    run_hook architect "${WT}/src/main.rs"
    assert_eq "${CODE}" 2 "結束碼"
}

test_architect_path_traversal_is_denied() {
    run_hook architect "${WT}/openspec/../src/main.rs"
    assert_eq "${CODE}" 2 "結束碼"
}

test_architect_writes_proposal() {
    run_hook architect "${WT}/openspec/changes/eng-1-x/design.md"
    assert_eq "${CODE}" 0 "結束碼"
}

test_integrator_edits_tasks_is_denied() {
    run_hook integrator "${WT}/openspec/changes/eng-1-x/tasks.md"
    assert_eq "${CODE}" 2 "結束碼"
}

test_integrator_updates_archived_handoff() {
    run_hook integrator "${WT}/openspec/changes/archive/2026-11-11-eng-1-x/handoff.md"
    assert_eq "${CODE}" 0 "結束碼"
}

test_integrator_syncs_main_specs() {
    run_hook integrator "${WT}/openspec/specs/core/spec.md"
    assert_eq "${CODE}" 0 "結束碼"
}

test_developer_roles_are_rejected() {
    local role
    for role in backend frontend; do
        run_hook "${role}" "${WT}/src/main.rs"
        assert_eq "${CODE}" 2 "${role} 結束碼"
        assert_contains "${OUT}" "未知角色" "${role} 說明"
    done
}

test_no_file_path_is_allowed() {
    OUT="$(printf '{"tool_input":{}}' | bash "${HOOK}" architect 2>&1 >/dev/null)"
    CODE=$?
    assert_eq "${CODE}" 0 "結束碼"
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
