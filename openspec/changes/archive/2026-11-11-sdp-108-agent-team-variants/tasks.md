# Tasks：sdp-108-agent-team-variants

> 1～6 在 littleduck-skills（分支 `improvement/SDP-108-agent-team-variants`）；7～9 在各專案 repo，等 1～6 完成後依序處理，各開同名分支與 PR。
> 測試先行：每組先寫會失敗的測試，再實作到通過。

## 1. installer：兩個 kit 選項

- [x] 1.1 新增 `tests/install.test.sh`（AAA，臨時目錄）：`agent-team` 非 0 且不寫檔、訊息含兩個新選項；`--list` 含兩個新選項、不含 `agent-team` 行；兩個選項各裝出自己的骨架、不混入另一種的檔案；兩者都裝出五個角色 skill（含 `backend-processor`）；重跑時既有 Agent 定義被略過、skill 被覆寫。先跑一次確認全部失敗
- [x] 1.2 `install.deps`：`agent-team:` 列換成 `agent-team-fullstack:`、`agent-team-single-side:`（`issue-architect`、`issue-integrator`、`backend-processor`、`frontend-processor`、`custom-review`）；驗證：`./install.sh --list` 不再報 deps 格式錯誤
- [x] 1.3 `install.sh`：`list_names`、`usage`、選項判斷、`kit_skills`、`install_kit` 依選項決定 kit 目錄；`agent-team` 在寫入前報錯並指引；檔頭說明同步更新；驗證：1.1 全數通過
- [x] 1.4 `completions/install.bash` 確認仍由 `--list` 產生候選（必要時調整）；驗證：`source` 後 `compgen` 對 `agent-team-s` 只補出 `agent-team-single-side`

## 2. kit 骨架：fullstack

- [x] 2.1 `git mv agent-team agent-team-fullstack` 保留歷史；驗證：`git status` 顯示 rename
- [x] 2.2 新增 `tests/agent-team-fullstack/guard-write-scope.test.sh`：以模擬 hook JSON 測 `architect`、`integrator` 既有正反向情境（改用角色參數），以及 `backend`／`frontend` 的子目錄放行、跨子目錄拒絕、archive 拒絕、`../` 穿越拒絕、`CLAUDE.md` 缺子目錄時拒絕；先跑確認失敗
- [x] 2.3 改寫 `.claude/hooks/guard-write-scope.sh`：角色參數、從 repo 根目錄 `CLAUDE.md` 的「## agent-team 設定」讀子目錄（fail closed）；參考 littleduck_website 的 yasumi｜fujimori 分支；驗證：2.2 通過
- [x] 2.4 `CLAUDE.md` 範本：移除 team-hq／repo 路徑表，加入「## agent-team 設定」（fullstack 欄位）、單一 worktree 慣例、依序派工、Agent 表（角色 → skill、hook 角色參數）、檢查指令依子目錄分列的寫法；保留層層把關、審查三分法、高風險、風險分級、合併設定、執行驗證、變異測試；驗證：grep 無「前端 repo／後端 repo／team-hq」
- [x] 2.5 Agent 定義：`chika.md` 改 `$CLAUDE_PROJECT_DIR` lint hook 並加 `guard-write-scope.sh backend`；`yuma.md` 加 `guard-write-scope.sh frontend`；`hyuse.md`／`osamu.md` hook 改角色參數；全部改為單一 worktree、一份變更目錄的說法；驗證：grep 無 `<backend-repo>`、`<frontend-repo>`、`<wt-root>`
- [x] 2.6 `ship-issue.md`：一份 worktree、讀「## agent-team 設定」（缺就停下）、先後端後前端依序派工、單一 patch／單一 reviewer 派工／單一 PR／單次合併、退回對象依發現所屬端；驗證：對照 design D6 逐步核對，grep 無「兩端」「team-hq」
- [x] 2.7 `openspec/handoff-template.md`、`review-template.md`：改為單一份（`review.md` 標題不分 backend／frontend，發現列加「端」欄）；驗證：階段註解仍列 `reviewing`、`pr-checking`、`awaiting-approval`
- [x] 2.8 `docs/multi-agent-workflow.md`：改寫為 fullstack 導入文件（安裝指令、「## agent-team 設定」、不可在子目錄建 `.claude/`、`.gitignore` 加 `/wt/` 與 `review-diff.patch`、變異測試與執行驗證設定、D2 對照表）；驗證：grep 無「前端 repo／後端 repo／team-hq」

## 3. kit 骨架：single-side

