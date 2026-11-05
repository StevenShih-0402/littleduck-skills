---
name: gen-story
description: 把一個 OpenSpec 變更做成對話劇本式的單檔 HTML 導覽投影片：由角色用簡短對話帶讀這次的決策與實際程式碼，並列出在系統上怎麼操作才看得到更動。輸出到目前專案的 docs/story/<change-id>.html。Use when the user invokes /gen-story with an OpenSpec change name, or asks for a walkthrough story of a change.
---

# /gen-story — 變更導覽投影片

用法：`/gen-story <change-id>`，例如 `/gen-story add-user-auth`。

目的：讓人不用讀一長串文字或逐行 diff，就能掌握這次改了什麼、程式長什麼樣、在系統上怎麼看到它。特別適合多 Agent 一次產出大量內容、難以逐項細看的情境。

本 skill **只讀不改**：只讀變更目錄與程式碼，不修改工作區、不 commit、不自動發布。任何階段都能執行；建議在實作與審查收尾之後執行，這時 commit 與行號已經穩定。

## 內容規則

- **不用圖片**：不放截圖或生成圖。畫面示意用 HTML 繪製，並標明「示意，非截圖」。
- **程式碼必須是專案實際的 code**：從檔案原文複製，可用 `…` 節錄，說明列寫**路徑與行號**。不寫虛構或改寫過的程式。回應範例裡的 id 這類示意值要標明。
- **mono 元素只放 ASCII**：等寬字區塊（`pre.code`、`.cap`、`.chip`、`.cmd`）用的字型沒有中文字形，塞中文或全形標點（如 `：`）在缺中文等寬字的環境會變成缺字豆腐（□），且版面檢查抓不到。中文說明一律移到一般字體區塊（標題、`.card`、`.small`／`.tiny`、`.look`、對話泡泡）；emoji 同理（`.look` 等用文字不用 `✅`）。
- **對話簡明扼要**：一則泡泡一兩句，一頁最多五則。解釋「為什麼」，不要朗讀程式碼。
- **一定要有實際操作**：怎麼啟動、點哪裡、會看到什麼；純文件或流程變更就寫怎麼驗證。
- **數字與結論要有出處**：測試數、差異表、風險等數字取自變更自身的紀錄（`handoff.md`、`review.md` 等，存在才引用），不自行推測。
- **照實寫沒驗證過的事**：沒實際操作過的步驟要明說。
- 全繁體中文，用詞照規格與程式，不另造名詞。

## 步驟

### 1. 找變更目錄

在目前專案（OpenSpec repo 根目錄）依序找，取第一個找到的：

1. `openspec/changes/<change-id>/`
2. 歸檔目錄：`openspec/changes/archive/*-<change-id>/`

都找不到就**停下回報**，不要瞎猜。變更已歸檔時，程式碼讀 repo 主幹；對應分支還沒合併就讀該分支。

### 2. 讀材料

**必備**（缺少就停下回報）：`proposal.md`、`design.md`、`tasks.md`。

**選用**（存在才讀，缺少不報錯）：`handoff.md`（風險、未完成、實跑結果）、`review.md`（最後一輪審查）、`.linear.md`（對應 issue）、`openapi.yaml`（API 契約）。純 OpenSpec 專案通常沒有前三者，照樣能產出導覽。

再找出關鍵檔案：以 git 偵測專案的 base 分支（例：`git symbolic-ref --quiet refs/remotes/origin/HEAD`，取不到就回退到當前分支的 upstream 或 fork point），用 `git diff --stat <base>...HEAD` 列出本次動到的檔案。`.linear.md` 存在時一併讀對應 issue 的原始需求。

### 3. 規劃章節

骨架固定，章節依變更調整，最多 5 章（`data-chapter` 1～5），沒有內容的章不出現：

| 位置 | 內容 | 何時出現 |
|------|------|----------|
| 封面 | 標題、一句話摘要、change-id、PR（有的話） | 一定 |
| 登場人物 | 只列實際出場的角色與章節路線 | 一定 |
| 問題與決策 | 原本的問題、關鍵取捨、新增與不變的東西 | 一定 |
| 實作 | 依變更拆章：前後端都動就各一章，只動一端就只有那一端；大變更可依模組拆 | 一定 |
| 實際操作 | 啟動方式、畫面或 API 上的確認步驟 | 一定；純文件或流程變更就寫怎麼驗證 |
| 檢查結果與待決事項 | 實跑結果、審查後的修正、上線前要做的事、後續 issue | 一定 |
| 檔案地圖 | 想自己讀的話，檔案在哪裡 | 一定 |

小變更以 6～8 頁為目標；大變更不超過 20 頁。

**角色依專案而定**：模板內建的角色樣式 class 沿用多 Agent 團隊的 5 個角色（`hyuse`／`chika`／`yuma`／`osamu`／`shiori`）與使用者旁白 `you`。若專案不是這種多 Agent 編制，就用**旁白**（`you`）或一個單一敘事者帶讀即可，不必硬湊 5 個角色；也可以依專案自己的角色命名，對應到模板既有的樣式 class。

### 4. 撰寫

1. 複製 `.claude/skills/gen-story/assets/story-template.html` 到目前專案的 `docs/story/<change-id>.html`，檔名就是 change-id。
2. 替換 `<title>` 的 `{{ISSUE-ID}}`、`{{主題}}`，並把投影片放在 `STORY:SLIDES` 註解的位置。
3. 版面與元件用法：

| 用途 | class |
|------|------|
| 頁面 | `section.slide`，帶 `data-chapter`、`data-name`；封面加 `cover` |
| 對話 | `.chat` > `.say.<角色>`，角色為 `you`、`hyuse`、`chika`、`yuma`、`osamu`、`shiori` |
| 程式碼 | `.codebox` > `pre.code`，`data-lang` 為 `py`／`ts`／`json`，`data-hl="3-5,8"` 標重點行；下方 `.cap` 寫路徑與行號 |
| 雙欄 | `.cols.c-talk`、`.c-talk-wide`（對話＋程式碼）、`.c-2` |
| 操作步驟 | `ol.steps`，指令用 `.cmd`，預期結果用 `.look` |
| 其他 | `.card`、`.tag`、`.chip`、`.flow`、`table.t`、`.matrix`（勾選示意）、`.tree`（檔案樹） |

`pre.code` 裡的 `<`、`>`、`&` 要寫成 HTML 實體。

### 5. 檢查版面

```bash
node .claude/skills/gen-story/scripts/check_layout.mjs docs/story/<change-id>.html --shots <scratchpad>/shots
```

腳本逐頁檢查文字超出外框、需要捲動、超出畫布、壓到頁尾，有問題時 exit code 為 1。修到通過，再用 Read 看截圖確認沒有怪異的版面。內容放不下就拆頁或節錄，不要縮小字級。

腳本需要 playwright（執行前置，比照 `draw-mermaid` 需要 docker）。playwright 預設從**目前專案的 `node_modules`** 載入；專案沒裝時，設環境變數 `PLAYWRIGHT_FROM=<已裝 playwright 的 repo 根目錄>` 指向他處。chromium 用 `~/.cache/ms-playwright` 已安裝的版本。

### 6. 回報

回報檔案路徑、頁數與章節、版面檢查結果，以及內容中標明沒驗證過的項目。**不自動 commit**，也不自動發布，user 要求才做。
