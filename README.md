# littleduck-skills

可重複使用的 Claude Code skills 集中 repo，並提供一行指令讓其他專案挑選、安裝／更新這些 skill。

## 內含資產

- `.claude/skills/` — 所有 skill：
  - `issue-reader` / `issue-processor` / `issue-solver` — 三段式 Linear → OpenSpec 流程
  - `openspec-*` — OpenSpec 提案／實作／歸檔／同步
  - `gen-html` — 用單檔 HTML 產生架構圖、流程圖、比較表等
  - `gen-story` — 把一個 OpenSpec 變更做成以圖表為主、對話劇本式的單檔 HTML 導覽投影片（版面檢查腳本需要 playwright，會擋下沒有圖或文字過多的頁面）
  - `draw-mermaid` — mermaid 圖表的選圖、畫法準則與渲染驗證（驗證腳本需要 docker）
  - `issue-architect` / `backend-processor` / `frontend-processor` / `issue-integrator` — 多 Agent 流程的提案（含執行驗證觀察點）、後端實作、前端實作（兩者可中斷接續、每項任務 WIP commit，附編輯後 lint hook）、整合（檢查與執行驗證含截圖觀察點／收尾開 PR／歸檔／模擬合併隊列並合併）。讀專案 `CLAUDE.md` 的「## agent-team 設定」支援 fullstack 與 single-side 兩種結構，隨兩種 agent-team kit 一起安裝
  - `custom-review` — 多 Agent 流程的 reviewer：PR 前對照 OpenSpec 規格審查需求／測試覆蓋與邏輯，PR 中評定內建 `/code-review`、`/security-review` 的發現，隨兩種 agent-team kit 一起安裝
- `.claude/commands/` — `opsx` 等 slash 指令
- `linear/` — Linear 回填模板（question / analyze / change）
- `spec-sync/` — 規格同步閘門的設定檔格式與範例（專案放 `openspec/spec-sync.yaml` 才啟用）
- `CLAUDE.md` — 跨專案通用的開發習慣
- `agent-team-fullstack/`、`agent-team-single-side/` — 多 Agent 開發工作流的兩種骨架與導入文件，都是「一個 repo、從 repo 根目錄啟動」：
  - **fullstack**：一個 repo 同時有前後端（例：`backend/`、`frontend/`）。五個角色（architect、後端、前端、integrator、reviewer），一份 worktree、一份變更目錄、一個 PR；後端與前端 Agent 依序派工，寫入範圍 hook 依子目錄限制
  - **single-side**：一個 repo 只有一端、只用一個開發 Agent（四個角色）
  - 兩者共用：`/ship-issue` 從提案一路自動做到合併（PR 前兩項檢查、PR 中四項檢查、模擬合併隊列，只有高風險時停下等你回覆「合併」）、`handoff.md`／`review.md` 範本、寫入範圍限制 hook；只在選對應選項時安裝

## 安裝 / 更新到其他專案

在要安裝的專案目錄執行一行指令即可，**不需要先 clone 本 repo**：

```sh
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- <選項> [目標專案路徑]
```

第一個參數**必填**；未給目標路徑時預設安裝到目前工作目錄（`$PWD`）。例：