- [x] 3.1 由 `agent-team-fullstack/` 複製出 `agent-team-single-side/`，刪除 `chika.md`；驗證：`.claude/agents/` 為 hyuse、yuma、osamu、shiori
- [x] 3.2 hook：移除 `backend`／`frontend` 角色，只留 `architect`、`integrator`；在 `tests/agent-team-single-side/guard-write-scope.test.sh` 測正反向與「開發角色參數被拒」；驗證：測試通過
- [x] 3.3 `CLAUDE.md` 範本：「## agent-team 設定」改 single-side 欄位（端、程式碼目錄），Agent 表只有一個開發 Agent；驗證：grep 無「前端 repo／後端 repo／team-hq」
- [x] 3.4 `yuma.md` 改為「開發 Agent」：預設 `/frontend-processor`，註明 `端: backend` 時改走 `/backend-processor` 與其 lint hook；不掛寫入限制；驗證：定義檔同時說明兩種端
- [x] 3.5 `ship-issue.md`：不判斷 BE／FE、只派開發 Agent，其餘同 2.6；驗證：對照 design D6 的 single-side 說明
- [x] 3.6 `docs/multi-agent-workflow.md`：改寫為 single-side 導入文件；驗證：grep 無「前端 repo／後端 repo／team-hq」

## 4. 角色 skill

- [x] 4.1 `issue-architect`：讀「## agent-team 設定」（缺就停下）、一份變更目錄、tasks 排序與 tag 規則、`.linear.md` 的 `repos` 記涉及的端、Linear 實作決策依涉及的端分段；驗證：對照 specs/issue-architect-skill 每條 scenario
- [x] 4.2 `issue-integrator`：單一 worktree／PR、依子目錄跑各端指令、契約只比對 `openapi.yaml` 與實作、單次合併、退回對象依端；驗證：對照 specs/issue-integrator-skill 每條 scenario
- [x] 4.3 `backend-processor`：在後端子目錄（single-side 為程式碼目錄）工作、`openapi.yaml` 就地定稿不複製、fullstack 有 `[FE]` 時交棒為 `frontend`；驗證：對照 specs/backend-processor-skill
- [x] 4.4 `frontend-processor`：在前端子目錄工作、fullstack 時後端未交棒就停下、指令在前端子目錄跑；驗證：對照 specs/frontend-processor-skill
- [x] 4.5 `custom-review`：一份變更目錄與一份 diff、契約檢查涵蓋前後端對同一份 `openapi.yaml`、發現標端；驗證：對照 specs/custom-review-skill
- [x] 4.6 `draw-mermaid`：「前後端分工」補同一 repo 的情況（跨前後端的圖放後端子目錄，前端用 repo 內相對連結）；驗證：分 repo 與同 repo 兩種寫法都有
- [x] 4.7 六個 skill 移除 Agent 名稱、改用角色稱呼；驗證：`grep -riE 'hyuse|chika|yuma|osamu|shiori|前端 repo|後端 repo|team-hq'` 對六個 skill 目錄無輸出
- [x] 4.8 （實作中新增，user 2026-11-11 同意）兩支 `post-edit-lint.sh` 改成從被編輯的檔案往上找最近的設定檔目錄（eslint 設定檔／`pants`、含 `[tool.ruff]` 的 `pyproject.toml`，不超過 git 根目錄）並在那裡跑 lint，fullstack 子目錄的設定才會生效；新增 `tests/.claude/skills/{frontend,backend}-processor/hooks/post-edit-lint.test.sh`（以假 lint 指令驗證子目錄設定、根目錄設定、無設定三種情況）；驗證：測試通過
- [x] 4.9 （實作中新增，user 2026-11-11 同意）`gen-story` 的角色 class 從 Agent 名稱改為角色名（architect／backend／frontend／integrator／reviewer），`spec-sync/README.md` 的「Osamu」改為 integrator；驗證：`grep -rniE 'hyuse|chika|yuma|osamu|shiori' .claude/skills spec-sync linear` 無輸出

- [x] 4.10 （實作中新增，user 2026-11-11 同意）fullstack 的子目錄欄位可列多個路徑（「、」或「,」分隔；第一項是跑檢查的目錄），寫入範圍 hook 對每一項放行「該檔案或其底下」；kit `CLAUDE.md`、`backend-processor`、`frontend-processor`、`issue-integrator` 同步說明；驗證：hook 測試新增 luke 式 `crates/、Cargo.toml、Cargo.lock` 正反向情境並通過，且以迴圈取代 `mapfile`（相容 macOS bash 3.2）

## 5. 本 repo 文件與規格

