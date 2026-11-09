# Proposal

## Why

SDP-100 要求 PR 前讓 Agent 實際把產品跑起來觀察，補上「測試全綠，產品卻跑不起來」的缺口。SDP-111（automate-ship-issue-flow）已經吸收了其中的**終端機層級**：Osamu「檢查」段會依各 repo `CLAUDE.md` 的「## 執行驗證」段啟動產品，再驗證指令與 HTTP 觀察點。調查後還剩兩個缺口：

1. **看不到畫面**：執行驗證格式明定「只寫終端機觀察得到的行為」，前端頁面能不能正常渲染無從驗證。issue 原文要的「截圖／瀏覽器」沒有做到。
2. **本次變更特有的觀察點沒人寫**：team-hq `CLAUDE.md` 說「本次變更特有的觀察點由 Hyuse 寫在 `design.md`」，`issue-integrator` 也會去讀，但 `issue-architect` skill 沒有任何對應指示，實際上不會產出。所以執行驗證只能跑 repo 層級的通用檢查（例：`/health`），驗不到這次改的功能。

## What Changes

- **執行驗證新增「截圖觀察點」**：repo `CLAUDE.md` 或 `design.md` 可以寫「截圖指令 → 預期畫面」。截圖指令由 repo 自訂（例：headless 瀏覽器 CLI），以 `{out}` 佔位輸出路徑。Osamu 把截圖存到 worktree 外的暫存目錄，用 Read 看圖，再對照預期畫面判定。不新增 Agent 工具，也不綁特定瀏覽器或框架。
- **判定分三種**：
  - 截圖工具不存在或瀏覽器無法啟動 → 該點記為「略過」，不擋流程。
  - 畫面明顯不符（空白頁、錯誤頁、預期元素不見）→ 不通過，退回開發 Agent。
  - 無法確定 → 放行，但列為風險寫進 `handoff.md`，交給 PR 前審查參考。
- **Hyuse 在 `design.md` 寫「## 執行驗證觀察點」**：`issue-architect` 要求每一端的 `design.md` 列出本次變更特有的觀察點（指令或截圖，格式同 repo `CLAUDE.md`）。沒有可觀察的行為時寫「無」並附理由。
- **文件同步**：team-hq `CLAUDE.md`（`agent-team/CLAUDE.md`）的執行驗證格式加入截圖觀察點，拿掉「只寫終端機觀察得到的行為」；setup 文件、`hyuse.md`、`osamu.md` 的敘述一併更新。

### 不納入

- 互動式瀏覽器操作（點擊、填表、多步驟流程）：需要的話由 repo 寫成 E2E 腳本，當作一般指令觀察點執行。
- 給 Osamu 加上瀏覽器 MCP 工具（Claude in Chrome、built-in browser）：這類工具依環境而定，subagent 不一定拿得到，而且會綁特定執行環境。
- 單人流程（`issue-reader` / `issue-processor` / `issue-solver`）的執行驗證：本次只處理多 Agent 流程。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `issue-integrator-skill`：「Checks are executed, not trusted」加入截圖觀察點的執行與三種判定，並明定執行驗證的觀察點來源包含 `design.md`。
- `issue-architect-skill`：新增 requirement，要求 `design.md` 列出本次變更特有的執行驗證觀察點。

## Impact

- `.claude/skills/issue-integrator/SKILL.md`：A2 執行驗證段（D 段重跑時沿用）。
- `.claude/skills/issue-architect/SKILL.md`：步驟 3 的 design.md 段。
- `agent-team/CLAUDE.md`：「執行驗證」格式說明。
- `agent-team/.claude/agents/hyuse.md`、`agent-team/.claude/agents/osamu.md`：邊界與回報（截圖暫存在 worktree 外，不算改檔）。
- `agent-team/docs/multi-agent-workflow.md`：setup 清單與升級指引（既有 team-hq 的 `CLAUDE.md` 是骨架檔，安裝不會覆寫，需要手動補）。
- `README.md`：視需要補一句。
- 不涉及 API、相依套件或 hook 變動。
