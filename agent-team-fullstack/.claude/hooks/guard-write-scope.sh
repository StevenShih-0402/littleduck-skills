#!/usr/bin/env bash
# .claude/hooks/guard-write-scope.sh
# 限制 architect、integrator 與前後端開發 Agent 的寫入範圍：PreToolUse hook（matcher: Write|Edit）。
#
# 由 Agent 定義 frontmatter 呼叫，參數是「角色」而不是 Agent 名稱（改名時不必改 hook）：
#     "$CLAUDE_PROJECT_DIR"/.claude/hooks/guard-write-scope.sh <architect|integrator|backend|frontend>
# stdin 為 Claude Code 的 hook JSON，取 tool_input.file_path 判斷；有 jq 用 jq，否則用 python3 解析。
# 放行 exit 0；拒絕 exit 2，stderr 回饋給 Agent。
#   architect ：只能寫 openspec/ 目錄內的檔案
#   integrator：只能寫變更目錄（含已歸檔）的 handoff.md、.linear.md，以及歸檔時同步的 openspec/specs/**
#   backend   ：只能寫所在 worktree 的後端子目錄與進行中的變更目錄 openspec/changes/<id>/
#   frontend  ：只能寫所在 worktree 的前端子目錄與進行中的變更目錄
# 前後端子目錄讀自專案根目錄 CLAUDE.md 的「## agent-team 設定」段落（本檔位於 <專案>/.claude/hooks/）；
# 欄位可列多個路徑（以「、」或「,」分隔，例：`crates/、Cargo.toml、Cargo.lock`），各自放行該檔案或該目錄底下。
# 讀不到就拒絕（fail closed）。已知缺口：管不到 Bash 寫檔，由 Agent 定義檔明文禁止。
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
    architect|integrator|backend|frontend) ;;
    *)
        echo "guard-write-scope.sh：未知角色「${role}」，應為 architect、integrator、backend 或 frontend" >&2
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

# setting <欄位名>：讀專案 CLAUDE.md「## agent-team 設定」段落內 `- **<欄位名>**：<值>` 的值；
# 值可列多個路徑（「、」「,」「，」分隔），一行印一個；每個去掉反引號、HTML 註解、前後空白、開頭 ./ 與結尾 /
setting() {
    local claude_md
    claude_md="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/CLAUDE.md"
    [[ -f "$claude_md" ]] || return 0
    awk -v key="$1" '
        /^## / { in_section = ($0 ~ /^## agent-team 設定[[:space:]]*$/); next }
        in_section && index($0, "- **" key "**：") == 1 {
            value = substr($0, length("- **" key "**：") + 1)
            sub(/<!--.*-->/, "", value)
            gsub(/`/, "", value)
            gsub(/、|，/, ",", value)
            n = split(value, items, ",")
            for (i = 1; i <= n; i++) {
                item = items[i]
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
                sub(/^\.\//, "", item)
                sub(/\/+$/, "", item)
                if (item != "") print item
            }
            exit
        }
    ' "$claude_md"
}

# worktree_root <路徑>：往上找最近一個含 .git（目錄或 git worktree 的 .git 檔）的祖先
worktree_root() {
    local dir
    dir="$(dirname "$1")"
    while [[ "$dir" != "/" && -n "$dir" ]]; do
        if [[ -e "$dir/.git" ]]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

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
    backend|frontend)
        if [[ "$role" == backend ]]; then
            key="後端子目錄"; other="frontend"; other_key="前端子目錄"
        else
            key="前端子目錄"; other="backend"; other_key="後端子目錄"
        fi
        # 不用 mapfile：macOS 內建的 bash 3.2 沒有
        paths=()
        while IFS= read -r line; do
            paths+=("$line")
        done < <(setting "$key")
        subdir="${paths[0]:-}"
        if [[ -z "$subdir" || " ${paths[*]:-} " == *" . "* ]]; then
            deny "專案 CLAUDE.md 的「## agent-team 設定」沒有宣告「${key}」（或宣告為 repo 根目錄），無法判斷寫入範圍；請 user 補上設定。"
        fi
        if ! root="$(worktree_root "$file_path")"; then
            deny "檔案不在任何 git worktree 內；開發 Agent 只能在本次的 worktree 內修改。"
        fi
        rel="${file_path#"$root"/}"
        for allowed in "${paths[@]}"; do
            [[ "$rel" == "$allowed" || "$rel" == "$allowed"/* ]] && exit 0
        done
        # 進行中的變更目錄（不含 archive）
        if [[ "$rel" =~ ^openspec/changes/([^/]+)/ && "${BASH_REMATCH[1]}" != archive ]]; then
            exit 0
        fi
        other_subdir="$(setting "$other_key" | head -n 1)"
        deny "${role} Agent 只能寫 ${paths[*]} 與 openspec/changes/<change-id>/（不含 archive）。${other_subdir:+${other_subdir}/ 屬於 ${other} Agent；}需要改其他位置時寫進 handoff.md 並回報。"
        ;;
esac
