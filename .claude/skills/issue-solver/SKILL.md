---
name: issue-solver
description: 收尾 OpenSpec 提案：專案有 openspec/spec-sync.yaml 時先做規格漏寫的最終檢查 → /opsx:archive 同步規格並歸檔 → 依功能切多個 commit → push 本次任務分支 → 建立 PR → 回報 PR 連結與「已進入 Review 階段」，最上層 issue 的狀態流轉交給 Linear automation、sub-issue 由 skill 手動同步。Use when the user invokes /issue-solver with an OpenSpec change name.
---

# Skill: Issue Solver

三段式 Linear → OpenSpec 流程的**第三段（收尾）**：把已實作完成的 change 歸檔、送出 PR，並讓 Linear 狀態跟上。

| 階段 | Skill | 呼叫方式 |
|------|-------|----------|
| 1. 讀 issue → 提案 | `issue-reader` | `/issue-reader ENG-99` |
| 2. 實作 | `issue-processor` | `/issue-processor <提案名稱>` |
| **3. 歸檔 → 依功能切 commit → push → PR**（本 skill） | `issue-solver` | `/issue-solver <提案名稱>` |

**呼叫方式**：`/issue-solver ocr-size-limit-and-version-api`

**本 skill 不寫功能程式碼**——`tasks.md` 若還有未完成項，回去跑 `/issue-processor`。

**parent / sub-issue 結構**：PR 的 magic word 與 comment 只針對交接檔 `issues`（最上層 issue）；
`sub_issues` 的模板內容前兩段 skill 已各自寫好，本 skill 不再動 description、不留 comment，
**只由步驟 7 手動把狀態同步成 In Review**。

---

## 前置準備

1. **Linear MCP 工具是 deferred**，先載入 schema 才能呼叫：

   ```
   ToolSearch("select:mcp__linear__save_comment,mcp__linear__save_issue,mcp__linear__list_issue_statuses")
   ```

   本 skill **不改最上層 issue 的狀態**（交給 Linear automation，見步驟 7），`save_issue` /
   `list_issue_statuses` **只用於同步 sub-issue 的狀態**。若 Linear MCP 未連線，照樣把歸檔／PR 做完，
   僅在報告中註明 comment 與 sub-issue 狀態未寫入。

2. 確認在專案根目錄（`.mcp.json`、`openspec/` 所在），且 `gh auth status` 正常（建 PR 要用）。

---

## 步驟 1：解析參數並讀交接檔（**務必在歸檔前讀**）

- 參數為 **OpenSpec change 名稱**。沒給就用 `openspec list --json` 列出進行中的 change，
  以 **AskUserQuestion** 讓 user 選，**不要自行猜**。
- 讀 `openspec/changes/<change>/.linear.md` 取得 `issues` / `primary_issue` / `sub_issues` / `code` /
  `label` / `branch` / `stage`。`issues` 是**主 issue**（最上層）、`sub_issues` 已由前兩段 skill 各自回填內容，本 skill 只同步其狀態
  （步驟 7）；舊格式沒有 `sub_issues` 欄位時視同 `-`。
  **歸檔會把整個 change 目錄搬走**，所以這一步一定要在步驟 3 之前做完，並把內容記在對話裡。
  （若已歸檔，改讀 `openspec/changes/archive/YYYY-MM-DD-<change>/.linear.md`。）
- 交接檔不存在時，用 **AskUserQuestion** 問 user 對應的 Linear issue 代號，不要憑 change 名稱猜。
- `stage` 不是 `applied` 時**停下來回報**：多半代表 `/issue-processor` 還沒跑完。

## 步驟 2：確認可以收尾

| 檢查 | 不通過時 |
|------|----------|
| `git branch --show-current` 等於交接檔的 `branch` | 停下來回報，不要自行切分支 |
| 分支名符合 `<label>/<ISSUE-ID>-<code>`、**含 Linear issue ID** | 停下來回報：這條分支不會觸發 Linear automation。建議 user 先 `git branch -m <新名>`（尚未 push 時）再重跑，**不要自己改名** |
| `tasks.md` 沒有未完成的 `- [ ]` | 列出未完成項，用 **AskUserQuestion** 讓 user 決定是繼續或先補完（env-blocked 且已就地註記者可繼續） |
| `git status` 有本次實作的變更 | 若完全乾淨，確認是否已 commit 過，避免重複收尾 |
| 規格同步閘門（見下方小節） | 在 `/opsx:archive` 之前以 **AskUserQuestion** 讓 user 選擇，未取得回覆前不得歸檔 |

