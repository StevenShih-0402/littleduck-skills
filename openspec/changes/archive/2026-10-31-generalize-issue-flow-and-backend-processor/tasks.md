# Tasks

> 安裝驗證一律在 scratchpad 的空目錄以本地 clone 的 `install.sh` 執行；「殘留檢查」指 `grep -rniE 'SDP-|IGN-|ollama|ignsw|tao_rui_projects' <檔案>` 無輸出。

## 1. issue 流程去專案化

- [x] 1.1 `issue-reader` / `issue-processor` / `issue-solver` 的 issue 辨識改為 `[A-Z][A-Z0-9]*-\d+`，範例統一為 `ENG-123`（design D1）。驗證：三份 SKILL.md 殘留檢查無輸出，且 `issue-reader` 步驟 1 的擷取規則寫的是通用樣式
- [x] 1.2 改寫 `issue-processor`「實作期間的規範」：移除 Ollama／`ollama_tools`／ruff／uv 等專案內容，只留通用條目，測試與 lint 指令改為「依專案 `CLAUDE.md` 與 `design.md`，沒寫就以 AskUserQuestion 詢問」（design D2）。驗證：殘留檢查無輸出；規範表逐條對照 spec「Issue flow skills are project-agnostic」的兩個情境
- [x] 1.3 `issue-processor` 加入破壞性變更守門段落，引用 `CLAUDE.md`「API 相容性」判準，`tasks.md` 要就地改既有端點且屬破壞性時停下回報並建議修 artifact。驗證：段落涵蓋 spec「Breaking API changes are not implemented in place」的兩個情境
- [x] 1.4 `> ▲ 前端需注意的變動` 區塊：更新 `linear/analyze_template.md`、`linear/change_template.md`，以及 issue-reader（主 issue 留佔位）、issue-processor（實作後回填，無影響寫「無」）的對應段落。驗證：兩份模板與兩份 SKILL.md 都提到此區塊，且 issue-reader 的主 issue 規則同時列出兩個引言區塊
- [x] 1.5 issue-solver 的 `Co-Authored-By` 範例改為不寫死模型版本（例：`Co-Authored-By: <依系統提供的署名>`）。驗證：`grep -n 'Opus' .claude/skills/issue-solver/SKILL.md` 無輸出

## 2. 規格同步閘門

- [x] 2.1 新增根目錄 `spec-sync/README.md`（設定檔格式：`rules[].name`、`paths`（含 `{名稱}` 擷取）、`exclude`、`spec_dir`、`spec_files`、`exempt_when`；路徑來源；通過判定；三選一處置）與 `spec-sync/spec-sync.example.yaml`（含單一擷取規則與一組路徑對應多個規格資料夾的規則）（design D3）。驗證：`python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" spec-sync/spec-sync.example.yaml` 成功；README 涵蓋 spec `spec-sync-gate` 每條 requirement；檔內無專案綁定字樣
- [x] 2.2 `issue-solver` 在 `/opsx:archive` 前加入「規格同步閘門」步驟：無設定檔即略過；未通過以 AskUserQuestion 三選一；免同步理由寫入 PR 內文；收尾報告逐規則列結果；護欄加入「閘門未解決不歸檔」。格式只引用 `spec-sync/README.md`，不在 SKILL.md 重抄。驗證：流程逐條對照 spec「issue-solver runs the spec sync gate before archiving」與 `spec-sync-gate` 的情境；description 欄位同步更新
- [x] 2.3 `install.deps`：`issue-reader` 一列加 `dir:spec-sync`。驗證：對空目錄跑 `install.sh issue-solver <dir>` 後 `<dir>/spec-sync/README.md` 與範例存在

## 3. backend-processor skill

- [x] 3.1 新增 `.claude/skills/backend-processor/SKILL.md`：輸入、讀交接資料（缺檔即停）、接續檢查、每項任務循環、規格同步（引用 `spec-sync/README.md`，免同步寫 handoff）、測試與 migration 正反向（指令引用專案 `CLAUDE.md`，沒寫就詢問）、openapi 定稿與前端單檔 commit、交接、完成定義、護欄（design D4）。以 `<backend-worktree>`、`<frontend-worktree>`、`<ISSUE-ID>` 為佔位。驗證：殘留檢查與 `grep -niE 'pants|docker compose|spectacular|IOA|LaB'` 皆無輸出；逐條對照 spec `backend-processor-skill` 前七條 requirement 的情境（實作時發現 agent-team 流程不產生 `.linear.md`：改為「有就核對分支、沒有就從 change-id 取 ISSUE-ID 且不得在預設分支」，spec 同步修正）
- [x] 3.2 新增 `.claude/skills/backend-processor/hooks/post-edit-lint.sh`（可執行）：依 design D6 的偵測順序決定 lint 指令、只處理單一 `.py` 檔、失敗 exit 2 附輸出末 40 行、model 提醒不影響退出碼。驗證：`sh -n`／`bash -n` 通過；以假 hook JSON 在 scratchpad 建的暫存 git repo 實測五種情況——非 `.py` 檔 exit 0、無 lint 工具 exit 0、`LITTLEDUCK_LINT_CMD=false` exit 2、`LITTLEDUCK_LINT_CMD=true` exit 0、編輯 `models.py` 時 stderr 含 migration 提醒且 exit 0（實作時發現開發機未必有 `jq`，改為缺 `jq` 時以 `python3` 解析；ruff 自動偵測加上「`uv run ruff --version` 跑得起來」的條件，避免專案未裝 ruff 時每次編輯都失敗；design D6 同步修正）
- [x] 3.3 `install.deps` 新增 `backend-processor: dir:spec-sync`。驗證：對空目錄跑 `install.sh backend-processor <dir>`，得到 skill 目錄（含 hook 且保有執行權限）與 `spec-sync/`；`install.sh --list` 列出 `backend-processor`

