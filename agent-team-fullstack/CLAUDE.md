# <專案名稱>

> 由 littleduck-skills 的 `install.sh agent-team-fullstack` 建立：一個 repo 同時有前後端，多 Agent 流程從本 repo 根目錄啟動。
> 本檔已存在時 installer 不覆寫；要取新版段落，參考 littleduck-skills 的 `agent-team-fullstack/CLAUDE.md` 手動合併。
> 完整的設計與導入步驟見 `docs/multi-agent-workflow.md`。

## agent-team 設定

<!-- 角色 skill、/ship-issue 與寫入範圍 hook 都讀這一段；欄位名不要改，值依專案填。 -->

- **結構**：fullstack
- **主幹**：main
- **worktree 根目錄**：wt/
- **後端子目錄**：backend/
- **前端子目錄**：frontend/

- 子目錄欄位可以列多個路徑（以「、」或「,」分隔），例：後端 crate 在 `crates/`、workspace 檔在根目錄時寫 `crates/、Cargo.toml、Cargo.lock`。以 `/` 結尾的是目錄，其餘是單一檔案；**第一項**是該端跑檢查指令的工作目錄，所有項目都是該端 Agent 可寫的範圍。
- worktree 根目錄在 repo 內，`.gitignore` 要有 `/wt/` 與 `review-diff.patch`。
- **不要在後端或前端子目錄下建立 `.claude/`**：角色 skill 一律裝在 repo 根目錄，子目錄再放一份會重複載入。

## 檢查指令

開發 Agent 與 integrator 依這張表在各子目錄跑檢查；沒有的項目寫「無」，不要留空（留空時 Agent 會停下回報）。

| 項目 | 後端（在後端子目錄執行） | 前端（在前端子目錄執行） |
|------|------|------|
| 安裝依賴 | `<指令>` | `<指令>` |
| 測試 | `<指令>` | `<指令>` |
| lint | `<指令，只對變更檔案>` | `<指令，只對變更檔案>` |
| 型別檢查 | `<指令或「無」>` | `<指令或「無」>` |
| migration 正反向 | `<指令或「無」>` | — |
| API schema 產出 | `<指令或「無」>` | — |

## Worktree 慣例

- 每個 issue **一份** worktree：`<worktree 根目錄>/<change-id>`，從主幹開分支：`git worktree add -b <branch> wt/<change-id> origin/<主幹>`。
- change-id **全小寫**，以 Linear issue 編號開頭，例：`eng-123-order-export`。OpenSpec CLI 不接受大寫。
- 分支：`<label>/<ISSUE-ID>-<code>`，ISSUE-ID 維持大寫，例：`feature/ENG-123-order-export`。Linear automation 靠它辨識 issue。
- 一份變更目錄（`wt/<change-id>/openspec/changes/<change-id>/`）、一份 `openapi.yaml`、一份 `handoff.md`、一份 `review.md`、一個 PR。
- 後端與前端 Agent **共用這份 worktree，依序派工**（先後端、後前端），不平行：兩者共用同一個 git index。

## Agent 與指令

| 名稱 | 角色 | 定義檔 | 流程步驟在 | 寫入限制 hook |
|------|------|--------|-----------|---------------|
| hyuse | architect：需求分析、UML、OpenAPI 草稿、提案 | `.claude/agents/hyuse.md` | `.claude/skills/issue-architect/` | `architect`：只寫 `openspec/` |
| chika | 後端 Agent：API、單元測試、migration | `.claude/agents/chika.md` | `.claude/skills/backend-processor/` | `backend`：只寫後端子目錄與變更目錄 |
| yuma | 前端 Agent：切版、API 串接 | `.claude/agents/yuma.md` | `.claude/skills/frontend-processor/` | `frontend`：只寫前端子目錄與變更目錄 |
| osamu | integrator：檢查（含執行驗證）、審查通過後收尾開 PR、歸檔、回寫 Linear、模擬合併隊列並合併 | `.claude/agents/osamu.md` | `.claude/skills/issue-integrator/` | `integrator`：只寫 `handoff.md`、`.linear.md` 與歸檔同步的 `openspec/specs/` |
| shiori | reviewer：PR 前對照 OpenSpec 規格審查 diff；PR 中評定 /code-review、/security-review 的發現 | `.claude/agents/shiori.md` | `.claude/skills/custom-review/` | 不需要：`tools` 只有 Read／Grep／Glob |
| `/ship-issue <id>` | 串起五個角色的總指揮：從提案一路自動做到合併，只在停下條件成立時問 user | `.claude/commands/ship-issue.md` | — | — |

