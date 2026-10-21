# team-hq — 多 Agent 協作中樞

本 repo 只放跨前後端的 Agent 定義與總指揮指令，**不放程式碼**。平常從這裡啟動 Claude Code。
完整的設計與導入步驟見 `docs/multi-agent-workflow.md`。

## Repo 路徑

| 角色 | 路徑 |
|------|------|
| 前端 repo | `<frontend-repo>` |
| 後端 repo | `<backend-repo>` |
| worktree 根目錄 | `<wt-root>`（建議與前後端 repo 同層的 `wt/`） |

以 additional directories（或 `claude --add-dir <路徑>`）把上述三個路徑加進來，Agent 才能讀寫。

## Worktree 慣例

- 每個 issue 一組前後端 worktree：`<wt-root>/<repo>-<change-id>`
- change-id 以 Linear issue 編號開頭，例：`ENG-123-order-export`，前後端用同一個 ID
- 開發 Agent 只在自己那份 worktree 內工作

## Agent 與指令

| 名稱 | 角色 | 定義檔 |
|------|------|--------|
| hyuse | architect：需求分析、UML、OpenAPI 草稿、提案 | `.claude/agents/hyuse.md` |
| chika | backend：API、單元測試、migration | `.claude/agents/chika.md` |
| yuma | frontend：切版、API 串接 | `.claude/agents/yuma.md` |
| osamu | integrator：檢查、歸檔、回寫 Linear、PR | `.claude/agents/osamu.md` |
| `/ship-issue <id>` | 串起四個 Agent 的總指揮 | `.claude/commands/ship-issue.md` |

## 交接規則

- 所有交接都落在 `openspec/changes/<change-id>/`，Agent 之間不共享對話
- 每個 Agent 開工先讀、結束時在 `handoff.md` 追加紀錄（範本：`openspec/handoff-template.md`）
- 只有兩個人工檢查點：提案核准、歸檔前確認
- 同一階段退回上限 2 次，超過交給使用者
