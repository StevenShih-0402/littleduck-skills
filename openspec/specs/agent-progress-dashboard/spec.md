# agent-progress-dashboard Specification

## Purpose
讓 user 不必看對話訊息，就能從看板得知每個多 Agent 任務（change）目前位於工作流的哪個階段、是否被退回或暫停，以及任務完成度，方便自己追蹤與向他人展示。

## Requirements

### Requirement: 進度資料只來自 handoff.md 與 tasks.md
看板 SHALL 只從 change 目錄的 `handoff.md`「## 狀態」區塊與 `tasks.md` 推導進度，不讀 Claude Code session 紀錄或其他來源。狀態區塊的「階段」「最後完成」「下一步」「暫停原因」「更新」五個欄位 SHALL 依欄位名取值，欄位順序或後方的 HTML 註解不影響結果。

#### Scenario: 讀出狀態區塊五個欄位
- **WHEN** handoff.md 的狀態區塊為 `- **階段**：backend <!-- … -->`、`- **最後完成**：1.2`、`- **下一步**：1.3`、`- **暫停原因**：無`、`- **更新**：chika — 2026-11-13 14:20`
- **THEN** 解析結果為階段 `backend`、最後完成 `1.2`、下一步 `1.3`、無暫停、更新者 `chika`、更新時間 `2026-11-13 14:20`

#### Scenario: 忽略狀態區塊以外的同名欄位
- **WHEN** handoff.md 下方的角色紀錄也出現 `- **階段**：` 字樣
- **THEN** 解析結果只採用「## 狀態」區塊內的值

### Requirement: handoff 階段對應畫面階段
看板 SHALL 依固定對照表把 handoff 階段值轉為畫面階段：`proposal`→提案、`backend`／`frontend`→開發、`integrating`→檢查、`reviewing`→PR 前審查、`pr-checking`→PR 中檢查、`awaiting-approval`→等待審批、`archived`→合併隊列。開發階段 SHALL 另外標示是後端或前端。

#### Scenario: 開發階段標示端別
- **WHEN** 階段為 `frontend`
- **THEN** 畫面階段為「開發」，並標示「前端」

#### Scenario: 歸檔後顯示合併隊列
- **WHEN** 階段為 `archived`
- **THEN** 畫面階段為「合併隊列」

### Requirement: 無法辨識的階段要明示
階段欄位缺少、狀態區塊不存在或值不在對照表中時，看板 SHALL 顯示為「無法辨識」並附上原始值，不得猜測成任何既有階段，也不得讓其他 change 的顯示失敗。

#### Scenario: 未知階段值
- **WHEN** 階段為 `deploying`
- **THEN** 該 change 顯示「無法辨識」與原始值 `deploying`，其餘 change 照常顯示

#### Scenario: 缺少狀態區塊
- **WHEN** handoff.md 沒有「## 狀態」區塊
- **THEN** 該 change 顯示「無法辨識」，原始值為空

### Requirement: 依結構決定顯示的階段列
看板 SHALL 依 change 的結構（fullstack 或 single-side）顯示階段列。fullstack 的開發階段 SHALL 分成後端與前端兩格；single-side 的開發階段 SHALL 只有一格並標示宣告端。

#### Scenario: fullstack 顯示前後端兩格
- **WHEN** change 結構為 fullstack 且階段為 `backend`
- **THEN** 階段列中開發分為「後端」「前端」兩格，目前位置在「後端」

#### Scenario: single-side 只顯示一格
- **WHEN** change 結構為 single-side、宣告端為 frontend，且階段為 `frontend`
- **THEN** 階段列中開發只有一格「開發（前端）」，目前位置在該格

### Requirement: 退回與暫停的呈現
「暫停原因」不為「無」時，看板 SHALL 在該 change 標示暫停並顯示原因全文；原因符合「…退回第 N 次」時 SHALL 另外標示為退回並顯示次數 N。

#### Scenario: 退回標示次數
- **WHEN** 階段為 `backend`、暫停原因為「PR 前審查退回第 2 次」
- **THEN** 該 change 標示「退回 ×2」並顯示原因全文，目前位置在開發（後端）

#### Scenario: 一般暫停
- **WHEN** 階段為 `awaiting-approval`、暫停原因為「高風險，等待 user 回覆合併」
- **THEN** 該 change 標示暫停並顯示原因全文，不標示退回

### Requirement: 任務完成度
看板 SHALL 以 `tasks.md` 的核取方塊計算完成度：方框內只有 `x`（不分大小寫、可含空白）算完成，其他標記算未完成，沒有核取方塊的行不計入。fullstack 結構 SHALL 另外依 `[BE]`／`[FE]` 標記分別計數。

