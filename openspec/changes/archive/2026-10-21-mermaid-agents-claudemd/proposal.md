# Proposal

> 對應 Linear：SDP-69

## Why

公司 monorepo 新增的 `draw-mermaid` skill、多 Agent 開發工作流建置文件，以及散落在各專案 `CLAUDE.md` 的開發習慣，目前都無法在新專案一鍵取得；而現行 `install.sh` 只能「全部照裝」，資產變多後使用者無法挑選、也無法把 Agent 團隊這種結構性資產與一般 skill 分開安裝。

## What Changes

- 搬入 `draw-mermaid` skill（`SKILL.md` + `scripts/render.sh`），移除與公司專案綁定的路徑、issue 代號與前後端 repo 名稱，保留通用的選圖、畫法、驗證準則。
- 新增 **agent-team 套件**：去公司化後的「多 Agent 開發工作流建置文件」＋ team-hq 骨架（`CLAUDE.md`、`.claude/agents/` 四個角色範本、`.claude/commands/ship-issue.md`、`handoff.md` 範本）。此套件**只在明確選擇 `agent-team` 時安裝**。
- 新增本 repo 根目錄 `CLAUDE.md`：彙整 `mygo_v2_anon` 與 `ignsw_bk_monorepo` 兩份 `CLAUDE.md` 中與專案無關的通用開發習慣（TDD/AAA、SOLID、Design Pattern、繁中註解與 commit、檔頭兩行註解、design 附 mermaid 圖、只 lint 變更範圍、禁止結構型斷言等）。
- **BREAKING**：`install.sh` 改為**必填**第一參數選擇要安裝的項目——單一 skill 名稱、`all`（除 agent-team 外全部）或 `agent-team`；未給或給錯時列出可選項並以非零狀態結束。原本 `install.sh [目標路徑]` 的呼叫方式需改為 `install.sh all [目標路徑]`。
- 安裝 skill 時一併帶上其相依資產（例：`issue-reader` 連帶 `openspec-*`、`opsx` 指令、`linear/` 模板）。
- 每次安裝一般 skill 時一併提供通用 `CLAUDE.md`，但**目標專案已有 `CLAUDE.md` 時不覆寫**，只提示略過。
- 提供 bash 的 **tab 鍵補齊**腳本，可補齊第一參數的可選項。
- 更新 README 說明新用法。

## Capabilities

### New Capabilities

- `draw-mermaid-skill`: repo 內提供可安裝的 `draw-mermaid` skill（含渲染驗證腳本），內容不綁定特定專案。
- `agent-team-kit`: 多 Agent 開發工作流的建置文件與 team-hq 資料夾骨架，作為獨立選項安裝。
- `dev-conventions`: repo 提供一份通用開發習慣的 `CLAUDE.md`，安裝時以「不存在才建立」的方式交付。

### Modified Capabilities

- `skill-installer`: 安裝指令改為必選安裝項目（skill 名稱 / `all` / `agent-team`），依相依關係帶入資產、支援 tab 補齊，並交付 `CLAUDE.md`；README 用法同步更新。

## Impact

- `install.sh`（介面改變，舊呼叫方式失效）、`README.md`
- 新增：`.claude/skills/draw-mermaid/`、`agent-team/`（套件來源目錄）、`CLAUDE.md`、`completions/install.bash`
- 外部依賴：`draw-mermaid` 的驗證腳本需要 docker（`minlag/mermaid-cli`），僅在使用者執行渲染時需要。
- 既有安裝者：重跑舊指令會得到用法錯誤，需改帶 `all`。
