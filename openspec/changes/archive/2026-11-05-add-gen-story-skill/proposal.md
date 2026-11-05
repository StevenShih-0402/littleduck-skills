# Proposal

## Why

多 Agent 流程一次會產出大量 diff、handoff、review 內容，人工逐項細看成本很高。既有專案（`ignsw_agents_team`）已實作 `gen-story` skill：把一個 OpenSpec 變更做成「對話劇本式」的單檔 HTML 導覽投影片，由角色用簡短對話帶讀決策與實際程式碼，並附上在系統上怎麼操作才看得到更動。該實作把路徑、repo 名稱、分支、角色都寫死在單一專案，無法重用。本變更把它移植成**通用版**，納入本 skill 發佈 repo，讓任何使用本 repo 的專案都能產出這種導覽。

## What Changes

- 新增 `gen-story` skill 到 `.claude/skills/gen-story/`，由既有專案專屬版移植並去除專案耦合：
  - `SKILL.md`：`/gen-story <change-id>` 的流程、內容規則與章節骨架。
  - `assets/story-template.html`：投影片骨架與 CSS 元件（含 `{{ISSUE-ID}}`／`{{主題}}` 佔位與 `STORY:SLIDES` 插入點）。
  - `scripts/check_layout.mjs`：以 playwright 逐頁檢查版面（超框／需捲動／超出畫布／壓頁尾），有問題 exit 1。
- 去除專案耦合，改為通用：
  - **變更目錄探索**改為單一 repo：`openspec/changes/<change-id>/`，歸檔則 `openspec/changes/archive/*-<change-id>/`；不再寫死 `~/tao_rui_projects/...` 與多 repo／worktree。
  - **base 分支**由 git 自動偵測（不寫死 `main`／`dev`）以計算 `git diff`。
  - **讀取材料**：`proposal.md`／`design.md`／`tasks.md` 一定讀；`handoff.md`／`review.md`／`.linear.md`／`openapi.yaml`「存在才讀」，純 OpenSpec 專案沒有這些 agent-team 產物也能跑。
  - **對話角色**不強制固定五角：模板保留 agent-team 的角色樣式 class（`you`／`hyuse`／`chika`／`yuma`／`osamu`／`shiori`），但 SKILL.md 說明角色依專案而定，非 agent-team 專案可用旁白／單一敘事者。
  - **輸出位置**改為目前專案的 `docs/story/<change-id>.html`。
  - **版面檢查腳本**的 playwright 載入路徑改為先找目前專案 `node_modules`，保留 `PLAYWRIGHT_FROM` 環境變數可覆寫。
- 安裝整合：README 的可選項表新增 `gen-story` 一列（比照 `gen-html`「只裝該 skill 本身」）。gen-story 無跨 skill 相依，`install.deps` 不需新增條目（未列出即視為無相依）。

本變更是 skill 發佈 repo 的資產新增與安裝文件同步，不涉及任何執行期服務或 API。

## Capabilities

### New Capabilities

- `gen-story-skill`: 本 repo 收錄並發佈的 `gen-story` skill——把一個 OpenSpec 變更做成通用、專案無關、對話劇本式的單檔 HTML 導覽投影片；只讀不改、不 commit，可安裝到外部專案。

### Modified Capabilities

<!-- 無。skill-installer 的需求是通用的「安裝使用者挑選的子集」「選項名稱由 repo 內容推導」，新增一個 skill 不改變這些需求；README 的選項列屬文件同步，非需求變更。 -->

## Impact

- 新增檔案：`.claude/skills/gen-story/SKILL.md`、`.claude/skills/gen-story/assets/story-template.html`、`.claude/skills/gen-story/scripts/check_layout.mjs`。
- 修改檔案：`README.md`（可選項表新增 `gen-story` 列）。
- 執行期相依：`check_layout.mjs` 需要 playwright（比照 `draw-mermaid` 需 docker，屬文件化的執行前置，非安裝相依）。
- 不影響既有 skill、指令、模板與安裝腳本行為。
