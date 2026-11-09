# Tasks

## 1. 版面檢查先行（測試先行：先備好會失敗的樣本）

- [x] 1.1 在 scratchpad 準備三份最小樣本 HTML（以 `story-template.html` 為底）：(a) 一頁只有 `.card`＋`ul.pts` 的非封面頁；(b) 有圖形元件但放 4 則對話泡泡的頁；(c) 有圖形元件但圖形外說明文字超過 150 字的頁。驗證：以**現行** `check_layout.mjs` 跑三份都 exit 0（證明現況抓不到）
- [x] 1.2 在 `.claude/skills/gen-story/scripts/check_layout.mjs` 開頭新增常數 `MAX_PROSE = 150`、`MAX_BUBBLES = 3` 與圖形元件 selector 清單（`.flow`、`.vs`、`.lanes`、`.branch`、`.stats`、`table.t`、`.matrix`、`.tree`、`.codebox`、`ol.steps`、`.cast`），並實作 design D1 的三條規則（缺少主視覺、對話過多、文字過多；封面 `section.slide.cover` 跳過；說明文字排除圖形元件內文字與 `h1`／`h2`／`.kicker`／`.tag`／`.cap`／`b.n`），沿用既有輸出格式並更新檔頭規則說明。驗證：1.1 三份樣本各自 exit 1，且輸出分別指出「缺少主視覺」「對話過多」「文字過多」與實際數值
- [x] 1.3 準備一份合規樣本（封面＋一頁含 `.flow` 與 2 則短泡泡）。驗證：新版腳本 exit 0（正向案例）

## 2. 模板圖表元件

- [x] 2.1 在 `.claude/skills/gen-story/assets/story-template.html` 新增 `.vs`（前後對照）、`.lanes`（泳道／時序）、`.branch`（分支決策）、`.stats`（數字磁磚）四組 CSS，沿用既有色票與防溢出規則，不引入圖片或外部 JS。驗證：在 scratchpad 做一份每頁各放一種新元件的樣本，`check_layout.mjs --shots` exit 0，並用 Read 看截圖確認箭頭、連接線、對齊正常

## 3. SKILL.md 規則與文件

- [x] 3.1 更新 `.claude/skills/gen-story/SKILL.md` 內容規則：第一條加入「以圖表為主」（非封面頁一個主視覺、能畫成圖就不寫條列、主視覺要承載本頁重點）；對話上限改為一頁 3 則、每則 40 字以內；整頁說明文字 150 字以內。驗證：`grep -n "以圖表為主\|150\|3 則" SKILL.md` 命中，且「最多五則」已不存在
- [x] 3.2 SKILL.md 元件表加入 `.vs`／`.lanes`／`.branch`／`.stats`，新增「內容類型 → 元件」對照表（涵蓋新舊元件），步驟 3 章節表加「建議主視覺」欄，步驟 5 說明三條內容規則與門檻（數字與腳本常數一致）。驗證：`grep -n "\.vs\|\.lanes\|\.branch\|\.stats\|建議主視覺" SKILL.md` 皆命中；人工比對 SKILL.md 的門檻數字與 `check_layout.mjs` 常數相同
- [x] 3.3 檢查 README 對 gen-story 的描述是否需同步（例：提及以圖表為主），需要才改。驗證：`grep -n gen-story README.md` 檢視結果，未改則在 task 註記理由
  - 已改 README 第 11 行的 gen-story 說明：加上「以圖表為主」與「版面檢查會擋下沒有圖或文字過多的頁面」。

## 4. 重做範例導覽

- [x] 4.1 依新規則重寫 `docs/story/add-gen-story-skill.html`：事實內容（程式碼片段與行號、數字）沿用原版並以現行檔案重新核對行號，每個非封面頁換成合適的主視覺（例：問題與決策用 `.vs`、檢查結果用 `.stats`）。驗證：`node .claude/skills/gen-story/scripts/check_layout.mjs docs/story/add-gen-story-skill.html --shots <scratchpad>/shots` exit 0
- [x] 4.2 用 Read 逐頁看 4.1 截圖，確認沒有缺字豆腐、怪異排版、純裝飾性圖形；依結果校正 `MAX_PROSE`／`MAX_BUBBLES`（若調整，SKILL.md 同步改並重跑 1.2、1.3、4.1）。驗證：最終門檻下 1.1 樣本仍 exit 1、1.3 與 4.1 exit 0
  - 4.1 實跑：重做為 10 頁（新增「找變更目錄」`.branch`、「材料分層」`table.t`，原「檢查結果與檔案地圖」拆成 `.stats` 與 `.tree` 兩頁）。程式碼行號改為現行 `check_layout.mjs` 28-36（腳本開頭多了常數區），catch 區塊以 `…` 節錄。以 `PLAYWRIGHT_FROM` 指向 npx 快取的 playwright 1.61.1 實跑：**✅ 10 頁版面檢查通過（exit 0）**。
  - 4.2 截圖逐頁目視：沒有缺字豆腐，也沒有版面錯位。門檻維持 `MAX_PROSE = 150`、`MAX_BUBBLES = 3`：用新腳本跑 main 上的舊版範例，第 3 頁「問題與決策」被判為缺少主視覺，且文字 204 字超過 150 字（exit 1），其餘頁通過；1.1 的三份樣本仍 exit 1，1.3 的樣本 exit 0。

## 5. 收尾檢查

- [x] 5.1 只對本次變更的檔案確認換行為 LF、檔頭兩行註解仍正確（`check_layout.mjs`）。驗證：`file` 指令不含 CRLF；`head -2 check_layout.mjs` 為路徑＋功能說明
- [x] 5.2 `openspec validate story-visual-first --strict` 通過
