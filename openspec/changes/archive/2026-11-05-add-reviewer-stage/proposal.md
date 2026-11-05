# Proposal

## Why

目前 agent-team kit 只有 architect / backend / frontend / integrator 四個角色：Osamu 的「檢查」只管「測試有沒有過、契約一不一致」，沒有任何一棒負責「測試過了但程式還是錯」的審查。開發 Agent 同時寫程式與測試，理解有偏差時兩者會一起錯、測試照樣綠燈，這個缺口目前要靠 user 在檢查點 2 自己看出來。

Anthropic 的程式碼審核流程（PR 前用全新 agent 審 code 品質、PR 中 AI 審查發現/篩選/處理問題）給了補這個缺口的做法；參考實作 `ignsw_agents_team` 已經把這套落成「Reviewer（Shiori）＋ `/custom-review` ＋ `/code-review` 包裝」並跑過，但它綁死 ignsw 的 Django/npm 技術棧與絕對路徑，無法直接被 skill_repo 的使用者取用。本變更把這套審查階段**通用化**後納入 kit，讓每個裝了 agent-team 的專案都能用。

## What Changes

- **新增 reviewer 角色 Shiori**：agent-team kit 增加第五個角色定義（唯讀 `Read, Grep, Glob`、`model: opus`、`color: red`），Osamu 檢查通過後對照 OpenSpec 規格審查 diff 的需求覆蓋、測試覆蓋、契約、邊界與邏輯；**只回報、不修改、不核准、不合併**。
- **新增 `/custom-review` skill**：Shiori 的審查方法——比對 proposal 驗收條件、delta specs 的 Requirement›Scenario、tasks 是否都實作且都有測試，並把內建 `/code-review` 的每條發現評定嚴重度／信心度；明示**不審**風格／命名／格式（交給 linter）與 reuse/simplify/efficiency。
- **`/ship-issue` 新增 code-review 步驟**：Osamu 檢查通過後，由主對話產生 `review-diff.patch`（Shiori 看不到 git diff）、偵測高風險檔案、以適當 effort 呼叫**內建** `/code-review`、派 Shiori 審查、把結果寫入 `review.md`，再決定退回或列 PR 備註。
- **integrator 切成「檢查 → （審查）→ 收尾」**：重切 commit 與開 PR 從「檢查通過後」移到「審查通過後」，避免審查退回修改後又要重切一次。
- **handoff 狀態階段擴充**：加入 `reviewing` 與 `ready-to-archive` 兩個階段。
- **新增 `review.md` 範本**：每輪記錄模式（shadow／自動退回）、範圍、高風險檔案、`/code-review` 指令、發現表與結果。
- **審查規則三分法**：機械性規則→linter（Osamu 檢查階段＋編輯後 hook）；需判斷的專案慣例→各 repo `CLAUDE.md`＋內建 `/code-review`；對照規格→`/custom-review`（Shiori）。寫進 team-hq CLAUDE.md 與 setup 文件。
- **Shadow mode 與退回上限**：前 N 個 issue 只彙報不自動退回並記錄誤報率；code-review 的退回與 Osamu 檢查的退回**共用同一上限**（同一目標最多 2 次，第 3 次停下交 user）。
- **保留內建 `/code-review`，不建立同名 skill**（同名會整個取代內建審查，失去 effort／`--fix`／`ultra`）。
- **installer 與文件同步**：agent-team 安裝一併放 `shiori.md`、`custom-review` skill 與 `review.md` 範本；README 與 team-hq CLAUDE.md 角色表由 4 角色改為 5 角色。

### 不納入（依 issue 指示）
- Anthropic Callout 標註的三項優化（審核題庫評分、誤報率統計、控制審核輪數／只審新改動／同類一次指出／不提重複意見）——太燒 token，先不導入。
- PR「合併時」的 merge queue、「合併後」的 feature flag／逐步上線／回滾——屬部署階段，超出 dev→PR 工作流範圍。

### 未來工作（本次只列出、不實作；另拆 Linear sub-issue 追蹤）
- **安全審核**：高風險變更（migration／認證／加密／權限）自動跑內建 `/security-review`。
- **PR 前確保正常運行**：整合／審查階段用 verify 類能力實際跑起產品觀察。
- **風險分級人工審批**：低／中／高風險對應檢查點 2 的審批深度（目前僅「高風險檔案需在檢查點 2 明確確認」部分涵蓋）。

## Capabilities

### New Capabilities
- `custom-review-skill`: 對照 OpenSpec 規格審查需求／測試覆蓋、契約、邊界與邏輯，並評定內建 `/code-review` 發現的嚴重度／信心度；只回報不修改，明示略過程式風格的審查方法。

### Modified Capabilities
- `agent-team-kit`: 新增第五個 reviewer 角色定義與 `review.md` 範本、handoff 狀態加入 `reviewing`／`ready-to-archive`、`/ship-issue` 加入 code-review 步驟與 shadow mode／共用退回上限、審查規則三分法寫入 kit 文件。
- `issue-integrator-skill`: integrator 由「檢查→收尾（重切+PR）→歸檔」改為「檢查→審查→收尾（重切+PR）→歸檔」，重切與開 PR 移到審查通過之後。
- `skill-installer`: agent-team 安裝一併佈署 `shiori.md`、`custom-review` skill 與 `review.md` 範本，並補 `install.deps` 相依。

## Impact

- **檔案**：`agent-team/.claude/agents/shiori.md`（新）、`agent-team/.claude/commands/ship-issue.md`、`agent-team/CLAUDE.md`、`agent-team/docs/multi-agent-workflow.md`、`agent-team/openspec/handoff-template.md`、`agent-team/openspec/review-template.md`（新）、`.claude/skills/custom-review/SKILL.md`（新）、`.claude/skills/issue-integrator/SKILL.md`、`.claude/skills/osamu`（osamu.md description）、`install.sh`、`install.deps`、`README.md`。
- **規格**：delta 更新 `agent-team-kit`、`issue-integrator-skill`、`skill-installer`，新增 `custom-review-skill`。
- **相容性**：對既有裝好 4 角色的專案是「新增」而非破壞——沒裝 Shiori 的專案 `/ship-issue` 的 code-review 步驟可退化為只跑內建 `/code-review`；既有 handoff 的舊階段值仍合法。
- **不碰**：本 repo 自身 `.claude/`（kit 檔放在 `agent-team/` 下，不影響本 repo session）。
