---
name: issue-processor
description: 依 OpenSpec 提案完成實作：讀交接檔 → 建 <label>/<ISSUE-ID>-<code> 分支 → /opsx:apply → 專案有 openspec/spec-sync.yaml 時檢查規格有無漏寫 → 依 change_template 把任務清單與解決過程回填 Linear。Use when the user invokes /issue-processor with an OpenSpec change name.
---

# Skill: Issue Processor

三段式 Linear → OpenSpec 流程的**第二段**：把 `issue-reader` 產出的提案實作完成，並把實作結果寫回 Linear。

| 階段 | Skill | 呼叫方式 |
|------|-------|----------|
| 1. 讀 issue → 提案 | `issue-reader` | `/issue-reader ENG-99` |
| **2. 實作**（本 skill） | `issue-processor` | `/issue-processor <提案名稱>` |
| 3. 歸檔 + PR | `issue-solver` | `/issue-solver <提案名稱>` |

**呼叫方式**：`/issue-processor ocr-size-limit-and-version-api`

**本 skill 不 commit、不 push、不歸檔**——那是 `issue-solver` 的事。實作完成後工作區會留著未 commit 的變更，這是預期狀態。

**parent / sub-issue 結構**：交接檔的 `issues` 是**主 issue**（最上層），只回頭補 `> 更動摘要` /
`> ▲ 前端需注意的變動` 兩個引言區塊；`# 實作完成` 則**寫在每一張 `sub_issues`**。本階段沒有狀態變化，
兩層都維持 In Progress。

---

## 前置準備

1. **Linear MCP 工具是 deferred**，先載入 schema 才能呼叫：

   ```
   ToolSearch("select:mcp__linear__get_issue,mcp__linear__save_issue")
   ```

   若 Linear MCP 未連線，**中止並請 user 先執行 `/mcp` → `linear` → `Authenticate`**。

2. 讀取 `linear/change_template.md`（**每次都要實際讀檔，不要憑記憶套格式**），步驟 5 回填要用。

3. 確認在專案根目錄（`.mcp.json`、`openspec/` 所在），並讀專案 `CLAUDE.md`（步驟 4 的測試與 lint 指令從這裡取）。

---

## 步驟 1：解析參數並讀交接檔

- 參數為 **OpenSpec change 名稱**。沒給就用 `openspec list --json` 列出進行中的 change，
  以 **AskUserQuestion** 讓 user 選，**不要自行猜**。
- 讀 `openspec/changes/<change>/.linear.md` 取得 `issues` / `primary_issue` / `sub_issues` / `code` /
  `label` / `branch` / `stage`。舊格式交接檔沒有 `sub_issues` 欄位時，視同 `-`（無 sub-issue）。

**交接檔不存在時**（例：change 不是由 `/issue-reader` 產生）：

1. 用 **AskUserQuestion** 問 user 對應的 Linear issue 代號與分支前綴（label 轉小寫）；
2. 用 `mcp__linear__get_issue` 確認該 issue 是否有 parent 或 sub-issue：**有 parent 就用
   AskUserQuestion 問 user 要以 parent 還是這張為主 issue**（同 `issue-reader` 步驟 2-1，不要自行決定）；
   有 sub-issue 則把它們填進 `sub_issues`；
3. 依 `issue-reader` 的格式**補寫一份 `.linear.md`**（`stage: proposed`）後再往下走，
   `branch` 一律組成 `<label>/<ISSUE-ID>-<code>`。

**`stage` 已是 `applied` 或 `archived`**：代表這個 change 已跑過本 skill，**停下來回報**並問 user 是要
續作未完成的 tasks 還是重跑，不要默默重來。

## 步驟 2：確認提案完整

- `openspec status --change "<change>" --json` 確認 artifacts 齊全（`proposal` / `design` / `specs` / `tasks`）。
- 有缺就**停下來回報**，建議先回去跑 `/issue-reader` 或 `/opsx:propose`，不要邊實作邊補提案。

## 步驟 3：建分支

**先建分支再改任何檔案**：

