---
description: 從 Linear issue 到 PR 的完整流程
argument-hint: <linear-issue-id>
---
處理 Linear issue $ARGUMENTS：

1. 為前後端各建立 worktree，路徑 ../wt/<repo>-<change-id>
2. 交給 hyuse 產生提案。完成後停下，摘要提案內容給我確認。
   【檢查點 1】我回覆「核准」才繼續；有修改意見就交回 hyuse。
3. 同時交給 chika（後端 worktree）與 yuma（前端 worktree）。
4. 交給 osamu 檢查。若 osamu 退回，依 handoff.md 交回對應的人修正，
   同一階段最多退回 2 次，超過就停下來告訴我。
5. osamu 檢查通過後，摘要結果與 PR 連結給我。
   【檢查點 2】我回覆「歸檔」後，osamu 才執行 /opsx:archive 並回寫 Linear。

小 issue（只動單一 repo、無 API 變更）可走捷徑：跳過 hyuse 的 OpenAPI 草稿，只派單一開發 Agent。
