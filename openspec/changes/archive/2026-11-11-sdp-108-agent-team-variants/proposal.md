# Proposal：把 agent-team 拆成 fullstack 與 single-side（SDP-108）

## Why

agent-team 目前只支援「team-hq＋前端 repo＋後端 repo」三個 repo，但實際使用的三個專案都是單一 repo。各專案只能在 `CLAUDE.md`、Agent 定義與 `ship-issue.md` 裡覆寫範本的假設（littleduck_website、code_city），或者裝了卻沒辦法用（luke：`chika.md` 的 lint hook 還是 `<backend-repo>` 佔位）。角色 skill 由 installer 管理，在專案內改會被覆寫，所以要回到 skill_repo 改。

## What Changes

- **BREAKING**：移除 `install.sh agent-team` 選項與 `agent-team/` 範本（前後端分兩個 repo 的版本不再維護）。執行 `install.sh agent-team` 時報錯，並提示改用下面兩個選項。
- 新增兩種 kit，各自是一個骨架目錄，由 `install.sh` 分別安裝：
  - `agent-team-fullstack`：一個 repo 同時有前後端。一份 worktree（`wt/<change-id>`）、一份變更目錄（`tasks.md` 同時有 `[BE]`、`[FE]`）、一份 `openapi.yaml`、一個 PR。後端與前端開發 Agent 共用 worktree，**先後端、後前端**依序派工。寫入範圍 hook 依子目錄限制開發 Agent。
  - `agent-team-single-side`：一個 repo 只有一端，只有一個開發 Agent。專案在 `CLAUDE.md` 宣告該端是 `backend` 或 `frontend`，開發 Agent 用該端的 processor skill，任務標該端的 `[BE]` 或 `[FE]`。
- 兩種 kit 裝**同一批角色 skill**（`issue-architect`、`issue-integrator`、`backend-processor`、`frontend-processor`、`custom-review` 及相依）。skill 只維護一份，改用「本 repo／後端子目錄／前端子目錄」的說法，執行時讀專案 `CLAUDE.md` 的「## agent-team 設定」段落（結構、子目錄或端、主幹、worktree 根目錄）決定怎麼走。
- 角色 skill 拿掉「前端 repo／後端 repo／兩端／team-hq」的假設，也**不再寫死 Agent 名稱**，改用角色稱呼（architect、後端 Agent、前端 Agent、integrator、reviewer）。這樣重跑 `install.sh` 後，`.claude/skills/` 不必重新套用各專案的 Agent 名稱。
- 寫入範圍 hook 的參數從 Agent 名稱改為角色名稱（`architect`、`integrator`、`backend`、`frontend`），專案改 Agent 名稱時不必改 hook。
- `ship-issue.md`、`docs/multi-agent-workflow.md`、kit 的 `CLAUDE.md` 範本、`handoff-template.md`、`review-template.md` 依兩種結構改寫：只建一份 worktree、只派一次 reviewer、只開一個 PR、只合併一次；不再複製 `openapi.yaml`，也不再分「後端 → 前端」合併。
- `draw-mermaid` 的「前後端分工」改成也涵蓋同一個 repo 的情況（跨前後端的圖畫在後端子目錄，前端以 repo 內相對連結指過去）。
- 更新三個專案（各 repo 各開 `improvement/SDP-108-agent-team-variants` 分支與 PR）：
  - littleduck_website、luke → `agent-team-fullstack`
  - code_city → `agent-team-single-side`（`端: frontend`）
  - 重裝後手動合併骨架，保留自訂 Agent 名稱與專案特有設定，刪掉已不需要的單一 repo 覆寫。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `agent-team-kit`：kit 從一份「三個 repo」骨架改成 fullstack 與 single-side 兩份單一 repo 骨架；新增「## agent-team 設定」宣告、開發 Agent 的子目錄寫入限制、依序派工、單一 PR 的合併；hook 改用角色參數。
- `skill-installer`：`agent-team` 選項換成 `agent-team-fullstack`、`agent-team-single-side`，舊選項報錯並指引；兩個選項都額外安裝 `backend-processor`。
- `issue-architect-skill`：只建一份變更目錄；`tasks.md` 依結構標 `[BE]`／`[FE]`；`.linear.md` 的 `repos` 改為記錄結構與涉及的端。
- `issue-integrator-skill`：一份 worktree、一個 PR；依子目錄分別跑兩端的檢查；合併不再分兩個 PR。
- `backend-processor-skill`：在後端子目錄內工作；`openapi.yaml` 就地定稿、不再複製到前端；fullstack 且有 `[FE]` 任務時交棒給前端。
- `frontend-processor-skill`：在前端子目錄內工作；fullstack 時接在後端之後開工。
- `custom-review-skill`：以一份變更目錄與一份 diff 審查；拿掉「兩份 `openapi.yaml` 一致」的檢查。

## Impact

- **本 repo**：`install.sh`、`install.deps`、`completions/install.bash`、`README.md`；刪除 `agent-team/`，新增 `agent-team-fullstack/`、`agent-team-single-side/`；`.claude/skills/{issue-architect,issue-integrator,backend-processor,frontend-processor,custom-review,draw-mermaid}/`；相關主規格（歸檔時同步）。
- **使用方**：已裝舊版 `agent-team` 的專案要改用新選項重裝，並手動合併骨架（installer 不覆寫既有骨架檔）。
- **三個專案 repo**：littleduck_website、luke、code_city 的 `.claude/`、`CLAUDE.md`、`docs/multi-agent-workflow.md`、`.gitignore`（luke 缺 `/wt/` 與 `review-diff.patch`）。
- **不在範圍**：Agent 名稱參數化（名稱仍寫在各專案的 Agent 定義與 `ship-issue.md`）、平行派工、前後端分兩個 repo 的支援。