```bash
git switch -c <branch>          # 交接檔的 branch，例：feature/ENG-99-version-api
```

- 分支名**必須含 Linear issue ID**（`<label>/<ISSUE-ID>-<code>`）。交接檔的 `branch` 若不合此格式
  （舊格式、手寫的），**先修正交接檔再建分支**——Linear 的 GitHub automation 靠分支名認 issue，
  格式不對就不會在開 PR 時自動轉 In Review。
- 若當前不在 `main` 或工作區不乾淨，**停下來回報**，不要自行 stash 或跨分支帶著改動走。
- 若分支已存在（重跑情境），`git switch <branch>` 切過去即可，並在報告中說明是續作。

## 步驟 4：執行 `/opsx:apply`

執行 `/opsx:apply <change 名稱>`，照該 change 的 `tasks.md` 逐項完成、逐項打勾。

實作期間的技術棧規範（測試、lint、建置、相依管理、執行環境）**一律以專案 `CLAUDE.md` 與
`openspec/changes/<change>/design.md` 為準**，本 skill 不另訂。以下是跨專案都成立的條目：

| 項目 | 規範 |
|------|------|
| 測試 | 依專案 `CLAUDE.md`／`design.md` 寫明的指令與環境執行，**只跑變更範圍**。兩份都沒寫怎麼跑時，以 **AskUserQuestion** 問 user，**不要自行猜指令** |
| lint / format | 依專案文件的工具，**只對本次 change 碰到的檔案**執行；不要跑會對整個 repo 越界 autofix 的指令 |
| 外部服務未就緒 | 資料庫、容器、第三方服務未啟動或缺憑證時，**提示 user 自行處理，不要代為啟動服務或處理憑證**；受此阻擋的部分照下方 env-blocked 註記 |
| 相依 | 只加 `design.md` 決定要用的套件，別順手多裝 |
| 註解 | 一律**繁體中文** |
| 版本 | change 含版本 bump 時，依專案 `CLAUDE.md` 的同步規則，所有出現版號的地方一起改；`CHANGELOG.md` 等檔案**存在時**才補，不存在不要為此新建 |

> greenfield 注意：某項工具（lint 設定、測試骨架）**若本 change 之前還沒建立**，
> 就依 `tasks.md` 把它一併建起來，不要因為「專案還沒有」就跳過 lint／測試。

### 破壞性變更：一律新舊版並存

實作前先依專案 `CLAUDE.md`「API 相容性」的判準，判定本次是否為**破壞性變更**——會讓 API 使用方原本能成功的請求變成失敗或報錯即是：路由改名或改 method、回應欄位改名／移除／改型別、請求契約收緊、權限收緊。

- 是破壞性變更時，**不就地修改既有端點**：保留舊端點，另開**跳版本號**的新端點（`api/v1/…` 保留 → 新增 `api/v2/…`）；舊版的移除必須是另一個獨立的 change。
- 新增選填請求欄位、新增回應欄位、放寬驗證、不影響契約的內部修正**不算**，可直接就地改。
- `tasks.md` 的條目讀起來要就地改既有端點、但依判準屬破壞性變更時，**停下來回報並建議更新 artifact**（改成新增新版端點），不要照字面實作。

若 `tasks.md` 有項目因環境限制做不到（服務未啟動、缺憑證、無法實機驗證等），
**在 `tasks.md` 就地註記原因（env-blocked）**，不要默默打勾，也不要因此停掉其餘任務。

### 實作完成後：規格同步閘門

專案有 `openspec/spec-sync.yaml` 時，`/opsx:apply` 完成後依 **`spec-sync/README.md`** 的判定檢查本次是否漏寫規格（規則格式與判定只讀該檔，本 skill 不另抄）；沒有設定檔就略過。

