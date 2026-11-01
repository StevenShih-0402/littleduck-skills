# littleduck-skills

可重複使用的 Claude Code skills 集中 repo，並提供一行指令讓其他專案挑選、安裝／更新這些 skill。

## 內含資產

- `.claude/skills/` — 所有 skill：
  - `issue-reader` / `issue-processor` / `issue-solver` — 三段式 Linear → OpenSpec 流程
  - `openspec-*` — OpenSpec 提案／實作／歸檔／同步
  - `gen-html` — 用單檔 HTML 產生架構圖、流程圖、比較表等
  - `draw-mermaid` — mermaid 圖表的選圖、畫法準則與渲染驗證（驗證腳本需要 docker）
  - `backend-processor` — 多 Agent 流程的後端實作棒（可中斷接續、每項任務 WIP commit），附編輯後 lint hook
  - `issue-architect` / `frontend-processor` / `issue-integrator` — 多 Agent 流程的提案、前端實作（附編輯後 lint hook）、檢查與歸檔棒，隨 `agent-team` 一起安裝
- `.claude/commands/` — `opsx` 等 slash 指令
- `linear/` — Linear 回填模板（question / analyze / change）
- `spec-sync/` — 規格同步閘門的設定檔格式與範例（專案放 `openspec/spec-sync.yaml` 才啟用）
- `CLAUDE.md` — 跨專案通用的開發習慣
- `agent-team/` — 多 Agent 開發工作流的建置文件與 team-hq 骨架，含寫入範圍限制 hook（只在選 `agent-team` 時安裝）

## 安裝 / 更新到其他專案

在要安裝的專案目錄執行一行指令即可，**不需要先 clone 本 repo**：

```sh
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- <選項> [目標專案路徑]
```

第一個參數**必填**；未給目標路徑時預設安裝到目前工作目錄（`$PWD`）。例：

```sh
# 只裝 draw-mermaid
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- draw-mermaid

# 除 agent-team 外全部裝到指定專案
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- all /path/to/your-project

# 在新的協作中樞 repo 建立 agent-team 骨架
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- agent-team /path/to/team-hq

# 列出全部可選項／顯示用法
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- --list
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- --help
```

缺少選項或選項不存在時，腳本會列出可選項並以非零狀態結束，不會複製任何檔案。

腳本會從 GitHub 下載本 repo 的壓縮檔到暫存目錄作為來源，安裝完（或失敗、被中斷）即清除，不會在電腦上留下 clone。需要 `curl` 或 `wget`，以及 `tar`；缺少工具或下載失敗時會說明原因並以非零狀態結束，不寫入目標專案。

### 固定版本

預設安裝 `main` 分支的最新內容。以環境變數 `LITTLEDUCK_REF` 指定分支、tag 或 commit SHA（注意變數要放在 `sh` 前面）：

```sh
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | LITTLEDUCK_REF=<分支或 tag> sh -s -- all
```

### 先檢視再執行

不想直接執行網路上的腳本時，可以先下載、看過內容再跑：

```sh
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh -o littleduck-install.sh
less littleduck-install.sh
sh littleduck-install.sh all
rm littleduck-install.sh
```

### 從本地 clone 安裝（進階）

已經 clone 本 repo（例如要修改 skill 再安裝）時，直接執行 clone 內的腳本，參數相同，且不會連網：

```sh
/path/to/littleduck-skills/install.sh <選項> [目標專案路徑]
```

### 選項與安裝內容

