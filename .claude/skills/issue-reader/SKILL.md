---
name: issue-reader
description: 從 Linear issue 代號產生 OpenSpec 提案：讀 issue → 檢查 question_template 格式 → /opsx:propose → 依 analyze_template 回填調查結果與實作決策 → 狀態轉 In Progress。Use when the user invokes /issue-reader with one or more Linear issue identifiers.
---

# Skill: Issue Reader

三段式 Linear → OpenSpec 流程的**第一段**：把 Linear issue 讀成一份 OpenSpec 提案，並把分析結果寫回 Linear。

| 階段 | Skill | 呼叫方式 |
|------|-------|----------|
| **1. 讀 issue → 提案**（本 skill） | `issue-reader` | `/issue-reader SDP-99` |
| 2. 實作 | `issue-processor` | `/issue-processor <提案名稱>` |
| 3. 歸檔 + PR | `issue-solver` | `/issue-solver <提案名稱>` |

**呼叫方式**：`/issue-reader SDP-99` 或 `/issue-reader SDP-99, SDP-102`（逗號或空白分隔皆可）。

**多張 issue 一律合併成單一提案**（同 SDP-11 + SDP-12 的做法）：一份 change、一條分支、一批 commit，最後回填到每一張 issue。

**parent / sub-issue 結構**：若 issue 底下掛著多個 sub-issue，**模板內容依區塊分層回填**——
最上層 issue 只留 `> 更動摘要` 引言區塊，`# 調查結果` / `# 實作決策`
則**寫在各自對應的 sub-issue**。`code:` 仍只補最上層那張，comment 也只寫最上層；sub-issue 的狀態
要跟著最上層一起流轉。詳見步驟 2-1 與步驟 5。

**本 skill 不碰程式碼、不建分支**——那是 `issue-processor` 的事。

---

## 前置準備

1. **Linear MCP 工具是 deferred**，先載入 schema 才能呼叫：

   ```
   ToolSearch("select:mcp__linear__get_issue,mcp__linear__save_issue,mcp__linear__list_issues,mcp__linear__list_issue_statuses")
   ```

   若 Linear MCP 未連線（`/mcp` 顯示斷線），**中止並請 user 先在 Claude Code 內執行 `/mcp` →
   `linear` → `Authenticate`**，不要自行嘗試其他憑證途徑。

2. 讀取兩份 template（**每次都要實際讀檔，不要憑記憶套格式**）：

   | 檔案 | 用途 | 用在 |
   |------|------|------|
   | `linear/question_template.md` | issue 提問格式（含 `code:`） | 步驟 2 檢查 |
   | `linear/analyze_template.md` | 調查結果 / 實作決策的回填格式 | 步驟 5 回填 |

3. 確認在專案根目錄（`.mcp.json`、`openspec/` 所在）。

---

## 步驟 1：解析參數

- 從參數取出所有 issue identifier（`SDP-\d+`）。**沒有任何 identifier 就中止**並說明呼叫方式，
  不要猜測要處理哪張 issue。
- 宣告：「本次處理：SDP-xx、SDP-yy（合併為單一提案）」。（層級判定在步驟 2-1，宣告可能因此修正。）

## 步驟 2：讀取 issue、判定主 issue、檢查格式

對每張 issue 呼叫 `mcp__linear__get_issue`。

### 2-1 判定主 issue（parent / sub-issue）

Linear issue 可能是「一張最上層 issue 底下掛多個 sub-issue」的結構。此時**回填分兩層**：最上層放
`> 更動摘要` （跨 sub-issue 的總覽），各 sub-issue 放自己的 `# 調查結果` /
`# 實作決策`。`code:` 只補最上層那張，comment 也只寫最上層，狀態則兩層都轉。

| 情況 | 處置 |
|------|------|
| 傳入的 issue **有 parent** | **停下來用 AskUserQuestion 問 user**：改以 parent（`SDP-xx`）為主 issue，還是就地處理這張 sub-issue。**不要自行決定**——這決定了分支名與 Linear automation 會動到哪張 issue。user 選 parent 就把主 issue 換成 parent，並對它重跑本小節（parent 之上還有 parent 時同樣處理） |
| 傳入的 issue **有 sub-issue** | 它就是主 issue。用 `mcp__linear__list_issues`（以 parent 過濾）或 `get_issue` 回傳的子項清單，取得**所有 sub-issue 的標題與 description** 作為步驟 3 的需求輸入。sub-issue 底下還有下一層就整棵讀進來，並把**最底層那批**當成分析回填的落點 |
| 兩者皆無 | 一般 issue，整份 `analyze_template.md`（引言區塊 + 調查結果 + 實作決策）都寫在這張 |

