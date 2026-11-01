# 多 Agent 開發工作流改造計畫

> 隨 littleduck-skills 的 `install.sh agent-team` 安裝。文中 `<team-hq-repo>`、`<frontend-repo>`、`<backend-repo>` 為佔位，請換成你的實際路徑；框架名稱（Django/DRF 等）僅為範例。

## 目標與現況

目標：把新版流程圖上的四個階段，各交給一個專職 Agent，由主對話（你）統一分派，約三週完成導入。

現況是一個 Agent 從讀 Linear 到寫 code 一路做完，context 越做越長，前後端也無法平行。新版流程已經切好四個階段，這份計畫做的是三件事：

1. 每個階段變成一個 subagent（角色、權限、模型），原本的 slash command 收進該角色的 skill。
2. OpenSpec 變更目錄成為角色之間唯一的交接介面，規定誰讀什麼、寫什麼。
3. 用一個總指揮指令 `/ship-issue` 串起全流程，並在兩處保留人工確認。

| 流程圖階段 | 對應 Agent | 主要 skill / 指令 | 產出 |
| --- | --- | --- | --- |
| /issue-architect | architect | /issue-architect（依 `openspec instructions` 寫 artifact） | proposal、UML、OpenAPI 草稿、兩份 tasks |
| /backend-processor | backend | /backend-processor、/opsx:apply | 後端 API（例：Django/DRF）、單元測試、migration |
| /frontend-processor | frontend | /frontend-processor、/opsx:apply | 畫面切版、API 串接 |
| /issue-integrator | integrator | /issue-integrator、/opsx:archive | 啟動檢查結果、歸檔、Linear 回寫、PR |

```mermaid
flowchart LR
    %% 宣告區
    Issue(["Linear issue"])
    Architect("Hyuse 產生提案")
    Gate1{"檢查點 1：核准提案？"}
    subgraph Develop["平行開發"]
        Backend("Chika 後端 worktree")
        Frontend("Yuma 前端 worktree")
    end
    Integrator{"Osamu 檢查通過？"}
    Gate2{"檢查點 2：同意歸檔？"}
    Done(["歸檔、回寫 Linear、PR"])

    %% 連線區
    Issue ==> Architect
    Architect ==> Gate1
    Gate1 -- "退回修改" --> Architect
    Gate1 == "核准" ==> Develop
    Develop ==> Integrator
    Integrator -- "退回，最多 2 次" --> Develop
    Integrator == "通過" ==> Gate2
    Gate2 == "歸檔" ==> Done
```

Chika 與 Yuma 在各自的 worktree 平行開發；Osamu 檢查失敗會退回開發者，同一階段最多兩次。

## 團隊編制

先建四個 Agent，和流程圖一一對應；QA 與演算法角色等四人跑順後再加。每個 Agent 可以取一個人名當 `name`，你就能用「Chika 幫我在後端執行 /backend-processor」這種方式呼叫。

| Agent | 建議人名 | 職責 | 工具權限 | 建議模型 | 工作目錄 |
| --- | --- | --- | --- | --- | --- |
| architect | Hyuse | 讀 Linear、系統分析、寫 UML 與 OpenAPI 草稿、執行 /opsx:propose | Read、Grep、Glob、Write（限 openspec/）、Linear MCP | opus | 前後端兩個 repo 的 openspec/ |
| backend | Chika | 依後端 tasks 開發 API、單元測試、migration | Read、Edit、Write、Bash | sonnet | 後端 worktree |
| frontend | Yuma | 依前端 tasks 切版、依 OpenAPI 串接 API | Read、Edit、Write、Bash | sonnet | 前端 worktree |
| integrator | Osamu | 啟動檢查、核對 tasks、/opsx:archive、回寫 Linear、開 PR | Read、Grep、Bash、Linear MCP、gh | sonnet | 兩個 worktree（唯讀為主） |

分工原則：

