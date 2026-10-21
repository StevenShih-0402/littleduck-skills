# littleduck-skills

可重複使用的 Claude Code skills 集中 repo，並提供一行指令讓其他專案挑選、安裝／更新這些 skill。

## 內含資產

- `.claude/skills/` — 所有 skill：
  - `issue-reader` / `issue-processor` / `issue-solver` — 三段式 Linear → OpenSpec 流程
  - `openspec-*` — OpenSpec 提案／實作／歸檔／同步
  - `gen-html` — 用單檔 HTML 產生架構圖、流程圖、比較表等
  - `draw-mermaid` — mermaid 圖表的選圖、畫法準則與渲染驗證（驗證腳本需要 docker）
- `.claude/commands/` — `opsx` 等 slash 指令
- `linear/` — Linear 回填模板（question / analyze / change）
- `CLAUDE.md` — 跨專案通用的開發習慣
- `agent-team/` — 多 Agent 開發工作流的建置文件與 team-hq 骨架（只在選 `agent-team` 時安裝）

## 安裝 / 更新到其他專案

```sh
/path/to/littleduck-skills/install.sh <選項> [目標專案路徑]
```

第一個參數**必填**；未給目標路徑時預設安裝到目前工作目錄（`$PWD`）。例：

```sh
# 只裝 draw-mermaid
/path/to/littleduck-skills/install.sh draw-mermaid

# 除 agent-team 外全部裝到指定專案
/path/to/littleduck-skills/install.sh all /path/to/your-project

# 在新的協作中樞 repo 建立 agent-team 骨架
/path/to/littleduck-skills/install.sh agent-team /path/to/team-hq
```

`install.sh --list` 列出全部可選項，`install.sh --help` 顯示用法。缺少選項或選項不存在時，腳本會列出可選項並以非零狀態結束，不會複製任何檔案。

### 選項與安裝內容

| 選項 | 安裝內容 |
|------|----------|
| `<skill 名稱>` | 該 skill，加上它在 `install.deps` 宣告的相依（見下） |
| `issue-reader` / `issue-processor` / `issue-solver` | 三段式 skill 一起裝，加上全部 `openspec-*` skill、`.claude/commands/opsx/`、`linear/` 模板 |
| `openspec-<名稱>` | 該 skill 與對應的 `.claude/commands/opsx/*.md` 指令 |
| `gen-html`、`draw-mermaid` | 只有該 skill 本身 |
| `all` | 除 agent-team 外的全部 `.claude/skills/`、`.claude/commands/`、`linear/` |
| `agent-team` | `CLAUDE.md`（team-hq 版）、`.claude/agents/` 四個角色、`.claude/commands/ship-issue.md`、`docs/multi-agent-workflow.md`、`openspec/handoff-template.md` |

skill 的相依寫在 repo 根目錄的 `install.deps`；新增 skill 時若它會呼叫其他 skill、指令或模板，記得在這裡補上。

### CLAUDE.md

除 `agent-team` 外，任何選項都會在目標專案**沒有** `CLAUDE.md` 時建立通用版本。目標已有 `CLAUDE.md` 時**不覆寫**，只印出略過訊息，需要的話請自行把本 repo 的 `CLAUDE.md` 合併進去。

### agent-team

骨架是「不存在才建立」：已存在的檔案（例如你改過的 agent 定義）一律略過，不覆寫。
這也代表本 repo 更新範本後不會自動傳到已安裝的專案；要取新版請先移除或改名舊檔再重跑。
安裝後把 `CLAUDE.md` 與 agent 定義裡的 `<frontend-repo>`、`<backend-repo>` 等佔位換成實際路徑，完整說明見 `docs/multi-agent-workflow.md`。

### Tab 補齊（bash）

在 `~/.bashrc` 加入：

```sh
source /path/to/littleduck-skills/completions/install.bash
```

之後輸入 `install.sh dr` 再按 Tab 會補齊為 `draw-mermaid`；第二個參數補齊目錄。可選項由 repo 內容即時產生，新增 skill 不必改補齊腳本。

### 從舊版用法遷移

舊版的 `install.sh /path/to/project`（不帶選項）已不再支援，請改成 `install.sh all /path/to/project`。若把目錄當成第一個參數，錯誤訊息會提示這個改法。

### 更新行為

**可重複執行**：再跑一次即就地更新到最新版本，不會產生重複或巢狀副本。缺少的目標目錄會自動建立。

> 注意：安裝會以本 repo 的版本覆寫目標專案中同名的 skill、指令與模板（`CLAUDE.md` 與 agent-team 骨架除外），請勿在目標專案直接修改這些檔案。
