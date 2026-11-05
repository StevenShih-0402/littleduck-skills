---
description: 多 Agent 流程總指揮：一張 Linear issue 從提案、前後端實作、檢查、程式碼審查到 PR 與歸檔，依序派工給 hyuse → chika → yuma → osamu（檢查）→ 程式碼審查（內建 /code-review ＋ shiori）→ osamu（收尾）→ osamu（歸檔），並在兩個人工檢查點停下。
argument-hint: <linear-issue-id> [<linear-issue-id> …]
---

# /ship-issue $ARGUMENTS

你是主對話（總指揮）。**你不寫提案、不寫程式碼、不跑檢查**，這些交給四個 Agent。你負責：問 user、建 worktree、派工、在檢查點停下、控制退回次數。

subagent 不能再派 subagent，也不能問 user，所以**所有要 user 決定的事都在這裡問完**再交棒。Agent 之間只透過 OpenSpec 變更目錄交接；派工時把下列參數寫進 prompt，不要轉述前一棒的對話內容。

repo 路徑、主幹分支、worktree 慣例見 team-hq 的 `CLAUDE.md`。

---

## 0. 讀 issue、決定參數（主對話）

1. 載入 Linear MCP（`ToolSearch("select:mcp__linear__get_issue")`），讀 `$ARGUMENTS` 的每一張 issue。
2. **判定主 issue**：做法同 `issue-reader` 步驟 2-1。傳入的是 sub-issue 時，用 AskUserQuestion 問 user 要以 parent 還是這張為主 issue；有 sub-issue 就一併列入。
3. **決定 code、label、分支名、change-id**：
   - code：issue description 的 `code:` 行；沒有就依標題推一個 kebab-case，並**告知 user**（多張 issue 時用 AskUserQuestion 讓 user 選）。
   - label：issue 的 label 轉小寫（`feature`、`fix` 等）。
   - 分支：`<label>/<ISSUE-ID>-<code>`，ISSUE-ID 維持大寫，Linear automation 靠它辨識 issue。
   - change-id：`<issue-id 小寫>-<code>`，例：`eng-123-order-export`。OpenSpec CLI 只接受小寫。
4. **決定要改哪幾端**（`repos`）：依 issue 內容判斷 backend、frontend；判斷不了就問 user。
5. 兩個 repo 的 `openspec/changes/` 已有同名 change，或已有同名分支時，停下回報 user，不要覆蓋。

## 1. 建 worktree（主對話）

依 team-hq `CLAUDE.md`「Worktree 慣例」，為 `repos` 列出的每一端，從該端主幹建立 worktree 與分支（`git worktree add -b <branch> <wt-root>/<repo>-<change-id> origin/<主幹>`），並依該端 `CLAUDE.md` 完成環境準備（例：安裝依賴、連結本機設定檔）。失敗就停下回報。

## 2. 提案 → hyuse

派 `hyuse`，prompt 帶入：主 issue、sub-issue、code、label、分支名、change-id、`repos`、兩端 worktree 路徑。

Hyuse 回傳後，若有「待確認問題」，就問 user，把答案再派給 Hyuse 修正，直到沒有待確認問題。

## 3. 檢查點 1：提案核准（停下）

向 user 摘要：change-id、提案重點、是否為破壞性變更、`openapi.yaml` 涉及的端點、`[BE]`／`[FE]` 任務數、兩端變更目錄路徑。

- user 回覆「核准」：在每一端執行以下步驟，任一步失敗就停下：
  1. 把狀態區塊的「最後完成」改為「提案核准」、「下一步」改為「開始實作」、「暫停原因」改為「無」，並更新「更新」欄。
  2. **只提交變更目錄**：`git add openspec/changes/<change-id>`，commit 訊息為 `wip(<ISSUE-ID>): 提案核准`。
  3. 執行 `git push -u origin <branch>`。

  開發 Agent 開工時會檢查 worktree 是否乾淨，所以提案一定要先提交。完成後進第 4 步。
- user 有修改意見：把意見派給 Hyuse 修正，再回到本檢查點。
- **沒有明確核准前，不得往下。**

## 4. 實作 → chika、yuma

先依序派工，穩定後再考慮平行：

