# Proposal

## Why

本 repo 的三段式 issue 流程 skill 是從個別專案搬回來的，目前仍帶有來源專案的痕跡：`issue-processor` 的實作規範寫的是某個 Ollama CLI 工具，三份 skill 的 issue 代號寫死為 `SDP-`，裝到其他專案會拿到錯誤的規範。另一方面，實際使用中的後端 monorepo 已經長出幾套可跨專案沿用的設計（規格同步閘門、後端實作 skill 與接續機制、編輯後自動 lint、破壞性變更守門），但 littleduck 尚未收錄；`agent-team` 的 Chika 定義甚至會呼叫一個 littleduck 沒有提供的 `/backend-processor`。

## What Changes

- **issue 流程去專案化**：`issue-reader` / `issue-processor` / `issue-solver` 改以通用的 Linear identifier 樣式辨識 issue（不再寫死 `SDP-`）；`issue-processor` 的實作規範改為「依專案 `CLAUDE.md` 與 `design.md`」的通用寫法，移除 Ollama／`ollama_tools` 等專案專屬內容；`Co-Authored-By` 範例改為不寫死模型版本。
- **破壞性變更守門**：`issue-processor` 實作前先依 `CLAUDE.md` 的 API 相容性判準判定；`tasks.md` 看起來要就地改既有端點但屬破壞性變更時，停下回報並建議修正 artifact，不照字面實作。
- **API 使用方影響區塊**：Linear 模板與 issue-* 在主 issue 加入 `> ▲ 前端需注意的變動` 引言區塊（無影響時寫「無」），對應 `CLAUDE.md` 的 API 相容性規範。
- **規格同步閘門（新增）**：專案可在 `openspec/spec-sync.yaml` 宣告「程式路徑 → 規格」規則，目標二選一：OpenSpec capability（檢查 change 是否帶有該 delta，實際寫入主規格交給歸檔時的 `/opsx:sync`）或自由格式文件資料夾（檢查文件本身）。閘門只偵測漏寫：實作階段（`issue-processor`、`backend-processor`）先檢查一輪，`issue-solver` 在歸檔前做最終檢查，未通過時以 AskUserQuestion 讓 user 選「先補規格後重跑／宣告免同步並寫理由（寫入 PR）／中止」。專案沒有設定檔就略過整個檢查。
- **`backend-processor` skill（新增）**：多 Agent 流程的後端實作棒通用骨架——讀交接資料（缺檔即停）、接續模式檢查、每項任務「驗證 → 勾選 → 更新狀態 → 列路徑 add → WIP commit → push」循環、測試與 migration 正反向驗證、`openapi.yaml` 定稿並同步到前端、交接。技術棧相關指令（測試、lint、schema 產生）一律引用專案 `CLAUDE.md`。
- **編輯後 lint hook（新增）**：隨 `backend-processor` 一起發佈的 PostToolUse hook 腳本，只對剛編輯的單一檔案跑 lint，失敗以 exit 2 回饋給 Agent；改到 model 時提醒 migration（不阻擋）；lint 指令可由環境變數指定或自動偵測。
- **agent-team 範本更新**：`handoff-template.md` 新增 `## 狀態` 區塊（就地改值）；`chika.md` 引用 lint hook，並以狀態區塊作為進度依據；`multi-agent-workflow.md` 補上 `backend-processor` 的安裝方式。

非破壞性：既有安裝方式、選項名稱與相依關係不變；已用舊版 `agent-team` 骨架建立的 team-hq 不會被覆寫，要取新版 `handoff-template.md` 須自行移除舊檔再重裝（既有行為）。

## Capabilities

### New Capabilities

- `issue-flow-skills`：三段式 Linear → OpenSpec 流程（issue-reader / issue-processor / issue-solver）與 `linear/` 模板的通用行為——issue 辨識、專案無關性、破壞性變更守門、API 使用方影響區塊。
- `spec-sync-gate`：以專案設定檔宣告程式路徑與規格（OpenSpec capability 或自由格式文件）的對應，偵測改了程式卻漏寫規格的機制，含檢查時機與免同步聲明；寫入主規格仍由 OpenSpec sync 負責。
- `backend-processor-skill`：多 Agent 流程中後端實作棒的 skill 與其附帶的編輯後 lint hook。

### Modified Capabilities

- `agent-team-kit`：`handoff.md` 範本須含狀態區塊；後端 Agent 定義須引用 `backend-processor` 與 lint hook。

## Impact

- `.claude/skills/issue-reader/`、`issue-processor/`、`issue-solver/` 的 `SKILL.md`。
- 新增 `.claude/skills/backend-processor/`（`SKILL.md`、`hooks/post-edit-lint.sh`）。
- 新增根目錄 `spec-sync/`（設定檔格式說明與範例），由 `issue-solver` 與 `backend-processor` 以 `dir:spec-sync` 相依帶入。
- `linear/analyze_template.md`、`linear/change_template.md`。
- `agent-team/openspec/handoff-template.md`、`agent-team/.claude/agents/chika.md`、`agent-team/docs/multi-agent-workflow.md`。
- `install.deps`（`backend-processor` 的相依）、`README.md`（內含資產清單）。
- `install.sh` 與補齊腳本不需修改：新 skill 由既有機制自動列為可選項。
