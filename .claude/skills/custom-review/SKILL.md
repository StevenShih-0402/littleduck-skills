---
name: custom-review
description: 多 Agent 流程的規格審查（reviewer），分兩種模式：「審查模式」在 PR 前對照 OpenSpec 變更目錄（proposal／tasks／delta specs／openapi.yaml）審查 diff 的需求覆蓋、測試涵蓋、契約與邏輯正確性；「評定模式」在 PR 中為內建 /code-review 與 /security-review 的每條發現評定嚴重度與信心度。第 2 輪起只審新改動、不重提舊意見。只回報，不修改。Use when the reviewer agent is dispatched by /ship-issue for review or rating, or the user asks the reviewer to review a change.
---

# Skill: Custom Review（對照 OpenSpec 規格的審查）

測試、lint、typecheck、執行驗證已經由 integrator 實際跑過而且通過；這裡要找的是「測試通過、但程式還是錯」的地方。開發 Agent 同時寫程式和測試，理解有偏差時兩者會一起錯、測試照樣通過——這是本審查要補的缺口。

本 skill 刻意**不叫 `code-review`**（同名的專案或個人 skill 會整個取代內建 `/code-review`，失去 effort 調整、`--fix`、`ultra`），也不叫 `spec-review`（以免誤認為 OpenSpec 自帶的審查）。內建 `/code-review` 與本 skill 並存、分工如下（專案 `CLAUDE.md`「審查規則三分法」）：

| 規則性質 | 放哪裡 | 誰檢查 | 何時 |
|----------|--------|--------|------|
| 機械性（命名格式、import 順序、程式碼格式） | linter／formatter 設定 | integrator「檢查」實際跑 lint，與編輯後 hook | PR 前 |
| 對照 OpenSpec 的需求覆蓋與測試涵蓋 | 本 skill（審查模式） | reviewer | PR 前 |
| 需要判斷的專案慣例（分層、錯誤格式、命名原則）與 bug | 專案 `CLAUDE.md` | 內建 `/code-review`，由本 skill（評定模式）評級 | PR 中 |
| 安全問題（高風險變更才跑） | — | 內建 `/security-review`，由本 skill（評定模式）評級 | PR 中 |

## 0. 模式

主對話的 prompt 會寫明「**審查模式**」或「**評定模式**」。兩者都沒寫、或寫了別的，停下回報，不要自行猜。

| 模式 | 時機 | 做什麼 |
|------|------|--------|
| 審查模式 | PR 前 | 自己對照規格審 diff（第 2 步），找出發現並評級 |
| 評定模式 | PR 中 | **不重新審一遍**；逐條核對 `/code-review`、`/security-review` 的發現是否成立並評級（第 3 步） |

## 1. 讀輸入

主對話會在 prompt 給下列輸入。一個 change 只有一份變更目錄與一份 diff；fullstack 時 diff 同時含前後端子目錄的改動，所以一次就看得到前後端之間的一致性：

1. worktree 根目錄的 `CLAUDE.md`（專案規則以它為準；「## agent-team 設定」標出前後端子目錄）。
2. 變更目錄 `openspec/changes/<change-id>/`：`proposal.md`、`tasks.md`、`specs/`、`openapi.yaml`。
3. `review-diff.patch`（主對話產生，放在變更目錄；reviewer 沒有 Bash，看不到 git，diff 只能從這裡讀）。第 2 輪起，patch 只包含上一輪之後的新改動。
4. 前幾輪的 `review.md`（第 1 輪會明寫「無」）。
5. **只有評定模式**：主對話轉交的 `/code-review` 與 `/security-review` 發現（沒有發現時會明寫「無」）。

缺任何一份就停下回報缺什麼，不要憑猜測審查。需要上下文時，用 Read／Grep 讀 worktree 裡的完整原始檔，不要只看 diff 片段。

## 2. 審查（審查模式）

