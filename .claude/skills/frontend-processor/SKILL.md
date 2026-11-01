---
name: frontend-processor
description: 多 Agent 流程的前端實作（Yuma）：讀 OpenSpec 變更目錄的 proposal／design／openapi.yaml／tasks 的 [FE] 項 → 在前端 worktree 實作（後端未定稿時依 openapi.yaml 以型別與 mock 先行），每完成一項 [FE] 任務即 WIP commit 並 push → lint／typecheck／test → 更新 handoff.md；支援中斷後的接續模式。不開 PR、不歸檔。Use when the frontend agent is dispatched by /ship-issue, or the user asks to run /frontend-processor on a change-id.
---

# Skill: Frontend Processor

多 Agent 流程的**前端實作棒**（流程總覽見 team-hq 的 `CLAUDE.md` 與 `docs/multi-agent-workflow.md`），結構與後端的 `backend-processor` 對稱。

**呼叫方式**：由 `/ship-issue` 派前端 Agent，或在 team-hq 啟動的 session 中指名「Yuma 執行 /frontend-processor `<change-id>`」。

## 輸入

- change-id（全小寫、以 Linear issue 代號開頭，例：`eng-123-order-export`）
- 前端 worktree 路徑（以下稱 `<frontend-worktree>`）
- 「接續模式」（選填）：中斷後重新派工時帶入，表示這個 change 已經有進度。

**所有修改只發生在 `<frontend-worktree>` 內。**

進度的依據是 `handoff.md` 的**狀態區塊**（`## 狀態`，就地改值），不是對話記憶，也不是 `.linear.md` 的 `stage`。

### 技術棧指令從哪裡來

套件安裝、型別與 API client 產生、mock、lint、typecheck、test 的實際指令，**一律以前端 repo 的 `CLAUDE.md` 與本 change 的 `design.md` 為準**。兩份都沒寫某項指令時，**停下回報缺少哪一項**，不要自行猜指令（subagent 不能問 user，由主對話去問）。本 skill 以下只寫「跑 lint」「跑測試」，不寫具體工具。

---

## 步驟 1：讀交接資料（缺檔即停）

讀 `<frontend-worktree>/openspec/changes/<change-id>/` 下的 `proposal.md`、`design.md`、`openapi.yaml`、`tasks.md`、`handoff.md` 與 `specs/`，以及前端 repo 的 `CLAUDE.md`。

- **任何一份不存在，就停下回報缺檔**，不要開始切版或串接。
- `handoff.md` 沒有狀態區塊（`## 狀態`）時，停下回報，提示 user 依新版 `handoff-template.md` 補上，不要自行補建。
- **分支**：有 `.linear.md` 時，`git -C <frontend-worktree> branch --show-current` 必須等於它的 `branch`；沒有 `.linear.md` 時，目前分支不得是預設分支。不符就停下回報。
- **ISSUE-ID**：有 `.linear.md` 就取 `primary_issue`；沒有時，從 change-id 開頭擷取 Linear 代號（`[a-z][a-z0-9]*-\d+`，不分大小寫）並轉成大寫。
- 只處理 `tasks.md` 中以 `[FE]` 開頭的項目。
- **契約是否已定稿**：`handoff.md` 已有「backend」一節，就表示後端已定稿 `openapi.yaml`（定稿版會由後端提交到本 worktree）。
- 依賴套件尚未安裝時（例：沒有 `node_modules/`），依前端 `CLAUDE.md` 的方式安裝。

### 接續檢查（依序；非接續模式也要做第 1、2 點）

1. `git status --porcelain` 非空：**停下**並列出所有檔案；不自行提交、不 stash、不還原、不刪除。
2. `git status -sb` 顯示 behind 或 diverged：**停下**回報。只有 ahead（已 commit 但沒 push）時，先 `git push` 再繼續。
3. 找出 `tasks.md` 中**最後一項已勾選**的 `[FE]` 任務，重跑它寫明的驗證。失敗就**取消勾選**，在狀態區塊的「暫停原因」寫明失敗原因，從該項重做。
4. 所有 `[FE]` 都已勾選、但狀態區塊的階段不是 `integrating`：代表中斷在收尾，直接從**步驟 4** 接續。
5. 開工時把狀態區塊的**階段**改為 `frontend`，填好「下一步」（第一個未勾選的任務）與「更新」（`<Agent 名稱> — <日期時間>`）。這個修改隨第一筆任務 commit 一起提交。

## 步驟 2：依 openapi.yaml 準備型別與 mock

`openapi.yaml` 是串接的**唯一依據**。**不改 `openapi.yaml`**；契約有問題時，記錄在 `handoff.md`，並回報要退回後端 Agent（欄位或行為不合用）或 architect（需求本身有問題）。

- **型別與 API client**：沿用前端 repo 既有的產生器與產出格式。如果產生器會以整份 schema 覆蓋整個產出目錄，**不要拿變更目錄裡只含本次端點的 `openapi.yaml` 直接跑它**，否則既有的型別會被刪掉。改為產到暫存目錄（例：`/tmp/<change-id>-api`），再只把本次新增或變動的 model 與 service 搬進產出目錄。
- **mock**：後端尚未定稿時，依前端 repo 既有的 mock 機制，為新端點補上 handler，先以 mock 切版。repo 有 mock 覆蓋率檢查時，一併跑過。
- 後端定稿後，若 `openapi.yaml` 有變動（看 `handoff.md` backend 節的「API 契約變動」），回頭同步型別與 mock。

型別與 mock 本身若是 `tasks.md` 的一項任務，就照步驟 3 的循環提交；若不是，就併入第一項用到它的任務一起提交。

## 步驟 3：實作

逐項完成 `[FE]` 任務。每一項任務都走同一個固定循環：

