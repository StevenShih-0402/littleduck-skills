---
name: backend-processor
description: 多 Agent 流程的後端實作（Chika）：讀 OpenSpec 變更目錄的 proposal／design／openapi.yaml／tasks 的 [BE] 項 → 在後端 worktree 實作，每完成一項 [BE] 任務即 WIP commit 並 push → 測試與 migration 正反向驗證 → 定稿 openapi.yaml 並複製到前端 → 更新 handoff.md；支援中斷後的接續模式。不開 PR、不歸檔。Use when the backend agent is dispatched by /ship-issue, or the user asks to run /backend-processor on a change-id.
---

# Skill: Backend Processor

多 Agent 流程的**後端實作棒**（流程總覽見 team-hq 的 `CLAUDE.md` 與 `docs/multi-agent-workflow.md`）。

**呼叫方式**：由 `/ship-issue` 派後端 Agent，或在 team-hq 啟動的 session 中指名「Chika 執行 /backend-processor `<change-id>`」。

## 輸入

- change-id（全小寫、以 Linear issue 代號開頭，例：`eng-123-order-export`；OpenSpec CLI 不接受大寫）
- 後端 worktree 路徑（以下稱 `<backend-worktree>`）
- 前端 worktree 與其變更目錄路徑（change 涉及前端時）
- 「接續模式」（選填）：中斷後重新派工時帶入，代表這個 change 已有進度。

**所有修改只發生在 `<backend-worktree>` 內**，唯一例外是步驟 4 把定稿 `openapi.yaml` 複製到前端變更目錄，並在前端 worktree 提交這一個檔案。

進度的依據是 `handoff.md` 的**狀態區塊**（`## 狀態`，就地改值），不是對話記憶，也不是 `.linear.md` 的 `stage`。

### 技術棧指令從哪裡來

測試、lint、schema 產生、migration 的實際指令與執行環境（本機、容器、虛擬環境）**一律以後端 repo 的 `CLAUDE.md` 與本 change 的 `design.md` 為準**。兩份都沒寫某項指令時，**停下來問 user**，不要自行猜指令。本 skill 以下只寫「跑測試」「跑 lint」，不寫具體工具。

---

## 步驟 1：讀交接資料（缺檔即停）

讀 `<backend-worktree>/openspec/changes/<change-id>/` 下的 `proposal.md`、`design.md`、`openapi.yaml`、`tasks.md`、`handoff.md` 與 `specs/`，以及後端 repo 的 `CLAUDE.md`。

- **任何一份不存在就停下回報缺檔**，不要開始實作。
- `handoff.md` 沒有狀態區塊（`## 狀態`）就停下回報，提示 user 依新版 `handoff-template.md` 補上，不要自行補建。
- **分支**：有 `.linear.md` 時，`git -C <backend-worktree> branch --show-current` 必須等於它的 `branch`；沒有 `.linear.md` 時，目前分支不得是預設分支。不符就停下回報。
- **ISSUE-ID**：有 `.linear.md` 取 `primary_issue`，否則從 change-id 開頭擷取 Linear 代號（`[a-z][a-z0-9]*-\d+`，不分大小寫）並轉成大寫。
- 只處理 `tasks.md` 中 `[BE]` 開頭的項目。

### 接續檢查（依序；非接續模式也要做第 1、2 點）

1. `git status --porcelain` 非空：**停下**，列出所有檔案並標出位於 `migrations/` 目錄下的檔案（寫到一半的 migration 最危險）；不自行提交、不 stash、不還原、不刪除。
2. `git status -sb` 顯示 behind 或 diverged：**停下**回報；只有 ahead（已 commit 但沒 push）就先 `git push` 再繼續。
3. 找出 `tasks.md` 中**最後一項已勾選**的 `[BE]` 任務，重跑它寫明的驗證。失敗就**取消勾選**，在狀態區塊的「暫停原因」寫明失敗原因，從該項重做。
4. 所有 `[BE]` 都已勾選、但狀態區塊階段不是 `integrating`：代表中斷在收尾，直接從**步驟 3** 接續。
5. 開工把狀態區塊的**階段**改為 `backend`，填好「下一步」（第一個未勾選的任務）與「更新」（`<Agent 名稱> — <日期時間>`）；這個修改隨第一筆任務 commit 一起提交。