- **Agent 是「誰」，skill 是「怎麼做」。** 流程步驟寫在 skill，角色檔只寫身分、邊界與交接規則。改流程只改 skill。
- **權限要真的限制。** architect 不改程式碼；integrator 不修 bug，發現問題就退回給 backend 或 frontend。
- **architect 用較強模型。** 規格錯了後面全錯，這一步最值得花 token；開發角色用 sonnet 控制成本。
- **後續擴編：** QA（Quinn，只能改 tests/，對照 spec 驗收）與演算法（Ada，寫 design.md 與 benchmark，用 opus）。

## 交接契約

Subagent 之間不共享對話，所有交接都落在同一個 OpenSpec 變更目錄裡；每個 Agent 開工先讀、結束寫回，缺檔就停下回報。

變更 ID 統一用 Linear issue 編號開頭並**全小寫**（OpenSpec CLI 不接受大寫），例如 `eng-123-order-export`；前後端兩個 repo 用同一個 ID，方便對照與歸檔。分支名保留大寫的 issue 編號（`feature/ENG-123-order-export`），讓 Linear automation 認得。

```
openspec/changes/eng-123-order-export/
├── proposal.md     # 需求背景、範圍、驗收條件（來自 Linear）
├── design.md       # UML：資料流、時序圖（Mermaid）
├── openapi.yaml    # Swagger 草稿，前後端共同依據
├── tasks.md        # 該 repo 的任務清單，完成就勾選
├── specs/          # OpenSpec 的需求差異
└── handoff.md      # 各 Agent 的交接紀錄與退回原因
```

| 檔案 | 寫入者 | 讀取者 | 規則 |
| --- | --- | --- | --- |
| proposal.md | architect | 全部 | 開發中不改；需求變動要退回 architect |
| design.md | architect | backend、frontend | 至少一張資料流圖、一張前後端互動時序圖 |
| openapi.yaml | architect 起草、backend 定稿 | frontend、integrator | backend 改欄位必須同步更新並在 handoff.md 註明 |
| tasks.md | architect 建立、開發者勾選 | integrator | 每個任務標註 `[BE]` 或 `[FE]`，勾選時附一行說明 |
| handoff.md | 每個 Agent 完成時追加 | 下一個 Agent | 格式：角色、時間、做了什麼、未完成、風險 |

前端 repo 的 `openapi.yaml` 是後端的副本。建議由 integrator 在檢查時比對兩份是否一致，不一致就退回。

## 執行步驟

分五個階段，每階段都用一個真實的小 issue 跑一次再往下走；前一階段的完成標準沒過，就不要進下一階段。

### Phase 0　前置作業（第 1 週，約半天）

**設定檔放哪裡：** 四個 Agent 與總指揮指令橫跨前後端，放在獨立的 team-hq repo；只跟單一 repo 有關的設定才放進前後端 monorepo。Claude Code 只載入啟動目錄所在專案的 `.claude/agents/`，放在任一邊，另一邊就叫不到 Hyuse 與 Osamu。

| 位置 | 專案具體路徑 | 放什麼 |
| --- | --- | --- |
| team-hq repo | `<team-hq-repo>` | 四個 agent 定義檔、/ship-issue、/issue-architect、/issue-integrator、/frontend-processor（含前端 lint hook）、寫入限制 hook、總覽用 CLAUDE.md |
| 前端 monorepo | `<frontend-repo>` | CLAUDE.md、openspec/ |
| 後端 monorepo | `<backend-repo>` | CLAUDE.md、/backend-processor skill、openspec/、後端測試與 migration hook |

```
~/work/
├── team-hq/            # 從這裡啟動 Claude Code
│   ├── CLAUDE.md       # 前後端 repo 路徑、worktree 慣例
│   └── .claude/
│       ├── agents/     # hyuse.md chika.md yuma.md osamu.md
│       ├── commands/   # ship-issue.md
│       ├── hooks/      # guard-write-scope.sh
│       └── skills/     # issue-architect、issue-integrator、frontend-processor 與相依
├── frontend/           # 前端 monorepo
├── backend/            # 後端 monorepo
└── wt/                 # 各 issue 的 worktree
```

