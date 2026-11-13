# Proposal

## Why

`/ship-issue` 跑多 Agent 流程時，進度只能從對話訊息的跳動推測；要給主管或其他人看「Agent 團隊現在在做什麼」很難想像（SDP-156）。長期想做成本地應用程式，但畫面樣貌與資料來源都還沒定，先用一個可以直接打開看的原型確認方向，避免直接投入執行檔開發後才發現呈現方式不對。

## What Changes

- 定義「Agent 任務進度」的**資料來源契約**：只讀 worktree 內 `openspec/changes/<change-id>/handoff.md` 的「## 狀態」區塊（階段／最後完成／下一步／暫停原因／更新）與同目錄 `tasks.md` 的勾選數；已歸檔的 change 改從 `openspec/changes/archive/<日期>-<change-id>/` 讀。
- 定義 handoff 階段值（`proposal`、`backend`、`frontend`、`integrating`、`reviewing`、`pr-checking`、`awaiting-approval`、`archived`）對應到畫面階段（提案、開發、檢查、PR 前審查、PR 中檢查、等待審批、合併隊列）的對照表，涵蓋 fullstack 與 single-side 兩種結構，以及「暫停原因」中的退回、暫停如何呈現。
- 新增一份原型：`prototypes/agent-progress-dashboard/`，含一支無相依的解析模組（把 handoff.md／tasks.md 文字轉成進度資料）與一頁 HTML 看板；看板以**假的 handoff.md 文字**經過同一支解析模組產生畫面，並發佈為 Artifact 讓 user 檢視。
- 解析模組附 `node --test` 測試，作為契約的可執行版本。
- 另做一頁 **RPG 基地畫面**（`base.html`，另發佈一個 Artifact）：科幻幾何風格的基地裡，每個任務由一個角色拿著、站在目前階段的工作站，角色外觀依負責的 Agent 角色而定；附「重播」把示範任務的 handoff.md 快照依序推進，看到角色沿流程移動。兩頁共用同一份示範資料與解析模組。
- 不讀 Claude Code session jsonl；本機執行檔（實際掃描 worktree、即時更新）不在本次範圍，看過原型後另開 issue。

## Capabilities

### New Capabilities

- `agent-progress-dashboard`：Agent 任務進度看板——從 handoff.md／tasks.md 推導每個 change 目前位於工作流哪個階段，並以看板呈現（本次為原型）。

### Modified Capabilities

（無。handoff.md 範本與各角色 skill 的寫入行為不變，本次只讀取。）

## Impact

- 新增 `prototypes/agent-progress-dashboard/`（`handoff-status.js`、`demo-data.js`、`index.html`、`base.html`）與 `tests/prototypes/agent-progress-dashboard/handoff-status.test.mjs`。
- 測試需要本機有 Node.js（`node --test`，不需 npm 套件）。
- installer、agent-team kit、各 skill 不受影響；原型目錄不會被安裝到使用者專案。
- 對外產出：兩個私人 Artifact 頁面（卡片看板、RPG 基地），發佈後連結回報給 user。
