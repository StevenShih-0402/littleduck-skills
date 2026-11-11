---
description: 多 Agent 流程總指揮（single-side：一個 repo 只有一端、一個開發 Agent）：一張 Linear issue 從提案、實作、PR 前兩項檢查（osamu 檢查＋執行驗證、shiori 規格審查）、開 PR、PR 中四項檢查（CI、/code-review、/security-review、按風險審批）到歸檔與合併，全程自動；只在高風險、退回超過上限、衝突等停下條件成立時才停下問 user。
argument-hint: <linear-issue-id> [<linear-issue-id> …]
---

# /ship-issue $ARGUMENTS

你是主對話（總指揮）。**你不寫提案、不寫程式碼、不跑測試**，這些交給四個 Agent。你負責：問 user、建 worktree、派工、執行內建審查指令、判定風險、控制退回次數。

subagent 不能再派 subagent，也不能問 user，所以**所有要 user 決定的事都由你來問**。Agent 之間只透過 OpenSpec 變更目錄交接；派工時把參數寫進 prompt，不要轉述前一棒的對話內容。

主幹、worktree 根目錄、端與程式碼目錄讀本 repo `CLAUDE.md` 的「## agent-team 設定」；高風險檔案樣式、風險分級、合併方式、CI 等待上限讀同一份 `CLAUDE.md` 的對應段落。以下以 `<base>` 指主幹、`<wt>` 指本次的 worktree 路徑（`<worktree 根目錄>/<change-id>`）。

本流程**一份 worktree、一份變更目錄、一個 PR**，只有一個開發 Agent（yuma），依「端」走 `frontend-processor` 或 `backend-processor`。

## 停下條件

本流程**沒有固定的人工檢查點**。user 執行 `/ship-issue` 後，一路做到合併；只有下列情況才停下問 user：

| 情況 | 在哪一步 |
|------|----------|
| `CLAUDE.md` 沒有「## agent-team 設定」或缺欄位 | 0 |
| issue 或程式碼釐不清的問題（含 Hyuse 的待確認問題） | 0、2 |
| 規格免同步聲明要確認 | 4 |
| 同一目標的退回會超過上限 | 見「退回規則」 |
| 判定為高風險，等 user 回覆「合併」 | 8 |
| 推送、開 PR、rebase 衝突、合併隊列檢查或 CI 失敗、CI 等待逾時、服務未啟動等 blocker | 任何一步 |

除此之外**不要停下來問「要不要繼續」**。

## 退回規則

- 同一目標（architect／開發 Agent）**最多退回 2 次**，以 `handoff.md` 的退回紀錄計數。以下來源**合併計算**：Osamu 檢查（4）、PR 前規格審查（5）、CI（7.1）、PR 中評定（7.5）。
- 實作問題退回 yuma；需求問題退回 hyuse。
- 第 3 次要退回時停下，向 user 摘要歷次退回原因，等待指示。
- 同一項發現開發 Agent 已在 `handoff.md` 寫明不採納理由，之後又被回報：停下交給 user。
- 退回給開發 Agent 時，prompt 帶 `handoff.md`（審查退回時加上 `review.md`）路徑、「**接續模式**」，以及「逐項修正，或在 `handoff.md` 寫明不採納理由」。修完一律回到**第 4 步**。
- 退回給 Hyuse（需求問題）時，修完回到**第 2 步**的提交提案，再往下走。

## 審查輪次（讓審查能結束）

- `review.md` 每輪都記錄「已審到」的 HEAD SHA。
- **PR 前（第 5 步）**：第 1 輪範圍是 `origin/<base>...HEAD`；第 2 輪起是 `git diff <上一輪已審到的 SHA> HEAD`。
- **PR 中（第 7 步）**：「已審到」記的是該輪的**收尾 HEAD**（`handoff.md` 最後一節收尾紀錄的值），不是審查當下的 HEAD。第 1 輪範圍是 `origin/<base>...HEAD`；第 2 輪起是 `<上一輪的收尾 HEAD>..HEAD`。PR 開好後 Osamu 收尾只重切收尾 HEAD 之後的 commit，所以它會一直是 HEAD 的祖先，這個範圍成立。
- 派 Shiori 時一併給前幾輪的 `review.md`，已記錄過、判為不成立、開發者不採納的發現都不再重提。

---

## 0. 讀設定與 issue、決定參數

