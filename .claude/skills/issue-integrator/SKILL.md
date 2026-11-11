---
name: issue-integrator
description: 多 Agent 流程的 integrator。分四段：「檢查」依專案 CLAUDE.md 的「## agent-team 設定」在各子目錄實際跑測試／lint／typecheck／migration 與執行驗證、核對 tasks、契約與規格同步，通過後設 reviewing 交主對話做 PR 前審查；「收尾」在審查通過後重切 commit、以 --force-with-lease 推送並開 PR（附 review.md 的 PR 備註）；「歸檔」在 PR 中檢查通過後執行 /opsx:archive、追加歸檔 commit 並回寫 Linear；「合併」模擬合併隊列，rebase 到最新主幹、重跑檢查與 CI，全綠才合併。支援 fullstack 與 single-side。Use when the integrator agent is dispatched by /ship-issue for check, finish, archive, or merge.
---

# Skill: Issue Integrator

多 Agent 流程的**整合與發布**角色（流程總覽見專案 `CLAUDE.md` 與 `docs/multi-agent-workflow.md`）。

本 skill 對應單人流程 `issue-processor` 的步驟 5 與 `issue-solver`，有幾個刻意的差異：

- **先開 PR、後歸檔**：單人流程是先歸檔再開 PR；這裡先開 PR 讓主對話跑 PR 中檢查（CI、`/code-review`、`/security-review`、風險審批），全部通過後才歸檔並追加歸檔 commit。
- **中間有審查**：「檢查」通過後不立刻重切、開 PR，而是設 `reviewing` 並停下，由主對話派 reviewer 做 PR 前審查；通過後才派本 skill「收尾」。
- **重切 commit**：開發 Agent 每完成一項任務就推送一筆 WIP commit；收尾時，由本 skill 把它們重切成依功能分組的 commit。
- **合併也是這裡做**：歸檔後由本 skill 模擬合併隊列並合併 PR。

以下「`issue-processor`」「`issue-solver`」指 `.claude/skills/` 下的同名 skill，Linear 模板在 repo 根目錄的 `linear/`。**做法照這兩個 skill 的對應步驟，本檔只寫差異。**

## 輸入

### 主對話傳入

- change-id、worktree 路徑（`wt/<change-id>`）
- 主幹分支（PR 的 base），例：`main`
- 這次是「**檢查**」、「**收尾**」、「**歸檔**」還是「**合併**」
  - 歸檔時必須附帶「PR 中檢查已通過」；變更判定為高風險時，還要附帶「user 已回覆合併」
  - 合併時必須附帶 PR 網址

缺少任何一項就停下回報。prompt 指定的執行段不是這四者之一時，停下回報，不要自行猜。

### 專案 `CLAUDE.md` 的「## agent-team 設定」

- **fullstack**：後端子目錄、前端子目錄。`.linear.md` 的 `repos` 列出的每一端，在**該端子目錄**跑該端的檢查（欄位列多個路徑時，第一項是跑檢查的目錄，全部項目都算該端的範圍）。
- **single-side**：程式碼目錄（預設 `.`）與端。只有一端，在程式碼目錄跑一次。

以下「各端」指 `repos` 列出的端：fullstack 可能是一端或兩端，single-side 永遠只有一端。缺這一段或缺欄位就停下回報。

## 邊界

- 不改程式碼，也不改 `tasks.md`、`proposal.md`、`design.md`、`openapi.yaml`（寫入限制 hook 會擋 Write／Edit），**不用 Bash 改檔**。
- 例外：B 段重切時的 `git reset --soft` 與 `git restore --staged`（只動 index），以及 D 段的 `git rebase`／`git rebase --abort`。
- 截圖觀察點的截圖指令會寫檔，但只寫到 worktree 外的暫存目錄，不算改檔；**不可把截圖寫進 worktree**。
- 可以寫：`handoff.md`、`.linear.md`，以及歸檔時同步的 `openspec/specs/**`。
- **不採信前一棒的結果**，每一項都自己實際執行。

### 指令從哪裡來

測試、lint、型別檢查、migration、執行驗證的實際指令與執行環境，**一律以專案 `CLAUDE.md`（「## 檢查指令」等段落）與本 change 的 `design.md` 為準**。兩份都沒寫某端的必要指令（測試、lint）時，停下回報缺少哪一端的哪一項，不要猜指令。執行驗證沒寫則略過（見 A2）。

### 退回對象

