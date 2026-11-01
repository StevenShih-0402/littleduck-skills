---
name: issue-integrator
description: 多 Agent 流程最後一棒（integrator）。分兩段：「檢查」實際跑前後端測試／lint／typecheck／migration、核對 tasks、契約與規格同步，不通過就退回，通過後依功能重切 commit、以 --force-with-lease 推送並開前後端 PR；「歸檔」在 user 回覆歸檔後對兩端執行 /opsx:archive、追加歸檔 commit 並回寫 Linear。Use when the integrator agent is dispatched by /ship-issue for check or archive.
---

# Skill: Issue Integrator

多 Agent 流程的**最後一棒**（流程總覽見 team-hq 的 `CLAUDE.md` 與 `docs/multi-agent-workflow.md`）。

本 skill 對應單人流程 `issue-processor` 的步驟 5 與 `issue-solver`，有兩個刻意的差異：

- **順序相反**：單人流程是先歸檔再開 PR；這裡先開 PR，讓 user 在檢查點 2 看 PR diff，user 回覆「歸檔」後才歸檔並追加歸檔 commit。
- **重切 commit**：開發 Agent 每完成一項任務就推送一筆 WIP commit；檢查通過後，由本 skill 把它們重切成依功能分組的 commit。

以下「`issue-processor`」「`issue-solver`」指 team-hq `.claude/skills/` 下的同名 skill，Linear 模板在 team-hq 的 `linear/`。**做法照這兩個 skill 的對應步驟，本檔只寫差異。**

## 輸入（由主對話傳入）

- change-id、前後端 worktree 路徑（由 `.linear.md` 的 `repos` 決定要看哪幾端）
- 兩端的主幹分支（PR 的 base），例：後端 `main`、前端 `dev`
- 這次是「**檢查**」還是「**歸檔**」；歸檔時必須附帶「user 已回覆歸檔」

缺少任何一項就停下回報。

## 邊界

- 不改程式碼，也不改 `tasks.md`、`proposal.md`、`design.md`、`openapi.yaml`（寫入限制 hook 會擋 Write／Edit），**不用 Bash 改檔**。
- 例外：A5 重切時的 `git reset --soft` 與 `git restore --staged`，兩者只動 index。
- 可以寫：兩端的 `handoff.md`、`.linear.md`，以及歸檔時同步的 `openspec/specs/**`。
- **不採信前一棒的結果**，每一項都自己實際執行。

### 指令從哪裡來

測試、lint、型別檢查、migration 的實際指令與執行環境，**一律以該端 repo 的 `CLAUDE.md` 與本 change 的 `design.md` 為準**。兩份都沒寫某項指令時，停下回報缺少哪一項，不要猜指令。

---

## A. 檢查

### A1. 讀交接資料

每一端都讀 `.linear.md`、`handoff.md`、`tasks.md`、`openapi.yaml`。缺檔就退回 architect（見 A4）。

讀 `handoff.md` 的狀態區塊：任一端的階段不是 `integrating`，就停下回報「該端尚未完成實作」，不往下檢查。

### A2. 實際執行

在每一端的 worktree 依該端 `CLAUDE.md` 執行：

| 項目 | 範圍 |
|------|------|
| 測試 | 本次變更範圍的測試 |
| lint | 本次變更的檔案（`git diff --name-only $(git merge-base HEAD origin/<base>)`），不跑會 autofix 的指令 |
| 型別檢查 | 該端有型別檢查時執行 |
| migration | 有 migration 時，先 migrate 到新版，再退回前一版，最後 migrate 回新版，確認正反向都能執行 |
| 規格 | 在 worktree 根目錄執行 `openspec validate <change-id> --strict` 與 `openspec validate --specs` |

需要的資料庫、快取等服務未啟動時，**停下來請 user 自己啟動**，不要代為啟動。

### A3. 核對

- 兩端的 `tasks.md` 沒有未勾選的 `- [ ]`。env-blocked 且已就地註記的項目可以放行，但要列進報告。
- 兩端的 `openapi.yaml` 內容一致（用 `diff` 比對）；後端實作的路由與回應欄位和 `openapi.yaml` 一致（可依後端 `CLAUDE.md` 產出實際 schema 來比對）。
- 兩端的 `.linear.md` 除了 `stage` 以外都一致。
- 兩端 worktree 乾淨（`git status --porcelain` 為空），且本機分支與 `origin/<branch>` 一致（`git status -sb` 沒有 ahead 或 behind）。不符就停下回報，不自行 commit 或 push。
- 破壞性變更有照 repo `CLAUDE.md`「API 相容性」的規定新舊版並存：舊端點保留，新增跳版號的端點。
- 開發 Agent 沒有改 `proposal.md`：執行 `git log --format='%h %s' $(git merge-base HEAD origin/<base>)..HEAD -- openspec/changes/<change-id>/proposal.md`。訊息以 `wip(` 開頭、但不是 `提案核准` 的 commit，就表示開發 Agent 動過提案。主對話核准時的 commit、上一輪重切後的功能 commit 都不算。
- **規格同步（最終閘門）**：該端 repo 有 `openspec/spec-sync.yaml` 時，依 `spec-sync/README.md` 的「判定」，以 `git diff --name-only $(git merge-base HEAD origin/<base>)` 收集路徑並換算出目標：
  - 通過的目標記下即可；`capability` 目標在報告註明「歸檔時由 sync 寫入主規格」。
  - 不通過的目標：如果該端 `handoff.md` 有對應的免同步聲明（`- **規格免同步**：<目標> — <理由>`），就放行，並把聲明逐條列進報告，讓 user 在檢查點 2 確認；沒有聲明就**不通過**，退回該端的開發 Agent。
  - 規則設定錯誤（同時寫了兩種目標或兩種都沒寫）時判為不通過，退回 architect 並在報告點出。
  - 只檢查有沒有寫，不判斷內容是否正確，也不自行補寫規格。
  - 沒有 `spec-sync.yaml` 時，這一項不適用。