1. 讀本 repo `CLAUDE.md` 的「## agent-team 設定」：**結構**必須是 `single-side`，且有主幹、worktree 根目錄、端（`backend` 或 `frontend`）、程式碼目錄。缺段落、缺欄位或結構不符就停下，告訴 user 要補哪幾個欄位（格式見 `docs/multi-agent-workflow.md`）。
2. 載入 Linear MCP（`ToolSearch("select:mcp__linear__get_issue")`），讀 `$ARGUMENTS` 的每一張 issue。
3. **判定主 issue**：做法同 `issue-reader` 步驟 2-1。傳入的是 sub-issue 時，用 AskUserQuestion 問 user 要以 parent 還是這張為主 issue；有 sub-issue 就一併列入。
4. **決定 code、label、分支名、change-id**：
   - code：issue description 的 `code:` 行；沒有就依標題推一個 kebab-case，並**告知 user**（多張 issue 時用 AskUserQuestion 讓 user 選）。
   - label：issue 的 label 轉小寫（`feature`、`fix` 等）。
   - 分支：`<label>/<ISSUE-ID>-<code>`，ISSUE-ID 維持大寫，Linear automation 靠它辨識 issue。
   - change-id：`<issue-id 小寫>-<code>`，例：`eng-123-order-export`。OpenSpec CLI 只接受小寫。
5. **`repos` 固定為「## agent-team 設定」的端**，不必問 user。
6. `openspec/changes/` 已有同名 change 或**同一張 issue 的 change**（例：先前用 `/issue-reader` 建的），或已有同名分支、同名 worktree 時，停下回報 user，不要覆蓋。

## 1. 建 worktree

從主幹建立一份 worktree 與分支：`git worktree add -b <branch> <wt> origin/<base>`，並依 `CLAUDE.md`「## 檢查指令」的「安裝依賴」在程式碼目錄完成環境準備。失敗就停下回報。

## 2. 提案 → hyuse，提交提案

派 `hyuse`，prompt 帶入：主 issue、sub-issue、code、label、分支名、change-id、`repos`、`<wt>`。

Hyuse 回傳後，若有「待確認問題」，就問 user，把答案再派給 Hyuse 修正，直到沒有待確認問題。

沒有待確認問題時，**不等 user 核准**，直接執行以下步驟，任一步失敗就停下：

1. 把狀態區塊的「最後完成」改為「提案」、「下一步」改為「開始實作」、「暫停原因」改為「無」，並更新「更新」欄。
2. **只提交變更目錄**：`git -C <wt> add openspec/changes/<change-id>`，commit 訊息為 `wip(<ISSUE-ID>): 提案`。
3. 執行 `git -C <wt> push -u origin <branch>`。

開發 Agent 開工時會檢查 worktree 是否乾淨，所以提案一定要先提交。接著向 user 用一兩句話說明提案重點與任務數（**只是告知，不等回覆**），進第 3 步。

## 3. 實作 → yuma

派 `yuma`，帶入 change-id、`<wt>`。派之前確認 `git -C <wt> status --porcelain` 為空。

開發 Agent 中途停下（額度用完、push 失敗、服務未啟動等），處理完原因後重派，prompt 加上「**接續模式**」。它會先重跑最後一項已勾任務的驗證，再從第一個未勾選的任務繼續；狀態區塊已是 `integrating` 時不再派。

Yuma 回報「要退回 Hyuse」（需求不明、無法實作）時，依「退回規則」處理。

## 4. PR 前 ①：確保正常運行 → osamu「檢查」

派 `osamu`，帶入：change-id、`<wt>`、`<base>`、「**檢查**」。Osamu 會在程式碼目錄實際跑測試、lint、typecheck、migration，跑 `openspec validate`，並依 `CLAUDE.md` 的「## 執行驗證」與 `design.md` 的「## 執行驗證觀察點」把產品跑起來觀察，含指令與截圖觀察點（沒設定就記錄略過）。

- **退回**：Osamu 會回報退回對象與第 N 次（狀態區塊已由 Osamu 改回並 push）。依「退回規則」處理。
- **通過**：Osamu 已把狀態區塊改為 `reviewing`。
  - Osamu 回報了**規格免同步聲明**時，用 AskUserQuestion 逐條請 user 確認（列出目標、觸發路徑、理由）。user 不同意任何一條，就視同檢查失敗：在 `handoff.md` 追加退回紀錄、階段改回開發階段（依「端」為 `backend` 或 `frontend`），依「退回規則」退回 yuma。
  - 沒有聲明，或 user 全部同意 → 進第 5 步。

## 5. PR 前 ②：檢查代碼品質 → shiori「審查模式」

本步驟**不跑 `/code-review`**（它在第 7 步對 PR 跑）。在這一步內依序做完，**中途不寫 `review.md`**（中斷時只會留下被 ignore 的 patch）：

