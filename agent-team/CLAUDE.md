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
| osamu | integrator：檢查、審查通過後收尾開 PR、歸檔、回寫 Linear | `.claude/agents/osamu.md` | `.claude/skills/issue-integrator/` |
| shiori | reviewer：對照 OpenSpec 規格審查 diff 的需求／測試覆蓋與邏輯，評定 /code-review 發現 | `.claude/agents/shiori.md` | `.claude/skills/custom-review/` |
| `/ship-issue <id>` | 串起五個角色的總指揮（含程式碼審查） | `.claude/commands/ship-issue.md` | — |

- 定義檔只寫身分、工具、模型、邊界與交接規則；**調整流程步驟只改 skill**。
- `install.sh agent-team` 會把 hyuse、yuma、osamu、shiori 用的 skill 裝進本 repo（重跑即更新）。後端 repo 則要另外安裝 `/backend-processor`（`install.sh backend-processor <backend-repo>`），否則 Chika 叫不到。
- hyuse、osamu 掛有寫入限制 hook（`.claude/hooks/guard-write-scope.sh`）：Hyuse 只能寫 `openspec/`；Osamu 只能寫 `handoff.md`、`.linear.md` 與歸檔時同步的 `openspec/specs/`。Shiori 的 `tools` 只有 Read／Grep／Glob，天生不能寫檔，不需掛 hook。
- **內建 `/code-review` 不要建立同名 skill**：同名的專案或個人 skill 會整個取代內建審查，失去 effort 調整、`--fix`、`ultra`。Shiori 用的是另取名的 `/custom-review`。
- subagent 不能再派 subagent，也不能用 AskUserQuestion，所以要問 user 的決定都在主對話（`/ship-issue`）先問完再交棒。

## 交接規則

- 所有交接都落在 `openspec/changes/<change-id>/`，Agent 之間不共享對話。
- 每個 Agent 開工先讀，結束時在 `handoff.md` 追加紀錄（範本：`openspec/handoff-template.md`）；程式碼審查結果寫在 `review.md`（範本：`openspec/review-template.md`）。
- `handoff.md` 開頭的「## 狀態」區塊就地改值，是流程進度的唯一依據；中斷後重新派工時，開發 Agent 依它接續。階段：`proposal → backend／frontend → integrating → reviewing（檢查通過，主對話跑程式碼審查）→ ready-to-archive（收尾開 PR 後）→ archived`。
- 檢查點 1 核准時，由主對話提交並推送提案；開發 Agent 每完成一項任務就 WIP commit 並 push；程式碼審查通過後，Osamu 收尾時把 WIP commit 重切成功能 commit。
- 只有兩個人工檢查點：提案核准、歸檔前確認。
- 同一階段退回上限 2 次，超過交給使用者；**Osamu 檢查退回與程式碼審查退回合併計算**。

## 審查規則三分法

程式碼審查依規則性質分三處放，各司其職、不重複：

| 規則性質 | 放哪裡 | 誰檢查 | 何時 |
|----------|--------|--------|------|
| 機械性（命名格式、import 順序、程式碼格式） | linter／formatter 設定（ruff／ESLint 等） | Osamu「檢查」實際跑 lint，與編輯後 hook | A 檢查段 |
| 需要判斷的專案慣例（分層、錯誤格式、命名原則） | 各 repo 的 `CLAUDE.md` | 內建 `/code-review`；開發 Agent 寫程式時遵守 | 5.5 程式碼審查 |
| 對照 OpenSpec 的需求覆蓋與測試涵蓋 | team-hq `/custom-review` | Shiori | 5.5 程式碼審查 |

- 機械性規則不交給 AI 審（交給 linter 擋，避免重複與浪費 token）；Shiori 遇到 `/code-review` 回報機械性項目會判為不成立。
- 導入初期以 **shadow mode** 跑前 N 個 issue（預設 5）：審查只彙報不自動退回，於檢查點 2 讓 user 逐條判定、記誤報率；可接受後才切自動退回（只有高嚴重度且高信心才退回）。

### 高風險檔案樣式

`/ship-issue` 5.5 以 `git diff --name-only` 比對本清單，命中就把該端 `/code-review` 的 effort 調為 `high`，並在檢查點 2 要 user 逐一確認。依專案技術棧填（預設留通用範例，沒有就留空）：

| 類別 | 樣式範例（依專案調整） |
|------|------|
| migration／schema | 資料庫遷移檔目錄，例：`**/migrations/**`（排除 `__init__`） |
| 認證 | 路徑或檔名含 `auth`、`token`、`session`、`jwt`、`otp`、`mfa` |
| 加密 | 引用加密函式庫或檔名含 `crypt` 的檔案 |
| 權限 | 路徑或檔名含 `permission`、`rbac`、`guard` |

### review-diff.patch 不進版控

`/ship-issue` 5.5 會在變更目錄產生 `review-diff.patch` 給唯讀的 Shiori 讀，審完即刪、不進 commit。**每個前後端 repo 的 `.gitignore` 都要加一行 `review-diff.patch`**，避免誤 commit。

## 新舊流程如何選用

| 情境 | 用哪條 |
|------|--------|
| 前後端都要改，或要讓前後端分工開發 | 從 team-hq 執行 `/ship-issue <id>` |
| 小 issue、只動一端 | 從 team-hq 單點呼叫 Chika（後端）或 Yuma（前端），或 `/ship-issue` 只填一端 |
| 單人、單一 repo 照舊 | 在該 repo 啟動，`/issue-reader` → `/issue-processor` → `/issue-solver` |

兩條流程**不可同時操作同一張 issue**。