#### Scenario: 計算完成數
- **WHEN** tasks.md 有 `- [x] 1.1 [BE] …`、`- [ X ] 1.2 [BE] …`、`- [~] 2.1 [FE] …`、`- [ ] 2.2 [FE] …`
- **THEN** 完成度為 2／4，後端 2／2、前端 0／2

#### Scenario: 沒有 tasks.md
- **WHEN** change 目錄沒有 tasks.md
- **THEN** 完成度顯示為「無任務清單」，不影響階段顯示

### Requirement: 已歸檔 change 的讀取位置
change 已歸檔時，看板 SHALL 改從 `openspec/changes/archive/<日期>-<change-id>/` 讀取 handoff.md 與 tasks.md；同一個 change-id 在未歸檔與歸檔位置都存在時 SHALL 以未歸檔位置為準。

#### Scenario: 只存在於 archive
- **WHEN** worktree 中 change 只存在於 `openspec/changes/archive/2026-11-13-sdp-1-demo/`
- **THEN** 看板讀該目錄的 handoff.md，change-id 顯示為 `sdp-1-demo`

### Requirement: 原型以假資料走同一條解析流程
原型看板 SHALL 以多筆假的 handoff.md／tasks.md 文字作為輸入，經過與上述規則相同的解析流程產生畫面，至少涵蓋每個畫面階段、fullstack 與 single-side、退回、暫停與無法辨識各一例，並 SHALL 在頁面上註明資料為示範用。

#### Scenario: 原型涵蓋所有情境
- **WHEN** 打開原型頁面
- **THEN** 頁面上可以看到提案、開發（後端／前端）、檢查、PR 前審查、PR 中檢查、等待審批、合併隊列、退回、暫停、無法辨識與 single-side 的範例，且頁面標示「示範資料」

### Requirement: 階段對應負責角色
看板 SHALL 依目前畫面階段決定負責的 Agent 角色：提案→architect、開發（後端）→後端 Agent、開發（前端）→前端 Agent、檢查→integrator、PR 前審查→reviewer、PR 中檢查→主對話、等待審批→user、合併隊列→integrator。無法辨識的階段 SHALL 沒有負責角色。

#### Scenario: 前端開發由前端 Agent 負責
- **WHEN** 階段為 `frontend`
- **THEN** 負責角色為前端 Agent

#### Scenario: 合併隊列由 integrator 負責
- **WHEN** 階段為 `archived`
- **THEN** 負責角色為 integrator

#### Scenario: 無法辨識沒有負責角色
- **WHEN** 階段為 `deploying`
- **THEN** 沒有負責角色

### Requirement: 基地畫面以角色代表任務
基地畫面 SHALL 為每個任務畫一個角色，角色外觀依該任務目前的負責角色而定，站在目前階段對應的工作站並拿著該任務。同一工作站有多個任務時 SHALL 並排顯示、不互相遮蓋；無法辨識的任務 SHALL 放在獨立的待查區。點選角色 SHALL 顯示該任務的階段、最後完成與下一步、暫停原因與完成度。

#### Scenario: 任務站在對應工作站
- **WHEN** 任務的階段為 `reviewing`
- **THEN** 該任務的角色以 reviewer 外觀站在「PR 前審查」工作站

#### Scenario: 退回與暫停標在角色上
- **WHEN** 任務的暫停原因為「PR 前審查退回第 2 次」
- **THEN** 該任務的角色旁顯示退回標記與次數 2

#### Scenario: 無法辨識放在待查區
- **WHEN** 任務的階段為 `deploying`
- **THEN** 該任務的角色出現在待查區，不站在任何工作站

### Requirement: 重播示範任務
基地畫面 SHALL 提供重播：把一個示範任務依時間排序的多份 handoff.md／tasks.md 快照逐步套用，每一步都經過與看板相同的解析流程，角色依結果移到新的工作站並換成新的負責角色外觀。使用者設定減少動態效果時 SHALL 直接切換位置、不播放移動動畫。

#### Scenario: 重播推進到下一步
- **WHEN** 重播從「階段 backend」的快照前進到「階段 frontend」的快照
- **THEN** 示範任務的角色從「後端」工作站移到「前端」工作站，外觀從後端 Agent 換成前端 Agent

#### Scenario: 重播包含退回
- **WHEN** 重播前進到暫停原因為「PR 前審查退回第 1 次」、階段為 `backend` 的快照
- **THEN** 角色回到「後端」工作站並顯示退回標記與次數 1