依問題所屬的端決定退回給誰：後端子目錄的問題、`[BE]` 任務、API 實作與 `openapi.yaml` 不符 → 後端 Agent；前端子目錄的問題、`[FE]` 任務 → 前端 Agent；需求或提案本身的問題 → architect。single-side 的實作問題一律退回唯一的開發 Agent。

---

## A. 檢查

### A1. 讀交接資料

讀變更目錄的 `.linear.md`、`handoff.md`、`tasks.md`、`openapi.yaml`。缺檔就退回 architect（見 A4）。

讀 `handoff.md` 的狀態區塊：階段不是 `integrating`，就停下回報「尚未完成實作」，不往下檢查。

### A2. 實際執行

對各端，在該端子目錄（single-side 為程式碼目錄）依 `CLAUDE.md` 執行：

| 項目 | 範圍 |
|------|------|
| 測試 | 本次變更範圍的測試 |
| lint | 本次變更、且位於該端子目錄的檔案（`git diff --name-only $(git merge-base HEAD origin/<base>) -- <子目錄>`），不跑會 autofix 的指令 |
| 型別檢查 | 該端有型別檢查時執行 |
| migration | 有 migration 時，先 migrate 到新版，再退回前一版，最後 migrate 回新版，確認正反向都能執行 |
| 規格 | 在 worktree 根目錄執行 `openspec validate <change-id> --strict` 與 `openspec validate --specs`（只跑一次） |
| 變異測試 | 本 change `design.md`「## 變異測試目標」所列的關鍵模組，見下 |
| 執行驗證 | 見下（整個 repo 跑一次） |

需要的資料庫、快取等服務未啟動時，**停下來請 user 自己啟動**，不要代為啟動。

**變異測試**（驗證關鍵模組的測試有效性）：對 `design.md`「## 變異測試目標」所列的關鍵模組跑變異測試，確認開發 Agent 產出的測試能在程式出錯時失敗，而不只是存在。

- 指令與通過閾值**取自專案 `CLAUDE.md` 的「## 變異測試」**；前後端各有指令時，依目標所在的子目錄選用（D 段時 change 已歸檔，改讀 `openspec/changes/archive/*-<change-id>/design.md` 的目標清單）。
- 下列情況記為略過／不適用，**不因此判為失敗**，在 `handoff.md` 與報告寫明：
  1. 「## 變異測試目標」內容為「無」→ 記「不適用（本次無關鍵模組）」；
  2. `CLAUDE.md` 沒有可用的變異測試指令 → 記「略過（CLAUDE.md 未設定變異測試）」。
- 有指令且有目標時，對每個目標模組執行變異指令，記下存活變異（surviving mutants）或變異分數，以及是否達閾值。
- 任一目標**低於閾值** → 退回該目標所屬那一端的開發 Agent（A4），重現步驟寫該變異測試指令。

**執行驗證**（PR 前「確保正常運行」）：觀察點有兩個來源，兩者都要跑，報告時分開列：

- **專案通用**：`CLAUDE.md` 的「## 執行驗證」段，每次都跑；
- **本次專屬**：`design.md` 的「## 執行驗證觀察點」段（D 段時 change 已歸檔，改讀 `openspec/changes/archive/*-<change-id>/design.md`）。內容寫「無」就只跑專案通用的觀察點。

1. `CLAUDE.md` 沒有「## 執行驗證」段，或段內沒有**啟動**指令：不執行，`design.md` 的觀察點也不跑（沒有啟動方式）。在 `handoff.md` 與報告記「執行驗證：略過（CLAUDE.md 未設定）」，**不因此判為失敗**。
2. 有設定時依序執行：
   - 以背景方式執行**啟動指令**，記下 PID 或停止方式；
   - 依**就緒檢查**等到服務就緒，超過該段寫的等待上限（沒寫就 60 秒）判為失敗；
   - 有截圖觀察點時，先用 `mktemp -d` 建暫存目錄（**必須在 worktree 外**，否則工作樹會變髒）；
   - 逐一執行**觀察點**，記下實際結果。觀察點分兩種：
     - **指令**：指令＋預期輸出，例：`curl -s -o /dev/null -w '%{http_code}' localhost:8000/health` 預期 `200`；
     - **截圖**：截圖指令＋預期畫面，處置見下；
   - 不論成功或失敗，最後都執行**停止指令**（沒寫就結束記下的 PID），確認沒有殘留的程序。