1. **產生 patch**：先 `git -C <wt> fetch origin <base>`，再依「審查輪次」決定範圍，寫到 `<wt>/openspec/changes/<change-id>/review-diff.patch`。Shiori 沒有 Bash、看不到 git diff，所以由你先產生；此檔已列入 `.gitignore`，不進 commit。
2. **派 Shiori**：變更含 delta specs 時，**一次**派 `shiori`，prompt 帶：「**審查模式**」、change-id、`<wt>`、變更目錄路徑（含 `review-diff.patch`）、前幾輪的 `review.md`（第 1 輪寫「無」）。純小改沒有 delta spec 時不派，本輪記為「未派（無 delta spec）」並視為通過。
3. **寫 `review.md`**：依 `openspec/review-template.md`，在變更目錄的 `review.md` 追加「第 N 輪 — PR 前」（檔案不存在就從範本建立），每條發現一列。處理欄：Shiori 評為「高嚴重度且高信心」的標「退回」，判為不成立的標「不成立」並附理由，其餘標「PR 備註」。
4. **狀態與 commit**：
   - 沒有要退回的：狀態區塊維持 `reviewing`，最後完成改「PR 前審查」、下一步「Osamu 收尾」；結果「通過」。
   - 有要退回的：狀態區塊改回開發階段（依「端」），暫停原因「PR 前審查退回第 N 次」；結果「退回第 N 次」，並在 `handoff.md` 追加退回紀錄。
   - 只 `git add` 變更目錄的 `review.md` 與 `handoff.md`，commit `wip(<ISSUE-ID>): PR 前審查第 N 輪` 並一般 push；然後刪除 `review-diff.patch`。
5. 有退回就依「退回規則」處理；沒有就進第 6 步。

## 6. 收尾、開 PR → osamu「收尾」

派 `osamu`，帶入：change-id、`<wt>`、`<base>`、「**收尾**」。

- Osamu 回報「需重新檢查」（檢查之後除 `handoff.md`、`review.md` 外還有變動）→ 回到第 4 步。
- **完成**：Osamu 已重切 commit（PR 已存在時只重切上次收尾之後的 commit）、以 `--force-with-lease` 推送、開好或沿用 PR（內文附 `review.md` 的 PR 備註），並把狀態區塊改為 `pr-checking` → 進第 7 步。

## 7. PR 中四項檢查（主對話執行）

依序做 7.1～7.5，**中途不寫 `review.md`**。

### 7.1 CI

1. 先用 `gh pr view <PR 網址> --json statusCheckRollup` 看 PR 有沒有任何 check。剛開 PR 時 check 可能還沒登記，**等 30 秒再看一次**，兩次都是空清單才判定「無 CI」，記錄略過、往下走。
2. 有 check 時執行 `timeout <CI 等待上限> gh pr checks <PR 網址> --watch --fail-fast`（上限見 `CLAUDE.md`「合併設定」，預設 30 分鐘），依 exit code 判讀：
   - `0`：全綠，往下走。
   - `124`（逾時）：停下回報 user，**不視為通過**。
   - 其他非 0：有 check 失敗。執行 `gh pr checks <PR 網址>` 取得失敗的 check 名稱與連結，在 `handoff.md` 追加退回紀錄（原因寫失敗的 check 與連結），依「退回規則」退回 yuma，**本輪 7.2 以後不做**。

### 7.2 AI 審核：內建 `/code-review`

1. **高風險判定**：`git -C <wt> diff --name-only origin/<base>...HEAD`，命中 `CLAUDE.md`「高風險檔案樣式」任一條，就是高風險。
2. 在本 session 內用 Skill 工具執行 `/code-review <level> <wt 絕對路徑> <範圍>`（範圍依「審查輪次」）。它以背景 forked subagent 執行，會讀到 worktree 的 `CLAUDE.md`。
   - effort level **每次明確寫出**（不寫會沿用上次輸入的 level）：預設 `medium`（`low` 容易漏報）；高風險時用 `high`。
   - 不帶 `--fix`、`--comment`；不用 `max`、`ultra`。

### 7.3 安全審核：內建 `/security-review`（只在高風險時）

不是高風險時，記為「不適用」，跳過。

官方文件：`/security-review` **不接受參數**，固定審查「目前分支 vs `origin` 預設分支」的 diff，並以 cwd 為準。主對話的 cwd 是 repo 根目錄（主幹），所以不能直接在本 session 執行：

1. 用 `git -C <wt> symbolic-ref --short refs/remotes/origin/HEAD` 取得 `origin` 預設分支。它等於主幹時，用 Bash 在 worktree 目錄以非互動模式執行：`cd <wt> && timeout 1200 claude -p "/security-review"`，取 stdout 作為發現。
2. 預設分支不等於主幹、指令失敗或沒有輸出時，**不另外跑**：7.2 對高風險變更本來就用 `high` effort，以它代替，並在 `review.md` 記「security-review 不可用，以 /code-review high 代替：<原因>」。