1. `repos` 含 backend 時，派 `chika`，帶入 change-id、後端 worktree 路徑、前端 worktree 與其變更目錄路徑。定稿的 `openapi.yaml` 要複製到前端，並在前端 worktree 只 commit 這一個檔案。
2. `repos` 含 frontend 時，派 `yuma`，帶入 change-id、前端 worktree 路徑。派之前確認前端 worktree 乾淨（`git status --porcelain` 為空）。

開發 Agent 中途停下（額度用完、push 失敗、服務未啟動等），處理完原因後重派同一個 Agent，prompt 加上「**接續模式**」。它會先重跑最後一項已勾任務的驗證，再從第一個未勾選的任務繼續；狀態區塊已是 `integrating` 的那一端不再派。

任一 Agent 回報「要退回 Hyuse」（需求不明、無法實作）時，把原因派給 Hyuse 修提案，修完回到**檢查點 1**。

## 5. 檢查 → osamu

派 `osamu`，帶入：change-id、兩端 worktree 路徑、兩端主幹分支、「**檢查**」。

- **退回**：Osamu 會回報退回對象與第 N 次（被退回那一端的狀態區塊已由 Osamu 改回並 push）。讀兩端 `handoff.md` 確認次數（**與 5.5 程式碼審查的退回合併計算**）。N ≤ 2 時，把 `handoff.md` 路徑派給該 Agent 修正（開發 Agent 帶「接續模式」），修完再派 Osamu 檢查。
- **N 會超過 2 時停下**，向 user 摘要歷次退回原因，等待 user 指示，不再自動退回。
- **通過**：Osamu 已把各端狀態區塊改為 `reviewing`（最後完成「integrator 檢查」），**不重切、不開 PR** → 進 5.5。

## 5.5 程式碼審查（主對話）

Osamu 檢查通過後、收尾前，由你（主對話）執行程式碼審查。保留內建 `/code-review`，**不要建立同名 skill**（同名會整個取代內建審查，失去 effort／`--fix`／`ultra`）。

**審查模式：`shadow`**（導入後前 N 個 issue，N 預設 5；誤報率可接受後，經 user 同意才把這裡改為 `自動退回`，見下方「計數與切換」）。

對 `repos` 每一端，在這一步內依序做完，**中途不寫 `review.md`**（中斷時只會留下被 ignore 的 patch）：

1. **產生 patch**：先 `git -C <worktree> fetch origin <base>`，再 `git -C <worktree> diff origin/<base>...HEAD > <worktree>/openspec/changes/<change-id>/review-diff.patch`。Shiori 沒有 Bash、看不到 git diff，所以由你先產生；此檔已列入 kit 的 `.gitignore`，不進 commit。
2. **高風險判定**：`git -C <worktree> diff --name-only origin/<base>...HEAD`，命中 team-hq `CLAUDE.md`「高風險檔案樣式」清單（migration／認證／加密／權限相關；依專案填，預設可留通用範例）任一條就是高風險。
3. **內建 `/code-review`**：在本 session 內用 Skill 工具執行 `/code-review <level> <worktree 絕對路徑> origin/<base>...HEAD`（目標文字一定要寫 worktree 路徑與範圍；它以背景 forked subagent 執行，會讀到該 worktree 的 `CLAUDE.md`）。前後端可同時啟動，等兩邊都回來再往下。
   - effort level **每次明確寫出**（不寫會沿用上次輸入的 level）：預設 `medium`（`low` 容易漏報）；該端高風險時用 `high`。
   - 不帶 `--fix`、`--comment`；不用 `max`、`ultra`。
4. **Shiori**：變更含 delta specs 時，所有端的 `/code-review` 都跑完後，**一次**派 `shiori`（她依預先載入的 `/custom-review` 步驟審查），prompt 帶：change-id、`repos` 每一端的 worktree 路徑與變更目錄路徑（含 `review-diff.patch`）、各端 `/code-review` 的發現全文（沒有就寫「無」）、審查模式。純小改沒有 delta spec 時可不派，只以 `/code-review` 的發現列 PR 備註。
5. **寫 `review.md`**：依 team-hq `openspec/review-template.md`，在每一端變更目錄的 `review.md` 追加「第 N 輪」（檔案不存在就從範本建立）：模式（shadow 時寫第幾個 issue）、範圍（`origin/<base>...<HEAD SHA>`）、高風險檔案、`/code-review` 實際指令、Shiori 是否派出；每條發現一列。處理欄依模式：
   - **shadow**：Shiori 建議退回的標「shadow：建議退回」，其餘「PR 備註」；不退回。
   - **自動退回**：Shiori 評為「高嚴重度且高信心」的標「退回」（含 Shiori 對 `/code-review` 發現的評級），其餘「PR 備註」。
   - 沒派 Shiori（小改）時：`/code-review` 的發現一律「PR 備註」。
   - Shiori 判為不成立的，處理欄標「不成立」並附理由。