## 步驟 2：實作

實作前先依後端 repo `CLAUDE.md`「API 相容性」的判準檢查：`tasks.md` 讀起來要就地改既有端點、但屬破壞性變更時，**停下來**在 `handoff.md` 記錄並回報要退回 architect，不要照字面做。

逐項完成 `[BE]` 任務。每一項任務都走同一個固定循環：

1. **驗證**：跑該項任務寫明的驗證。沒通過就不勾選、不提交，修好再繼續。
2. **勾選**：`tasks.md` 打勾，同一行附一句說明（例：`- [x] 2.1 [BE] 新增匯出 API — 新增 ExportView 與 3 支測試`）。
3. **更新狀態區塊**：`handoff.md` 的「最後完成」「下一步」「更新」就地改值（不追加、不寫 commit SHA；之後可用 `git log --grep "wip(<ISSUE-ID>): <任務編號>"` 找到對應 commit）。
4. **提交**：列出路徑 `git add`（該項任務改的檔案 + `tasks.md` + `handoff.md`；**第一筆**另含整個變更目錄 `openspec/changes/<change-id>/`），**不用 `git add -A`／`git add .`**。
5. **commit**：訊息 `wip(<ISSUE-ID>): <任務編號> <任務摘要>`，摘要用繁體中文，結尾附系統提供的 `Co-Authored-By` 署名行。
6. **push**：第一次 `git push -u origin <branch>`，之後 `git push`。

範例（ISSUE-ID 為 ENG-200、任務 2.1）：

```bash
git -C <backend-worktree> add openspec/changes/eng-200-export/tasks.md \
                              openspec/changes/eng-200-export/handoff.md \
                              src/apps/export/views.py \
                              tests/apps/export/test_views.py
git -C <backend-worktree> commit -m "wip(ENG-200): 2.1 新增匯出 API

Co-Authored-By: <依系統提供的署名>"
git -C <backend-worktree> push          # 第一筆改用 git push -u origin <branch>
git -C <backend-worktree> status --porcelain   # 必須為空；有殘留就補進下一筆 commit
```

規則：

- model 與其 migration 放**同一筆** commit，不可提交只有一半的 migration。
- pre-commit hook 失敗就修好再 commit，**不得 `--no-verify`**。
- commit 後 `git status --porcelain` 要為空；有漏掉的檔案補進下一筆 commit。
- push 失敗就**停下**，在狀態區塊「暫停原因」註明「commit 尚未推送」並回報；不 force push。
- **規格同步**：後端 repo 有 `openspec/spec-sync.yaml` 時，改到命中規則的路徑就在**同一項任務內**補上規格並一起 commit（規則與判定只讀 `spec-sync/README.md`）：
  - `capability` 目標：寫或更新本 change 的 delta（`openspec/changes/<change-id>/specs/<capability>/spec.md`，依 OpenSpec delta 格式）。**不要直接改 `openspec/specs/` 的主規格**——歸檔時由 `/opsx:archive` 的 sync 寫入。
  - `spec_dir` 目標：更新文件本身。

  屬該規則 `exempt_when` 的情形時，改在 `handoff.md` 的 backend 節逐目標寫一行，交由收尾的最終閘門確認：

  ```markdown
  - **規格免同步**：<目標> — <理由>
  ```
- 需求無法實作或有歧義：**不改 `proposal.md`**，在 `handoff.md` 記錄並回報要退回 architect。
- 做不到的項目（服務未啟動、缺憑證等）在 `tasks.md` 就地註記原因（env-blocked），不默默打勾；同時填狀態區塊的「暫停原因」。

## 步驟 3：測試