| 選項 | 安裝內容 |
|------|----------|
| `<skill 名稱>` | 該 skill，加上它在 `install.deps` 宣告的相依（見下） |
| `issue-reader` / `issue-processor` / `issue-solver` | 三段式 skill 一起裝，加上全部 `openspec-*` skill、`.claude/commands/opsx/`、`linear/` 模板、`spec-sync/` |
| `openspec-<名稱>` | 該 skill 與對應的 `.claude/commands/opsx/*.md` 指令 |
| `gen-html`、`draw-mermaid` | 只有該 skill 本身 |
| `backend-processor` | 該 skill（含 `hooks/post-edit-lint.sh`）與 `spec-sync/`；裝在後端 repo，供 agent-team 的後端 Agent 使用 |
| `frontend-processor` | 該 skill（含 `hooks/post-edit-lint.sh`）與 `spec-sync/`；`agent-team` 已會裝進 team-hq，只有想在前端 repo 單獨使用時才需另外安裝 |
| `issue-architect` / `issue-integrator` | 該 skill，加上整組 issue 流程（同 `issue-reader`）；`issue-architect` 另帶 `draw-mermaid` |
| `all` | 除 agent-team 外的全部 `.claude/skills/`、`.claude/commands/`、`linear/`、`spec-sync/` |
| `agent-team` | 骨架：`CLAUDE.md`（team-hq 版）、`.claude/agents/` 四個角色、`.claude/commands/ship-issue.md`、`.claude/hooks/guard-write-scope.sh`、`docs/multi-agent-workflow.md`、`openspec/handoff-template.md`；再加上角色 skill `issue-architect`、`issue-integrator`、`frontend-processor` 與它們的相依（issue 流程、`openspec-*`、`draw-mermaid`、`opsx` 指令、`linear/`、`spec-sync/`）。`backend-processor` 不在其中，要另外裝到後端 repo |

skill 的相依寫在 repo 根目錄的 `install.deps`；新增 skill 時若它會呼叫其他 skill、指令或模板，記得在這裡補上。

### CLAUDE.md

除 `agent-team` 外，任何選項都會在目標專案**沒有** `CLAUDE.md` 時建立通用版本。目標已有 `CLAUDE.md` 時**不覆寫**，只印出略過訊息，需要的話請自行把本 repo 的 `CLAUDE.md` 合併進去。

### agent-team

骨架是「不存在才建立」：已存在的檔案（例如你改過的 agent 定義）一律略過，不覆寫。
這也代表本 repo 更新範本後不會自動傳到已安裝的專案；要取新版請先移除或改名舊檔再重跑。
例如 `openspec/handoff-template.md` 新增了「## 狀態」區塊，`backend-processor` 依賴它，舊骨架要先移除該檔再重跑才拿得到。
又例如 `hyuse.md`、`yuma.md`、`osamu.md`、`ship-issue.md` 改為引用隨附的角色 skill 與 hook；用舊骨架建立的 team-hq 要先移除這幾個檔再重跑。

角色 skill（`issue-architect`、`issue-integrator`、`frontend-processor` 與其相依）則和其他 skill 一樣**每次重跑都覆寫更新**，請勿在 team-hq 直接修改。
安裝後把 `CLAUDE.md` 與 agent 定義裡的 `<frontend-repo>`、`<backend-repo>` 等佔位換成實際路徑，完整說明見 `docs/multi-agent-workflow.md`。

### Tab 補齊（bash，僅本地 clone）

補齊需要讀取本地 repo 的內容，只適用於從本地 clone 執行 `install.sh`。在 `~/.bashrc` 加入：

```sh
source /path/to/littleduck-skills/completions/install.bash
```

之後輸入 `install.sh dr` 再按 Tab 會補齊為 `draw-mermaid`；第二個參數補齊目錄。可選項由 repo 內容即時產生，新增 skill 不必改補齊腳本。

### 從舊版用法遷移

舊版的 `install.sh /path/to/project`（不帶選項）已不再支援，請改成 `install.sh all /path/to/project`。若把目錄當成第一個參數，錯誤訊息會提示這個改法。

### 更新行為

**可重複執行**：再跑一次即就地更新到最新版本，不會產生重複或巢狀副本。缺少的目標目錄會自動建立。

> 注意：安裝會以本 repo 的版本覆寫目標專案中同名的 skill、指令與模板（`CLAUDE.md` 與 agent-team 骨架除外），請勿在目標專案直接修改這些檔案。
