# Tasks

> 安裝驗證一律在 scratchpad 的空目錄，以本地 clone 的 `install.sh` 執行。「殘留檢查」指 `grep -rniE 'IGN-|ign-[0-9]|ignsw|IngenuityOA|tao_rui_projects|steven-shih|pants|spectacular|spec_root|LaB|IOA' <檔案>` 沒有輸出。

## 1. 三個角色 skill

- [x] 1.1 新增 `.claude/skills/issue-architect/SKILL.md`。內容包括：
  - 輸入（缺參數即停）、讀 issue 與格式檢查（照 `issue-reader`）、系統分析（含破壞性變更判斷）；
  - 依 `openspec instructions` 在每一端建變更目錄；
  - design.md 的 UML 規則、`openapi.yaml` 草稿與前端副本、`tasks.md` 的 `[BE]`／`[FE]` 標註與可平行區塊；
  - handoff.md 與 `.linear.md`（加 `repos:`）、Linear 回填；
  - 護欄。

  驗證：殘留檢查沒有輸出；逐條對照 spec `issue-architect-skill`。
- [x] 1.2 新增 `.claude/skills/frontend-processor/SKILL.md`，結構對齊 `backend-processor`（design D4）：
  - 讀交接資料、接續檢查；
  - 型別與 mock（不覆蓋整個產出目錄）；
  - 每項任務 WIP 循環、規格同步、檢查（指令取自專案文件，沒寫就停下回報）；
  - 交接、完成定義、護欄。

  驗證：殘留檢查沒有輸出；`grep -niE 'msw|openapi-typescript-codegen|npm run gen'` 沒有輸出；逐條對照 spec `frontend-processor-skill`。（實作時發現 `backend-processor` 開工會檢查 worktree 是否乾淨，前端也一樣，所以提案必須在檢查點 1 由主對話提交，已寫進 3.3。）
- [x] 1.3 新增可執行的 `.claude/skills/frontend-processor/hooks/post-edit-lint.sh`（design D5）。驗證：
  - `bash -n` 通過；
  - 在 scratchpad 的暫存 git repo 以假 hook JSON 實測六種情況：
    - `.py` 檔 → exit 0
    - 沒有 eslint 設定 → exit 0
    - `LITTLEDUCK_FE_LINT_CMD=false` → exit 2
    - `LITTLEDUCK_FE_LINT_CMD=true` → exit 0
    - 有設定檔但缺 `node_modules/.bin/eslint` → exit 0
    - 移除 `jq` 後走 `python3` 路徑，結果相同
- [x] 1.4 新增 `.claude/skills/issue-integrator/SKILL.md`（design D8）：
  - 輸入與兩段模式、邊界；
  - A 檢查：讀交接、實際執行、核對、規格同步閘門判定、退回、通過後重切與 PR；
  - B 歸檔：兩端歸檔、validate、`archived`、歸檔 commit、Linear 回寫；
  - 護欄。

  驗證：殘留檢查沒有輸出；`grep -n 'Linear Document\|git mv'` 沒有輸出；逐條對照 spec `issue-integrator-skill`。（實作時發現：提案在檢查點 1 已提交，用 diff 看不出開發 Agent 有沒有改 `proposal.md`，改為檢查 `wip(` 開頭、但不是「提案核准」的 commit 有沒有動到它。）
- [x] 1.5 `backend-processor` 的 change-id 範例改為小寫；ISSUE-ID 改為不分大小寫擷取後轉大寫（design D7）。驗證：`grep -n 'ENG-[0-9]*-[a-z]' .claude/skills/backend-processor/SKILL.md` 沒有輸出。

## 2. 安裝

- [x] 2.1 `install.deps`：
  - 新增 `issue-architect: skill:issue-reader skill:draw-mermaid`
  - 新增 `issue-integrator: skill:issue-reader`
  - 新增 `frontend-processor: dir:spec-sync`
  - 新增 `agent-team: skill:issue-architect skill:issue-integrator skill:frontend-processor`

  檔頭註解補充 `agent-team` 列的意義。
