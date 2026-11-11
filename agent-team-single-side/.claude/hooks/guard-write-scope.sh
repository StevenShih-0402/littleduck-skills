#!/usr/bin/env bash
# .claude/hooks/guard-write-scope.sh
# 限制 architect 與 integrator 的寫入範圍：PreToolUse hook（matcher: Write|Edit）。
# single-side 只有一個開發 Agent、擁有整個程式碼目錄，不掛本 hook。
#
# 由 Agent 定義 frontmatter 呼叫，參數是「角色」而不是 Agent 名稱（改名時不必改 hook）：
#     "$CLAUDE_PROJECT_DIR"/.claude/hooks/guard-write-scope.sh <architect|integrator>
# stdin 為 Claude Code 的 hook JSON，取 tool_input.file_path 判斷；有 jq 用 jq，否則用 python3 解析。
# 放行 exit 0；拒絕 exit 2，stderr 回饋給 Agent。
#   architect ：只能寫 openspec/ 目錄內的檔案
#   integrator：只能寫變更目錄（含已歸檔）的 handoff.md、.linear.md，以及歸檔時同步的 openspec/specs/**
# 已知缺口：管不到 Bash 寫檔，由 Agent 定義檔明文禁止。
set -euo pipefail

role="${1:-}"
hook_json="$(cat)"
if command -v jq >/dev/null 2>&1; then
    file_path="$(printf '%s' "$hook_json" | jq -r '.tool_input.file_path // empty')"
else
    file_path="$(printf '%s' "$hook_json" | python3 -c \
        'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path") or "")')"
fi

deny() {
    echo "已拒絕（${role} 寫入限制）：${file_path}" >&2
    echo "$1" >&2
    exit 2
}

case "$role" in
    architect|integrator) ;;
    *)
        echo "guard-write-scope.sh：未知角色「${role}」，應為 architect 或 integrator（single-side 的開發 Agent 不掛本 hook）" >&2
        exit 2
        ;;
esac

if [[ -z "$file_path" ]]; then
    # 沒有檔案路徑的工具呼叫不在本 hook 管轄
    exit 0
fi

# normalize <路徑>：轉絕對路徑並消去 ../，避免以 ../ 繞過前綴比對（macOS 的 realpath 沒有 -m，改用 python3）
normalize() {
    realpath -m -- "$1" 2>/dev/null ||
        python3 -c 'import os,sys; print(os.path.normpath(os.path.abspath(sys.argv[1])))' "$1"
}
file_path="$(normalize "$file_path")"

case "$role" in
    architect)
        [[ "$file_path" == */openspec/* ]] && exit 0
        deny "architect 只能寫入 openspec/ 目錄；程式碼由開發 Agent 實作。"
        ;;
    integrator)
        # 進行中或已歸檔 change 的交接檔
        [[ "$file_path" =~ /openspec/changes/[^/]+/(handoff\.md|\.linear\.md)$ ]] && exit 0
        [[ "$file_path" =~ /openspec/changes/archive/[^/]+/(handoff\.md|\.linear\.md)$ ]] && exit 0
        # 歸檔時同步的主規格
        [[ "$file_path" == */openspec/specs/* ]] && exit 0
        deny "integrator 不修改程式碼與提案檔（tasks.md／proposal.md／design.md／openapi.yaml）；發現問題請寫進 handoff.md 退回對應 Agent。"
        ;;
esac