判定完成後，在對話中宣告最終的**主 issue**與**sub-issue 清單**（含各層要寫哪些區塊）。
往下所有步驟（含 `issue-processor` / `issue-solver`）提到的「每一張 issue」，除非另外指明 sub-issue，
**一律指主 issue**——分支名、`code:`、PR magic word、comment 都只認主 issue。

### 2-2 檢查格式

對**主 issue** 逐項比對 `linear/question_template.md`（sub-issue 不檢查、不補 `code:`）：

| 檢查項 | 不符時的處置 |
|--------|--------------|
| 有標題 | 標題為空才中止（幾乎不會發生） |
| description 有 `code:` 行 | **自動補齊**（見下） |
| description 有問題敘述 | 完全空白則中止並回報，無從推導需求。**例外**：帶 sub-issue 的 parent 若 description 空白或只有大方向，只要 sub-issue 有足夠內容就繼續，不中止 |

**自動補齊 `code:`**：以 issue 標題推導 kebab-case 英文短代號（例：「新增回傳版本號的 API」→
`version-api`；「檔案上傳加上 25MB 大小限制」→ `upload-size-limit`）。推導後：

1. 用 `mcp__linear__save_issue` 把 `code: <推導值>` **插在標題敘述之後、原 description 之前**，
   保留原內容不動。
2. 在對話中明確告知：「SDP-xx 缺 `code:`，已依標題補為 `<值>` 並寫回 Linear」——**必須讓 user 看到**，
   因為這個值決定分支名。

**分支代號 `code` 的決定**（本 skill 只決定、不建分支）：

- 單張 issue → 直接用它的 `code`。
- 多張 issue → 用 **AskUserQuestion** 讓 user 從各 issue 的 `code` 中挑一個，或提供一個新的合併代號。
  **不要自行挑選**，分支名是 user 之後要一直看到的東西。

**分支命名規範**：`<prefix>/<ISSUE-ID>-<code>`，例：`feature/SDP-99-version-api`、`bug/SDP-12-auth-bug`。

| 欄位 | 來源 |
|------|------|
| `prefix` | 該 issue 的 Linear label **原字轉小寫**，不做語意映射（`Feature` → `feature`、`Bug` → `bug`、`Improvement` → `improvement`）。多張 issue 或多個 label 時取**第一張 issue 的第一個 label**；完全沒有 label 時用 `feature`，並在報告中說明 |
| `ISSUE-ID` | Linear issue 代號**原字大寫**（`SDP-99`）。多張 issue 時用**第一張**（主 issue），其餘 issue 靠 PR 內文的 magic word 關聯 |
| `code` | 上面決定的 kebab-case 短代號 |

> **issue ID 必須在分支名裡**：Linear 的 GitHub automation 靠分支名認 issue，PR 開啟時才會自動把狀態
> 轉為 In Review。少了這段，後續 `issue-solver` 只能得到一個不會自動流轉的分支。

## 步驟 3：產生 OpenSpec 提案

執行 `/opsx:propose`，輸入為**合併後的需求敘述**：把各 issue 的標題與 description（去掉 `code:` 行）
整理成一段說明，並附上 issue 代號。**帶 sub-issue 時，每張 sub-issue 的標題與 description 也要一併整理進去**
（標明各段出自哪張 sub-issue），提案範圍＝parent ＋ 全部 sub-issue。change 名稱用 kebab-case，多 issue 時取能涵蓋兩者的名字
（例：`ocr-size-limit-and-version-api`）。

propose 會產出 `proposal.md` / `design.md` / `specs/**` / `tasks.md`。**先照 propose 自己的流程走完**
（含它會問的釐清問題），不要在這裡搶著寫程式碼。

> 若調查後發現 issue 描述的問題**不存在於現有程式碼**（例：已修過、或屬誤解），**停下來回報**，
> 不要硬生出一個提案。

## 步驟 4：寫交接檔 `.linear.md`

三個 skill 是分開呼叫的，`issue-processor` / `issue-solver` 只拿得到「提案名稱」，
**必須靠這份檔案才知道對應哪張 issue、要建哪條分支**。propose 完成後立刻寫
`openspec/changes/<change>/.linear.md`（與 `.openspec.yaml` 同層，會隨 change 一起被歸檔）：

```markdown
<!-- issue-reader 產生的交接檔；issue-processor / issue-solver 讀取。請勿手動修改 issues / branch。 -->
issues: SDP-99, SDP-102
primary_issue: SDP-99
sub_issues: SDP-100, SDP-101
code: version-api
label: feature
branch: feature/SDP-99-version-api
change: ocr-size-limit-and-version-api
stage: proposed
```