### 規格同步閘門（最終閘門）

規則格式、路徑來源、通過判定與三種處置**只讀 `spec-sync/README.md`**，本 skill 不另抄。實作階段（`issue-processor`／`backend-processor`）已檢查過一輪，這裡是歸檔前的最後確認，**免同步只在這裡宣告**。

1. 專案沒有 `openspec/spec-sync.yaml` → 本檢查**不適用**，直接略過。
2. 依 README「判定」收集變更路徑（本流程步驟 4 才 commit，變更多半還在工作區，未追蹤檔一定要算進去）、換算受影響的目標並判定：
   - `capability` 目標：本 change 有對應的 delta 即通過，報告註明「歸檔時由 sync 寫入主規格」；主規格被直接修改但沒有 delta 仍判不通過。
   - `spec_dir` 目標：文件本身有更新才通過。
3. 有目標不通過時，以 **AskUserQuestion** 列出不通過的目標與觸發路徑（`handoff.md` 已有的免同步聲明一併列出供確認），讓 user 選：
   - 「先補規格後重跑」：本次**停止、不歸檔**，user 補完（或跑 `/issue-processor`）後重跑本 skill；
   - 「宣告免同步並提供理由」：僅限該規則 `exempt_when` 描述的情形；逐目標記下理由，寫進步驟 6 的 PR 內文；
   - 「中止」：不歸檔、不 commit、不 push。

## 步驟 3：歸檔

執行 `/opsx:archive <change 名稱>`：同步 delta spec 到 `openspec/specs/`、change 目錄搬進
`openspec/changes/archive/YYYY-MM-DD-<change>/`。

歸檔後：

1. 跑 `openspec validate --specs` 確認全綠。
2. 把已搬到 archive 的 `.linear.md` 的 `stage` 改為 `archived`。

## 步驟 4：依功能切多個 commit

1. **以「功能」為單位切成多個 commit**，不要一個巨大 commit，也不要用「一張 issue／一項 task
   = 一筆 commit」硬套——一張 issue 含多個功能就切多筆，多張 issue 共用同一個功能就併成一筆。
   判斷基準是**這批改動在說同一件事嗎**，而不是 `tasks.md` 的條目數。慣用切法：
   - 每個功能的程式碼各一筆（`feat(<scope>): …（ENG-xx）`）；跨檔案但同一功能的改動放同一筆
   - 修正類與新功能分開（`fix(<scope>): …`）
   - 版本 bump + 文件一筆（`docs: …`）
   - openspec 歸檔與 spec 同步一筆（`chore(openspec): …`）

   每筆 commit 都要能單獨看懂、且不留半成品狀態（例如功能程式碼與其測試同一筆）。
2. commit message 一律**繁體中文**，結尾加上系統提供的署名行（不要自行寫死模型名稱或版本），格式如：

   ```
   Co-Authored-By: <依系統提供的署名>
   ```

3. commit 後確認 `git status` 為空（本來就未追蹤的既有檔案不算，但要在報告中點出）。

## 步驟 5：push 本次任務的分支

多筆 commit 全部完成後，**一次 push 這次任務的那條分支**（步驟 1 交接檔的 `branch`，
即步驟 2 已確認的當前分支）——不要為每筆 commit 分開 push、也不要另開新分支。

```bash
git push -u origin <branch>
```

被拒（分支已存在且非 fast-forward 等）就**停下來回報**，**不要 force push**。

## 步驟 6：建立 PR

```bash
gh pr create --base main --head <branch> --title "<標題>" --body "<內文>"
```

- **標題**：繁體中文一句話帶出本次更動，並在結尾標註 issue 代號，例：
  `新增後端版本號 API 並補上 OCR 檔案大小限制（ENG-99, ENG-102）`