3. 任一觀察點不通過 → 退回該觀察點所屬那一端的開發 Agent（A4；API 回應歸後端、畫面歸前端），重現步驟寫該觀察點的指令（截圖觀察點附截圖路徑）。

**截圖觀察點**：截圖指令以 `{out}` 佔位輸出檔。把它換成 `<暫存目錄>/<序號>.png` 後執行：

| 結果 | 怎麼認 | 處置 |
|------|--------|------|
| 有產出 PNG | 指令成功、檔案存在 | 用 Read 開圖，對照預期畫面判定（見下表） |
| 工具不可用 | 沒產出 PNG，且錯誤訊息含 `command not found`（exit 127）、`npx canceled due to missing packages`、`Executable doesn't exist` 或 `playwright install` 等「工具或瀏覽器沒裝」的訊息 | 該點記為「略過（工具不可用）」並附錯誤訊息，**不因此判為失敗** |
| 產品連不上 | 沒產出 PNG，且錯誤訊息是 `net::ERR_` 開頭（例：`net::ERR_CONNECTION_REFUSED`）或導覽逾時 | 不通過 |
| 其他失敗 | 沒產出 PNG，訊息無法歸類 | 視為「無法確定」，附錯誤訊息 |

> exit code 不足以區分工具缺失和產品問題：實測 `npx -y playwright@<版本> screenshot` 在瀏覽器未安裝、連線被拒時都是 exit 1。一定要看錯誤訊息。

看圖判定：

| 判定 | 條件 | 處置 |
|------|------|------|
| 符合 | 畫面呈現預期畫面點名的元素與文字 | 通過 |
| 明顯不符 | 空白頁、錯誤頁（含 404／500）、框架的錯誤覆蓋層、亂碼、預期畫面點名的元素不存在 | 不通過 |
| 無法確定 | 畫面有內容，但無法從圖判斷是否符合（例：資料筆數看不清、元素被遮住） | **不判為失敗**；在 `handoff.md` 列為風險，附截圖路徑與看不清的地方，交給 PR 前審查參考 |

只有「明顯不符」與「產品連不上」會擋流程。拿不準時判「無法確定」，不要判「明顯不符」，避免無謂退回占用退回次數。截圖留在暫存目錄、不刪除，路徑寫進 `handoff.md`。

### A3. 核對

- `tasks.md` 沒有未勾選的 `- [ ]`。env-blocked 且已就地註記的項目可以放行，但要列進報告。
- 後端實作的路由與回應欄位和 `openapi.yaml` 一致（可依 `CLAUDE.md` 產出實際 schema 來比對）；fullstack 時，前端讀取的欄位也都在 `openapi.yaml` 裡。`openapi.yaml` 只有一份，不比對副本。
- worktree 乾淨（`git status --porcelain` 為空），且本機分支與 `origin/<branch>` 一致（`git status -sb` 沒有 ahead 或 behind）。不符就停下回報，不自行 commit 或 push。
- fullstack：後端 Agent 的 commit 沒有動到前端子目錄，前端 Agent 的反之（以 `wip(<ISSUE-ID>): <任務編號>` 對應 `tasks.md` 的 `[BE]`／`[FE]`，用 `git show --name-only` 檢查）。越界時退回越界的那一端。
- 破壞性變更有照 `CLAUDE.md`「API 相容性」的規定新舊版並存：舊端點保留，新增跳版號的端點。
- 開發 Agent 沒有改 `proposal.md`：執行 `git log --format='%h %s' $(git merge-base HEAD origin/<base>)..HEAD -- openspec/changes/<change-id>/proposal.md`。訊息以 `wip(` 開頭、但不是 `wip(<ISSUE-ID>): 提案` 的 commit，就表示開發 Agent 動過提案。主對話提交提案的 commit、上一輪重切後的功能 commit 都不算。
- **規格同步（最終閘門）**：專案有 `openspec/spec-sync.yaml` 時，依 `spec-sync/README.md` 的「判定」，以 `git diff --name-only $(git merge-base HEAD origin/<base>)` 收集路徑並換算出目標：
  - 通過的目標記下即可；`capability` 目標在報告註明「歸檔時由 sync 寫入主規格」。
  - 不通過的目標：如果 `handoff.md` 有對應的免同步聲明（`- **規格免同步**：<目標> — <理由>`），就放行，並把聲明逐條列進報告，**由主對話當下請 user 確認**；沒有聲明就**不通過**，退回觸發路徑所屬那一端的開發 Agent。
  - 規則設定錯誤（同時寫了兩種目標或兩種都沒寫）時判為不通過，退回 architect 並在報告點出。
  - 只檢查有沒有寫，不判斷內容是否正確，也不自行補寫規格。
  - 沒有 `spec-sync.yaml` 時，這一項不適用。