平常從 team-hq 啟動，用 additional directories 設定（或 `--add-dir`）加入前後端 repo 與 wt/。Hyuse、Yuma、Osamu 讀 team-hq 的 skill；Chika 讀後端 repo 的 /backend-processor。兩邊不對稱的原因：`backend-processor` 的 lint hook 以後端 repo 路徑註冊，也可能被後端 repo 自己的 `.claude/settings.json` 使用，所以裝在後端；其餘三個 skill 只在 team-hq 被呼叫，隨 `install.sh agent-team` 一起安裝並在重跑時更新。

- [ ] 建立 team-hq repo，放入四個 agent 定義檔與 /ship-issue
- [ ] 在 team-hq 的 CLAUDE.md 寫明前後端 repo 路徑與 worktree 慣例
- [ ] 設定 additional directories，確認從 team-hq 能讀寫兩個 repo 與 wt/
- [ ] 在後端 repo 安裝 /backend-processor（含編輯後 lint hook 與規格同步說明 `spec-sync/`）：
      `curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- backend-processor <backend-repo>`
- [ ] 確認 team-hq 的 `.claude/skills/` 已有 `issue-architect`、`issue-integrator`、`frontend-processor`（`install.sh agent-team` 會一併安裝；重跑即更新 skill，但不覆寫已存在的骨架檔）

* [ ] 決定 worktree 慣例：例如 `../wt/<repo>-<change-id>`，每個 issue 一組前後端 worktree
* [ ] 前後端 repo 各自執行 OpenSpec 初始化，確認 /opsx:propose、/opsx:apply、/opsx:archive 可用
* [ ] 每個 repo 寫好 `CLAUDE.md`：技術棧、目錄結構、啟動 / 測試 / lint 指令、命名慣例
* [ ] 確認 Linear MCP 已連線，能讀 issue、能改狀態與留言
* [ ] 確認 `gh` CLI 已登入，能開 PR
* [ ] 建立 `handoff.md` 範本，放進 OpenSpec 的變更樣板（範本已隨安裝放在 `openspec/handoff-template.md`；開頭的「## 狀態」區塊就地改值，開發 Agent 中斷後靠它接續。已用舊版骨架建立的 team-hq，安裝不會覆寫既有檔案，要取新版範本須先移除或改名舊的 `openspec/handoff-template.md` 再重跑 `install.sh agent-team`）

完成標準：在任一 repo 手動開一個 worktree，能跑起服務與測試。

### Phase 1　Architect（第 1 週）

- [ ] 檢視隨安裝提供的 /issue-architect：讀 issue → 系統分析 → UML → OpenAPI 草稿 → 前後端各一份變更目錄。它不呼叫 /opsx:propose（subagent 不能回答釐清問題），改依 `openspec instructions` 逐份寫 artifact
- [ ] 把 `hyuse.md` 的 `<frontend-repo>` 等佔位換成實際路徑；寫入限制 hook 已在 frontmatter 註冊
- [ ] 確認 skill 的規定符合你的專案：同一個 change-id 在前後端各產生一份 `tasks.md`，任務標註 `[BE]` / `[FE]`
- [ ] 用 2 個已完成的舊 issue 試跑，比對產出與你當初實際做法的差異
- [ ] 依差異修正 skill，直到你不需大改就能核准提案

完成標準：連續 2 個 issue 的提案，你只做小幅修改就核准。

### Phase 2　Backend 與 Frontend（第 2 週）

