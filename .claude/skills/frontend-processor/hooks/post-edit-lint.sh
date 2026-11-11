#!/usr/bin/env bash
# .claude/skills/frontend-processor/hooks/post-edit-lint.sh
# 編輯後自動 lint：PostToolUse hook（matcher: Write|Edit），只對剛編輯的單一 JS／TS 檔跑 lint。
# 執行目錄是離該檔最近、含 eslint 設定檔的祖先目錄（不超過 git 根目錄；fullstack 的前端子目錄），找不到才用 git 根目錄。
#
# 註冊方式（擇一）：
#   - 前端 Agent 定義 frontmatter `hooks`，路徑用 "$CLAUDE_PROJECT_DIR"/.claude/skills/…（見 agent-team kit 的 Agent 定義範本）
#   - 專案 .claude/settings.json 的 PostToolUse hook
# stdin 為 Claude Code 的 hook JSON，取 tool_input.file_path；有 jq 用 jq，否則用 python3 解析。
#
# 處理的副檔名：.ts .tsx .js .jsx .mjs .cjs .vue
# lint 指令決定順序：
#   1. 環境變數 LITTLEDUCK_FE_LINT_CMD（例："npx --no-install eslint"、"pnpm exec biome lint"），檔案路徑附在最後
#      （與後端 hook 的 LITTLEDUCK_LINT_CMD 分開，fullstack 時兩支 hook 在同一個 session 的環境下執行）
#   2. 執行目錄有 eslint 設定檔（eslint.config.* 或 .eslintrc*）且其 node_modules/.bin/eslint 存在 → npx --no-install eslint
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

# has_eslint_config <目錄>：該目錄有 eslint 設定檔
has_eslint_config() {
    local config
    for config in "$1"/eslint.config.* "$1"/.eslintrc*; do
        [[ -e "$config" ]] && return 0
    done
    return 1
}

# 從檔案所在目錄往上找最近的 eslint 設定目錄，最多到 git 根目錄；找不到就用 git 根目錄
lint_dir=""
dir="$(dirname "$file_path")"
while :; do
    if has_eslint_config "$dir"; then
        lint_dir="$dir"
        break
    fi
    [[ "$dir" == "$repo_root" || "$dir" == "/" ]] && break
    dir="$(dirname "$dir")"
done

# 決定 lint 指令；偵測不到就不處理，不阻擋編輯
lint_cmd="${LITTLEDUCK_FE_LINT_CMD:-}"
if [[ -z "$lint_cmd" ]]; then
    if [[ -n "$lint_dir" && -x "$lint_dir/node_modules/.bin/eslint" ]]; then
        lint_cmd="npx --no-install eslint"
    else
        exit 0
    fi
fi
[[ -n "$lint_dir" ]] || lint_dir="$repo_root"
rel_path="${file_path#"$lint_dir"/}"

if ! output="$(cd "$lint_dir" && $lint_cmd "$rel_path" 2>&1)"; then
    echo "${lint_cmd} ${rel_path} 未通過：" >&2
    echo "$output" | tail -n 40 >&2
    exit 2
fi
exit 0