### A4. 退回

任一項不通過時：

1. 在 `handoff.md` 追加一節 integrator 紀錄，寫明：「退回：第 N 次」、退回對象（architect／後端 Agent／前端 Agent，single-side 為開發 Agent）、原因、重現指令。N 是同一對象在 `handoff.md` 中既有的退回次數加一（**與 PR 前審查、CI、PR 中評定的退回合併計算**）。同時有多端不通過時，每一端各記一筆。
2. 把狀態區塊的階段改回被退回那一端的 `backend`／`frontend`（fullstack 兩端都退回時改 `backend`：後端修完、交棒後再由前端修；退回 architect 時改為 `proposal`）。「暫停原因」填「integrator 退回第 N 次」，「下一步」填要修的內容。
3. 只 commit `handoff.md`，訊息為 `wip(<ISSUE-ID>): integrator 退回第 N 次`，然後一般 `git push`。交棒時 worktree 要保持乾淨。
4. 回報主對話要退回給誰。**N 會超過 2 時就不再退回**，改為回報「需 user 處理」，並摘要歷次退回原因。

ISSUE-ID 取 `.linear.md` 的 `primary_issue`。

### A5. 通過：設 reviewing、交出審查

檢查全部通過時，**不重切、不開 PR**（那是收尾段的事）：

1. 更新狀態區塊：階段改為 `reviewing`，「最後完成」填「integrator 檢查」，「下一步」填「PR 前審查」。
2. 追加一節「integrator（<Agent 名稱>）— 檢查通過」，內容包括：各端每項檢查的實際指令與結果、變異測試結果（逐一列出每個目標模組的變異分數與是否達閾值；略過／不適用的附原因）、執行驗證結果（專案通用與本次專屬分開，逐一列出觀察點的結果；截圖觀察點附截圖路徑，略過的附原因；整段沒設定就寫「略過」）、截圖暫存目錄路徑、規格免同步聲明、風險（含判為「無法確定」的截圖觀察點）。
3. 只 commit `handoff.md`，訊息 `docs(openspec): 記錄 <ISSUE-ID> 檢查結果`，一般 `git push`。

回報主對話（主對話據此進行**PR 前審查**）：

- 各端每項檢查的指令與結果、變異測試結果（每個目標模組達標／未達標，或略過／不適用）、執行驗證結果（含截圖觀察點：通過／略過／無法確定各幾點）；
- `handoff.md` 中的風險項，包括判為「無法確定」的截圖觀察點與截圖路徑；
- 規格免同步聲明：逐條列出目標、觸發路徑與理由；沒有就寫「無」。

---

## B. 收尾（只在主對話傳入「收尾」時；PR 前審查已通過）

收尾前先確認狀態區塊階段為 `reviewing`；不是就停下回報。在 worktree 執行：

1. `git fetch origin <base>`；`git status --porcelain` 必須為空（審查只動了變更目錄的 `review.md`、`handoff.md`，且已 commit）。若檢查之後除 `handoff.md`、`review.md` 外還有變動，回報主對話「需重新檢查」。
2. 記下 `OLD=$(git rev-parse HEAD)`，並決定重切起點 `FROM`：
   - 還沒有 PR（`gh pr view <branch>` 失敗）：`FROM=$(git merge-base HEAD origin/<base>)`，從分支起點重切全部 commit。
   - PR 已存在：`FROM` 取 `handoff.md` 最後一節收尾紀錄的「收尾 HEAD」，**只重切它之後的 commit**。之前的 commit SHA 保持不變，PR 中審查才能用 `<上輪 SHA>..HEAD` 做增量審查。`FROM` 不是 `HEAD` 的祖先（`git merge-base --is-ancestor $FROM HEAD` 失敗）時停下回報。
   - `FROM` 等於 `OLD`（沒有新 commit）時跳過第 3～5 步。