- 依後端 repo `CLAUDE.md` 的方式跑測試，**只跑變更範圍**。需要的資料庫、快取等服務未啟動時，**停下來請 user 自己啟動**，不要代為啟動或輪詢。
- 有 migration：先 migrate 到新版，再退回前一版，確認正反向都能執行，最後再 migrate 回新版。
- 收尾對本次變更的檔案跑 format 與 lint（只帶變更檔，不掃整個 repo）。
- 為了讓測試通過而改了程式碼：另做一筆 `wip(<ISSUE-ID>): 修正測試`（同樣列出路徑 `git add`、commit、push）。

## 步驟 4：定稿 openapi.yaml

1. 依後端 repo `CLAUDE.md` 的方式產出實際 schema（或打 schema 端點），比對本次涉及的端點。
2. 讓 `openapi.yaml` 與實作**一致**：草稿與實作不同時，以實作為準更新 `openapi.yaml`，並在 `handoff.md` 寫明改了哪些欄位。定稿後 commit（`wip(<ISSUE-ID>): 定稿 openapi.yaml`）並 push。
3. change 涉及前端時，把定稿的 `openapi.yaml` 複製到前端變更目錄（覆蓋草稿副本），用 `diff` 確認兩份相同。
4. **在前端 worktree 只 commit 那一個檔案**並 push，讓交棒給前端 Agent 時前端 worktree 也是乾淨的：

```bash
git -C <frontend-worktree> add openspec/changes/<change-id>/openapi.yaml
git -C <frontend-worktree> commit -m "wip(<ISSUE-ID>): 同步後端定稿 openapi.yaml

Co-Authored-By: <依系統提供的署名>"
git -C <frontend-worktree> push          # 前端分支第一次推送改用 git push -u origin <branch>
```

只加這一個路徑；不用 `git add -A`／`git add .`，也不提交前端 worktree 的其他檔案。

## 步驟 5：交接

1. 在 `handoff.md` 追加「backend（<Agent 名稱>）」一節：做了什麼、未完成、風險、API 契約變動（格式見範本）。
2. 狀態區塊：階段改為 `integrating`；「下一步」寫「等待 integrator 檢查」（涉及前端時寫「等待前端完成」）；「暫停原因」填「無」；更新「最後完成」「更新」。
3. 有 `.linear.md` 時把 `stage` 改為 `applied`（已是 `applied` 就不動）。`stage` 只是粗粒度對照，流程進度以狀態區塊為準。
4. 最後一筆 WIP commit（`wip(<ISSUE-ID>): 後端交接`，列出路徑 `git add`）並 push，確認 `git status --porcelain` 為空、`git status -sb` 沒有 ahead。

## 完成定義

- `[BE]` 任務全部勾選，或未完成項已就地註記原因；
- 本次新增／變動的 API 都有測試，且實際跑過並通過；
- migration 可正反向執行（有 migration 時）；
- `openapi.yaml` 與實作一致，前端副本相同（涉及前端時）；
- `handoff.md` 已追加 backend 節；
- 有 `openspec/spec-sync.yaml` 時，命中規則的目標已補上（`capability` 為 change 內的 delta、`spec_dir` 為文件本身），或 `handoff.md` 已逐目標寫免同步聲明；
- 後端 worktree 乾淨、本機分支與遠端一致（前端 worktree 的 `openapi.yaml` 副本也已提交並推送）；
- 狀態區塊階段為 `integrating`。

---

## 護欄

- 只做 WIP commit 與一般 `git push`；**不 force push、不改寫已推送的歷史、不 `--no-verify`、不 `git add -A`／`git add .`**。
- 不開 PR、不歸檔——那是 integrator 的事（integrator 檢查通過後會把 WIP commit 重切成依功能分組的 commit）。
- 不改 `proposal.md`；不碰 `<backend-worktree>` 以外的檔案（前端 `openapi.yaml` 副本及其單檔 commit 除外）。
- 不跑會對整個 repo 越界 autofix 的指令；不自行處理任何憑證或 token。
