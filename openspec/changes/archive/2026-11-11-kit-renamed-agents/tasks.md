# Tasks

## 1. 測試先行

- [x] 1.1 在 `tests/install.test.sh` 新增 `test_rerun_after_renaming_agents_creates_no_template_agents`：裝 `agent-team-fullstack` 後把五個 Agent 定義改名（例：`hyuse.md` → `hikaru.md`），重跑同一 kit，斷言 `.claude/agents/` 只剩改名後的五個檔、內容不變，輸出含「已有 Agent 定義」的略過原因；驗證：此時跑 `bash tests/install.test.sh` 該案例失敗（紅燈）
- [x] 1.2 新增 `test_single_side_rerun_after_renaming_agents_still_restores_other_files`：同 1.1 但用 `agent-team-single-side`，並先刪掉 `.claude/commands/ship-issue.md`，斷言重跑後 `ship-issue.md` 被重新建立、範本 Agent 未被建立；驗證：紅燈
- [x] 1.3 新增 `test_agents_dir_without_definitions_installs_all_templates`：目標先建立空的 `.claude/agents/`（只放 `.gitkeep`），裝 `agent-team-fullstack`，斷言 5 個範本 Agent 都被建立；驗證：此案例在現有實作即通過（保護第一次安裝行為）

## 2. installer 實作

- [x] 2.1 修改 `install.sh` 的 `install_kit`：迴圈前快照目標 `.claude/agents/` 第一層是否有 `*.md`；迴圈中對 `.claude/agents/*.md` 範本，同名檔存在印「略過（已存在）」、否則在快照為真時印「略過（.claude/agents/ 已有 Agent 定義，不建立範本名稱的 Agent）」，兩者皆計入略過數；其他檔案行為不變；驗證：`bash tests/install.test.sh` 全綠（含既有 `test_rerun_keeps_edited_agent_and_updates_skill`）
- [x] 2.2 快照為真且有範本被略過時，結尾提示補一行「要取範本 Agent 請參考 kit 目錄的 `.claude/agents/` 手動合併」，並更新 `install.sh` 檔頭說明 kit 選項的那兩行；驗證：手動對改名後的暫存目錄跑一次 `./install.sh agent-team-fullstack <dir>`，目視輸出
- [x] 2.3 只對 `install.sh`、`tests/install.test.sh` 跑 `sh -n` 與 `shellcheck`（若有安裝）；驗證：無新增警告（實際：`sh -n install.sh`、`bash -n tests/install.test.sh` 通過；本機未安裝 shellcheck，未執行）

## 3. 文件

- [x] 3.1 `README.md`（約 114–116 行）把「改名後重跑會再建立範本名稱的 Agent 定義…要刪掉」改為描述新行為：`.claude/agents/` 已有任何 Agent 定義時整組範本 Agent 不建立、輸出會說明；驗證：`grep -n "刪掉多出來" README.md` 無結果
- [x] 3.2 `agent-team-fullstack/CLAUDE.md`、`agent-team-single-side/CLAUDE.md`、兩份 `docs/multi-agent-workflow.md` 的同段提醒改為新行為；驗證：`grep -rn "刪掉多出來" agent-team-*` 無結果

## Workflow follow-up

- 實作完成後由 `/issue-processor kit-renamed-agents` 回填 Linear；收尾以 `/issue-solver kit-renamed-agents` 歸檔並開 PR。