- `capability` 目標看本 change 有沒有對應的 delta（`openspec/changes/<change>/specs/<capability>/spec.md`），**不要直接改 `openspec/specs/` 的主規格**——主規格由 `issue-solver` 歸檔時的 sync 寫入。
- `spec_dir` 目標看文件本身有沒有更新。
- 有不通過的目標時，以 **AskUserQuestion** 列出目標與觸發路徑，讓 user 選：
  - 「現在補上」：寫 delta（依 OpenSpec delta 格式，ADDED／MODIFIED 等）或更新文件，視為本次實作的一部分，補完重跑檢查；
  - 「留給 issue-solver 決定」：不補，在報告列為待決，由收尾時的最終閘門決定補或宣告免同步。
- **免同步不在本階段宣告**。

## 步驟 5：回填實作結果

依 `linear/change_template.md`，用 `mcp__linear__save_issue` 更新 description。
**有 sub-issue 時，寫入分兩層**（延續 `issue-reader` 步驟 5 的分層）：

| 落點 | 做什麼 |
|------|--------|
| **主 issue**（交接檔 `issues` 每一張） | **只回頭補 analyze 區塊開頭的兩個引言**（`issue-reader` 留的佔位），**不加** `# 實作完成` 區塊 |
| **每一張 sub-issue**（`sub_issues`） | 以水平線 `---` 接在既有內容之後，寫 `# 實作完成（日期）`，內容**只限該 sub-issue 範圍**的任務 |

沒有 sub-issue 的一般 issue：兩件事都做在同一張（`# 實作完成` 接在 question + analyze 之後）。

- `# 實作完成（日期）`：**列出該範圍 `tasks.md` 的內容**（讓閱覽者一眼看出完成了哪些任務，含未完成項
  與原因），清單底下簡短說明更動的範圍與重點。日期用絕對日期。跨多張 sub-issue 的任務寫在最相關那張，
  其餘以代號交叉引用，不要整段複製。
- `> 更動摘要`（主 issue）：人類易讀的重點描述，涵蓋**全部 sub-issue** 的成果。
- `> ▲ 前端需注意的變動`（主 issue）：API 路徑、欄位名、序列化欄位、權限等會影響 API 使用方的變動，一樣彙整全部
  sub-issue；確實沒有就寫「無」。新增新版端點時要列出新路徑與改動的欄位。

**狀態維持 In Progress**（主 issue 與 sub-issue 皆是）——轉狀態是 `issue-solver` 開 PR 之後的事。

## 步驟 6：更新交接檔

把 `.linear.md` 的 `stage` 改為 `applied`。若步驟 3 實際使用的分支名與交接檔不同，一併更正 `branch`。

---

## 完成後的報告

必須包含：

- change 名稱與對應 issue（有 sub-issue 時說明主 issue 補了哪兩個引言、哪幾張 sub-issue 各自寫了實作完成）
- 分支名（已建立／已切換）
- `tasks.md` 完成度（幾項完成、哪幾項未完成及原因）
- 測試與 lint 的實際結果（**跑了什麼、結果如何；跳過就說跳過**，不要粉飾）
- 規格同步閘門結果：不適用／通過／現在補上了哪些／留給 issue-solver 的待決目標
- 已回填的 Linear issue
- **下一步指令**：`/issue-solver <change 名稱>`

---

## 護欄

- **本 skill 到實作 + 回填為止**：不要 `git commit`、不要 `git push`、不要 `/opsx:archive`、不要開 PR。
- **先建分支再改檔案**，絕不在 `main` 上直接實作。
- **破壞性變更不就地改既有端點**：`tasks.md` 要求就地改、但屬破壞性變更時停下回報，建議改成新增新版端點。
- 遇到「tasks 語意不清」「實作揭露設計問題」→ **停下來回報並建議更新 artifact**，不要靠猜測往下做。
- 對 Linear 的寫入是對外可見的動作：只改 description，**不要順手改 assignee、priority、project、label**。
- **不要把 `# 實作完成` 寫進帶 sub-issue 的主 issue**，也**不要把引言區塊寫進 sub-issue**；
  本階段不動任何 issue 的狀態。
- 若 user 在流程中途要求改變做法，以 user 當下的指示為準，並在最終報告說明偏離了哪一步。