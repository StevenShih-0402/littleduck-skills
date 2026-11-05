# Tasks

## 1. 移植並通用化資產檔

- [x] 1.1 建立 `.claude/skills/gen-story/assets/story-template.html`，由來源 `~/tao_rui_projects/ignsw_agents_team/.claude/skills/gen-story/assets/story-template.html` 移植；保留 `{{ISSUE-ID}}`／`{{主題}}` 佔位、`STORY:SLIDES` 插入點與角色樣式 class（`you`／`hyuse`／`chika`／`yuma`／`osamu`／`shiori`）。驗證：`grep -n "STORY:SLIDES\|{{ISSUE-ID}}\|.say.shiori" assets/story-template.html` 三者都命中，且 `grep -niE "ignsw|tao_rui|IngenuityOA" assets/story-template.html` 無輸出
- [x] 1.2 建立 `.claude/skills/gen-story/scripts/check_layout.mjs`，由來源移植並改掉 playwright 載入：預設找當前專案 `node_modules`，保留 `PLAYWRIGHT_FROM` 覆寫，移除寫死的前端 repo 路徑。驗證：`grep -n "PLAYWRIGHT_FROM" scripts/check_layout.mjs` 命中，且 `grep -niE "tao_rui|ignsw_fullstack|IngenuityOA" scripts/check_layout.mjs` 無輸出

## 2. 撰寫通用 SKILL.md

- [x] 2.1 撰寫 `.claude/skills/gen-story/SKILL.md`：frontmatter（name、description）＋用法 `/gen-story <change-id>`；變更目錄探索改為 `openspec/changes/<change-id>/` 與歸檔 `openspec/changes/archive/*-<change-id>/`；base 分支由 git 自動偵測；材料分必備（proposal/design/tasks）與選用（handoff/review/.linear/openapi 存在才讀）。驗證：`grep -niE "tao_rui|ignsw_fullstack|ignsw_bk_monorepo|IngenuityOA|ROOT=~" SKILL.md` 無輸出；`grep -n "openspec/changes" SKILL.md` 命中
- [x] 2.2 在 SKILL.md 保留內容規則（不用截圖、程式碼需專案原文含路徑行號、一定要有實際操作、數字出處、全繁中）、固定章節骨架、只讀不改不 commit 的護欄，並說明對話角色依專案而定、非 agent-team 專案可用旁白／單一敘事者，及 playwright 為執行前置（可用 `PLAYWRIGHT_FROM`）。驗證：`grep -n "旁白\|PLAYWRIGHT_FROM\|不 commit\|路徑與行號\|截圖" SKILL.md` 各命中

## 3. 安裝整合與文件同步

- [x] 3.1 在 `README.md`「選項與安裝內容」表新增 `gen-story` 一列（比照 `gen-html`：只裝該 skill 本身），並在「內含資產」清單提及 gen-story。驗證：`grep -n "gen-story" README.md` 命中；確認未在 `install.deps` 新增條目（gen-story 無跨 skill 相依，未列出即無相依）
- [x] 3.2 確認安裝器可選項涵蓋 gen-story：`sh install.sh --list` 的輸出包含 `gen-story`（可選項由 repo 內容即時產生，無需改補齊腳本）。驗證：`sh install.sh --list 2>&1 | grep -n gen-story` 命中

## 4. 端到端驗證

- [x] 4.1 在一個已安裝 playwright 的 OpenSpec 專案（或以 `PLAYWRIGHT_FROM` 指向既裝版本）對一個既有 change-id 執行 `/gen-story <change-id>`，確認產出 `docs/story/<change-id>.html` 單檔、涵蓋骨架章節、程式碼標路徑行號、含實際操作步驟，且過程未修改任何原始檔、未建立 commit
  - 已以本 change（`add-gen-story-skill`）實跑：產出 `docs/story/add-gen-story-skill.html`（8 頁、涵蓋封面／登場人物／問題與決策／實作×2／安裝整合／實際操作／檢查結果與檔案地圖；程式碼標 `check_layout.mjs` 17–24、`SKILL.md` 30–31）。結構檢查通過（title 已替換、無殘留佔位、`pre.code` 實體正確），過程未改任何原始檔、未 commit。
- [x] 4.2 對 4.1 產出的 HTML 執行 `node .claude/skills/gen-story/scripts/check_layout.mjs docs/story/<change-id>.html --shots <scratchpad>/shots`，確認全頁通過（exit 0）；若有超框頁則拆頁或節錄後重跑至通過
  - 以 `PLAYWRIGHT_FROM` 指向既裝 playwright 實跑：**✅ 8 頁版面檢查通過（exit 0）**。（起初本機缺 chromium 系統相依 `libnspr4.so`／`libnss3`／`libasound2t64`，`apt-get install` 補齊後即通過。）
  - Read 截圖人工檢視：初版發現 mono 元素（`.chip`／`pre.code`／`.cap`／`.cmd`）放中文與全形冒號造成缺字（□），已把那些位置改為 ASCII、中文移到一般字體區塊，重跑仍 exit 0 且截圖無缺字。