- **內文**必須包含：
  1. 更動摘要（人類易讀）
  2. 各筆 commit 的一句話說明
  3. 測試與 lint 的實際結果（跳過的要寫明原因）；規格同步閘門有選「免同步」時，逐目標寫明目標與理由
  4. **Linear 連結行**：**主 issue**（交接檔 `issues`）每張各一行 magic word，例：

     ```
     Fixes ENG-99
     Fixes ENG-102
     ```

     用途是**確保 GitHub 端的 issue 關聯**（含分支名沒帶到的第二、三張 issue）。狀態流轉本身
     由分支名 `<label>/<ISSUE-ID>-<code>` 觸發，兩者並存、不衝突。

     **sub-issue 不列 magic word**——它們的狀態改由步驟 7 手動同步，避免兩套機制互相覆蓋；
     要在 PR 內文提到 sub-issue，用純文字列出代號即可。
  5. 結尾：

     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     ```

- 回報 PR 網址。

## 步驟 7：回報；最上層交給 automation、sub-issue 手動同步

**主 issue（最上層 issue）的狀態本 skill 一律不寫。** 分支名含 issue ID，Linear 的 workflows &
automations 會在 PR 開啟時自動把它轉為 **In Review**，合併後再自動歸檔（Done）。

PR 建立後做三件事：

1. 在**每張主 issue** 加一則 comment（`mcp__linear__save_comment`）附上 PR 網址，方便從 Linear 追。
   **sub-issue 不加 comment。**
2. **同步 sub-issue 狀態**（交接檔 `sub_issues` 非 `-` 時）：分支名只帶得到最上層那張，automation 不會動到
   sub-issue，所以這裡用 `mcp__linear__save_issue` 把**每一張 sub-issue** 轉成與最上層相同的
   **In Review**（團隊無同名狀態時，先 `mcp__linear__list_issue_statuses` 取實際清單挑語意最接近的
   「審查中」類狀態，並在報告中說明）。**只改 `state`，不動 description / assignee / priority 等其他欄位。**
   merge 之後的 Done 不在本 skill 範圍——在報告中提醒 user：automation 只會歸檔最上層那張，
   sub-issue 需自行收尾。
3. 向 user 回報 **PR 連結** 與 **「已進入 Review 階段」**，並說明：等 user review 並 merge PR 後，
   Linear 會自動把最上層 issue 歸檔。

**嚴禁**：對**主 issue**呼叫 `mcp__linear__save_issue` 改 state，或把任何 issue（含 sub-issue）
切成 **Done**。PR 尚未合併，這些手動狀態操作都會蓋掉 automation 的結果。

---

## 完成後的報告

必須包含：

- change 名稱與歸檔路徑
- 分支名，以及**依功能切出的每一筆 commit** 各一句話說明（含切分依據）
- 是否已 push、**PR 網址**
- **「ENG-xx 已進入 Review 階段」**——並說明狀態由 Linear automation 依分支名自動轉換，
  待 user review + merge PR 後由 Linear 自動歸檔
- **sub-issue（若有）**：哪幾張已由本 skill 手動轉成 In Review（description 本階段不動）；
  並提醒 merge 後 automation 只會歸檔最上層那張，sub-issue 的 Done 要 user 自行收尾
- **規格同步閘門結果**：不適用／逐條規則列出通過（`capability` 註明已由歸檔時的 sync 寫入主規格）或免同步（目標與理由）
- **沒做完 / 跳過的事項及原因**（env-blocked、未實機驗證的部分等）——不要粉飾

---

## 護欄

- **不要跳步驟**：`stage` 不是 `applied` 就不歸檔；未歸檔就不 commit 收尾。
- **規格同步閘門未通過且 user 未選「免同步」時不歸檔**（選「先補規格」就停止，補完後重跑）。
- **不要把整批改動壓成單一 commit**，也不要在本 skill 內另開／切換分支——commit 依功能切多筆，
  一律落在步驟 2 確認過的那條任務分支上，最後一次 push。
- **不要 force push**、不要自行 merge PR、不要改 PR 的 reviewer / label。
- **主 issue 的狀態完全不要手動改**（尤其不要轉 Done）：In Review 由 PR 開啟時的 automation 處理，
  歸檔由 merge 後的 automation 處理。user 明講要手動轉才照做。
- 對 Linear 的寫入僅限兩項：主 issue 的「附 PR 連結的 comment」、sub-issue 的 `state`（步驟 7-2）。
  **不要改 assignee、priority、project、label**，也不要改任何 issue 的 description（模板內容在前兩段 skill 就寫完了）。
- 若 user 在流程中途要求改變做法，以 user 當下的指示為準，並在最終報告說明偏離了哪一步。