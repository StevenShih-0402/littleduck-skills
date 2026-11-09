# Proposal

## Why

現行 `/ship-issue` 有兩個必經的人工檢查點：提案核准、歸檔前確認。PR 開好後還要 user 手動合併，所以一張 issue 從頭到尾至少要介入三次。SDP-111 希望照 Anthropic「層層把關」的審核流程（見 Linear 文件〈如何審核 AI 產出的 Code？〉）改造：user 只要執行 `/ship-issue`，Agent 團隊就一路做到合併。中途可以問 user 問題，但不再設固定檢查點。人只在**高風險變更**時把關。

SDP-90 底下的 SDP-99（安全審核）、SDP-100（PR 前實際跑起產品）、SDP-101（按風險審批）原本是 add-reviewer-stage 拆出的未來工作，正好是這條全自動流程缺的關卡，本次一併納入。

## What Changes

- **BREAKING：移除檢查點 1 與檢查點 2。** Hyuse 的待確認問題問完後，主對話直接提交並推送提案，接著派工開發。Osamu 收尾後不再等 user 回覆「歸檔」。
- **PR 前兩項檢查**（都通過才開 PR）：
  - **確保正常運行**：Osamu「檢查」沿用現有的測試／lint／typecheck／migration，並新增**執行驗證**：依各 repo `CLAUDE.md` 的啟動指令與觀察點，實際把產品跑起來觀察。repo 沒寫就記錄為略過，不擋流程（吸收 SDP-100）。
  - **檢查代碼品質**：派不帶開發上下文的 Shiori，依 `/custom-review` 對照規格審需求與測試覆蓋。內建 `/code-review` 從這一段移到 PR 中。
- **PR 中四項檢查**（Osamu 收尾開 PR 後，由主對話執行）：
  - **CI**：等 PR 的 checks 全部結束。有失敗就退回；repo 沒有 CI 就記錄略過。
  - **AI 審核**：對 PR 範圍跑內建 `/code-review`，結果由 Shiori 評定嚴重度與信心度。
  - **安全審核**：命中高風險檔案樣式時，跑內建 `/security-review`（吸收 SDP-99）。
  - **按風險審批**：依可設定的判定把變更分成低／中／高。低、中自動往下；**高風險停下來回報 user，等 user 回覆「合併」才繼續**。這是唯一保留的人工關卡（吸收 SDP-101）。
- **BREAKING：移除 shadow mode。** 審查直接採自動退回：只有「高嚴重度且高信心」的發現退回，其餘寫成 PR 備註並留言到 PR。退回上限維持同一目標 2 次，Osamu 檢查、PR 前審查、PR 中檢查共用。`review.md` 拿掉「user 判定」欄與 shadow 計數。
- **審查要能結束**：從第 2 輪起只審上一輪之後的新改動；同類問題一次全部指出；已提過或已判不成立的意見不再重提。
- **新增 integrator「合併」段（模擬合併隊列）**：歸檔後，依後端 → 前端的順序，先把分支 rebase 到最新的主幹，重跑檢查並等 CI 通過，再以 `gh pr merge --merge` 合併。rebase 衝突或檢查失敗就停下或退回，不強行合併。**BREAKING**：Osamu 原本「不 merge PR」的邊界改成「只在合併段、前置條件都成立時 merge」。
- **歸檔前移到合併前、不需 user 同意**：PR 中檢查通過（高風險則 user 已回覆「合併」）後，Osamu 歸檔、追加歸檔 commit、回寫 Linear，接著進合併段。
- **規格免同步聲明改為當下詢問**：Osamu 檢查回報免同步聲明時，主對話當下用 AskUserQuestion 請 user 確認，不再留到檢查點 2。
- **handoff 狀態階段調整**：`reviewing` 之後改為 `pr-checking` → （高風險時）`awaiting-approval` → `archived`，移除 `ready-to-archive`。
- **文件同步**：team-hq `CLAUDE.md`、setup 文件、README、Shiori／Osamu／Hyuse 相關敘述改寫成新流程，並說明既有 team-hq 怎麼升級（骨架檔不會被安裝覆寫）。

### 不納入

- 合併後的功能開關、逐步上線、觀察與回滾：user 之後自行寫進 `CLAUDE.md` 當開發準則。
- Anthropic 的審核題庫評分與誤報率統計：需要累積正式環境問題與 PR 作者回饋，另開 issue。
- GitHub 原生 merge queue：個人 repo 無法使用，一律由 Agent 模擬。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `agent-team-kit`：`/ship-issue` 移除兩個檢查點，改為 PR 前兩檢查、PR 中四檢查、高風險人工審批、自動歸檔與合併；移除 shadow mode；`review.md` 與 handoff 階段跟著調整；Shiori 與 Osamu 定義改寫邊界。
- `issue-integrator-skill`：檢查段加入執行驗證；歸檔段改以「PR 中檢查已通過」為前置條件；新增模擬合併隊列的合併段。
- `custom-review-skill`：輸入不再包含 `/code-review` 發現（改由 PR 中的評定模式處理）；新增「評定」模式與增量審查規則。
- `spec-sync-gate`：多 Agent 流程的免同步聲明，改由主對話在 Osamu 檢查後當下請 user 確認，不再列到檢查點 2。

## Impact

- **檔案**：`agent-team/.claude/commands/ship-issue.md`（主要改寫）、`.claude/skills/issue-integrator/SKILL.md`、`.claude/skills/custom-review/SKILL.md`、`.claude/skills/issue-architect/SKILL.md`（狀態區塊用語）、`agent-team/.claude/agents/osamu.md`、`shiori.md`、`hyuse.md`（視需要）、`agent-team/CLAUDE.md`、`agent-team/docs/multi-agent-workflow.md`、`agent-team/openspec/handoff-template.md`、`agent-team/openspec/review-template.md`、`spec-sync/README.md`、`README.md`。
- **規格**：delta 更新 `agent-team-kit`、`issue-integrator-skill`、`custom-review-skill`、`spec-sync-gate`。
- **相容性**：流程行為改變（不再停在檢查點、會自動合併）。`install.sh agent-team` 會覆寫角色 skill，但骨架檔（`ship-issue.md`、agent 定義、範本、team-hq `CLAUDE.md`）已存在就略過。新版 integrator 搭舊版 `ship-issue.md` 會因為前置條件不符而停下，不會誤合併。升級步驟寫在 README 與 setup 文件。
- **外部依賴**：`gh` 需要有 merge 權限；`/security-review` 是否能指定 worktree 與範圍，實作時依官方文件確認（見 design.md）。
- **單人流程不受影響**：`issue-reader` → `issue-processor` → `issue-solver` 不變。
