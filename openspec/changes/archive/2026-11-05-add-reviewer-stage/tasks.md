# Tasks

## 1. Reviewer 角色與 custom-review skill

- [x] 1.1 新增 `.claude/skills/custom-review/SKILL.md`：定義 Shiori 的審查方法（對照 proposal／delta specs／tasks 的需求與測試覆蓋、openapi.yaml 契約、邊界、邏輯；每條發現評來源／嚴重度／信心度／檔案:行號／對應需求／說明／建議處理；明示不審風格與 reuse/simplify/efficiency；只回報不修改；輸入缺就停）。驗證：`openspec show custom-review-skill --type spec` 的每條 Requirement 都能在 SKILL.md 找到對應段落，且 frontmatter 有 name/description。
- [x] 1.2 新增 `agent-team/.claude/agents/shiori.md`：frontmatter `tools: Read, Grep, Glob`、`model: opus`、`color: red`、指向 `.claude/skills/custom-review/SKILL.md`；body 明載只回報、不寫入/核准/合併。驗證：`grep` 確認 tools 僅這三項、無 Write/Edit/Bash，且引用 custom-review。

## 2. ship-issue 審查步驟、review 範本與狀態階段

- [x] 2.1 在 `agent-team/.claude/commands/ship-issue.md` 於 Osamu「檢查」通過後、收尾前插入 code-review 步驟：每側產 git-ignore 的 `review-diff.patch`、依可設定樣式偵測高風險檔案、跑內建 `/code-review`（effort 預設 medium、高風險 high、禁 max/ultra/`--fix`/`--comment`）、派 Shiori、寫 `review.md`、依「高嚴重度且高信心」退回否則列 PR 備註、shadow mode 只彙報、退回與 Osamu 檢查共用上限 2 次；整合器派工改為「檢查／收尾／歸檔」三模式。驗證：`openspec show agent-team-kit --type spec` 的 code-review 相關 Requirement 都能對到 ship-issue.md 段落。
- [x] 2.2 新增 `agent-team/openspec/review-template.md`：每輪一段（模式 shadow/自動退回、範圍、高風險檔案、`/code-review` 實際指令、是否派 Shiori、發現表含嚴重度/信心度/user 判定欄、結果）。驗證：`grep` 確認表頭含「嚴重度」「信心度」「user 判定」與「結果」。
- [x] 2.3 更新 `agent-team/openspec/handoff-template.md` 的 `## 狀態` 階段註解，在 `integrating` 與 `archived` 之間加入 `reviewing`、`ready-to-archive`。驗證：`grep reviewing agent-team/openspec/handoff-template.md` 命中，且 `openspec validate add-reviewer-stage --strict` 通過。
- [x] 2.4 把 `review-diff.patch` 的 git-ignore 指引寫進 setup 文件（並確認 kit 不把它進 commit）。驗證：setup 文件搜得到 `review-diff.patch` 的 `.gitignore` 說明。

## 3. Integrator 切成檢查 → 審查 → 收尾

- [x] 3.1 更新 `.claude/skills/issue-integrator/SKILL.md`：檢查通過時設 stage `reviewing` 並停（不重切、不開 PR）；新增「收尾」run（審查通過後才重切 commit、`--force-with-lease` push、開/重用 PR、把 `review.md` 的 PR 備註附進 PR 內文、stage 設 `ready-to-archive`）；歸檔 run 行為不變。驗證：`openspec show issue-integrator-skill --type spec` 的 MODIFIED Requirement 都對得到 SKILL.md。
- [x] 3.2 更新 `agent-team/.claude/agents/osamu.md` 的 description 與 body，反映「檢查／收尾／歸檔」三段與重切移到審查後。驗證：`grep` 確認 description 同時含檢查、收尾、歸檔。

## 4. 規則三分法與文件同步

- [x] 4.1 在 `agent-team/CLAUDE.md` 寫入審查規則三分法（機械性→linter＋編輯後 hook；需判斷慣例→repo `CLAUDE.md`＋內建 `/code-review`；對照規格→`custom-review`）與 5 角色表（加入 Shiori）。驗證：`grep` 確認三層對應與 Shiori 皆在。
- [x] 4.2 更新 `agent-team/docs/multi-agent-workflow.md`：新增審查階段章節（流程、shadow mode、共用退回上限、保留內建 `/code-review` 不建同名 skill），並說明 `custom-review` 隨 agent-team 安裝。驗證：文件含審查階段章節且提到 shadow mode 與 custom-review。
- [x] 4.3 更新 `README.md` 角色表由 4 角色改為 5 角色、加入審查階段簡述與「未來工作」（安全審核／verify 跑起產品／風險分級人工審批）。驗證：`grep -i shiori README.md` 命中且列出三項未來工作。

## 5. Installer 佈署新檔

- [x] 5.1 更新 `install.deps`：`agent-team` 的 role skills 相依加入 `custom-review`；kit 檔案清單加入 `shiori.md` 與 `review-template.md`。驗證：`grep custom-review install.deps` 命中。
- [x] 5.2 更新 `install.sh`：`agent-team` 安裝一併佈署 `shiori.md`、`review-template.md`（kit 檔 skip-if-present）與 `custom-review` skill（overwrite-on-update）。驗證：對空目錄跑 `install.sh agent-team <tmp>` 後，`<tmp>/.claude/agents/shiori.md`、`<tmp>/.claude/skills/custom-review/SKILL.md`、`<tmp>/openspec/review-template.md` 皆存在。
- [x] 5.3 確認 bash completion 的可選名稱自動含 `custom-review`（由 `.claude/skills/` 目錄推導，不需硬編）。驗證：completion 候選列出 `custom-review`。

## 6. 通用化與整合驗證

- [x] 6.1 掃描所有新增／修改的 kit 與 skill 檔，確認無 `ignsw`、`IngenuityOA`、`tao_rui_projects`、絕對個人路徑、Django/DRF/pants/npm workspaces 等專屬字串，repo 路徑一律 placeholder。驗證：`grep -rEi 'ignsw|IngenuityOA|tao_rui_projects|/home/steven' agent-team .claude/skills/custom-review` 無輸出。
- [x] 6.2 從空目錄端到端跑一次 `install.sh agent-team`，確認五角色定義、`custom-review`、`review-template.md` 到位，且安裝結果同樣無專屬字串；`openspec validate add-reviewer-stage --strict` 通過。驗證：安裝輸出列出上述檔案、grep 無專屬字串、validate 通過。

## Workflow follow-up

- 本 change 實作完成後，依 `issue-solver` 做規格漏寫的最終檢查、`/opsx:archive` 同步規格並歸檔、切 commit、push、開 PR。
- 歸檔後驗證 `openspec/specs/` 已併入 `custom-review-skill` 並更新 `agent-team-kit`／`issue-integrator-skill`／`skill-installer`。