1. **驗證**：跑該項任務寫明的驗證。沒通過就不勾選、不提交，修好再繼續。
2. **勾選**：在 `tasks.md` 打勾，同一行附一句說明（例：`- [x] 3.1 [FE] 匯出按鈕與下載流程 — 新增 ExportButton 與 2 支元件測試`）。
3. **更新狀態區塊**：`handoff.md` 的「最後完成」「下一步」「更新」就地改值。不追加、不寫 commit SHA；之後可用 `git log --grep "wip(<ISSUE-ID>): <任務編號>"` 找到對應的 commit。
4. **提交**：列出路徑 `git add`（該項任務改的檔案、`tasks.md`、`handoff.md`；**第一筆**另含整個變更目錄 `openspec/changes/<change-id>/` 中尚未提交的檔案）。**不用 `git add -A`／`git add .`**。
5. **commit**：訊息為 `wip(<ISSUE-ID>): <任務編號> <任務摘要>`，摘要用繁體中文，結尾附系統提供的 `Co-Authored-By` 署名行。
6. **push**：第一次用 `git push -u origin <branch>`，之後用 `git push`。

```bash
git -C <frontend-worktree> add openspec/changes/eng-200-export/tasks.md \
                               openspec/changes/eng-200-export/handoff.md \
                               src/features/export/ExportButton.tsx \
                               src/features/export/ExportButton.test.tsx
git -C <frontend-worktree> commit -m "wip(ENG-200): 3.1 匯出按鈕與下載流程

Co-Authored-By: <依系統提供的署名>"
git -C <frontend-worktree> push
git -C <frontend-worktree> status --porcelain   # 必須為空；有殘留就補進下一筆 commit
```

規則：

- 規格分類與撰寫方式依前端 `CLAUDE.md`。跨前後端的流程圖以後端為準，前端只畫前端特有的內容。
- 編輯檔案後，PostToolUse hook 會自動跑 lint；失敗的訊息要修掉，不要忽略。
- pre-commit hook 失敗就修好再 commit，**不得使用 `--no-verify`**。
- push 失敗就**停下**，在狀態區塊的「暫停原因」註明「commit 尚未推送」並回報；不 force push。
- **規格同步**：前端 repo 有 `openspec/spec-sync.yaml` 時，改到命中規則的路徑，就在**同一項任務內**補上規格並一起 commit（規則與判定只讀 `spec-sync/README.md`）：
  - `capability` 目標：寫或更新本 change 的 delta（`openspec/changes/<change-id>/specs/<capability>/spec.md`）。**不要直接改 `openspec/specs/` 的主規格**。
  - `spec_dir` 目標：更新文件本身。

  屬於該規則 `exempt_when` 的情形時，改在 `handoff.md` 的 frontend 節逐目標寫一行，交由 integrator 的最終閘門確認：

  ```markdown
  - **規格免同步**：<目標> — <理由>
  ```
- 需求無法實作或有歧義：**不改 `proposal.md`**，在 `handoff.md` 記錄並回報要退回 architect。
- 做不到的項目（後端服務未啟動、缺憑證等）在 `tasks.md` 就地註記原因（env-blocked），不要默默打勾；同時填寫狀態區塊的「暫停原因」。

## 步驟 4：檢查

在 `<frontend-worktree>` 依前端 `CLAUDE.md` 跑 **lint、typecheck、test** 三項，三項都要實際通過。

- 失敗且確定不是本次造成的（既有的 baseline 失敗），在 `handoff.md` 註明哪幾項、怎麼確認不是本次造成的。
- 為了讓檢查通過而改了程式碼：另做一筆 `wip(<ISSUE-ID>): 修正檢查`（同樣列出路徑 `git add`、commit、push）。

## 步驟 5：交接

1. 在 `handoff.md` 追加「frontend（<Agent 名稱>）」一節，內容包括：做了什麼、未完成、風險，以及**仍靠 mock、等後端定稿後才能串接的部分**（格式見範本）。
2. 狀態區塊：
   - 階段改為 `integrating`；
   - 「下一步」寫「等待 integrator 檢查」；後端仍未完成時，寫「等待後端完成」；
   - 「暫停原因」填「無」；
   - 更新「最後完成」與「更新」。
3. 有 `.linear.md` 時，把 `stage` 改為 `applied`（已經是 `applied` 就不動）。
4. 做最後一筆 WIP commit（`wip(<ISSUE-ID>): 前端交接`，列出路徑 `git add`）並 push，確認 `git status --porcelain` 為空，且 `git status -sb` 沒有 ahead。

## 完成定義

- `[FE]` 任務全部勾選，或未完成項已就地註記原因；
- lint、typecheck、test 在 worktree 實際跑過並通過（baseline 失敗已在 `handoff.md` 註明）；
- 型別與 mock 和目前的 `openapi.yaml` 一致；
- 有 `openspec/spec-sync.yaml` 時，命中規則的目標已補上，或 `handoff.md` 已逐目標寫免同步聲明；
- `handoff.md` 已追加 frontend 節；
- 前端 worktree 乾淨，本機分支與遠端一致；
- 狀態區塊的階段為 `integrating`。

---

## 護欄

- 只做 WIP commit 與一般 `git push`。**不 force push、不改寫已推送的歷史、不用 `--no-verify`、不用 `git add -A`／`git add .`**。
- 不開 PR、不歸檔，那是 integrator 的工作（integrator 檢查通過後，會把 WIP commit 重切成依功能分組的 commit）。
- 不改 `proposal.md` 與 `openapi.yaml`；不碰 `<frontend-worktree>` 以外的檔案。
- 不跑會對整個 repo 越界 autofix 的指令；不自行處理任何憑證或 token。