- **需求覆蓋**：`proposal.md` 的驗收條件、delta specs 的每個 Requirement › Scenario、`tasks.md` 每一項，是否都有實作。
- **測試涵蓋**：上述每一項是否都有對應的測試；找不到時寫明檢查過哪些測試檔。
- **契約**：後端實作與 `openapi.yaml` 是否一致（路徑、方法、欄位名稱與型別、狀態碼）；fullstack 時，前端讀寫的欄位、路徑與狀態碼處理是否都和同一份 `openapi.yaml` 一致。
- **邊界情況**：空值、空清單、權限不足、時區、併發。
- **邏輯錯誤**：條件寫反、漏掉狀態、N+1 查詢、競態條件。

**不審**：程式風格、命名格式、格式（交給 linter）。違反 `CLAUDE.md` 專案慣例由 PR 中的 `/code-review` 負責，這裡不另外找。重用、簡化、效率類意見不要報。

第 2 輪起只審本輪 patch 內的改動；但判斷某處改動是否正確時，仍可讀完整原始檔。

## 3. 評定（評定模式）

逐條核對 `/code-review` 與 `/security-review` 的每一條發現：

- 對照 patch 與完整原始檔，確認發現**是否成立**。不成立的仍要列出，嚴重度與信心度留空，說明欄寫明理由。
- `/code-review` 若回報了命名格式、import 順序等機械性項目，判為不成立，理由寫「機械性規則交給 linter」。
- `/security-review` 的發現：在 diff 中能指出具體的攻擊或濫用路徑（輸入從哪裡來、到哪裡造成什麼後果）時評為高嚴重度；只是「可能不安全」、找不到路徑的，信心度最多「中」。
- 不另外找新發現。看到明顯的新問題時，可以列一條、來源寫「reviewer」，但只限高嚴重度且有程式碼證據的。

## 4. 評級欄位

審查模式自己的發現、評定模式的每一條發現，都要給出：

| 欄位 | 內容 |
|------|------|
| 端 | `BE`／`FE`：發現所在的子目錄或對應的 `[BE]`／`[FE]` 任務；single-side 寫宣告的端。主對話依此決定退回給誰 |
| 來源 | reviewer／/code-review／/security-review |
| 嚴重度 | 高（會造成錯誤行為、資料錯誤或安全問題）／中（特定條件下出錯，或需求漏測）／低（影響小） |
| 信心度 | 高（有程式碼證據，能指出觸發條件）／中／低 |
| 檔案:行號 | worktree 相對路徑與行號；同類問題列出所有位置 |
| 對應需求 | `tasks.md` 項次、`Requirement › Scenario`，或違反的 `CLAUDE.md` 慣例；都找不到就寫「無」 |
| 說明 | 具體輸入或狀態 → 錯誤結果；慣例違反則寫違反哪一條、為什麼 |
| 建議處理 | 退回／PR 備註／不成立 |

- **只有「高嚴重度且高信心」才建議退回**，其餘一律建議 PR 備註。
- **慣例違反**（例如商業邏輯寫錯層、自訂錯誤格式）本身沒有造成錯誤行為時，嚴重度最多「中」，建議 PR 備註；同時造成錯誤行為的，依錯誤行為評級。
- **無法確認就不報**：沒有程式碼證據、只是「可能」的，不要列。

## 5. 讓審查能結束

- **不重提**：前幾輪 `review.md` 已記錄的發現（同一位置、同一成因），不論當時處理是退回、PR 備註、不成立，或開發者在 `handoff.md` 寫明不採納，都不再列出。評定模式遇到 `/code-review` 重報舊發現時，列出並標「不成立」，理由寫「前幾輪已記錄（第 N 輪 #M）」。
- **同類一次指出**：同一種錯誤出現在多個地方時，合併成一條，檔案:行號欄列出所有位置，讓開發者一次改完。
- **只看新改動**：第 2 輪起不回頭重審上一輪已審過的程式碼。

## 6. 回報

一張上述格式的表格（沒有發現就寫「無」），再加一段總結：模式、建議退回幾條（依端分列）、PR 備註幾條、判為不成立幾條（其中幾條是重複的舊發現）。

不修改任何檔案；結果由主對話寫進 `review.md`。
