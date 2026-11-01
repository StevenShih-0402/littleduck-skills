<!-- handoff.md 範本：複製到 openspec/changes/<change-id>/handoff.md。「狀態」區塊就地改值、永遠反映最新進度；下方各角色紀錄只追加，不改前面的內容。 -->
# Handoff：<change-id>

## 狀態

<!-- 就地改值，不追加。中斷後重新派工時，開發 Agent 以這裡判斷從哪裡接續；不寫 commit SHA（以 git log --grep "wip(<ISSUE-ID>): <任務編號>" 對應）。
  階段由誰寫入：proposal（architect 建立；核准時主對話更新「最後完成」）→ backend／frontend（開發 Agent 開工）
  → integrating（開發 Agent 交接；integrator 檢查通過後維持，下一步「等待 user 回覆歸檔」）→ archived（integrator 歸檔）。
  integrator 退回時改回 backend／frontend（退回 architect 為 proposal）。 -->

- **階段**：proposal <!-- proposal | backend | frontend | integrating | archived -->
- **最後完成**：無
- **下一步**：<任務編號或等待誰>
- **暫停原因**：無
- **更新**：<名稱> — <YYYY-MM-DD HH:MM>

---

## <角色>（<name>）— <YYYY-MM-DD HH:MM>

- **做了什麼**：
- **未完成**：
- **風險**：
- **API 契約變動**：<無／改了哪些欄位或路徑>
- **退回**：<無／退回給誰、原因、第幾次>