6. **狀態與 commit**：
   - 沒有要退回的：每一端狀態區塊維持 `reviewing`，最後完成改「程式碼審查」、下一步「Osamu 收尾」；結果「通過」。
   - 有要退回的：被退回那一端改回 `backend`／`frontend`（暫停原因「程式碼審查退回第 N 次」），其他端改回 `integrating`；結果「退回第 N 次」，並在被退回那一端 `handoff.md` 追加退回紀錄（**N 與 Osamu 退回合併計算**）。
   - 每一端只 `git add` 變更目錄的 `review.md` 與 `handoff.md`，commit `wip(<ISSUE-ID>): 程式碼審查第 N 輪` 並一般 push；然後刪除 `review-diff.patch`。
7. **退回**：N ≤ 2 時把 `review.md`、`handoff.md` 路徑派給該 Agent，prompt 加「逐項修正，或在 `handoff.md` 寫明不採納理由」；修完回到第 5 步（Osamu 重新檢查），再回到本步驟審查。第 3 次要退回時停下交給 user。同一項不採納後再次被回報，也停下交給 user。

**計數與切換**：開始審查時，數各端 archive 目錄中模式為 shadow 的 `review.md`（同一 change-id 只算一次），加上本次就是第幾個 shadow issue。累計滿 N 個後，在下一次檢查點 2 彙報誤報率（user 判定「不認同」條數 ÷ 總條數）並問 user 是否改為自動退回；user 同意才改上方「審查模式」。

## 5.6 收尾 → osamu

派 `osamu`，帶入：change-id、兩端 worktree 路徑、兩端主幹分支、「**收尾**」。

- Osamu 回報「需重新檢查」（檢查之後除 `handoff.md`、`review.md` 外還有變動）→ 回到第 5 步。
- **完成**：Osamu 已把 WIP commit 重切成功能 commit、以 `--force-with-lease` 推送、開好 PR（說明附 `review.md` 最後一輪的 PR 備註），並把兩端狀態區塊改為 `ready-to-archive` → 進檢查點 2。

## 6. 檢查點 2：歸檔前確認（停下）

向 user 摘要：

- Osamu 實際跑的測試、lint、typecheck、`openspec validate` 結果；
- 重切後的 commit 清單與 tree 比對結果；
- 兩個 PR 連結（請 user 看 diff）；
- 兩端 `handoff.md` 中的風險與未完成項；
- `review.md` 最後一輪的結果（PR 備註；shadow mode 時逐條列出，請 user 判定「認同／不認同」）；
- **高風險檔案**（有的話逐一列出，請 user 確認已逐一看過這些檔案的 diff，沒有確認不歸檔）；
- 規格免同步聲明：逐條列出目標與理由，請 user 確認確實屬於該規則允許免同步的情形。

處理方式：

- user 回覆「歸檔」：shadow mode 時先把 user 的逐條判定回填到各端 `review.md` 的「user 判定」欄，只 commit `review.md`（`wip(<ISSUE-ID>): 記錄審查判定`）並 push，再進第 7 步。
- user 要求修改：依內容派給 Chika 或 Yuma（實作問題）、或 Hyuse（需求問題）。修完後回到第 5 步，Osamu 會從分支起點重切全部 commit。
- **沒有明確回覆「歸檔」前，不得往下。**

## 7. 歸檔 → osamu

派 `osamu`，帶入：change-id、兩端 worktree 路徑、兩端主幹分支、「**歸檔**，user 已回覆歸檔」。

完成後向 user 回報：歸檔路徑、`validate --specs` 結果、追加的 commit、Linear 回寫結果、沒做完的事。並提醒 user：PR 合併後要自行移除 worktree。

---

**小 issue 的捷徑**（只動單一 repo、沒有 API 變更）：`repos` 只填那一端，Hyuse 的 `openapi.yaml` 寫 `paths: {}`，第 4 步只派那一端的開發 Agent；5.5 沒有 delta spec 時可不派 Shiori，只跑 `/code-review`。
