---
name: issue-architect
description: 多 Agent 流程第一棒（architect）：讀 Linear issue → 讀專案 CLAUDE.md 的「## agent-team 設定」→ 系統分析 → 在 worktree 建一份 OpenSpec 變更目錄（proposal／specs／design 含 UML／openapi.yaml 草稿／標 [BE][FE] 的 tasks）→ 寫 handoff.md 與 .linear.md → 回填 Linear 分析並轉 In Progress。支援 fullstack 與 single-side 兩種結構。不寫程式碼、不 commit。Use when the architect agent is dispatched by /ship-issue, or the user asks the architect to draft a proposal.
---

# Skill: Issue Architect

多 Agent 流程的**第一棒**（流程總覽見專案 `CLAUDE.md` 與 `docs/multi-agent-workflow.md`）。

| 階段 | 負責 | 流程步驟 |
|------|------|----------|
| **1. issue → 提案**（本 skill） | architect | 本檔 |
| 2. 實作 | 後端 Agent／前端 Agent（single-side 只有一個開發 Agent） | `/backend-processor`、`/frontend-processor` |
| 3. 檢查、PR、歸檔、合併 | integrator | `/issue-integrator` |

本 skill 對應單人流程的 `issue-reader`，差別在於：

- 多了 `openapi.yaml` 與 `handoff.md`；
- `design.md` 必須有 UML；
- **不能問 user**：subagent 沒有 AskUserQuestion。

以下「`issue-reader`」指 `.claude/skills/issue-reader/SKILL.md`，Linear 模板在 repo 根目錄的 `linear/`。**做法照 `issue-reader` 的對應步驟，本檔只寫差異。**

---

## 輸入

### 主對話傳入

| 參數 | 例 |
|------|----|
| 主 issue、sub-issue | `ENG-128`；sub-issue `-` |
| code、label、分支名 | `order-export`、`feature`、`feature/ENG-128-order-export` |
| change-id（全小寫） | `eng-128-order-export` |
| 涉及哪幾端（`repos`） | `backend, frontend` 或只有其一 |
| worktree 路徑 | `wt/eng-128-order-export` |

主 issue 用 parent 還是 sub-issue、多張 issue 用哪個 code，**主對話已經問過 user**，照傳入值做，不要自行更改。

### 專案 `CLAUDE.md` 的「## agent-team 設定」

| 欄位 | fullstack | single-side |
|------|-----------|-------------|
| 結構 | `fullstack` | `single-side` |
| 子目錄 | 後端子目錄、前端子目錄 | 程式碼目錄（預設 `.`） |
| 端 | — | `backend` 或 `frontend` |

缺任何參數、缺這一段或缺必要欄位，就停下回報缺什麼，不要建立變更目錄。

## 步驟 1：讀 issue、檢查格式

1. 讀 `linear/question_template.md`、`linear/analyze_template.md`，每次都要實際讀檔。
2. 用 `mcp__linear__get_issue` 讀主 issue 與每張 sub-issue，並用 `mcp__linear__list_comments` 讀 comment。
3. 格式檢查與自動補 `code:` 照 `issue-reader` **步驟 2-2**。格式嚴重不符、無法判斷需求時**不要硬寫提案**，改列成待確認問題回傳。

## 步驟 2：系統分析

在 worktree 內讀專案 `CLAUDE.md` 與相關程式碼（後端的路由、序列化、service、model；前端的頁面、資料流、API client），確認：

- issue 描述的問題是否真的存在。不存在就停下回報，同 `issue-reader` 步驟 3 的備註。
- 會動到哪些端點，以及**是否為破壞性變更**。判準見專案 `CLAUDE.md`「API 相容性」；屬破壞性時，提案必須寫成「保留舊版、新增跳版號的新端點」（例：`api/v1/…` 保留，新增 `api/v2/…`），不得就地修改。
- fullstack：前端要跟著改哪些頁面或資料流。
- 專案有 `openspec/spec-sync.yaml` 時，預計改到的路徑會命中哪些規則（判定只讀 `spec-sync/README.md`）。命中 `capability` 規則時，要在 `specs/` 寫對應的 delta；命中 `spec_dir` 規則時，要在 tasks 排一項更新該文件的任務。

## 步驟 3：建立變更目錄