- [ ] 檢視 /backend-processor（後端 repo）與 /frontend-processor（team-hq），兩者第一步都是讀 proposal、design、openapi、tasks；測試、lint 等指令取自各 repo 的 CLAUDE.md，沒寫就停下回報
- [ ] 建立 `chika.md`、`yuma.md`，各自限定只在自己的 worktree 工作
- [ ] backend skill 寫明完成定義：API 通過單元測試、migration 可正反向執行、openapi.yaml 已定稿
- [ ] frontend skill 寫明：先用 openapi.yaml 產生型別或 mock，後端未完成也能先切版
- [ ] 先依序跑（先 BE 後 FE），穩定後再試平行
- [ ] 加上 hook：編輯檔案後自動跑 lint / 型別檢查。後端用 /backend-processor 附帶的 `hooks/post-edit-lint.sh`：`chika.md` 範本的 frontmatter 已註冊（把 `<backend-repo>` 換成實際路徑）；不想綁在 Agent 上時，改在後端 repo 的 `.claude/settings.json` 加同樣的 PostToolUse hook（matcher `Write|Edit`）。lint 指令可用環境變數 `LITTLEDUCK_LINT_CMD` 指定，未指定時自動偵測 `./pants` 或 ruff，都沒有就不跑。前端用 /frontend-processor 附帶的 `hooks/post-edit-lint.sh`，已在 `yuma.md` 註冊（路徑以 `$CLAUDE_PROJECT_DIR` 指向 team-hq，不需替換）；lint 指令可用 `LITTLEDUCK_FE_LINT_CMD` 指定，未指定時有 eslint 設定檔與本地 eslint 才跑

完成標準：一個前後端都有改動的 issue，兩個 Agent 各自完成 tasks，且 handoff.md 紀錄完整。

### Phase 3　Integrator（第 2–3 週）

- [ ] 檢視隨安裝提供的 /issue-integrator：實際跑兩端測試 → 核對 tasks 全勾 → 比對兩份 openapi.yaml → 規格同步閘門 → 重切 commit 並開 PR；user 回覆「歸檔」後才歸檔並回寫 Linear
- [ ] 確認 `osamu.md` 的寫入限制 hook 生效：發現問題只寫進 handoff.md 並退回，不自行修改程式碼
- [ ] 在 team-hq `CLAUDE.md` 的 repo 表填好兩端主幹，Osamu 開 PR 時以它為 base
- [ ] 刻意製造一個錯誤（例如欄位名不一致），確認 Osamu 會退回而不是放行

完成標準：Osamu 能正確擋下刻意製造的錯誤，正常 issue 能產出可審查的 PR。

### Phase 4　總指揮與自動化（第 3 週）

- [ ] 檢視隨安裝提供的 `/ship-issue <issue-id>`，串起四個 Agent（摘要見下一節）
- [ ] 前後端改用平行執行，各自使用獨立 worktree
- [ ] 設定退回上限：同一階段退回 2 次就停下來交給你
- [ ] 用 3 個新 issue 端到端跑完，記錄每個 issue 你介入的次數與原因

完成標準：一般 issue 你只需在兩個檢查點介入。

## 範本

完整範本已隨 `install.sh agent-team` 放進 team-hq，直接修改即可；frontmatter 可用欄位以你目前 Claude Code 版本的官方文件為準。這裡只列每個檔案的重點，避免與實際檔案不同步。

| 檔案 | 重點 |
| --- | --- |
| `.claude/agents/hyuse.md` | opus；照 `/issue-architect`；PreToolUse 掛 `guard-write-scope.sh hyuse`，只能寫 `openspec/`；不能問 user，疑問列成待確認問題回傳 |
| `.claude/agents/chika.md` | sonnet；照後端 repo 的 `/backend-processor`；PostToolUse 掛後端 lint hook（`<backend-repo>` 要換成實際路徑） |
| `.claude/agents/yuma.md` | sonnet；照 team-hq 的 `/frontend-processor`；PostToolUse 掛前端 lint hook；不改 `openapi.yaml` |
| `.claude/agents/osamu.md` | sonnet；照 `/issue-integrator`；PreToolUse 掛 `guard-write-scope.sh osamu`；不採信前一棒、不自己修、只在重切後用 `--force-with-lease` |
| `.claude/commands/ship-issue.md` | 先問完 user 再派工；檢查點 1 核准時提交並推送提案；依序派 Chika、Yuma；Osamu 檢查與退回上限；檢查點 2 回覆「歸檔」後才派 Osamu 歸檔 |
| `.claude/hooks/guard-write-scope.sh` | Hyuse 與 Osamu 共用的寫入範圍限制；管不到 Bash，靠定義檔明文禁止 |
| `openspec/handoff-template.md` | 「## 狀態」區塊就地改值，下方各角色紀錄只追加 |

