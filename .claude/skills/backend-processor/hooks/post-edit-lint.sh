#!/usr/bin/env bash
# .claude/skills/backend-processor/hooks/post-edit-lint.sh
# 編輯後自動 lint：PostToolUse hook（matcher: Write|Edit），只對剛編輯的單一 .py 檔跑 lint。
# 執行目錄是離該檔最近、有可執行 pants 或含 [tool.ruff] 的 pyproject.toml 的祖先目錄（不超過 git 根目錄；
# fullstack 的後端子目錄），找不到才用 git 根目錄。
#
# 註冊方式（擇一）：
#   - 後端 Agent 定義 frontmatter `hooks`，路徑用 "$CLAUDE_PROJECT_DIR"/.claude/skills/…（見 agent-team kit 的 Agent 定義範本）
#   - 專案 .claude/settings.json 的 PostToolUse hook
# stdin 為 Claude Code 的 hook JSON，取 tool_input.file_path；有 jq 用 jq，否則用 python3 解析。
#
# lint 指令決定順序：
#   1. 環境變數 LITTLEDUCK_LINT_CMD（例："./pants lint"、"uv run ruff check"），檔案路徑附在最後
#   2. 執行目錄有可執行的 ./pants → ./pants lint
#   3. 執行目錄的 pyproject.toml 有 [tool.ruff]、有 uv 且專案環境裝得到 ruff → uv run ruff check
#   4. 都沒有 → 不處理
# 失敗時 exit 2，把輸出末 40 行回饋給 Agent。刻意不跑 format／fix（會改檔、可能越界），留給 Agent 收尾時自己跑。
set -euo pipefail

hook_json="$(cat)"
if command -v jq >/dev/null 2>&1; then
    file_path="$(printf '%s' "$hook_json" | jq -r '.tool_input.file_path // empty')"
else
    file_path="$(printf '%s' "$hook_json" | python3 -c \
        'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path") or "")')"
fi

[[ "$file_path" == *.py ]] || exit 0
[[ -f "$file_path" ]] || exit 0

repo_root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$repo_root" ]] || exit 0

# is_lint_root <目錄>：有可執行的 pants，或 pyproject.toml 含 [tool.ruff]
is_lint_root() {
    [[ -x "$1/pants" ]] && return 0
    [[ -f "$1/pyproject.toml" ]] && grep -q '^\[tool\.ruff' "$1/pyproject.toml"
}

# 從檔案所在目錄往上找最近的 lint 設定目錄，最多到 git 根目錄；找不到就用 git 根目錄
lint_dir=""
dir="$(dirname "$file_path")"
while :; do
    if is_lint_root "$dir"; then
        lint_dir="$dir"
        break
    fi
    [[ "$dir" == "$repo_root" || "$dir" == "/" ]] && break
    dir="$(dirname "$dir")"
done

# 決定 lint 指令；偵測不到就不處理，不阻擋編輯
lint_cmd="${LITTLEDUCK_LINT_CMD:-}"
if [[ -z "$lint_cmd" ]]; then
    if [[ -n "$lint_dir" && -x "$lint_dir/pants" ]]; then
        lint_cmd="./pants lint"
    elif [[ -n "$lint_dir" ]] && command -v uv >/dev/null 2>&1 \
        && (cd "$lint_dir" && uv run --quiet ruff --version >/dev/null 2>&1); then
        lint_cmd="uv run ruff check"
    else
        exit 0
    fi
fi
[[ -n "$lint_dir" ]] || lint_dir="$repo_root"
rel_path="${file_path#"$lint_dir"/}"

# 動到 model 時提醒 migration（只提醒，不影響退出碼）
if [[ "$rel_path" =~ (^|/)models\.py$ || "$rel_path" =~ (^|/)models/ ]]; then
    echo "提醒：已修改 model（${rel_path}），請確認是否需要新增 migration，並驗證正反向 migrate。" >&2
fi

if ! output="$(cd "$lint_dir" && $lint_cmd "$rel_path" 2>&1)"; then
    echo "${lint_cmd} ${rel_path} 未通過：" >&2
    echo "$output" | tail -n 40 >&2
    exit 2
fi
exit 0
