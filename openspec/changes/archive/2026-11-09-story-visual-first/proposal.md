# Proposal

## Why

SDP-109：`/gen-story` 產出的導覽投影片字太多，難以閱讀。現行 `SKILL.md` 只限制對話長度（一則一兩句、一頁最多五則），沒有任何「以圖表為主」的規定；模板雖已有 `.flow`／`table.t`／`.matrix`／`.tree` 等圖形元件，範例 `docs/story/add-gen-story-skill.html` 8 頁中卻一個 `.flow`、`table.t` 都沒用到，整份以 `.card` 與 `ul.pts` 文字條列為主（每頁約 150～240 字）。規則沒寫、檢查也抓不到，產出自然退回文字堆疊。

## What Changes

- **`SKILL.md` 新增「以圖表為主」內容規則**：每頁（封面除外）要有一個主視覺；給出「內容類型 → 圖表元件」對照表（流程用 `.flow`、比較用 `table.t`／前後對照、分支決策用分支圖、數字用數字磁磚……）；收緊文字上限（對話泡泡則數與字數、每頁說明文字字數），並明訂「能畫成圖就不寫成條列」。
- **`story-template.html` 補圖表元件**：在既有元件之外新增幾種純 HTML/CSS 繪製的圖形（前後對照、泳道／時序、分支決策、數字磁磚），延續「不用圖片」的規則，並在 `SKILL.md` 元件表列出用法。
- **`check_layout.mjs` 新增文字密度檢查**：非封面頁缺少圖形元件、或說明文字超過上限時，列為問題並以 exit code 1 結束；門檻寫成腳本開頭的常數。
- **重做範例導覽** `docs/story/add-gen-story-skill.html`：依新規則改寫並通過新的版面檢查，作為示範。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `gen-story-skill`：新增「投影片以圖表為主」的需求（每頁主視覺、文字上限、模板提供的圖表元件）；修改「唯讀並檢查版面」需求，版面檢查腳本加上文字密度與缺少圖形的檢查。

## Impact

- `.claude/skills/gen-story/SKILL.md`：內容規則、元件表、版面檢查說明。
- `.claude/skills/gen-story/assets/story-template.html`：新增圖表元件的 CSS（與必要時的範例註解）。
- `.claude/skills/gen-story/scripts/check_layout.mjs`：新增文字密度規則。
- `docs/story/add-gen-story-skill.html`：依新規則重做。
- 相容性：已產出的舊導覽重跑新版檢查可能不通過（文字過多）；這是預期中的收緊，只影響之後重跑檢查的情境，不影響已存在檔案的顯示。無 API、無相依套件變動。