- 定義檔只寫身分、工具、模型、邊界與交接規則；**調整流程步驟只改 skill**。
- **Agent 名稱可以改**：改檔名、frontmatter 的 `name` 與本表即可。角色 skill 不寫 Agent 名稱，hook 的參數是角色不是名稱，所以重跑 installer 後不必再改 `.claude/skills/`。**改名後可以放心重跑 installer**：`.claude/agents/` 已有任何 Agent 定義（不論檔名）時，installer 不會建立範本名稱的 Agent 定義，並在輸出逐檔說明略過原因；只有 `.claude/agents/` 不存在或沒有 `*.md` 時才建立全部範本。
- 重跑 `install.sh agent-team-fullstack` 會更新 `.claude/skills/` 的角色 skill；本檔、Agent 定義、`ship-issue.md`、hook、範本已存在時一律略過。
- **內建 `/code-review` 不要建立同名 skill**：同名的專案或個人 skill 會整個取代內建審查，失去 effort 調整、`--fix`、`ultra`。reviewer 用的是另取名的 `/custom-review`。
- subagent 不能再派 subagent，也不能用 AskUserQuestion，所以要問 user 的決定都在主對話（`/ship-issue`）先問完再交棒。

## 交接規則

- 所有交接都落在 `openspec/changes/<change-id>/`，Agent 之間不共享對話。
- 每個 Agent 開工先讀，結束時在 `handoff.md` 追加紀錄（範本：`openspec/handoff-template.md`）；程式碼審查結果寫在 `review.md`（範本：`openspec/review-template.md`）。
- `handoff.md` 開頭的「## 狀態」區塊就地改值，是流程進度的唯一依據；中斷後重新派工時，開發 Agent 依它接續。階段：`proposal → backend → frontend → integrating → reviewing（檢查通過，主對話做 PR 前審查）→ pr-checking（收尾開 PR 後，主對話做 PR 中檢查）→ awaiting-approval（只有高風險）→ archived（歸檔後由 integrator 合併）`。沒有 `[BE]` 任務時跳過 `backend`，沒有 `[FE]` 任務時後端直接交 `integrating`。
- architect 沒有待確認問題時，主對話直接提交並推送提案（不等 user 核准）；開發 Agent 每完成一項任務就 WIP commit 並 push；PR 前審查通過後，integrator 收尾時把 WIP commit 重切成功能 commit。
- **流程中不固定停下等 user 確認**。主對話只在停下條件成立時問 user：釐不清的問題、規格免同步聲明要確認、退回超過上限、判定為高風險、衝突或其他 blocker（完整清單見 `/ship-issue`「停下條件」）。
- 同一目標（architect／後端／前端）退回上限 2 次，超過交給使用者；**integrator 檢查、PR 前審查、CI、PR 中評定的退回合併計算**。退回對象依發現所屬的端（`[BE]`／`[FE]`）決定。合併隊列失敗不退回，直接交給使用者（change 已歸檔）。

## 層層把關

| 階段 | 檢查 | 誰做 |
|------|------|------|
| PR 前 | 確保正常運行：兩個子目錄各自的測試、lint、typecheck、migration，以及執行驗證 | integrator「檢查」 |
| PR 前 | 驗證測試有效性：對關鍵模組跑變異測試 | integrator「檢查」 |
| PR 前 | 檢查代碼品質：對照規格審需求與測試覆蓋 | reviewer 審查模式 |
| PR 中 | CI：等 PR checks 全綠（沒有 CI 就記錄略過） | 主對話 |
| PR 中 | AI 審核：內建 `/code-review` | 主對話，reviewer 評定 |
| PR 中 | 安全審核：內建 `/security-review`（只在高風險時） | 主對話，reviewer 評定 |
| PR 中 | 按風險審批：低／中自動往下，高停下等 user 回覆「合併」 | 主對話 |
| 合併時 | 合併隊列：rebase 到最新主幹、重跑檢查與 CI，全綠才合併 | integrator「合併」 |

合併後的功能開關、逐步上線、觀察與回滾不在本流程內。

## 審查規則三分法

程式碼審查依規則性質分三處放，各司其職、不重複：

| 規則性質 | 放哪裡 | 誰檢查 | 何時 |
|----------|--------|--------|------|
| 機械性（命名格式、import 順序、程式碼格式） | linter／formatter 設定（ruff／ESLint 等） | integrator「檢查」實際跑 lint，與編輯後 hook | PR 前 |
| 對照 OpenSpec 的需求覆蓋與測試涵蓋 | `/custom-review` skill | reviewer（審查模式） | PR 前 |
| 需要判斷的專案慣例（分層、錯誤格式、命名原則） | 本 `CLAUDE.md` | 內建 `/code-review`，reviewer（評定模式）評級；開發 Agent 寫程式時遵守 | PR 中 |

- 機械性規則不交給 AI 審（交給 linter 擋，避免重複與浪費 token）；reviewer 遇到 `/code-review` 回報機械性項目會判為不成立。
- 審查直接採自動退回：只有 reviewer 評為「高嚴重度且高信心」的發現退回，其餘寫成 PR 備註並留言到 PR。
- 審查要能結束：第 2 輪起只審上一輪之後的新改動，前幾輪已記錄的發現不再重提，同類問題一次列出所有位置。

### 高風險檔案樣式