## 4. agent-team 範本

- [x] 4.1 `agent-team/openspec/handoff-template.md` 加入 `## 狀態` 區塊（design D5），放在追加式紀錄之上並註明「就地改值」。驗證：對照 spec「Handoff template carries a status block」
- [x] 4.2 `agent-team/.claude/agents/chika.md`：改為執行 `/backend-processor`、以狀態區塊為進度依據，frontmatter 加 PostToolUse `Write|Edit` hook 指向 `<backend-repo>/.claude/skills/backend-processor/hooks/post-edit-lint.sh`。驗證：殘留檢查無輸出；frontmatter 為合法 YAML（`python3 -c` 載入 `---` 之間內容成功）
- [x] 4.3 `agent-team/docs/multi-agent-workflow.md` 與 `agent-team/CLAUDE.md`：導入清單加上 `install.sh backend-processor <backend-repo>`、hook 改放專案 `settings.json` 的寫法、`handoff.md` 狀態區塊說明，並註明舊骨架要取新版 `handoff-template.md` 須先移除舊檔。驗證：對照 spec「Setup document explains installing backend-processor」；殘留檢查無輸出

## 5. 文件與整體驗證

- [x] 5.1 `README.md`「內含資產」與「選項與安裝內容」表加入 `backend-processor` 與 `spec-sync/`。驗證：README 列出的每個選項都能被 `install.sh --list` 找到（實作時補改 `install.sh` 的 `all` 分支與檔頭註解，讓 `all` 一併複製 `spec-sync/`，與 README 一致）
- [x] 5.2 整體回歸：對三個空目錄分別跑 `all`、`issue-reader`、`agent-team`，確認 `all` 含 `backend-processor` 與 `spec-sync/`、`agent-team` 的 `handoff-template.md` 有狀態區塊，且重跑 `all` 無巢狀副本；對全部新增／修改檔案跑殘留檢查無輸出；`openspec validate generalize-issue-flow-and-backend-processor --strict` 通過

## 6. 閘門改為「檢查 delta、更新交給 sync」

> 實作後討論的追加調整：OpenSpec 格式的規格改由 `/opsx:archive`（內含 sync）寫入主規格，閘門只偵測漏寫；自由格式文件維持檢查檔案本身。

- [x] 6.1 更新 spec `spec-sync-gate`、design D3（含流程圖）：規則目標二選一——`capability`（change 內有該 capability 的 delta 即通過，主規格由 archive 同步）或 `spec_dir`（自由格式，檢查檔案本身）；檢查時機前移到實作階段，`issue-solver` 保留為歸檔前的最終閘門。驗證：`openspec validate --strict` 通過；流程圖以 draw-mermaid 腳本渲染並目視
- [x] 6.2 更新 `spec-sync/README.md` 與範例：兩種目標的欄位、判定、各 skill 的時機與處置；範例至少一條 `capability` 規則。驗證：範例 YAML 可載入、每條規則恰有一種目標；殘留檢查無輸出
- [x] 6.3 `issue-processor` 在 `/opsx:apply` 完成後跑閘門，未通過以 AskUserQuestion 讓 user 選「現在補上（寫 delta 或更新文件）」或「留給 issue-solver 決定」；`issue-solver` 的閘門說明改為兩種目標、`capability` 通過者在報告註明「歸檔時由 sync 寫入」。驗證：兩份 SKILL.md 對照 spec 的情境；description 同步
- [x] 6.4 `backend-processor` 的規格同步段落改為：`capability` 規則在同一項任務內寫或更新 change 的 delta，`spec_dir` 規則更新文件本身；完成定義同步。驗證：對照 spec `backend-processor-skill`「Specs are synced within the task」（必要時修改該 requirement）；`openspec validate --strict` 通過

## Workflow follow-up

- 檢查通過後 `/opsx:archive`，並確認新增的 `issue-flow-skills`、`spec-sync-gate`、`backend-processor-skill` 主規格 Purpose 正確。
- 合併後在 ignsw_bk_monorepo 評估是否改以 `openspec/spec-sync.yaml` 取代 issue-solver 內寫死的四段檢查（另開 change）。
