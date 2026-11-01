---
name: issue-architect
description: 多 Agent 流程第一棒（architect）：讀 Linear issue → 系統分析 → 在前後端 worktree 以同一個 change-id 各建 OpenSpec 變更目錄（proposal／specs／design 含 UML／openapi.yaml 草稿／標 [BE][FE] 的 tasks）→ 寫 handoff.md 與 .linear.md → 回填 Linear 分析並轉 In Progress。不寫程式碼、不 commit。Use when the architect agent is dispatched by /ship-issue, or the user asks the architect to draft a proposal.
---

# Skill: Issue Architect

多 Agent 流程的**第一棒**（流程總覽見 team-hq 的 `CLAUDE.md` 與 `docs/multi-agent-workflow.md`）。

| 階段 | 負責 | 流程步驟 |
|------|------|----------|
| **1. issue → 提案**（本 skill） | architect（Hyuse） | 本檔 |
| 2. 後端實作 | backend（Chika） | 後端 repo 的 `/backend-processor` |
| 3. 前端實作 | frontend（Yuma） | `/frontend-processor` |
| 4. 檢查、PR、歸檔 | integrator（Osamu） | `/issue-integrator` |

本 skill 對應單人流程的 `issue-reader`，差別在於：

- 前後端各一份變更目錄；
- 多了 `openapi.yaml` 與 `handoff.md`；
- `design.md` 必須有 UML；
- **不能問 user**：subagent 沒有 AskUserQuestion。

以下「`issue-reader`」指 team-hq `.claude/skills/issue-reader/SKILL.md`，Linear 模板在 team-hq 的 `linear/`。**做法照 `issue-reader` 的對應步驟，本檔只寫差異。**

---

## 輸入（由主對話傳入）

| 參數 | 例 |
|------|----|
| 主 issue、sub-issue | `ENG-128`；sub-issue `-` |
| code、label、分支名 | `order-export`、`feature`、`feature/ENG-128-order-export` |
| change-id（全小寫） | `eng-128-order-export` |
| 要改哪幾端（`repos`） | `backend, frontend` 或只有其一 |
| worktree 路徑 | `<wt-root>/<backend-repo>-<change-id>`、`<wt-root>/<frontend-repo>-<change-id>` |

主 issue 用 parent 還是 sub-issue、多張 issue 用哪個 code，**主對話已經問過 user**，照傳入值做，不要自行更改。缺任何參數就停下回報。

## 步驟 1：讀 issue、檢查格式

1. 讀 `linear/question_template.md`、`linear/analyze_template.md`，每次都要實際讀檔。
2. 用 `mcp__linear__get_issue` 讀主 issue 與每張 sub-issue，並用 `mcp__linear__list_comments` 讀 comment。
3. 格式檢查與自動補 `code:` 照 `issue-reader` **步驟 2-2**。格式嚴重不符、無法判斷需求時**不要硬寫提案**，改列成待確認問題回傳。

## 步驟 2：系統分析

在 worktree 內讀兩端的 `CLAUDE.md` 與相關程式碼（後端的路由、序列化、service、model；前端的頁面、資料流、API client），確認：

- issue 描述的問題是否真的存在。不存在就停下回報，同 `issue-reader` 步驟 3 的備註。
- 會動到哪些端點，以及**是否為破壞性變更**。判準見 repo 的 `CLAUDE.md`「API 相容性」；屬破壞性時，提案必須寫成「保留舊版、新增跳版號的新端點」（例：`api/v1/…` 保留，新增 `api/v2/…`），不得就地修改。
- 前端要跟著改哪些頁面或資料流。
- 後端 repo 有 `openspec/spec-sync.yaml` 時，預計改到的路徑會命中哪些規則（判定只讀 team-hq 的 `spec-sync/README.md`）。命中 `capability` 規則時，要在 `specs/` 寫對應的 delta；命中 `spec_dir` 規則時，要在 tasks 排一項更新該文件的任務。前端同理。

## 步驟 3：建立前後端變更目錄

對 `repos` 列出的每一端，在**該端 worktree 的根目錄**執行：

```bash
openspec new change <change-id>
openspec instructions <artifact> --change <change-id> --json   # 取各 artifact 的規則與模板
```

- **不要呼叫 `/opsx:propose`**：它會問釐清問題，而你不能問 user。直接依 `openspec instructions` 逐一寫各 artifact。
- 兩端的 `proposal.md` 講同一件事，可以各自聚焦該端的 Impact。`specs/` 依各端既有的規格分類寫；repo 的 `CLAUDE.md` 有規格分類或放置規則時照它。

### design.md：至少兩張 UML

