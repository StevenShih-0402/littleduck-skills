# Proposal

## Why

`agent-team` 的四個角色中，Hyuse 呼叫 `/issue-architect`、Yuma 呼叫 `/frontend-processor`、Osamu 呼叫 `/issue-integrator`，但 littleduck 只收錄了 Chika 用的 `backend-processor`。照 README 安裝 `agent-team` 後，三個角色都叫不到自己的 skill，整條 `/ship-issue` 流程跑不起來。這三個 skill 在實際使用中的 team-hq（`ignsw_agents_team`）與前端 repo 已經跑過一輪，可以去專案化後收錄。

## What Changes

- **`issue-architect` skill（新增）**：Hyuse 的流程。讀 Linear issue、系統分析，在前後端 worktree 用同一個 change-id 各建 OpenSpec 變更目錄（proposal／specs／design 含 UML／`openapi.yaml` 草稿／標 `[BE]`、`[FE]` 的 tasks），寫 `handoff.md` 與 `.linear.md`，再回填 Linear 分析並把狀態轉為 In Progress。subagent 不能問 user，所以不呼叫 `/opsx:propose`，而是依 `openspec instructions` 逐份寫 artifact，不確定的事列成待確認問題回傳。
- **`frontend-processor` skill（新增）**：Yuma 的流程，和 `backend-processor` 對稱。讀交接資料（缺檔即停）；後端尚未定稿時依 `openapi.yaml` 先做型別與 mock；每完成一項 `[FE]` 任務就 WIP commit 並 push；支援接續模式；lint、typecheck、test 的指令一律取自前端 repo 的 `CLAUDE.md` 或 `design.md`。附一支編輯後 lint hook，只對剛編輯的單一 JS／TS 檔跑 eslint，也可用環境變數指定 lint 指令。
- **`issue-integrator` skill（新增）**：Osamu 的流程，分兩段。「檢查」段實際跑兩端的測試、lint、型別檢查與 migration 正反向，核對 tasks 是否全勾、兩份 `openapi.yaml` 是否一致、規格同步閘門；不通過就寫進 `handoff.md` 退回對應角色。通過後把 WIP commit 依功能重切，以 `--force-with-lease` 推送並開前後端 PR。「歸檔」段要等 user 回覆「歸檔」，才在兩端歸檔、追加歸檔 commit 並回寫 Linear。
- **寫入範圍 hook（新增，agent-team 骨架）**：`guard-write-scope.sh` 是 Hyuse 和 Osamu 的 PreToolUse hook。Hyuse 只能寫 `openspec/`；Osamu 只能寫 `handoff.md`、`.linear.md` 與歸檔時同步的 `openspec/specs/`。
- **`agent-team` 一併安裝三個 skill**：`install.sh agent-team` 除了骨架，還把 `issue-architect`、`issue-integrator`、`frontend-processor` 及它們的相依同步進 team-hq 的 `.claude/skills/`。相依包括 `issue-*` 系列、`openspec-*` 系列、`draw-mermaid`、`linear/` 與 `spec-sync/`。skill 和其他 skill 一樣每次覆寫更新；骨架仍維持「已存在就略過」。
- **agent-team 範本更新**：`hyuse.md`、`yuma.md`、`osamu.md` 改為讀 team-hq 的 skill、註冊對應 hook，並列出實際需要的工具。`ship-issue.md` 寫明每一棒要帶的參數，並規定檢查點 1 核准時由主對話 commit、push 提案，開發 Agent 開工時 worktree 才是乾淨的。`CLAUDE.md` 的 repo 表加上各 repo 的主幹分支。`multi-agent-workflow.md` 的導入清單改為「三個 skill 隨 agent-team 安裝」。
- **change-id 改為全小寫**：OpenSpec CLI 會拒絕大寫的 change 名稱，因此 `agent-team` 文件與 `backend-processor` 的範例由 `ENG-123-order-export` 改為 `eng-123-order-export`。`backend-processor` 從 change-id 取 ISSUE-ID 時，改為不分大小寫擷取後轉成大寫。
- **規格同步閘門的時機表**：補上 `frontend-processor`（實作中檢查）與 `issue-integrator`（多 Agent 流程的最終閘門：缺規格時有 `handoff.md` 的免同步聲明就放行，並列給 user 在檢查點 2 確認；沒有聲明就退回）。

非破壞性：既有的選項名稱與 `all`、單一 skill 的行為不變，新 skill 會自動成為可選項，也包含在 `all` 中。已用舊骨架建立的 team-hq 重跑 `agent-team` 時，已存在的角色檔不會被覆寫（既有行為），要取新版 `hyuse.md`、`yuma.md`、`osamu.md`、`ship-issue.md` 須先移除舊檔。

## Capabilities

### New Capabilities

- `issue-architect-skill`：多 Agent 流程第一棒，把 Linear issue 轉成前後端兩份 OpenSpec 提案與交接檔。
- `frontend-processor-skill`：多 Agent 流程的前端實作棒，以及它附帶的編輯後 lint hook。
- `issue-integrator-skill`：多 Agent 流程最後一棒，負責檢查、退回、重切 commit、開 PR，以及經 user 核准後的歸檔與 Linear 回寫。

### Modified Capabilities

- `skill-installer`：`agent-team` 選項除了骨架，還要安裝三個角色 skill 及其相依。
- `agent-team-kit`：骨架要包含寫入範圍 hook；Hyuse、Yuma、Osamu 的定義改為引用各自的 skill 與 hook；`/ship-issue` 要在核准時提交提案，並把參數傳給每一棒。
- `spec-sync-gate`：時機與處置加入 `frontend-processor` 與 `issue-integrator`。

## Impact

- 新增 `.claude/skills/issue-architect/`、`.claude/skills/issue-integrator/`、`.claude/skills/frontend-processor/`（含 `hooks/post-edit-lint.sh`）。
- 新增 `agent-team/.claude/hooks/guard-write-scope.sh`。
- 修改 `agent-team/.claude/agents/{hyuse,yuma,osamu}.md`、`agent-team/.claude/commands/ship-issue.md`、`agent-team/CLAUDE.md`、`agent-team/docs/multi-agent-workflow.md`。
- `.claude/skills/backend-processor/SKILL.md`（change-id 範例改小寫、ISSUE-ID 擷取不分大小寫）。
- `install.deps`（新增三個 skill 的相依，以及 `agent-team` 的 skill 清單）、`install.sh`（`agent-team` 分支多裝 skill）、`spec-sync/README.md`、`README.md`。
- 補齊腳本不需修改，新 skill 由既有機制自動列為可選項。