| 欄位 | 意義 |
|------|------|
| `issues` | **主 issue**（最上層），`code:` / 引言區塊（更動摘要）/ comment / PR magic word 都認這些 |
| `sub_issues` | `issues` 底下的 sub-issue，**各自回填調查結果 / 實作決策 / 實作完成**，狀態一併同步；沒有就寫 `-` |

`stage` 由後續 skill 依序改為 `applied`（issue-processor 完成）、`archived`（issue-solver 完成）。

在對話中明確告知交接檔路徑與 `branch` 值。

## 步驟 5：回填調查結果，狀態轉 In Progress

依 `linear/analyze_template.md` 的區塊組出內容，用 `mcp__linear__save_issue` 更新 description：
**原 question 內容一律保留，以水平線 `---` 分隔後接上新內容**。

**有 sub-issue 時，區塊分兩層寫**（這是為了讓最上層保持乾淨的總覽、細節各歸各的）：

| 落點 | 寫哪些區塊 |
|------|-----------|
| **主 issue**（交接檔 `issues`） | **只有** `> 更動摘要` 引言區塊，**此時先留佔位**（`change_template.md` 要求實作完成後才回頭填，那是 `issue-processor` 的事）。**不寫** `# 調查結果` / `# 實作決策` |
| **每一張 sub-issue** | `# 調查結果（日期）` + `# 實作決策`，內容**只限該 sub-issue 的範圍**。不寫引言區塊 |

沒有 sub-issue 的一般 issue：四個區塊全寫在該張（引言一樣留佔位）。

- `# 調查結果（日期）`：該 sub-issue 提的問題是否真的存在於現有程式碼／業務邏輯、問題根源與成因。
  日期用絕對日期（`2026-07-31`）。
- `# 實作決策`：將進行什麼修改；**特別註明與 issue 原文的差異**（例：檔案落點改了、取值位置改了），
  這是回填最有價值的部分。
- 一段分析橫跨多張 sub-issue 時，寫在**最相關**的那張，其餘張以代號交叉引用（`詳見 SDP-101`），
  不要整段複製到每一張。
- 調查後判定某張 sub-issue **不需要改動**（問題不存在、已修過）時，該張照樣要寫，把結論寫清楚。

多張主 issue 時，各自的 description 都要寫，並在文中交叉引用另一張的代號。

接著把狀態改為 **In Progress**（`mcp__linear__save_issue` 的 `state`）——**主 issue 與其底下的每一張
sub-issue 都要轉**。若團隊沒有同名狀態，先用 `mcp__linear__list_issue_statuses` 取實際清單，
選語意最接近的「進行中」類狀態並在報告中說明。

---

## 完成後的報告

必須包含：

- 處理的 issue 與最終狀態（應為 In Progress）
- **parent / sub-issue 結構**（若有）：主 issue 是哪張（只留兩個引言佔位）、哪幾張 sub-issue 各自寫了
  調查結果 / 實作決策
- change 名稱與 `openspec/changes/<change>/` 路徑
- **交接檔內容**（issues / sub_issues / branch / stage）
- 自動補的 `code`（若有）
- **下一步指令**：`/issue-processor <change 名稱>`

---

## 護欄

- **本 skill 到 propose + 回填為止**：不要建分支、不要動任何程式碼、不要跑 `/opsx:apply`。
- **不要自行決定分支代號**（多 issue 時）與**不要隱藏自動補的 `code`**——這兩件都會影響 user 後續操作。
- **傳入的是 sub-issue 時不要自行往上跳到 parent**：一律用 AskUserQuestion 問過 user 再決定主 issue。
- **不要把 `# 調查結果` / `# 實作決策` 寫進帶 sub-issue 的主 issue**，也**不要把引言區塊寫進 sub-issue**
  ——分層的意義就是最上層只看總覽、細節在各 sub-issue。
- **不要補 sub-issue 的 `code:`、不要在 sub-issue 留 comment**；對 sub-issue 的寫入只有 description
  的分析區塊與 `state`。
- 遇到「issue 描述與現況不符」「需求語意不清」→ **停下來回報**，不要靠猜測生提案。
- 對 Linear 的寫入是對外可見的動作：狀態只轉到 In Progress，**不要順手改 issue 的 assignee、
  priority、project、label**。
- 若 user 在流程中途要求改變做法，以 user 當下的指示為準，並在最終報告說明偏離了哪一步。