在 **worktree 根目錄**執行（一個 change 只有一份變更目錄）：

```bash
openspec new change <change-id>
openspec instructions <artifact> --change <change-id> --json   # 取各 artifact 的規則與模板
```

- **不要呼叫 `/opsx:propose`**：它會問釐清問題，而你不能問 user。直接依 `openspec instructions` 逐一寫各 artifact。
- `specs/` 依專案既有的規格分類寫；`CLAUDE.md` 有規格分類或放置規則時照它。

### design.md：至少兩張 UML

**先用 Skill 工具載入 `draw-mermaid`**（不可用時直接讀 `.claude/skills/draw-mermaid/SKILL.md`），再畫：

- 至少一張 `flowchart` **資料流圖**；
- 至少一張 `sequenceDiagram`：fullstack 畫**前後端互動時序圖**；single-side 畫使用者或模組間的互動。沒有可畫的互動時可以省略，但 MUST 在 `design.md` 寫明省略原因。

### design.md：執行驗證觀察點

`design.md` 要有一節 `## 執行驗證觀察點`，列出**跑起產品後能證明本次變更有效**的觀察點。integrator「檢查」時會跟專案 `CLAUDE.md`「## 執行驗證」的通用觀察點一起跑。

- 格式同 `CLAUDE.md` 的觀察點，兩種擇一：
  - **指令**：`<指令>` → `<預期輸出>`，API 以這種為主，例：`curl -s localhost:8000/api/v2/orders/export | jq '.data | length'` → `大於 0`；
  - **截圖**：`<截圖指令，輸出寫 {out}>` → `<預期畫面>`，畫面以這種為主。截圖指令沿用 `CLAUDE.md` 既有的寫法，只換網址。
- 只寫**本次變更**的行為，不重複 `CLAUDE.md` 的通用觀察點（例：`/health`）。
- 預期畫面要**點名具體元素**（標題文字、欄位、按鈕、筆數），不要寫「頁面正常顯示」。integrator 看圖時只有點名的元素能當判準。
- 啟動方式、port、登入狀態以 `CLAUDE.md` 為準，不要自創；需要登入才看得到的頁面，`CLAUDE.md` 沒提供帶登入的截圖方式時改用指令觀察點，或列成待確認問題。
- 沒有能在執行時觀察的行為（例：只動文件、純重構）：寫「無」並附理由。
- `CLAUDE.md` 的「## 執行驗證」沒有啟動指令：照樣寫觀察點，並在該節註明「專案尚未設定執行驗證，integrator 檢查時會略過」，同時列進**待確認問題**，讓主對話提醒 user 補設定。

### design.md：變異測試目標

`design.md` 要有一節 `## 變異測試目標`，標出**本次變更**中需要驗證測試有效性的關鍵模組／路徑（例：權限檢查、狀態機等關鍵邏輯）。integrator「檢查」時會對這些目標跑變異測試。

- **只標本次變更碰到的關鍵邏輯**，不要列全專案；criticality 由你這次的系統分析判定。
- 每個目標寫出模組或路徑（含子目錄，例：`backend/orders/state_machine.py`）；對應實作該目標的 `tasks.md` 任務要點名（見下）。
- **不要在此選變異測試工具、指令或通過閾值**——那些由專案 `CLAUDE.md` 提供；此節只寫「要驗哪些模組」。
- 本次沒有權限、狀態機等關鍵邏輯時，這節寫「無」並附理由（integrator 會據此記為不適用、不跑）。

### openapi.yaml：API 契約草稿

- 放在變更目錄 `openspec/changes/<change-id>/openapi.yaml`，**只有這一份**。格式為 OpenAPI 3，只寫本次新增或變動的端點（路徑、method、request／response schema、錯誤碼）。
- 欄位命名與回應封包格式要對齊後端既有的序列化與 schema 產出習慣，不要自創。
- 後端 Agent 實作後會就地定稿；前端 Agent 依同一份串接。
- 不涉及 API 的 issue（含沒有 HTTP API 的 single-side 專案）仍要建這個檔，內容寫 `paths: {}`，並在 `info.description` 註明「本次無 API 變動」。

### tasks.md：標註負責端