3. 執行 `git reset --soft $FROM`，再執行 `git restore --staged .`（只動 index，不動工作樹）。接著依功能分批 `git add <路徑>` 並 commit，切法照 `issue-solver` **步驟 4**（繁體中文 message、`Co-Authored-By` 署名行）。注意：
   - 此時**還沒歸檔**，所以不含 `chore(openspec)` 歸檔那一筆；
   - 變更目錄本身（含 `review.md`）與實作放在同一批；
   - fullstack 的前後端改動**分開 commit**（例：`feat(api): …`、`feat(web): …`），方便 PR 中依端閱讀；
   - 退回修正後的重切（PR 已存在）以「修正內容」分組，例：`fix(<範圍>): 修正 PR 中審查指出的 …`。
4. `git diff $OLD HEAD` 必須為空。不為空就 `git reset --soft $OLD` 還原，並停下回報。
5. 執行 `git push --force-with-lease=<branch>:$OLD origin <branch>`。被拒絕就停下回報，**不得改用 `--force`**。
6. 開 PR 照 `issue-solver` **步驟 6**；PR 已存在就沿用（force push 後內容會自動更新）。base 用主對話傳入的主幹。
   - **PR 內文附上 `review.md` 標為「PR 備註」的發現**（沒有就寫「目前無 PR 備註」）；PR 已存在時用 `gh pr edit --body-file` 更新這一段。
   - 一個 change 只有一個 PR，主 issue 的 magic word 放在這個 PR。
7. 更新狀態區塊：階段改為 `pr-checking`，「最後完成」填「integrator 收尾（開 PR）」，「下一步」填「PR 中檢查」。
8. 追加一節「integrator（<Agent 名稱>）— 收尾」，內容包括：重切前的 SHA `OLD`、重切起點 `FROM`、重切後的 commit 清單、tree 比對結果、PR 連結、附進 PR 的 review.md 備註條數、風險，以及一行「**收尾 HEAD**：`<第 5 步推送後的 git rev-parse HEAD>`」。下次收尾以它為 `FROM`；本筆紀錄 commit 在它之後，會和之後的修正一起被重切。
9. 以 `docs(openspec): 記錄 <ISSUE-ID> 收尾結果` commit，並一般 `git push`。

回報主對話（主對話據此進行**PR 中檢查**）：

- 重切前的 SHA、重切起點、重切後的 commit 清單、tree 比對結果；
- PR 連結；
- `handoff.md` 中的風險項。

---

## C. 歸檔（只在 prompt 寫明「PR 中檢查已通過」時）

先確認前置條件，任一不成立就停下回報、不歸檔：

- prompt 寫明「PR 中檢查已通過」；
- `review.md` 最後一輪的風險等級為「高」時，prompt 另外寫明「user 已回覆合併」；
- 狀態區塊階段為 `pr-checking` 或 `awaiting-approval`。

在 worktree 執行：

1. **歸檔**：在 worktree 的根目錄，用 Skill 工具執行 `openspec-archive-change`（即 `/opsx:archive <change-id>`；不可用時直接讀 `.claude/skills/openspec-archive-change/SKILL.md` 照做），做法照 `issue-solver` **步驟 3**。
   - 歸檔流程中需要選擇是否同步 spec 時，一律選「同步」；
   - 遇到無法自行判斷的 blocker 就停下回報。
2. **驗證**：在 worktree 根目錄執行 `openspec validate --specs`，失敗就停下回報。
3. **更新交接檔**：把 archive 目錄內 `handoff.md` 的狀態區塊階段改為 `archived`（下一步「合併」），`.linear.md` 的 `stage` 改為 `archived`。
4. **commit 與推送**：以 `chore(openspec): 歸檔 <change-id>（<ISSUE-ID>）` 為一筆 commit，一般 push 到同一條分支。
5. **回寫 Linear**：照 `issue-processor` **步驟 5**（主 issue 補兩個引言區塊；sub-issue 寫 `# 實作完成（日期）`，依 `linear/change_template.md`）。`repos` 同時有前後端時，`# 實作完成` 分成「後端」「前端」兩段，各列出該端的 `tasks.md` 項目。
6. **PR comment 與 sub-issue 狀態**：照 `issue-solver` **步驟 7**。主 issue 的狀態交給 Linear automation，不手動改。

回報：

- 歸檔路徑、`validate --specs` 結果、追加的 commit
- Linear 回寫結果
- 沒做完的事與原因

---

## D. 合併（模擬合併隊列；只在主對話傳入「合併」時）

先確認前置條件，任一不成立就停下回報、不合併：

