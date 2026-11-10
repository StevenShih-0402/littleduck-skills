# Proposal

## Why

多 Agent 流程目前「測試通過就信任」——開發 Agent（Chika/Yuma）寫完測試跑綠就過，integrator 也只實際跑一次測試確認通過，沒有任何環節驗證這些測試是否真的有效（能在程式出錯時失敗）。權限檢查、狀態機這類關鍵邏輯一旦被無效測試（例如沒有斷言、只驗呼叫不驗結果）覆蓋，流程會以為有保護、實際上沒有。本次引入變異測試，讓「Agent 產出的測試可被驗證」。

## What Changes

- **architect（issue-architect）逐案標示關鍵模組**：系統分析時在 `design.md` 新增一個「## 變異測試目標」區塊，列出本次變更中需要驗證測試有效性的關鍵模組／路徑（例：權限檢查、狀態機），並在對應 `tasks.md` 任務點名；本次無關鍵邏輯時該區塊寫「無」並說明。範圍僅限重點部分，不涵蓋全專案。
- **integrator（issue-integrator）檢查段執行並把關**：在 check run 既有的「實際執行、不信任報告」檢查中，新增對 `design.md` 標示之關鍵模組跑變異測試一項。變異測試指令與通過閾值一律取自該端 repo 的 `CLAUDE.md`（project-agnostic）；未設定指令時記為 skipped、不阻斷流程（與現有「執行驗證未設定則記 skipped」一致）；低於閾值則檢查失敗，依既有「退回並計數」機制退回該端開發 Agent，重現指令即該變異測試指令。
- **結果記錄**：變異測試結果（存活變異數、捕捉率、是否達閾值或 skipped）寫入該端 `handoff.md` 的 integrator 區塊與 integrator 報告；設計階段的目標清單隨 `design.md` 一起交接。
- **文件同步（agent-team-kit）**：team-hq `CLAUDE.md` 的「層層把關」說明與 setup 文件加入變異測試這一道檢查的定位（屬 integrator 檢查段、只針對關鍵模組、指令來自各 repo `CLAUDE.md`）。
- 開發 Agent（backend/frontend）與 reviewer（custom-review）**不**執行變異測試——驗證集中在 integrator 一處。

## Capabilities

### New Capabilities
<!-- 無新增 capability；本次只調整既有三個 skill 的行為。 -->

### Modified Capabilities
- `issue-architect-skill`: 新增「architect 於 `design.md` 標示本次變更的變異測試關鍵模組、並在 `tasks.md` 點名；無關鍵邏輯時寫明」的需求。
- `issue-integrator-skill`: 擴充 check run 的「實際執行、不信任報告」需求，納入對關鍵模組的變異測試——指令／閾值來自 repo `CLAUDE.md`、未設定記 skipped 不阻斷、低於閾值依既有計數退回。
- `agent-team-kit`: 擴充 team-hq `CLAUDE.md` 與 setup 文件的檢查流程說明，記錄變異測試這道關卡的定位與來源。

## Impact

- **受影響的 skill 定義**：`.claude/skills/issue-architect/SKILL.md`、`.claude/skills/issue-integrator/SKILL.md`，以及 `agent-team/CLAUDE.md`、`agent-team/openspec/handoff-template.md` 的說明（如需新增變異測試記錄欄位）。
- **受影響的規格**：`openspec/specs/issue-architect-skill/spec.md`、`openspec/specs/issue-integrator-skill/spec.md`、`openspec/specs/agent-team-kit/spec.md`。
- **對使用此流程的專案**：若專案希望啟用變異測試，需在自己的 `CLAUDE.md` 提供變異測試指令與閾值；未提供者流程維持現狀（該檢查記 skipped，不影響既有行為），屬**非破壞性**變更。
- **不影響**：backend-processor / frontend-processor / custom-review 的行為、API 契約、既有退回計數上限（變異測試退回沿用同一計數）。