`/ship-issue` 第 7 步以 `git diff --name-only` 比對本清單，命中就把 `/code-review` 的 effort 調為 `high`、跑 `/security-review`，並把變更判定為高風險。依專案技術棧填（預設留通用範例，沒有就留空）：

| 類別 | 樣式範例（依專案調整） |
|------|------|
| migration／schema | 資料庫遷移檔目錄，例：`backend/**/migrations/**`（排除 `__init__`） |
| 認證 | 路徑或檔名含 `auth`、`token`、`session`、`jwt`、`otp`、`mfa` |
| 加密 | 引用加密函式庫或檔名含 `crypt` 的檔案 |
| 權限 | 路徑或檔名含 `permission`、`rbac`、`guard` |
| 流程設定 | `.claude/agents/**`、`.claude/hooks/**`、CI 設定 |

### 風險分級

`/ship-issue` 第 8 步依下表判定**整個變更**的風險等級。依專案調整：

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
| `/security-review` | 內建指令不接受參數，固定審查「目前分支 vs `origin` 預設分支」。主幹不是 `origin` 預設分支時改以 `/code-review high` 代替。需要能指定分支或 PR 的安全掃描時，可選裝官方 Claude Security plugin（`/claude-security`） |

`gh` 需要有本 repo 的 merge 權限。

## 執行驗證

integrator「檢查」會讀這一段，把產品跑起來觀察。沒寫這一段就略過，不擋流程。前後端都要跑時，啟動與停止寫成會同時啟動前後端的指令（例：docker compose），觀察點前後端都列。

<!-- 範例，依專案改寫；不需要就刪掉整段：
- **啟動**：`<背景啟動指令>`
- **就緒檢查**：`<指令>`（等待上限 60 秒）
- **觀察點**：
  - `curl -s -o /dev/null -w '%{http_code}' localhost:8000/health` → `200`
  - 截圖：`npx -y playwright@1.61.1 screenshot --wait-for-timeout 2000 http://localhost:5173/ {out}` → 首頁，標題「訂單管理」與左側選單可見，沒有錯誤提示
- **停止**：`<停止指令>`
-->

觀察點有兩種：

- **指令**：指令輸出或 HTTP 回應，與預期值比對。
- **截圖**：截圖指令用 `{out}` 佔位輸出檔，integrator 會換成 worktree 外暫存目錄的路徑，執行後用 Read 看圖，對照預期畫面判定。只有「明顯不符」（空白頁、錯誤頁、點名的元素不見）會擋流程；看不清時列為風險；截圖工具或瀏覽器沒裝時該點略過。

截圖觀察點的注意事項：

- 截圖工具與瀏覽器要預先裝在執行 integrator 的環境（例：`npx playwright install chromium`）。**指令要固定版本**，版本要和已安裝的瀏覽器相符。
- 等待頁面載入由截圖指令處理（`--wait-for-timeout`、`--wait-for-selector`）。
- 預期畫面要點名具體元素，不要寫「頁面正常」。
- 需要登入的頁面：先用 `--save-storage <檔案>` 存下登入狀態，截圖時帶 `--load-storage <檔案>`；這個檔案含憑證，放在 worktree 外、不進版控。也可以只截公開頁。
- 互動流程（點擊、填表）不在截圖觀察點內；需要時寫成 E2E 腳本，當作指令觀察點執行。

這一段是每次都跑的通用觀察點；**本次變更特有的觀察點由 architect 寫在 `design.md` 的「## 執行驗證觀察點」**，格式相同，integrator 兩者都跑。

## 變異測試

integrator「檢查」會對關鍵模組跑變異測試，確認 Agent 產出的測試真的能在程式出錯時失敗，而不只是存在。

- **只在 integrator「檢查」段跑**；開發 Agent 與 reviewer 都不跑。
- **範圍只限 architect 在 `design.md`「## 變異測試目標」逐案標示的關鍵模組**（例：權限檢查、狀態機），不做全專案變異測試。標示為「無」時記為不適用、不跑。
- **指令與通過閾值寫在這一段**；沒設定就略過、不擋流程。前後端用不同工具時分別寫。

<!-- 範例，依專案改寫；不需要就刪掉：
- **後端指令**：`<變異測試指令，接受目標模組/路徑參數>`
- **前端指令**：`<變異測試指令>`
- **通過閾值**：`<變異分數下限，例：80%>`
-->

- 某目標低於閾值時，integrator 退回該目標所屬那一端的開發 Agent，重現步驟寫該變異測試指令，退回次數與其他檢查合併計算。

## 新舊流程如何選用

| 情境 | 用哪條 |
|------|--------|
| 前後端都要改，或要讓 Agent 分工開發 | `/ship-issue <id>` |
| 小 issue、只動一端 | `/ship-issue <id>`（只有一端有任務時只派那一端），或單點呼叫該端開發 Agent |
| 單人照舊 | `/issue-reader` → `/issue-processor` → `/issue-solver` |

兩條流程**不可同時操作同一張 issue**。
