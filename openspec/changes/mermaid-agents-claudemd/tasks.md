# Tasks

## 1. draw-mermaid skill

- [ ] 1.1 從 `~/tao_rui_projects/ignsw_bk_monorepo/.claude/skills/draw-mermaid/` 複製 `SKILL.md` 與 `scripts/render.sh` 到 `.claude/skills/draw-mermaid/`，確認 `render.sh` 保有執行權限（`test -x`）
- [ ] 1.2 去公司化 `SKILL.md`：移除 `IGN-127`/`IGN-129`、`module-mermaid-diagrams` spec 引用、`projects/<proj>`／`IngenuityOA_Frontend` 放置規則，改寫為以目標專案相對路徑表示的通用放置與前後端分工準則；以 `grep -nE 'ignsw|IngenuityOA|tao_rui_projects|IGN-' -r .claude/skills/draw-mermaid` 無結果驗證
- [ ] 1.3 準備一份含一個合法圖與一個語法錯誤圖的 md 樣本（放 scratchpad），分別執行 `render.sh`，確認合法者產出 default/dark SVG 且退出碼 0、錯誤者印出失敗區塊且退出碼非 0（docker 不可用時於報告註記 env-blocked）

## 2. agent-team 套件

- [ ] 2.1 建立 `agent-team/docs/multi-agent-workflow.md`：以 SDP-69 附件為底，將公司路徑換成 `<team-hq-repo>`／`<frontend-repo>`／`<backend-repo>` 佔位，Django/DRF 改為範例敘述
- [ ] 2.2 建立 `agent-team/.claude/agents/{hyuse,chika,yuma,osamu}.md`：依附件範本與「團隊編制」表補齊 yuma、osamu 的 tools、邊界、完成定義；frontmatter 欄位 `name`/`description`/`tools`/`model` 皆具備
- [ ] 2.3 建立 `agent-team/.claude/commands/ship-issue.md`、`agent-team/CLAUDE.md`（repo 路徑佔位、worktree 慣例 `../wt/<repo>-<change-id>`、additional directories 說明）、`agent-team/openspec/handoff-template.md`（角色、時間、做了什麼、未完成、風險）
- [ ] 2.4 以 `grep -rnE 'ignsw|IngenuityOA|tao_rui_projects' agent-team` 無結果驗證去公司化；在本 repo 根目錄啟動 Claude Code 時 `/agents` 不出現 hyuse 等範本

## 3. 通用 CLAUDE.md

- [ ] 3.1 依 design D6 撰寫 repo 根目錄 `CLAUDE.md`，逐條涵蓋 `dev-conventions` spec 列出的規則，並以 `grep -nE 'ignsw|Pants|libs/common|gunicorn' CLAUDE.md` 無結果驗證

## 4. 安裝器

- [ ] 4.1 新增 `install.deps`（design D3 內容），並以 grep 核對 issue-*/openspec-* SKILL.md 中引用的 `/opsx:*` 指令與 `linear/` 模板都落在展開結果內
- [ ] 4.2 改寫 `install.sh`：必填第一參數、`--help`/`--list`、未知或缺參數時印用法＋可選清單並非零結束且不寫入任何檔、第一參數為既存目錄時提示改用 `all <路徑>`
- [ ] 4.3 實作相依展開（遞迴去重）與逐 skill／指令／目錄同步；`all` 維持整目錄同步；驗證：對空的 scratchpad 目標分別跑 `draw-mermaid`（只出現該 skill、無 linear/commands）、`issue-reader`（帶齊 openspec-*、opsx 指令、linear）、`all`（無任何 agent-team 檔），並重跑一次確認無巢狀副本
- [ ] 4.4 實作 `CLAUDE.md` 不存在才建立：對已有 `CLAUDE.md` 的目標跑 `all`，以 `cmp` 確認原檔不變且輸出含略過訊息；無 `CLAUDE.md` 的目標則被建立
- [ ] 4.5 實作 `agent-team` 逐檔 scaffold：空目標建出全部套件檔；預先放一份修改過的 `.claude/agents/chika.md` 再跑，確認內容不變且列為略過；套件安裝不附帶通用 `CLAUDE.md` 以外的 skill
- [ ] 4.6 新增 `completions/install.bash`（design D5），以 `bash -c 'source completions/install.bash; COMP_WORDS=(install.sh dr); COMP_CWORD=1; _littleduck_install; echo "${COMPREPLY[@]}"'` 驗證輸出 `draw-mermaid`；暫時新增一個 skill 目錄確認自動出現在候選中後移除
- [ ] 4.7 更新 `README.md`：新用法（單一 skill／`all`／`agent-team` 範例）、可選清單與各自帶入的資產、tab 補齊設定、`CLAUDE.md` 不覆寫與 agent-team 範本不更新的說明、舊用法遷移；照 README 指令實際跑一次確認可用

## Workflow follow-up

- `/issue-processor mermaid-agents-claudemd` 完成實作並回填 Linear。
- `/issue-solver mermaid-agents-claudemd` 歸檔、同步 specs、開 PR。