- [x] 2.2 `install.sh`：`agent-team` 分支在 `install_kit` 之後，以 `deps_of agent-team` 取出 `skill:` 項目交給 `install_selected`，且不呼叫 `install_claude_md`；`deps_of agent-team` 若含非 `skill:` 項目就報格式錯誤；同步更新檔頭註解與 `usage`。驗證：
  - 對空目錄跑 `install.sh agent-team <dir>`，確認骨架、三個 skill、相依（`issue-reader` 系列、`openspec-*`、`draw-mermaid`、`opsx`、`linear/`、`spec-sync/`）都存在，兩支 hook 有執行權限，`CLAUDE.md` 是 team-hq 版；
  - 改動 `<dir>/.claude/agents/hyuse.md` 與 `<dir>/.claude/skills/issue-architect/SKILL.md` 後重跑：前者不變，後者還原；
  - 跑 `install.sh all <dir2>`，確認沒有任何骨架檔；
  - `install.sh --list` 列出三個新 skill。

## 3. agent-team 骨架

- [x] 3.1 新增可執行的 `agent-team/.claude/hooks/guard-write-scope.sh`（design D6）。驗證：`bash -n` 通過，以假 hook JSON 實測 spec「Write-scope hook limits architect and integrator writes」的四個情境，再加上「沒有 file_path → 0」「未知角色 → 2」「osamu 寫 archive 下的 handoff.md → 0」「osamu 寫 openspec/specs → 0」。
- [x] 3.2 改寫 `agent-team/.claude/agents/hyuse.md`、`yuma.md`、`osamu.md`：
  - 指向 team-hq 的 skill，frontmatter 註冊 hook，tools 列出實際需要的工具；
  - 寫清楚邊界與結束時的回報項目。

  驗證：三份 frontmatter 都能以 `python3 yaml.safe_load` 載入；殘留檢查沒有輸出。
- [x] 3.3 改寫 `agent-team/.claude/commands/ship-issue.md`（design D9）：
  - 第 0 步先問完 user；建 worktree；派 Hyuse 與待確認問題往返；
  - 檢查點 1 時提交並推送提案；
  - 依序派 Chika、Yuma；派 Osamu 檢查、處理退回上限、檢查點 2、派 Osamu 歸檔；
  - 單端小 issue 的捷徑。

  驗證：每一棒的參數與 spec「Orchestration commits the approved proposal and passes parameters」一致。
- [x] 3.4 `agent-team/CLAUDE.md`：
  - repo 表加「主幹」欄；change-id 改為全小寫，分支保留大寫 ISSUE-ID；
  - Agent 表註明 skill 位置（Chika 在後端 repo，其餘在 team-hq）；
  - 加上寫入範圍 hook 說明，以及新舊流程的選用方式。

  `agent-team/openspec/handoff-template.md` 註解補上各階段由誰寫入。驗證：殘留檢查沒有輸出；`grep -n 'ENG-123-order' agent-team -r` 只命中分支名範例（分支名保留大寫 ISSUE-ID，屬預期），不出現在 change-id。
- [x] 3.5 `agent-team/docs/multi-agent-workflow.md`：
  - 導入清單改為「三個 skill 隨 agent-team 安裝、backend-processor 另外裝到後端 repo」；
  - Yuma 的 lint hook 與 `LITTLEDUCK_FE_LINT_CMD`；
  - change-id 範例改小寫；
  - Phase 1–3 改為「調整已安裝的 skill」；
  - 範本段落與骨架一致。

  驗證：殘留檢查沒有輸出。

## 4. 文件

- [x] 4.1 `spec-sync/README.md` 的「各 skill 的時機與處置」表加入 `frontend-processor` 與 `issue-integrator`，檔頭註明隨哪些 skill 安裝。驗證：對照 spec `spec-sync-gate` 修改後的 requirement。
- [x] 4.2 `README.md`：
  - 「內含資產」加入三個 skill；
  - 「選項與安裝內容」表的 `agent-team` 列寫明會一併安裝三個 skill 與相依，加入 `frontend-processor` 列；
  - 「agent-team」小節說明 skill 會覆寫更新、骨架不會。

  驗證：README 列出的每個選項都能在 `install.sh --list` 找到。

## 5. 整體驗證

- [x] 5.1 對所有新增與修改的檔案跑殘留檢查，沒有輸出（實際只命中 `backend-processor/hooks/post-edit-lint.sh` 與 `multi-agent-workflow.md` 中的 `./pants`：這是上一個 change 就有的通用 lint 工具偵測，不是專案殘留，不在本次範圍）；兩支新 hook 與 `install.sh` 通過 `bash -n`／`sh -n`；`openspec validate add-agent-team-role-skills --strict` 通過。
- [x] 5.2 回歸：對空目錄分別跑 `all`、`issue-reader`、`backend-processor`、`agent-team`，結果與 README 描述一致；重跑 `all` 不產生巢狀副本。
