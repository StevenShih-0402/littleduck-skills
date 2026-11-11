<!--
  review-template.md 範本：複製到 openspec/changes/<change-id>/review.md（一個 change 一份，前後端的發現都記在這裡，以「端」欄區分）。
  由 /ship-issue 主對話寫入（代 reviewer、內建 /code-review 與 /security-review）：
    - PR 前（第 5 步）：reviewer 審查模式，對照規格審 diff。
    - PR 中（第 7 步）：CI、/code-review、/security-review（高風險才跑），由 reviewer 評定模式評級。
  只追加：每輪審查加一節「第 N 輪」，不改寫前面的輪次。
  「已審到」是下一輪增量審查的起點：PR 前寫審查當下的 HEAD SHA；PR 中寫該輪的收尾 HEAD（handoff.md 收尾紀錄的值）。
  review-diff.patch 是審查用的暫存 diff，已列入 .gitignore，不進 commit。
-->
# 程式碼審查：<change-id>

## 第 N 輪 — PR 前／PR 中 — YYYY-MM-DD HH:MM

- **範圍**：origin/<base>...HEAD（第 1 輪）／<上一輪已審到的 SHA>..HEAD（第 2 輪起）
- **已審到**：<SHA>
- **審查指令**：
  - PR 前：reviewer 審查模式（已派／未派：無 delta spec）
  - PR 中：CI <全綠／無 CI／失敗：check 名稱>；`<實際執行的 /code-review 指令>`；/security-review <已跑／不適用／以 /code-review high 代替：原因>；reviewer 評定模式（已派／未派：無發現）
- **高風險檔案**：無／逐一列出（命中時 /code-review 用 high，並跑 /security-review）
- **風險等級**（只有 PR 中）：低／中／高 — <判定理由>／—（本輪有退回）

| # | 端 | 來源 | 嚴重度 | 信心度 | 檔案:行號 | 對應需求 | 說明 | 處理 |
|---|----|------|--------|--------|-----------|---------|------|------|
| 1 | BE／FE | reviewer／/code-review／/security-review | 高／中／低 | 高／中／低 | path:line（同類問題列出所有位置） | tasks x.y／Requirement › Scenario／無 | 輸入或狀態 → 錯誤結果 | 退回／PR 備註／不成立：理由 |

- **結果**：通過／退回第 N 次（退回哪一端；與 integrator 檢查、CI 退回合併計算）