平常也可以單點呼叫，例如「Chika 幫我在後端執行 /backend-processor」或「Osamu 幫我檢查 eng-123-order-export」。

## 檢查點、風險與驗收

全流程只保留兩個必經的人工檢查點：提案核准、歸檔前確認。其他環節靠 Agent 之間的退回機制處理。

| 檢查點 | 時機 | 你要看什麼 |
| --- | --- | --- |
| 1. 提案核准 | architect 完成後 | 範圍是否符合 issue、OpenAPI 欄位是否合理、tasks 拆分是否可平行 |
| 2. 歸檔前 | integrator 檢查通過後 | PR diff、測試結果、handoff.md 中的風險項 |

| 風險 | 徵兆 | 對策 |
| --- | --- | --- |
| 規格錯誤一路傳到底 | 開發中頻繁回頭改 proposal | 檢查點 1 不放水；architect 遇到不明確就停下問 |
| 前後端 API 不一致 | 前端串接失敗、欄位名對不上 | openapi.yaml 單一來源，integrator 比對兩份 |
| Agent 回報不實 | 回報「測試全過」但實際失敗 | integrator 必須實際執行測試，不採信前一棒的摘要 |
| token 與時間成本暴增 | 小 issue 也跑完整四棒 | 小 issue 走捷徑，只派單一開發 Agent |
| 無限退回 | 同一問題來回修 | 退回上限 2 次，超過交給你 |

## 常見問題

### 多加幾個 backend / frontend Agent 會變快嗎？能同時處理多個 Linear 任務嗎？

多建定義檔本身不會變快；同時處理多個 issue 做得到，但瓶頸會轉移到你的審查量與環境隔離上。

**定義檔是樣板，不是人力。** `chika.md` 可以同時啟動多個實例，平行度取決於有沒有彼此獨立的工作，而不是定義檔數量。

**同一個 issue 多派開發 Agent，效益通常很低：**

- 後端任務多半碰同一批 model、serializer、migration，平行寫容易衝突
- 拆分與對齊 openapi.yaml 的協調成本，常高於省下的時間
- 單一 issue 的時間主要花在規格與審查，不在寫 code
- 例外：issue 能切成互不相干的模組時，由 Hyuse 在 tasks.md 標出可平行區塊，再同時派兩個 Chika 實例

**要變快，應該增加同時進行的 issue 數。** 每個 issue 各自一組 worktree、一個 change-id、一條 `/ship-issue`，在不同 session 執行。並行前要先處理：

| 項目 | 問題 | 做法 |
| --- | --- | --- |
| 執行環境 | 多條產線共用 port 與測試資料庫會互相干擾 | docker compose 以 change-id 當 project name，各自獨立 port 與 DB |
| 資料庫 migration（例：Django） | 兩個分支都產生同編號 migration | Osamu 在開 PR 前檢查，必要時執行 `makemigrations --merge` |
| 修改範圍重疊 | 同時改同一模組會衝突 | Hyuse 在提案中列出預計修改的檔案範圍，你依此決定能否並行 |
| 前端共用元件與型別 | 同時改共用元件或 API 型別 | 後合併的分支負責 rebase |

**真正的上限是你。** 每個 issue 有兩個檢查點，並行越多，審查負擔越重。

- 從 2 條並行開始，穩定後再考慮第 3 條
- 用管線化取代純平行：Chika 與 Yuma 開發 issue A 時，Hyuse 先寫 issue B 的提案
- 集中審查：例如早上一次核准提案、下午一次看 PR，減少切換成本
- 注意用量：並行會明顯拉高 token 消耗與 rate limit 壓力，Hyuse 使用 opus 的部分尤其明顯