- 每一項 MUST 以 `[BE]` 或 `[FE]` 開頭，例：`- [ ] 2.1 [BE] 新增 api/v2/... 端點與測試`。
- **fullstack**：`[BE]` 與 `[FE]` 寫在同一份 `tasks.md`。開發 Agent 依序執行（後端全部做完，前端才開工），所以 **`[BE]` 任務排在依賴它的 `[FE]` 任務之前**；建議以章節分開（例：`## 2. 後端`、`## 3. 前端`）。
- **single-side**：每一項都標宣告的端的 tag（`frontend` → `[FE]`、`backend` → `[BE]`）。
- 每項任務寫明**驗證方式**（要跑的測試或檢查，含在哪個子目錄跑）。開發 Agent 中斷後重來時，會重跑最後一項已勾任務的驗證。
- 有 migration 的任務，要把 model 與 migration 寫在同一項，不要拆開。
- 實作 `## 變異測試目標` 所列關鍵模組的任務，要在該項**點名為變異測試目標**（例：`- [ ] 2.3 [BE] 實作訂單狀態機轉換（變異測試目標：backend/orders/state_machine.py）`）。
- 測試、lint、版本號 bump 的規範依專案 `CLAUDE.md`；前端的完成定義見 `/frontend-processor`。

## 步驟 4：handoff.md 與 .linear.md

1. 把 `openspec/handoff-template.md` 複製進變更目錄。用 Read 加 Write 複製，不要用 Bash `cp`，因為寫入限制 hook 只看 Write／Edit。
   - 填上 change-id；
   - 狀態區塊：階段 `proposal`、最後完成「提案」、下一步「等待主對話提交提案」、暫停原因「無」、更新者與時間；
   - 追加第一節「architect（<Agent 名稱>）」。
2. 寫一份 `.linear.md`，格式照 `issue-reader` **步驟 4**，另加 `repos:` 一行（涉及的端）：

   ```markdown
   <!-- issue-architect 產生的交接檔；backend-processor / frontend-processor / issue-integrator 讀取。請勿手動修改 issues / branch。 -->
   issues: ENG-128
   primary_issue: ENG-128
   sub_issues: -
   code: order-export
   label: feature
   branch: feature/ENG-128-order-export
   change: eng-128-order-export
   repos: backend, frontend
   stage: proposed
   ```

   `stage` 只是粗粒度的對照，流程進度以 `handoff.md` 狀態區塊為準。single-side 的 `repos` 就是宣告的端。
3. 執行 `openspec status --change <change-id> --json`，確認 artifacts 齊全；再執行 `openspec validate <change-id> --strict`。

### 修訂提案

因 user 意見，或開發 Agent、integrator 退回而修訂時：

- 把狀態區塊的階段維持或改回 `proposal`，並更新「下一步」與「暫停原因」；
- 如果是退回造成的修訂，在交接紀錄追加一節，寫明退回原因與改了什麼。

## 步驟 5：回填 Linear、轉 In Progress

照 `issue-reader` **步驟 5** 處理：主 issue 與 sub-issue 的分層、`# 調查結果（日期）`、`# 實作決策`、引言佔位、狀態轉 In Progress。差異如下：

- `# 實作決策` 寫出 change-id 與 `openapi.yaml` 涉及的端點；`repos` 同時有前後端時，分成「後端」「前端」兩段。
- comment 以外的欄位都不改（assignee、priority、project、label 都不動）。

---

## 結束時回報

- change-id、變更目錄路徑
- `tasks.md` 任務數（`[BE]`、`[FE]` 各幾項）
- 是否為破壞性變更、`openapi.yaml` 涉及哪些端點
- 執行驗證觀察點數（或「無」與理由）；專案尚未設定執行驗證時要註明
- 命中哪些規格同步規則（沒有 `spec-sync.yaml` 就寫「不適用」）
- 已回填的 Linear issue 與狀態
- 待確認問題（沒有就寫「無」）

## 護欄

- 只寫 `openspec/` 目錄（寫入限制 hook 會擋其他路徑）。Bash 只用來跑 `openspec` CLI、唯讀的 `git` 指令與讀檔，**不可用 Bash 寫檔或改檔**。
- 不寫程式碼、不 commit、不 push、不建分支或 worktree（主對話已經建好）。
- 不能問 user：所有不確定的事都列成「待確認問題」回傳，**不要把猜測寫進提案**。
- 不修改 `linear/*_template.md` 與 `issue-*` skill。
