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
| osamu | integrator：檢查（含執行驗證）、審查通過後收尾開 PR、歸檔、回寫 Linear、模擬合併隊列並合併 | `.claude/agents/osamu.md` | `.claude/skills/issue-integrator/` |
| shiori | reviewer：PR 前對照 OpenSpec 規格審查 diff 的需求／測試覆蓋與邏輯；PR 中評定 /code-review、/security-review 的發現 | `.claude/agents/shiori.md` | `.claude/skills/custom-review/` |
| `/ship-issue <id>` | 串起五個角色的總指揮：從提案一路自動做到合併，只在停下條件成立時問 user | `.claude/commands/ship-issue.md` | — |

- 定義檔只寫身分、工具、模型、邊界與交接規則；**調整流程步驟只改 skill**。
- `install.sh agent-team` 會把 hyuse、yuma、osamu、shiori 用的 skill 裝進本 repo（重跑即更新）。後端 repo 則要另外安裝 `/backend-processor`（`install.sh backend-processor <backend-repo>`），否則 Chika 叫不到。
- hyuse、osamu 掛有寫入限制 hook（`.claude/hooks/guard-write-scope.sh`）：Hyuse 只能寫 `openspec/`；Osamu 只能寫 `handoff.md`、`.linear.md` 與歸檔時同步的 `openspec/specs/`。Shiori 的 `tools` 只有 Read／Grep／Glob，天生不能寫檔，不需掛 hook。
- **內建 `/code-review` 不要建立同名 skill**：同名的專案或個人 skill 會整個取代內建審查，失去 effort 調整、`--fix`、`ultra`。Shiori 用的是另取名的 `/custom-review`。
- subagent 不能再派 subagent，也不能用 AskUserQuestion，所以要問 user 的決定都在主對話（`/ship-issue`）先問完再交棒。

## 交接規則

- 所有交接都落在 `openspec/changes/<change-id>/`，Agent 之間不共享對話。
- 每個 Agent 開工先讀，結束時在 `handoff.md` 追加紀錄（範本：`openspec/handoff-template.md`）；程式碼審查結果寫在 `review.md`（範本：`openspec/review-template.md`）。
- `handoff.md` 開頭的「## 狀態」區塊就地改值，是流程進度的唯一依據；中斷後重新派工時，開發 Agent 依它接續。階段：`proposal → backend／frontend → integrating → reviewing（檢查通過，主對話做 PR 前審查）→ pr-checking（收尾開 PR 後，主對話做 PR 中檢查）→ awaiting-approval（只有高風險）→ archived（歸檔後由 Osamu 合併）`。
- Hyuse 沒有待確認問題時，主對話直接提交並推送提案（不等 user 核准）；開發 Agent 每完成一項任務就 WIP commit 並 push；PR 前審查通過後，Osamu 收尾時把 WIP commit 重切成功能 commit。
- **流程中不固定停下等 user 確認**。主對話只在停下條件成立時問 user：釐不清的問題、規格免同步聲明要確認、退回超過上限、判定為高風險、衝突或其他 blocker（完整清單見 `/ship-issue`「停下條件」）。
- 同一目標退回上限 2 次，超過交給使用者；**Osamu 檢查、PR 前審查、CI、PR 中評定的退回合併計算**。合併隊列失敗不退回，直接交給使用者（change 已歸檔）。

## 層層把關

| 階段 | 檢查 | 誰做 |
|------|------|------|
| PR 前 | 確保正常運行：測試、lint、typecheck、migration、執行驗證 | Osamu「檢查」 |
| PR 前 | 檢查代碼品質：對照規格審需求與測試覆蓋 | Shiori 審查模式 |
| PR 中 | CI：等 PR checks 全綠（沒有 CI 就記錄略過） | 主對話 |
| PR 中 | AI 審核：內建 `/code-review` | 主對話，Shiori 評定 |
| PR 中 | 安全審核：內建 `/security-review`（只在高風險時） | 主對話，Shiori 評定 |
| PR 中 | 按風險審批：低／中自動往下，高停下等 user 回覆「合併」 | 主對話 |
| 合併時 | 合併隊列：rebase 到最新主幹、重跑檢查與 CI，兩端都綠才依後端→前端合併 | Osamu「合併」 |

合併後的功能開關、逐步上線、觀察與回滾不在本流程內。

## 審查規則三分法

程式碼審查依規則性質分三處放，各司其職、不重複：

| 規則性質 | 放哪裡 | 誰檢查 | 何時 |
|----------|--------|--------|------|
| 機械性（命名格式、import 順序、程式碼格式） | linter／formatter 設定（ruff／ESLint 等） | Osamu「檢查」實際跑 lint，與編輯後 hook | PR 前 |
| 對照 OpenSpec 的需求覆蓋與測試涵蓋 | team-hq `/custom-review` | Shiori（審查模式） | PR 前 |
| 需要判斷的專案慣例（分層、錯誤格式、命名原則） | 各 repo 的 `CLAUDE.md` | 內建 `/code-review`，Shiori（評定模式）評級；開發 Agent 寫程式時遵守 | PR 中 |

- 機械性規則不交給 AI 審（交給 linter 擋，避免重複與浪費 token）；Shiori 遇到 `/code-review` 回報機械性項目會判為不成立。
- 審查直接採自動退回：只有 Shiori 評為「高嚴重度且高信心」的發現退回，其餘寫成 PR 備註並留言到 PR。
- 審查要能結束：第 2 輪起只審上一輪之後的新改動，前幾輪已記錄的發現不再重提，同類問題一次列出所有位置。