```sh
# 只裝 draw-mermaid
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- draw-mermaid

# 除 agent-team kit 外全部裝到指定專案
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- all /path/to/your-project

# 一個 repo 同時有前後端：裝 fullstack 的多 Agent 骨架
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- agent-team-fullstack /path/to/your-project

# 一個 repo 只有一端：裝 single-side 的多 Agent 骨架
curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- agent-team-single-side /path/to/your-project

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
| `gen-html`、`gen-story`、`draw-mermaid` | 只有該 skill 本身 |
| `backend-processor` / `frontend-processor` | 該 skill（含 `hooks/post-edit-lint.sh`）與 `spec-sync/`；兩種 agent-team kit 都已包含，只有不用 kit、想單獨使用時才需另外安裝 |
| `issue-architect` / `issue-integrator` | 該 skill，加上整組 issue 流程（同 `issue-reader`）；`issue-architect` 另帶 `draw-mermaid` |
| `all` | 除 agent-team kit 外的全部 `.claude/skills/`、`.claude/commands/`、`linear/`、`spec-sync/` |
| `agent-team-fullstack` | 骨架：`CLAUDE.md`（含「## agent-team 設定」，`結構: fullstack`）、`.claude/agents/` 五個角色（architect、後端、前端、integrator、reviewer；預設名稱 hyuse／chika／yuma／osamu／shiori）、`.claude/commands/ship-issue.md`、`.claude/hooks/guard-write-scope.sh`（依子目錄限制開發 Agent）、`docs/multi-agent-workflow.md`、`openspec/handoff-template.md`、`openspec/review-template.md`；再加上角色 skill `issue-architect`、`issue-integrator`、`backend-processor`、`frontend-processor`、`custom-review` 與它們的相依（issue 流程、`openspec-*`、`draw-mermaid`、`opsx` 指令、`linear/`、`spec-sync/`） |
| `agent-team-single-side` | 同上，但骨架只有四個角色（一個開發 Agent），`CLAUDE.md` 宣告 `結構: single-side` 與「端」（`backend` 或 `frontend`），開發 Agent 依「端」走對應的 processor skill |
| ~~`agent-team`~~ | 已移除（前後端分兩個 repo 的版本不再維護）；選它會報錯並指引改用上面兩個 |

skill 的相依寫在 repo 根目錄的 `install.deps`；新增 skill 時若它會呼叫其他 skill、指令或模板，記得在這裡補上。

### CLAUDE.md

除兩種 agent-team kit 外，任何選項都會在目標專案**沒有** `CLAUDE.md` 時建立通用版本（kit 則建立自己的 `CLAUDE.md` 範本）。目標已有 `CLAUDE.md` 時**不覆寫**，只印出略過訊息，需要的話請自行把本 repo 的 `CLAUDE.md` 合併進去。

### agent-team kit

兩種 kit 都裝在**專案 repo 的根目錄**，平常就從這裡啟動 Claude Code：

| 專案結構 | 選項 | 開發 Agent |
|----------|------|-----------|
| 一個 repo 同時有前後端（例：`backend/` + `frontend/`、`crates/` + `web/`） | `agent-team-fullstack` | 後端、前端各一個，共用 worktree 依序派工 |
| 一個 repo 只有一端（例：純 API、純前端、桌面程式、CLI） | `agent-team-single-side` | 一個，依「端」走 `backend-processor` 或 `frontend-processor` |

- 安裝後在專案 `CLAUDE.md` 填好「## agent-team 設定」（結構、主幹、worktree 根目錄、子目錄或端）與「## 檢查指令」；角色 skill、`/ship-issue`、寫入範圍 hook 都讀這一段，不寫死目錄。專案已有 `CLAUDE.md` 時 installer 不覆寫，要手動把 kit 的段落合併進去。
- 骨架是「不存在才建立」：已存在的檔案（Agent 定義、`ship-issue.md`、hook、範本、`CLAUDE.md`）一律略過，不覆寫；Agent 定義另以整組判斷，`.claude/agents/` 已有任何 Agent 定義就不建立範本名稱的 Agent。本 repo 更新範本後不會自動傳到已安裝的專案；要取新版請先移除或改名舊檔再重跑，或參考 kit 目錄手動合併。
- 角色 skill（`issue-architect`、`issue-integrator`、`backend-processor`、`frontend-processor`、`custom-review` 與其相依）和其他 skill 一樣**每次重跑都覆寫更新**，請勿在專案內直接修改。
- **Agent 名稱可以改**（改定義檔檔名、`name`、`CLAUDE.md` 的 Agent 表與 `ship-issue.md`）。角色 skill 只用角色稱呼、不寫 Agent 名稱，hook 的參數也是角色（`architect`、`integrator`、`backend`、`frontend`），所以重跑 installer 後不必再改 `.claude/skills/`。**改名後可以放心重跑 installer**：`.claude/agents/` 已有任何 Agent 定義（不論檔名）時，installer 不會建立範本名稱的 Agent 定義，並在輸出逐檔說明略過原因；只有 `.claude/agents/` 不存在或沒有 `*.md` 時才建立全部範本。
- 完整說明見 kit 內的 `docs/multi-agent-workflow.md`。

#### 從舊版 agent-team 遷移

舊版 `install.sh agent-team`（協作中樞 repo 加上前後端分兩個 repo）已移除。已用舊版、在單一 repo 裡靠覆寫段落運作的專案：

1. 先 diff 現有骨架與舊版 kit，列出專案自己的差異（Agent 名稱、color、模型、檢查指令、專案規則）。
2. 依專案結構執行 `install.sh agent-team-fullstack <repo>` 或 `install.sh agent-team-single-side <repo>`：角色 skill 更新為新版，已存在的骨架檔會被略過。
3. 以新版 kit 的骨架為底逐檔合併第 1 步的差異：hook 參數改成角色名稱，刪掉「本專案的差異（單一 repo）」之類的覆寫段落。
4. 專案 `CLAUDE.md` 加「## agent-team 設定」，刪掉單一 repo 的對照段落；執行驗證、變異測試、高風險檔案樣式等專案設定保留。
5. 驗收：`grep -riE '前端 ?repo|後端 ?repo|team-?hq' .claude/skills/` 應無輸出；用一張小 issue 跑 `/ship-issue`。

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

> 注意：安裝會以本 repo 的版本覆寫目標專案中同名的 skill、指令與模板（`CLAUDE.md` 與 agent-team kit 骨架除外），請勿在目標專案直接修改這些檔案。

## Remote Control（手機監看）

想在手機上監看 Claude Code 的進度、派新任務給本機時：

```bash
.claude/scripts/remote-control.sh start   # 在背景 tmux 啟動 server；status／stop／attach 查詢、停止、接回
```

首次啟動步驟、手機端操作與限制見 [docs/remote-control.md](docs/remote-control.md)。

## Agent 進度看板（原型）

把 `/ship-issue` 各任務目前在工作流的哪個階段畫成看板，目前只有示範資料的原型，不會安裝到其他專案：

- 資料來源：只讀 change 目錄 `handoff.md` 的「## 狀態」區塊與 `tasks.md` 的勾選；歸檔後改讀 `openspec/changes/archive/<日期>-<change-id>/`。
- 階段對照：`proposal`→提案、`backend`／`frontend`→開發、`integrating`→檢查、`reviewing`→PR 前審查、`pr-checking`→PR 中檢查、`awaiting-approval`→等待審批、`archived`→合併隊列；其他值顯示「無法辨識」。暫停原因含「退回第 N 次」時標示退回次數。
- 檔案：解析模組 `prototypes/agent-progress-dashboard/handoff-status.js`（無相依）、兩頁共用的示範資料 `demo-data.js`、卡片看板 `index.html`、RPG 基地 `base.html`。
- RPG 基地：每個任務由一個幾何角色拿著，站在目前階段的工作站；角色外觀依負責的 Agent（提案 Hyuse、後端 Chika、前端 Yuma、檢查與合併隊列 Osamu、PR 前審查 Shiori、PR 中檢查主對話、等待審批是你）。「播放」會依序套用示範任務的 handoff.md 快照，看角色沿流程移動與退回。

```bash
node --test tests/prototypes/   # 解析模組的測試（需要 Node.js 18 以上）
```

本機預覽頁面時，伺服器要以 `charset=utf-8` 送出 HTML；`python3 -m http.server` 不帶 charset，中文會變亂碼。
