---
name: custom-review
description: 多 Agent 流程的規格審查（Shiori）：對照 OpenSpec 變更目錄（proposal／tasks／delta specs／openapi.yaml）審查前後端 diff 的需求覆蓋、測試涵蓋與邏輯正確性，並為內建 /code-review 的每條發現評定嚴重度與信心度。只回報，不修改。Use when Shiori is dispatched by /ship-issue code review, or the user asks Shiori to review a change.
---

# Skill: Custom Review（對照 OpenSpec 規格的審查）

測試、lint、typecheck 已經由 Osamu 實際跑過而且通過；這裡要找的是「測試通過、但程式還是錯」的地方。開發 Agent 同時寫程式和測試，理解有偏差時兩者會一起錯、測試照樣通過——這是本審查要補的缺口。

本 skill 刻意**不叫 `code-review`**（同名的專案或個人 skill 會整個取代內建 `/code-review`，失去 effort 調整、`--fix`、`ultra`），也不叫 `spec-review`（以免誤認為 OpenSpec 自帶的審查）。內建 `/code-review` 與本 skill 並存、分工如下（team-hq `CLAUDE.md`「審查規則三分法」）：

| 規則性質 | 放哪裡 | 誰檢查 |
|----------|--------|--------|
| 機械性（命名格式、import 順序、程式碼格式） | linter／formatter 設定 | Osamu「檢查」實際跑 lint，與編輯後 hook |
| 需要判斷的專案慣例（分層、錯誤格式、命名原則） | 各 repo 的 `CLAUDE.md` | 內建 `/code-review`；開發 Agent 寫程式時遵守 |
| 對照 OpenSpec 的需求覆蓋與測試涵蓋 | 本 skill | Shiori |

## 1. 讀輸入

主對話會在 prompt 給下列輸入，**一次派工涵蓋 `repos` 的每一端**，這樣才看得到前後端之間的一致性：

1. team-hq `CLAUDE.md` 與各端 repo 根目錄的 `CLAUDE.md`（專案規則以它們為準）。
2. 每一端的變更目錄 `openspec/changes/<change-id>/`：`proposal.md`、`tasks.md`、`specs/`、`openapi.yaml`。
3. 每一端的 `review-diff.patch`（主對話以 `git diff origin/<base>...HEAD` 產生，放在變更目錄；Shiori 沒有 Bash，看不到 git，diff 只能從這裡讀）。
4. 主對話轉交的各端 `/code-review` 發現（沒有發現時會明寫「無」）。

缺任何一份就停下回報缺什麼，不要憑猜測審查。需要上下文時，用 Read／Grep 讀 worktree 裡的完整原始檔，不要只看 diff 片段。

## 2. 審查

- **需求覆蓋**：`proposal.md` 的驗收條件、delta specs 的每個 Requirement › Scenario、`tasks.md` 每一項，是否都有實作。
- **測試涵蓋**：上述每一項是否都有對應的測試；找不到時寫明檢查過哪些測試檔。
- **契約**：實作與 `openapi.yaml` 是否一致（路徑、方法、欄位名稱與型別、狀態碼）；前後端兩份 `openapi.yaml` 是否一致（跨兩端的變更）。
- **邊界情況**：空值、空清單、權限不足、時區、併發。
- **邏輯錯誤**：條件寫反、漏掉狀態、N+1 查詢、競態條件。

**不審**：程式風格、命名格式、格式（交給 linter）。違反 `CLAUDE.md` 專案慣例由 `/code-review` 負責回報，這裡不另外找，只負責評級（見下一步）。重用、簡化、效率類意見不要報。

## 3. 評級

自己的發現、以及 `/code-review` 的**每一條**發現，都要給出：

| 欄位 | 內容 |
|------|------|
| 來源 | Shiori／/code-review |
| 嚴重度 | 高（會造成錯誤行為、資料錯誤或安全問題）／中（特定條件下出錯，或需求漏測）／低（影響小） |
| 信心度 | 高（有程式碼證據，能指出觸發條件）／中／低 |
| 檔案:行號 | worktree 相對路徑與行號 |
| 對應需求 | `tasks.md` 項次、`Requirement › Scenario`，或違反的 `CLAUDE.md` 慣例；都找不到就寫「無」 |
| 說明 | 具體輸入或狀態 → 錯誤結果；慣例違反則寫違反哪一條、為什麼 |
| 建議處理 | 退回／PR 備註 |

- **只有「高嚴重度且高信心」才建議退回**，其餘一律建議 PR 備註。
- **慣例違反**（例如商業邏輯寫錯層、自訂錯誤格式）本身沒有造成錯誤行為時，嚴重度最多「中」，建議 PR 備註；同時造成錯誤行為的，依錯誤行為評級。
- **無法確認就不報**：沒有程式碼證據、只是「可能」的，不要列。
- 判斷某條 `/code-review` 發現不成立時，仍要列出，嚴重度與信心度留空，說明欄寫明不成立的理由。`/code-review` 若回報了命名格式、import 順序等機械性項目，判為不成立，理由寫「機械性規則交給 linter」。

## 4. 回報

每一端一張上述格式的表格（沒有發現就寫「無」），再加一段總結：各端建議退回幾條、PR 備註幾條、哪些 `/code-review` 發現判為不成立。

不修改任何檔案；結果由主對話寫進各端的 `review.md`。
