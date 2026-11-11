#!/usr/bin/env bash
# tests/install.test.sh
# install.sh 的 agent-team kit 選項測試：舊選項報錯、兩種 kit 各裝自己的骨架、角色 skill 與重跑行為。
#
# 執行：bash tests/install.test.sh
# 每個 test_* 在獨立的暫存目錄執行，以本地 clone 模式呼叫 install.sh，不連網。
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="${REPO_DIR}/install.sh"
ROLE_SKILLS="issue-architect issue-integrator backend-processor frontend-processor custom-review"

PASSED=0
FAILED=0
FAILED_NAMES=()
CURRENT_OK=1

# ---------- 沙箱 ----------

setup_sandbox() {
    WORK="$(mktemp -d)"
    TARGET="${WORK}/target"
    mkdir -p "${TARGET}"
}

teardown_sandbox() {
    rm -rf "${WORK}"
}

# 執行 install.sh；結果放在 OUT（stdout+stderr）與 CODE
run_install() {
    OUT="$(sh "${INSTALL}" "$@" 2>&1)"
    CODE=$?
}

# 目標目錄內的檔案清單（相對路徑）
target_files() {
    (cd "${TARGET}" && find . -type f | sed 's|^\./||' | sort)
}

# ---------- assert ----------

fail() {
    CURRENT_OK=0
    printf '    ✗ %s\n' "$1"
}
assert_eq() { [[ "$1" == "$2" ]] || fail "${3:-} 預期 [$2]，實際 [$1]"; }
assert_ne() { [[ "$1" != "$2" ]] || fail "${3:-} 不應為 [$2]"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "${3:-} 應包含 [$2]，實際：$1"; }
assert_file() { [[ -f "$1" ]] || fail "${2:-} 應存在：$1"; }
assert_no_file() { [[ ! -e "$1" ]] || fail "${2:-} 不應存在：$1"; }

# ---------- 舊選項 ----------

test_old_agent_team_selection_is_rejected_without_writes() {
    # Arrange：空目標
    # Act
    run_install agent-team "${TARGET}"
    # Assert
    assert_ne "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "agent-team-fullstack" "指引 fullstack"
    assert_contains "${OUT}" "agent-team-single-side" "指引 single-side"
    assert_eq "$(target_files)" "" "目標應為空"
}

test_list_shows_both_kits_and_not_old_option() {
    # Arrange：無
    # Act
    run_install --list
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_contains "${OUT}" "agent-team-fullstack" "列出 fullstack"
    assert_contains "${OUT}" "agent-team-single-side" "列出 single-side"
    if printf '%s\n' "${OUT}" | grep -qx 'agent-team'; then
        fail "不應列出 agent-team"
    fi
}

# ---------- 兩種 kit ----------

test_fullstack_installs_its_scaffold() {
    # Arrange：空目標
    # Act
    run_install agent-team-fullstack "${TARGET}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    for f in CLAUDE.md docs/multi-agent-workflow.md .claude/commands/ship-issue.md \
        .claude/hooks/guard-write-scope.sh openspec/handoff-template.md openspec/review-template.md; do
        assert_file "${TARGET}/${f}"
    done
    assert_eq "$(ls "${TARGET}/.claude/agents" | wc -l | tr -d ' ')" 5 "Agent 定義數"
    assert_file "${TARGET}/.claude/agents/chika.md" "後端 Agent"
    assert_contains "$(cat "${TARGET}/CLAUDE.md")" "fullstack" "CLAUDE.md 宣告結構"
}

test_single_side_installs_its_scaffold_only() {
    # Arrange：空目標
    # Act
    run_install agent-team-single-side "${TARGET}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(ls "${TARGET}/.claude/agents" | wc -l | tr -d ' ')" 4 "Agent 定義數"
    assert_no_file "${TARGET}/.claude/agents/chika.md" "single-side 不應有後端 Agent"
    assert_contains "$(cat "${TARGET}/CLAUDE.md")" "single-side" "CLAUDE.md 宣告結構"
}

test_both_kits_install_the_role_skills() {
    local kit
    for kit in agent-team-fullstack agent-team-single-side; do
        # Arrange：每種 kit 一個空目標
        rm -rf "${TARGET}" && mkdir -p "${TARGET}"
        # Act
        run_install "${kit}" "${TARGET}"
        # Assert
        assert_eq "${CODE}" 0 "${kit} 結束碼"
        for s in ${ROLE_SKILLS} issue-reader draw-mermaid openspec-archive-change; do
            assert_file "${TARGET}/.claude/skills/${s}/SKILL.md" "${kit}"
        done
        assert_file "${TARGET}/.claude/commands/opsx/apply.md" "${kit}"
        assert_file "${TARGET}/linear/question_template.md" "${kit}"
    done
}

test_rerun_keeps_edited_agent_and_updates_skill() {
    # Arrange：先裝一次，再改 Agent 定義、把 skill 弄舊
    run_install agent-team-fullstack "${TARGET}"
    printf 'edited\n' >"${TARGET}/.claude/agents/hyuse.md"
    printf 'old\n' >"${TARGET}/.claude/skills/issue-architect/SKILL.md"
    # Act
    run_install agent-team-fullstack "${TARGET}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_eq "$(cat "${TARGET}/.claude/agents/hyuse.md")" "edited" "Agent 定義不覆寫"
    assert_contains "${OUT}" "略過（已存在）：.claude/agents/hyuse.md" "回報略過"
    assert_eq "$(cat "${TARGET}/.claude/skills/issue-architect/SKILL.md")" \
        "$(cat "${REPO_DIR}/.claude/skills/issue-architect/SKILL.md")" "skill 覆寫為新版"
}

test_all_does_not_install_any_kit_file() {
    # Arrange：空目標
    # Act
    run_install all "${TARGET}"
    # Assert
    assert_eq "${CODE}" 0 "結束碼"
    assert_no_file "${TARGET}/.claude/agents" "不應有 Agent 定義"
    assert_no_file "${TARGET}/.claude/commands/ship-issue.md" "不應有 ship-issue"
    assert_no_file "${TARGET}/.claude/hooks" "不應有 hook"
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
            FAILED_NAMES+=("${fn}")
            printf '  ✗ %s\n' "${fn}"
        fi
    done
    printf '\n%d passed, %d failed\n' "${PASSED}" "${FAILED}"
    [[ "${FAILED}" == "0" ]]
}

main "$@"
