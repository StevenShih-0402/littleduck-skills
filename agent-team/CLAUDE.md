# team-hq — 多 Agent 協作中樞

本 repo 只放跨前後端的 Agent 定義、總指揮指令與角色 skill，**不放程式碼**。平常從這裡啟動 Claude Code。
完整的設計與導入步驟見 `docs/multi-agent-workflow.md`。

## Repo 路徑

| 角色 | 路徑 | 主幹 |
|------|------|------|
| 前端 repo | `<frontend-repo>` | `<frontend-base>`（例：`main`、`dev`） |
| 後端 repo | `<backend-repo>` | `<backend-base>`（例：`main`） |
| worktree 根目錄 | `<wt-root>`（建議與前後端 repo 同層的 `wt/`） | — |

以 additional directories（`.claude/settings.json` 的 `permissions.additionalDirectories`，或 `claude --add-dir <路徑>`）把上述三個路徑加進來，Agent 才能讀寫。
hook 只從啟動目錄的設定載入，前後端 repo 的 `.claude/settings.json` 在這裡不生效，所以寫入限制與 lint hook 都掛在 Agent 定義檔的 frontmatter。

## Worktree 慣例

- 每個 issue 一組前後端 worktree：`<wt-root>/<repo>-<change-id>`，從各自的主幹開分支。
- change-id **全小寫**，以 Linear issue 編號開頭，例：`eng-123-order-export`。OpenSpec CLI 不接受大寫，前後端用同一個 ID。
- 分支：`<label>/<ISSUE-ID>-<code>`，ISSUE-ID 維持大寫，例：`feature/ENG-123-order-export`。Linear automation 靠它辨識 issue。
- 開發 Agent 只在自己那份 worktree 內工作。

## Agent 與指令

| 名稱 | 角色 | 定義檔 | 流程步驟在 |
|------|------|--------|-----------|
| hyuse | architect：需求分析、UML、OpenAPI 草稿、提案 | `.claude/agents/hyuse.md` | `.claude/skills/issue-architect/` |
| chika | backend：API、單元測試、migration | `.claude/agents/chika.md` | 後端 repo 的 `.claude/skills/backend-processor/` |
| yuma | frontend：切版、API 串接 | `.claude/agents/yuma.md` | `.claude/skills/frontend-processor/` |
| osamu | integrator：檢查、PR、歸檔、回寫 Linear | `.claude/agents/osamu.md` | `.claude/skills/issue-integrator/` |
| `/ship-issue <id>` | 串起四個 Agent 的總指揮 | `.claude/commands/ship-issue.md` | — |

- 定義檔只寫身分、工具、模型、邊界與交接規則；**調整流程步驟只改 skill**。
- `install.sh agent-team` 會把 hyuse、yuma、osamu 用的 skill 裝進本 repo（重跑即更新）。後端 repo 則要另外安裝 `/backend-processor`（`install.sh backend-processor <backend-repo>`），否則 Chika 叫不到。
- hyuse、osamu 掛有寫入限制 hook（`.claude/hooks/guard-write-scope.sh`）：Hyuse 只能寫 `openspec/`；Osamu 只能寫 `handoff.md`、`.linear.md` 與歸檔時同步的 `openspec/specs/`。
- subagent 不能再派 subagent，也不能用 AskUserQuestion，所以要問 user 的決定都在主對話（`/ship-issue`）先問完再交棒。

## 交接規則

- 所有交接都落在 `openspec/changes/<change-id>/`，Agent 之間不共享對話。
- 每個 Agent 開工先讀，結束時在 `handoff.md` 追加紀錄（範本：`openspec/handoff-template.md`）。
- `handoff.md` 開頭的「## 狀態」區塊就地改值，是流程進度的唯一依據；中斷後重新派工時，開發 Agent 依它接續。
- 檢查點 1 核准時，由主對話提交並推送提案；開發 Agent 每完成一項任務就 WIP commit 並 push；Osamu 檢查通過後把 WIP commit 重切成功能 commit。
- 只有兩個人工檢查點：提案核准、歸檔前確認。
- 同一階段退回上限 2 次，超過交給使用者。

## 新舊流程如何選用

| 情境 | 用哪條 |
|------|--------|
| 前後端都要改，或要讓前後端分工開發 | 從 team-hq 執行 `/ship-issue <id>` |
| 小 issue、只動一端 | 從 team-hq 單點呼叫 Chika（後端）或 Yuma（前端），或 `/ship-issue` 只填一端 |
| 單人、單一 repo 照舊 | 在該 repo 啟動，`/issue-reader` → `/issue-processor` → `/issue-solver` |

兩條流程**不可同時操作同一張 issue**。