- `openspec/changes/<change-id>/` 已不存在，且 `openspec/changes/archive/` 下有 `*-<change-id>`（已歸檔）；
- worktree 乾淨，本機分支與 `origin/<branch>` 一致；
- prompt 帶了 PR 網址，且 `gh pr view <網址> --json state` 為 `OPEN`。

合併方式取 `CLAUDE.md`「合併設定」（沒寫就用 `--merge`，保留重切後的功能 commit）；CI 等待上限取同一處（沒寫就 30 分鐘）。

### D1. 排隊：驗證

1. `git fetch origin <base>`。`git merge-base --is-ancestor origin/<base> HEAD` 成立（主幹沒有前進）就跳到第 4 步。
2. 記下 `OLD=$(git rev-parse HEAD)`，執行 `git rebase origin/<base>`。
   - **衝突**：立刻 `git rebase --abort`，確認 `git rev-parse HEAD` 等於 `OLD`，停止整個 D 段，回報衝突的檔案（`git diff --name-only --diff-filter=U` 在 abort 前取得）。**不合併。**
3. 對各端重跑 A2 的測試、lint、型別檢查、migration，以及執行驗證（有設定才跑；本次專屬觀察點改讀歸檔目錄的 `design.md`，截圖觀察點的判定同 A2）。任一失敗 → 執行 `git reset --hard $OLD` 還原到 rebase 前（只在本段允許，因為工作樹在 rebase 前是乾淨的），停止整個 D 段並回報失敗項目與重現指令。**不退回開發 Agent**（change 已歸檔，開發 Agent 找不到交接檔），交由 user 決定。
   通過後執行 `git push --force-with-lease=<branch>:$OLD origin <branch>`，被拒絕就停下回報，不得改用 `--force`。
4. 等 CI：用 `gh pr view <網址> --json statusCheckRollup` 確認有沒有 check（剛推送時等 30 秒再看一次，兩次都空才判定無 CI）。有 check 時執行 `timeout <上限> gh pr checks <網址> --watch --fail-fast`：`0` 通過；`124` 逾時、其他非 0 失敗，都停止整個 D 段並回報，不合併。

### D2. 合併

1. 合併前再 `git fetch origin <base>`。主幹在 D1 之後又前進時，重跑一次 D1（衝突或失敗就停下回報）。
2. `gh pr merge <PR 網址> --merge`（或設定的合併方式），確認 `gh pr view --json state` 變成 `MERGED`。
3. 不帶 `--admin`，不帶 `--delete-branch`，不刪 worktree。

### D3. 同步 Linear

合併完成後，用 `mcp__linear__get_issue` 讀主 issue 目前的狀態（由 Linear automation 依 PR 合併轉換）。`.linear.md` 的 `sub_issues` 不是 `-` 時，把每一張 sub-issue 的狀態改成和主 issue 相同（`mcp__linear__save_issue` 的 `state`）。主 issue 還沒轉換時，等 30 秒再讀一次；仍未轉換就在報告註明「主 issue 狀態未自動轉換，sub-issue 未同步」，不手動改主 issue。

回報：

- 是否 rebase、各端重跑檢查（含執行驗證與截圖觀察點）與 CI 結果；
- 合併結果（PR 網址與 `MERGED`，或停在哪一步、原因）；
- sub-issue 同步結果；
- 提醒：worktree 與已合併的分支由 user 自行移除。

---

## 護欄

- 檢查段不重切、不開 PR、不歸檔；收尾段才重切與開 PR；沒有「PR 中檢查已通過」（高風險時加上「user 已回覆合併」）就不進入 C 段；沒有歸檔就不進入 D 段。
- 只在 B 段（重切）與 D 段（rebase）以帶預期值的 `--force-with-lease=<branch>:<SHA>` 推送，其他情況一律不 force push，也不得改用 `--force`。
- `git reset --hard` 只允許在 D1 第 3 步還原到 rebase 前的 `OLD`。
- **只在 D 段 merge PR**：前置條件都成立、檢查與 CI 都綠才合併；禁止 `gh pr merge --admin`，禁止繞過失敗或逾時的檢查。不刪分支、不刪 worktree。
- 不改 PR 的 reviewer／label；對 Linear 只寫 `issue-processor`／`issue-solver` 允許的欄位，以及 D3 的 sub-issue 狀態。
- 發現問題只退回或回報，不自己修。
- 不修改 `linear/*_template.md` 與 `issue-*` skill。
