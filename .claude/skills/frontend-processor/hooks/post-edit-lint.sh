#!/usr/bin/env bash
# .claude/skills/frontend-processor/hooks/post-edit-lint.sh
# 編輯後自動 lint：PostToolUse hook（matcher: Write|Edit），只對剛編輯的單一 JS／TS 檔在其所屬 repo 根目錄跑 lint。
#
# 註冊方式（擇一）：
#   - team-hq 的前端 Agent 定義 frontmatter `hooks`（見 agent-team 的 yuma.md 範本）
#   - 前端 repo 的 .claude/settings.json 的 PostToolUse hook
# stdin 為 Claude Code 的 hook JSON，取 tool_input.file_path；有 jq 用 jq，否則用 python3 解析。
#
# 處理的副檔名：.ts .tsx .js .jsx .mjs .cjs .vue
# lint 指令決定順序：
#   1. 環境變數 LITTLEDUCK_FE_LINT_CMD（例："npx --no-install eslint"、"pnpm exec biome lint"），檔案路徑附在最後
#      （與後端 hook 的 LITTLEDUCK_LINT_CMD 分開，兩支 hook 可能在同一個 team-hq session 的環境下執行）
#   2. repo 根目錄有 eslint 設定檔（eslint.config.* 或 .eslintrc*）且 node_modules/.bin/eslint 存在 → npx --no-install eslint
#   3. 都沒有 → 不處理（例：worktree 尚未安裝依賴）
# 失敗時 exit 2，把輸出末 40 行回饋給 Agent。刻意不跑 --fix（會改檔）與 typecheck（太慢，留給 /frontend-processor 的完成定義）。
set -euo pipefail

hook_json="$(cat)"
if command -v jq >/dev/null 2>&1; then
    file_path="$(printf '%s' "$hook_json" | jq -r '.tool_input.file_path // empty')"
else
    file_path="$(printf '%s' "$hook_json" | python3 -c \
        'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path") or "")')"
fi

case "$file_path" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue) ;;
    *) exit 0 ;;
esac
[[ -f "$file_path" ]] || exit 0

repo_root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$repo_root" ]] || exit 0
rel_path="${file_path#"$repo_root"/}"

# 決定 lint 指令；偵測不到就不處理，不阻擋編輯
lint_cmd="${LITTLEDUCK_FE_LINT_CMD:-}"
if [[ -z "$lint_cmd" ]]; then
    has_config=0
    for config in "$repo_root"/eslint.config.* "$repo_root"/.eslintrc*; do
        if [[ -e "$config" ]]; then
            has_config=1
            break
        fi
    done
    if [[ "$has_config" == 1 && -x "$repo_root/node_modules/.bin/eslint" ]]; then
        lint_cmd="npx --no-install eslint"
    else
        exit 0
    fi
fi

if ! output="$(cd "$repo_root" && $lint_cmd "$rel_path" 2>&1)"; then
    echo "${lint_cmd} ${rel_path} 未通過：" >&2
    echo "$output" | tail -n 40 >&2
    exit 2
fi
exit 0