- [x] 5.1 `README.md`：選項表、一行安裝範例、角色 skill 說明改為兩個 kit；新增「從舊版 agent-team 遷移」段落；驗證：README 的一行指令在空目錄實際執行成功（遠端 `main` 尚無新 kit 且本階段不 push，改以本地 clone 跑同參數驗證：兩種 kit 在空目錄安裝成功、`agent-team` 報錯且不寫檔；遠端一行指令待 PR 合併後於 Workflow follow-up 再確認）
- [x] 5.2 `openspec validate sdp-108-agent-team-variants --strict` 與 `openspec validate --specs` 通過

## 6. 本 repo 整合確認

- [x] 6.1 跑 `tests/install.test.sh` 與兩份 hook 測試全數通過；跑 design.md「## 執行驗證觀察點」四條指令，結果與預期相符
- [x] 6.2 在臨時目錄以 `agent-team-fullstack` 安裝後，對安裝結果 grep 舊 Agent 名稱以外的殘留（`<backend-repo>`、`<frontend-repo>`、`team-hq`），應為 0

## 7. 專案遷移：littleduck_website（fullstack）

- [x] 7.1 開分支 `improvement/SDP-108-agent-team-variants`；先 diff 現有骨架與舊 kit，列出專案差異清單（名稱、color、檢查指令、設計同步規則）
- [x] 7.2 以本地 clone 執行 `install.sh agent-team-fullstack`；逐檔合併骨架（hikaru／yasumi／fujimori／teshima／akafuku、hook 改 kit 版角色參數）；驗證：差異清單逐條核對
- [x] 7.3 `CLAUDE.md` 加「## agent-team 設定」（`backend/`、`frontend/`），刪「單一 repo 設定」與 Agent 定義、`ship-issue.md` 的覆寫段落，保留專案特有段落；驗證：grep 無「單一 repo 設定」「本專案的差異」
- [x] 7.4 hook 正反向手動驗證（yasumi 寫 `frontend/` 被拒、fujimori 寫 change 目錄放行）；`.claude/skills/` 不分大小寫 grep 其他專案的 Agent 名稱與「前端 repo／後端 repo／team-hq」為 0
- [x] 7.5 確認可跑：`/ship-issue` 第 0 步能讀到「## agent-team 設定」、Agent 定義的 hook 指令路徑都存在且可執行（實際跑 `/ship-issue` 與開 PR 依 user 2026-11-11 決定移到 Workflow follow-up；本階段只改到工作區、不 commit）

## 8. 專案遷移：luke（fullstack）

- [x] 8.1 開分支；執行 `install.sh agent-team-fullstack`；因骨架為未修改的舊 kit，直接以新 kit 取代（刪舊骨架後重裝）；驗證：`chika.md` 無 `<backend-repo>`
- [x] 8.2 `CLAUDE.md` 加「## agent-team 設定」（`crates/`、`web/`）與依子目錄的檢查指令（取自 Makefile）、執行驗證；`.gitignore` 加 `/wt/`、`review-diff.patch`；驗證：執行驗證指令實跑成功
- [x] 8.3 `.claude/skills/` grep 驗收同 7.4；確認可跑同 7.5（不 commit、不開 PR）

## 9. 專案遷移：code_city（single-side）

- [x] 9.1 開分支；diff 現有骨架與舊 kit，列出專案差異清單（kagura 的 Bevy／cargo 規則、gintoki 的 CLI 破壞性變更說法）
- [x] 9.2 以本地 clone 執行 `install.sh agent-team-single-side`；合併骨架（gintoki／kagura／sadaharu／shinpachi）；`CLAUDE.md` 加「## agent-team 設定」（`端: frontend`、程式碼目錄 `.`），刪「agent-team（單一 repo、單一開發 Agent）」與各覆寫段落；驗證：差異清單逐條核對
- [x] 9.3 `.claude/skills/` grep 驗收同 7.4（含 `chika`）；確認可跑同 7.5（不 commit、不開 PR）

## Workflow follow-up

- `/issue-solver sdp-108-agent-team-variants`：歸檔、同步主規格並開 littleduck-skills 的 PR。
- 三個專案的工作區改動（第 7～9 組）各自 commit、push 並開 PR（分支 `improvement/SDP-108-agent-team-variants`）。
- 驗收：littleduck_website 用一張小 issue 實際跑 `/ship-issue`，確認先後端後前端、寫入範圍 hook、單一 PR 的收尾與合併正常；luke、code_city 至少跑到第 2 步（提案）確認設定讀得到。
- 三個專案的 PR 由各自 repo 合併；合併前確認 littleduck-skills 的 PR 已合併（遠端 `main` 才有新 kit）。
