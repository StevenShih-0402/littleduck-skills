---
name: gen-html
description: 產出單檔 HTML + Tailwind CSS 的說明頁（架構圖、流程圖、比較表等），預設台北黑體、淡色系、以簡報基本圖形／表格／箭頭呈現，輸出到 monorepo 根目錄。當次的樣式或內容調整由呼叫參數說明。Use when the user invokes /gen-html with a topic, or asks to turn an explanation / architecture into an HTML page file.
---

# Skill: Gen HTML

把一個主題（模組架構、執行流程、檔案關係、決策比較……）做成**單一 HTML 檔**，讓人用瀏覽器直接開來看。

**呼叫方式**：

```
/gen-html <主題>[；<當次調整>][；輸出：<路徑>]
```

例：

- `/gen-html lineworks_bot 模組的執行流程與檔案關係`
- `/gen-html IGN-113 匯出欄位版面 v1 / v2 對照；改成深藍主色、只要表格不要流程圖`
- `/gen-html OCR 上傳到辨識完成的流程；輸出：projects/ingenuity_oa/docs/ocr_flow.html`

沒給主題就用 **AskUserQuestion** 問，不要自行猜。

---

## 預設規格（當次沒說明就一律套用）

| 項目 | 預設 |
|------|------|
| 技術 | 單檔 HTML；Tailwind 走 CDN `https://cdn.tailwindcss.com`；不另外拆 CSS / JS 檔 |
| 字體 | 台北黑體：`"Taipei Sans TC Beta"`, `"Taipei Sans TC"` 優先，**退回 Google Fonts `Noto Sans TC`**（台北黑體不在 Google Fonts，也沒有可確認的公開 CDN，**不要編造字型網址**）；程式碼用 mono |
| 色調 | 淡色系：`slate-50` 底、白色卡片、`*-50` 填色 + `*-200` 框線 + `*-600/700` 文字；一個語意一個色（例：入口／View 天藍、邏輯／Service 淡紫、非同步／Task 琥珀、設定／共用薄荷綠、外部服務淡粉），並在封面以圖例膠囊交代一次 |
| 呈現手法 | 簡報基本圖形：圓角方塊、虛線邊界框、分層帶、步驟卡、結果徽章、**CSS 箭頭**（`.arrow-right` 窄螢幕自動轉直向、`.arrow-down`）、表格；每個章節一張「投影片」卡片 |
| 版面 | `max-w-6xl` 置中；寬螢幕橫排、窄螢幕直排，手機寬度不可出現水平捲動（表格外層包 `overflow-x-auto`） |
| 語言 | 全繁體中文，註解也是 |
| 輸出位置 | monorepo 根目錄，檔名 `<主題>_<類型>.html`（snake_case 英文，例：`lineworks_architecture.html`）；同名檔已存在先問要覆寫還是另取名 |

元件骨架見同目錄的 **`template.html`**——**每次都要實際讀檔**，從中挑需要的元件組合，不要憑記憶重寫樣式。`{{…}}` 是佔位，全部要換成實際內容。

### 當次調整

使用者在呼叫時說明的調整（配色、字體、只要表格、加某張圖、輸出路徑、改成英文……）**優先於預設**，只作用於當次。
若使用者明說「以後都這樣」，才回頭修改本檔的「預設規格」表與 `template.html`，並在報告中說明改了哪些預設。

---

## 步驟

1. **解析參數**：拆出主題、當次調整、輸出路徑。
2. **蒐集內容**：
   - 主題是 repo 內的程式／模組：**實際讀相關檔案**（view / service / task / urls / settings / compose 等）確認呼叫關係與名稱，不憑印象畫圖。
   - 主題是這段對話已說明過的內容：以對話內容為準，有疑義再讀檔確認。
   - 圖中出現的類別名、函式名、路徑、狀態碼都要與程式碼一致。
3. **規劃章節**：一般順序為「封面 → 流程圖 → 結構／依賴圖 → 對照表」，依主題取捨，**每張投影片開頭一句結論**（讀者要帶走什麼）。圖能說清楚的不要再寫長段落。
4. **讀 `template.html`**，組出頁面並寫入輸出路徑。
5. **安全檢查**（必做）：
   - 頁面**不可含任何真實憑證或識別值**。以各子專案 `src/env/.env.*` 中的值 grep 產出檔，命中即改成佔位或刪除（例：Bot ID、Client ID、Secret、帳號、內網 IP 以外的主機帳密）。
   - 不放公司內部敏感資訊以外的人名（以角色稱呼）。
6. **自我檢查**：HTML 標籤成對、沒有殘留 `{{`；`grep -c "{{"` 應為 0。

---

## 完成後的報告

- 輸出路徑（可點的 `path`）與頁面章節清單（一行一章）
- 套用了哪些當次調整；若有預設規格無法滿足（例：本機未裝台北黑體會顯示 Noto Sans TC）要明說
- 是否實際在瀏覽器確認過畫面——**環境沒有瀏覽器就照實說「未目視確認」**，不要說「已確認排版」
- 檔案在 git 的狀態：根目錄產出的檔案通常是未追蹤，提醒 user 決定要 commit、加進 `.gitignore` 或移走，**避免被 `/issue-solver` 一併 commit 進不相關的 PR**

---

## 護欄

- **只產出本機檔案**：不發佈成 claude.ai Artifact、不上傳任何外部服務，除非 user 明確要求。
- 不 commit、不 push。
- 外部資源只允許 `cdn.tailwindcss.com` 與 Google Fonts；其餘一律內嵌。
- 不改動既有程式碼或文件；本 skill 只新增（或經同意後覆寫）指定的 HTML 檔。