### 高風險檔案樣式

`/ship-issue` 第 7 步以 `git diff --name-only` 比對本清單，命中就把該端 `/code-review` 的 effort 調為 `high`、跑 `/security-review`，並把變更判定為高風險。依專案技術棧填（預設留通用範例，沒有就留空）：

| 類別 | 樣式範例（依專案調整） |
|------|------|
| migration／schema | 資料庫遷移檔目錄，例：`**/migrations/**`（排除 `__init__`） |
| 認證 | 路徑或檔名含 `auth`、`token`、`session`、`jwt`、`otp`、`mfa` |
| 加密 | 引用加密函式庫或檔名含 `crypt` 的檔案 |
| 權限 | 路徑或檔名含 `permission`、`rbac`、`guard` |

### 風險分級

`/ship-issue` 第 8 步依下表判定**整個變更**的風險等級（任一端是高就算高）。依專案調整：

| 等級 | 條件（任一成立） | 處置 |
|------|-----------------|------|
| 高 | 命中上方「高風險檔案樣式」；破壞性 API 變更；`/security-review` 有成立的發現（列為 PR 備註） | 停下，等 user 看過高風險檔案的 diff 後回覆「合併」 |
| 中 | 動到執行期程式碼或 API（非破壞性） | 自動往下，最終報告列出 |
| 低 | 只動文件、測試、註解 | 自動往下 |

單人開發沒有「兩位審批者」，所以高風險改成 user 核准一次，中風險由 AI 審查代替一位審批者。

### 合併設定

| 項目 | 值（依專案調整） |
|------|------|
| 合併方式 | `--merge`（保留重切後的功能 commit；repo 只允許 squash 或 rebase 時改成對應的 `gh pr merge` 旗標） |
| CI 等待上限 | 30 分鐘（超過就停下回報，不視為通過） |
| `/security-review` | 內建指令不接受參數，固定審查「目前分支 vs `origin` 預設分支」。主幹不是 `origin` 預設分支的 repo 會改以 `/code-review high` 代替。需要能指定分支或 PR 的安全掃描時，可選裝官方 Claude Security plugin（`/claude-security`） |

`gh` 需要有該 repo 的 merge 權限。

### 執行驗證（各 repo 的 `CLAUDE.md`）

Osamu「檢查」會讀前後端 repo `CLAUDE.md` 的「## 執行驗證」段，把產品跑起來觀察。沒寫這一段就略過，不擋流程。格式：

```markdown
## 執行驗證

- **啟動**：`<背景啟動指令>`
- **就緒檢查**：`<指令>`（等待上限 60 秒）
- **觀察點**：
  - `curl -s -o /dev/null -w '%{http_code}' localhost:8000/health` → `200`
  - `<指令>` → `<預期輸出>`
  - 截圖：`npx -y playwright@1.61.1 screenshot --wait-for-timeout 2000 http://localhost:5173/ {out}` → 首頁，標題「訂單管理」與左側選單可見，沒有錯誤提示
- **停止**：`<停止指令>`
```

觀察點有兩種：

- **指令**：指令輸出或 HTTP 回應，與預期值比對。
- **截圖**：截圖指令用 `{out}` 佔位輸出檔，Osamu 會換成 worktree 外暫存目錄的路徑，執行後用 Read 看圖，對照預期畫面判定。只有「明顯不符」（空白頁、錯誤頁、點名的元素不見）會擋流程；看不清時列為風險；截圖工具或瀏覽器沒裝時該點略過。

截圖觀察點的注意事項：

- 截圖工具與瀏覽器要預先裝在執行 Osamu 的環境（例：`npx playwright install chromium`）。**指令要固定版本**，版本要和已安裝的瀏覽器相符；不帶版本會抓最新版，常常對不上已裝的瀏覽器。
- 等待頁面載入由截圖指令處理（`--wait-for-timeout`、`--wait-for-selector`）。
- 預期畫面要點名具體元素，不要寫「頁面正常」。
- 需要登入的頁面：先用 `--save-storage <檔案>` 存下登入狀態，截圖時帶 `--load-storage <檔案>`；這個檔案含憑證，放在 worktree 外、不進版控。也可以只截公開頁。
- 互動流程（點擊、填表）不在截圖觀察點內；需要時寫成 E2E 腳本，當作指令觀察點執行。

repo 這一段是每次都跑的通用觀察點；**本次變更特有的觀察點由 Hyuse 寫在該端 `design.md` 的「## 執行驗證觀察點」**，格式相同，Osamu 兩者都跑。

### review-diff.patch 不進版控

`/ship-issue` 第 5、7 步會在變更目錄產生 `review-diff.patch` 給唯讀的 Shiori 讀，審完即刪、不進 commit。**每個前後端 repo 的 `.gitignore` 都要加一行 `review-diff.patch`**，避免誤 commit。

## 新舊流程如何選用

| 情境 | 用哪條 |
|------|--------|
| 前後端都要改，或要讓前後端分工開發 | 從 team-hq 執行 `/ship-issue <id>` |
| 小 issue、只動一端 | 從 team-hq 單點呼叫 Chika（後端）或 Yuma（前端），或 `/ship-issue` 只填一端 |
| 單人、單一 repo 照舊 | 在該 repo 啟動，`/issue-reader` → `/issue-processor` → `/issue-solver` |

兩條流程**不可同時操作同一張 issue**。