### A4. 退回

任一項不通過時：

1. 在**出問題那一端**的 `handoff.md` 追加一節 integrator 紀錄，寫明：「退回：第 N 次」、退回對象（architect／backend／frontend 的 Agent 名稱）、原因、重現指令。N 是同一對象在 `handoff.md` 中既有的退回次數加一。
2. 把該端狀態區塊的階段改回 `backend`／`frontend`（退回 architect 時改為 `proposal`）。「暫停原因」填「integrator 退回第 N 次」，「下一步」填要修的內容。
3. 只 commit 該端的 `handoff.md`，訊息為 `wip(<ISSUE-ID>): integrator 退回第 N 次`，然後一般 `git push`。交棒時 worktree 要保持乾淨。
4. 回報主對話要退回給誰。**N 會超過 2 時就不再退回**，改為回報「需 user 處理」，並摘要歷次退回原因。

ISSUE-ID 取 `.linear.md` 的 `primary_issue`。

### A5. 通過：重切 commit、推送、開 PR

每一端各自執行：

1. `git fetch origin <base>`；`git status --porcelain` 必須為空。
2. 記下 `OLD=$(git rev-parse HEAD)` 與 `BASE=$(git merge-base HEAD origin/<base>)`。`OLD` 先記著，第 6 步一起寫進 `handoff.md`。
3. 執行 `git reset --soft $BASE`，再執行 `git restore --staged .`（只動 index，不動工作樹）。接著依功能分批 `git add <路徑>` 並 commit，切法照 `issue-solver` **步驟 4**（繁體中文 message、`Co-Authored-By` 署名行）。注意：
   - 此時**還沒歸檔**，所以不含 `chore(openspec)` 歸檔那一筆；
   - 變更目錄本身與實作放在同一批；
   - 退回修正後再次檢查時，一樣從分支起點重切全部 commit。
4. `git diff $OLD HEAD` 必須為空。不為空就 `git reset --soft $OLD` 還原，並停下回報。
5. 執行 `git push --force-with-lease=<branch>:$OLD origin <branch>`。被拒絕就停下回報，**不得改用 `--force`**。
6. 開 PR 照 `issue-solver` **步驟 6**；PR 已存在就沿用（force push 後內容會自動更新）。base 用主對話傳入的該端主幹。
   - 主 issue 的 magic word 只放在其中一端的 PR（優先放後端），另一端用純文字列出 issue 代號，避免兩個 PR 重複觸發。
   - 兩個 PR 的內文互相附上對方的連結。
7. 更新兩端的狀態區塊：階段維持 `integrating`，「最後完成」填「integrator 檢查通過」，「下一步」填「等待 user 回覆歸檔」。
8. 追加一節「integrator（<Agent 名稱>）— 檢查通過」，內容包括：實際指令與結果、重切前的 SHA `OLD`、重切後的 commit 清單、tree 比對結果、PR 連結、規格免同步聲明、風險。
9. 以 `docs(openspec): 記錄 <ISSUE-ID> 檢查結果` commit，並一般 `git push`。

回報主對話（主對話據此進行**檢查點 2**）：

- 每項檢查的指令與結果
- 重切前的 SHA 與重切後的 commit 清單、tree 比對結果
- 兩個 PR 連結
- `handoff.md` 中的風險項
- 規格免同步聲明：逐條列出目標與理由；沒有就寫「無」

---

## B. 歸檔（只在 user 回覆「歸檔」後）

每一端各自執行：

1. **歸檔**：在該端 worktree 的根目錄，用 Skill 工具執行 `openspec-archive-change`（即 `/opsx:archive <change-id>`；不可用時直接讀 team-hq `.claude/skills/openspec-archive-change/SKILL.md` 照做），做法照 `issue-solver` **步驟 3**。
   - 歸檔流程中需要選擇是否同步 spec 時，一律選「同步」；
   - 遇到無法自行判斷的 blocker 就停下回報。
2. **驗證**：在 worktree 根目錄執行 `openspec validate --specs`，失敗就停下回報。
3. **更新交接檔**：把 archive 目錄內 `handoff.md` 的狀態區塊階段改為 `archived`，`.linear.md` 的 `stage` 改為 `archived`。
4. **commit 與推送**：以 `chore(openspec): 歸檔 <change-id>（<ISSUE-ID>）` 為一筆 commit，一般 push 到同一條分支。

兩端都完成後：

5. **回寫 Linear**：照 `issue-processor` **步驟 5**（主 issue 補兩個引言區塊；sub-issue 寫 `# 實作完成（日期）`，依 `linear/change_template.md`）。`# 實作完成` 分成「後端」「前端」兩段，列出各自的 `tasks.md`。
6. **PR comment 與 sub-issue 狀態**：照 `issue-solver` **步驟 7**。主 issue 的狀態交給 Linear automation，不手動改。

回報：

- 兩端的歸檔路徑、`validate --specs` 結果、追加的 commit
- Linear 回寫結果
- 沒做完的事與原因

---

## 護欄

- 檢查段不歸檔；沒有「user 已回覆歸檔」就不進入 B 段。
- 只在 A5 以 `--force-with-lease=<branch>:$OLD` 推送重切結果，其他情況一律不 force push。
- 不 merge PR、不改 PR 的 reviewer／label；對 Linear 只寫 `issue-processor`／`issue-solver` 允許的欄位。
- 發現問題只退回，不自己修。
- 不修改 `linear/*_template.md` 與 `issue-*` skill。