### 7.4 評定 → shiori「評定模式」

7.2、7.3 都完成後，**一次**派 `shiori`，prompt 帶：「**評定模式**」、change-id、`<wt>`、變更目錄路徑、本輪範圍的 `review-diff.patch`（產生方式同第 5 步）、`/code-review` 與 `/security-review` 的發現全文（沒有就寫「無」）、前幾輪的 `review.md`。

`/code-review` 與 `/security-review` 都沒有任何發現時，可以不派，本輪記為「無發現」。

### 7.5 寫 `review.md`、留言到 PR

1. 在 `review.md` 追加「第 N 輪 — PR 中」：範圍、已審到的 SHA、CI 結果、`/code-review` 實際指令、`/security-review` 結果（已跑／不適用／以 /code-review high 代替）、風險等級（判定方式見第 8 步；本輪有退回時寫「—」），每條發現一列。處理欄規則同第 5 步。
2. 用 `gh pr comment <PR 網址> --body-file <暫存檔>` 在 PR 留一則留言，內容是本輪標為「PR 備註」與「退回」的發現（沒有就寫「本輪無發現」）。暫存檔放在系統暫存目錄，用完刪除。
3. **狀態與 commit**：
   - 沒有要退回的：狀態區塊維持 `pr-checking`，最後完成「PR 中檢查」，下一步「風險審批」。
   - 有要退回的：做法同第 5 步第 4 點（暫停原因「PR 中檢查退回第 N 次」）。
   - 只 commit `review.md` 與 `handoff.md`，訊息 `wip(<ISSUE-ID>): PR 中檢查第 N 輪`，一般 push；刪除 `review-diff.patch`。
4. 有退回就依「退回規則」處理（修完回到第 4 步，之後的審查都只看新改動）。沒有就進第 8 步。

## 8. 按風險審批

依 `CLAUDE.md`「風險分級」判定**整個變更**的等級。判定在 7.5 寫 `review.md` 時就做，結果已記在最後一輪的「風險等級」欄。

- **低／中**：直接進第 9 步，不問 user。
- **高**：
  1. 狀態區塊改為 `awaiting-approval`，暫停原因「高風險，等待 user 回覆合併」；只 commit `handoff.md`、`review.md`，訊息 `wip(<ISSUE-ID>): 等待高風險審批`，一般 push。
  2. 向 user 摘要：判定為高風險的原因（命中的檔案樣式、破壞性 API 變更、成立的安全發現）、逐一列出高風險檔案、PR 連結、`review.md` 最後一輪的 PR 備註、`handoff.md` 中的風險項與執行驗證結果。請 user 看過這些檔案的 diff 後回覆「合併」。
  3. user 回覆「合併」→ 進第 9 步。user 要求修改 → 依內容派給 yuma（實作）或 hyuse（需求），算一次退回，修完回到第 4 步。**沒有明確回覆「合併」前，不得往下。**

## 9. 歸檔 → osamu「歸檔」

派 `osamu`，帶入：change-id、`<wt>`、`<base>`、「**歸檔**，PR 中檢查已通過」，高風險時再加「user 已回覆合併」。

Osamu 會歸檔（同步規格）、追加歸檔 commit、回寫 Linear。失敗就停下回報 user。

## 10. 合併 → osamu「合併」

派 `osamu`，帶入：change-id、`<wt>`、`<base>`、PR 網址、「**合併**」。

Osamu 會模擬合併隊列：rebase 到最新主幹、重跑檢查、等 CI；全綠才合併，並同步 sub-issue 狀態。

- **rebase 衝突、rebase 後檢查或 CI 失敗**：Osamu 不會合併。**停下交給 user**，摘要失敗原因與衝突檔案。change 已歸檔，不退回開發 Agent。

## 11. 最終報告

全部完成後向 user 回報：

- PR 連結與合併結果（合併 commit 或「未合併：原因」）
- 風險等級與判定理由；高風險時 user 何時回覆合併
- 各輪審查結果摘要：`review.md` 最後一輪的 PR 備註（逐條列出）、退回次數與原因
- 執行驗證結果（已跑／略過）、CI 結果（全綠／無 CI）、`/security-review` 實際走哪條路
- Linear 回寫結果
- 提醒 user：PR 已合併，要自行移除 worktree（`git worktree remove <wt>`）與已合併的分支

---

**小 issue**：沒有 API 變更時 Hyuse 的 `openapi.yaml` 寫 `paths: {}`；第 5 步沒有 delta spec 時不派 Shiori。其餘步驟照常，PR 中四項檢查不省略。
