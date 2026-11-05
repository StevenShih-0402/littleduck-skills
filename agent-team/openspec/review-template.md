<!--
  review-template.md 範本：複製到 openspec/changes/<change-id>/review.md（每端一份，放在該端變更目錄）。
  由 /ship-issue 主對話在 5.5 程式碼審查時寫入（代 Shiori 與內建 /code-review）。
  只追加：每輪審查加一節「第 N 輪」，不改寫前面的輪次。唯一例外是 shadow mode 在檢查點 2 回填「user 判定」欄。
  review-diff.patch 是審查用的暫存 diff，已列入各 repo 的 .gitignore，不進 commit。
-->
# 程式碼審查：<change-id>（<backend|frontend>）

## 第 N 輪 — YYYY-MM-DD HH:MM

- **模式**：shadow（第 K／N 個 issue）／自動退回
- **範圍**：origin/<base>...<HEAD SHA>
- **高風險檔案**：無／逐一列出（命中時 /code-review 用 high）
- **/code-review**：`<實際指令>`
- **Shiori**：已派／未派（無 delta spec 的小改）

| # | 來源 | 嚴重度 | 信心度 | 檔案:行號 | 對應需求 | 說明 | 處理 | user 判定 |
|---|------|--------|--------|-----------|---------|------|------|-----------|
| 1 | Shiori／/code-review | 高／中／低 | 高／中／低 | path:line | tasks x.y／Requirement › Scenario／無 | 輸入或狀態 → 錯誤結果 | 退回／PR 備註／shadow：建議退回／不成立 | （檢查點 2 填：認同／不認同） |

- **結果**：通過／退回第 N 次（與 Osamu 檢查退回合併計算）