**先用 Skill 工具載入 `draw-mermaid`**（不可用時直接讀 team-hq `.claude/skills/draw-mermaid/SKILL.md`），再畫：

- 至少一張 `flowchart` **資料流圖**；
- 至少一張 `sequenceDiagram` **前後端互動時序圖**。只改單一端、沒有前後端互動時可以省略，但 MUST 在 `design.md` 寫明省略原因。

以後端那份為主；前端 `design.md` 以連結指向後端的圖，只補前端特有的內容（頁面跳轉、狀態、路由守衛）。

### openapi.yaml：API 契約草稿

- 放在**後端**變更目錄 `openspec/changes/<change-id>/openapi.yaml`，格式為 OpenAPI 3，只寫本次新增或變動的端點（路徑、method、request／response schema、錯誤碼）。
- 欄位命名與回應封包格式要對齊後端既有的序列化與 schema 產出習慣，不要自創。
- 前端變更目錄放一份**內容相同的副本**；後端定稿後會覆蓋它。
- 不涉及 API 的 issue 仍要建這個檔，內容寫 `paths: {}`，並在 `info.description` 註明「本次無 API 變動」。

### tasks.md：標註負責端

- 每一項 MUST 以 `[BE]` 或 `[FE]` 開頭，例：`- [ ] 2.1 [BE] 新增 api/v2/... 端點與測試`。
- 後端 `tasks.md` 只放 `[BE]`，前端只放 `[FE]`；兩份都在開頭寫一行「對端任務見 <另一端路徑>」。
- 每項任務寫明**驗證方式**（要跑的測試或檢查）。開發 Agent 中斷後重來時，會重跑最後一項已勾任務的驗證。
- 標出可平行的區塊，例：`> 可平行：前端 3.x 可依 openapi.yaml 以 mock 先行，不必等後端 2.x`。
- 有 migration 的任務，要把 model 與 migration 寫在同一項，不要拆開。
- 測試、lint、版本號 bump 的規範依各端的 `CLAUDE.md`；前端的完成定義見 `/frontend-processor`。

## 步驟 4：handoff.md 與 .linear.md

1. 把 team-hq 的 `openspec/handoff-template.md` 複製進每一端的變更目錄。用 Read 加 Write 複製，不要用 Bash `cp`，因為寫入限制 hook 只看 Write／Edit。
   - 填上 change-id；
   - 狀態區塊：階段 `proposal`、最後完成「提案」、下一步「等待檢查點 1 核准」、暫停原因「等待 user 核准提案」、更新者與時間；
   - 追加第一節「architect（<Agent 名稱>）」。
2. 每一端寫一份**內容相同**的 `.linear.md`，格式照 `issue-reader` **步驟 4**，另加 `repos:` 一行：

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

   `stage` 只是粗粒度的對照，流程進度以 `handoff.md` 狀態區塊為準。
3. 在每一端執行 `openspec status --change <change-id> --json`，確認 artifacts 齊全；再執行 `openspec validate <change-id> --strict`。

### 修訂提案

因 user 意見，或開發 Agent、integrator 退回而修訂時：

- 把兩端狀態區塊的階段維持或改回 `proposal`，並更新「下一步」與「暫停原因」；
- 如果是退回造成的修訂，在交接紀錄追加一節，寫明退回原因與改了什麼。

## 步驟 5：回填 Linear、轉 In Progress

照 `issue-reader` **步驟 5** 處理：主 issue 與 sub-issue 的分層、`# 調查結果（日期）`、`# 實作決策`、引言佔位、狀態轉 In Progress。差異如下：

- `# 實作決策` 分成「後端」「前端」兩段，並寫出 change-id 與 `openapi.yaml` 涉及的端點。
- comment 以外的欄位都不改（assignee、priority、project、label 都不動）。

---

## 結束時回報

- change-id、前後端變更目錄路徑
- `tasks.md` 任務數（`[BE]`、`[FE]` 各幾項，以及可平行的區塊）
- 是否為破壞性變更、`openapi.yaml` 涉及哪些端點
- 命中哪些規格同步規則（沒有 `spec-sync.yaml` 就寫「不適用」）
- 已回填的 Linear issue 與狀態
- 待確認問題（沒有就寫「無」）

## 護欄

- 只寫 `openspec/` 目錄（寫入限制 hook 會擋其他路徑）。Bash 只用來跑 `openspec` CLI、唯讀的 `git` 指令與讀檔，**不可用 Bash 寫檔或改檔**。
- 不寫程式碼、不 commit、不 push、不建分支或 worktree（主對話已經建好）。
- 不能問 user：所有不確定的事都列成「待確認問題」回傳，**不要把猜測寫進提案**。
- 不修改 `linear/*_template.md` 與 `issue-*` skill。
