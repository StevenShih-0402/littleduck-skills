// prototypes/agent-progress-dashboard/demo-data.js
// 卡片看板與 RPG 基地共用的示範資料：照 handoff 範本格式產生的 handoff.md／tasks.md 文字與重播快照

const STAGE_COMMENT = "<!-- proposal | backend | frontend | integrating | reviewing | pr-checking | awaiting-approval | archived -->";

/** 依 handoff 範本格式組出 handoff.md 全文 */
function handoffText(changeId, s, history = []) {
  return [
    `# Handoff：${changeId}`,
    "",
    "## 狀態",
    "",
    "<!-- 就地改值，不追加。 -->",
    "",
    `- **階段**：${s.stage} ${STAGE_COMMENT}`,
    `- **最後完成**：${s.lastDone}`,
    `- **下一步**：${s.next}`,
    `- **暫停原因**：${s.pause ?? "無"}`,
    `- **更新**：${s.by} — ${s.at}`,
    "",
    "---",
    "",
    ...history,
  ].join("\n");
}

/** 依 [標記, 內容] 組出 tasks.md 全文 */
function tasksText(items) {
  return ["# Tasks", "", ...items.map(([mark, text]) => `- [${mark}] ${text}`)].join("\n");
}

/** fullstack 的 tasks.md：be／fe 為各任務是否完成 */
const fullTasks = (be, fe) =>
  tasksText([
    ...be.map((done, i) => [done ? "x" : " ", `1.${i + 1} [BE] 後端任務 ${i + 1}`]),
    ...fe.map((done, i) => [done ? "x" : " ", `2.${i + 1} [FE] 前端任務 ${i + 1}`]),
  ]);

/** 靜態示範任務：涵蓋每個階段、退回、暫停、無法辨識與 single-side */
export const FIXTURES = [
  {
    changeId: "sdp-301-order-export", title: "訂單匯出 CSV", structure: "fullstack",
    handoff: handoffText("sdp-301-order-export", { stage: "proposal", lastDone: "無", next: "主對話提交提案", by: "hyuse", at: "2026-11-13 09:12" }),
    tasks: fullTasks([0, 0, 0], [0, 0]),
  },
  {
    changeId: "sdp-302-login-mfa", title: "登入加上 MFA", structure: "fullstack",
    handoff: handoffText("sdp-302-login-mfa", { stage: "backend", lastDone: "1.2", next: "1.3", by: "chika", at: "2026-11-13 10:40" }),
    tasks: fullTasks([1, 1, 0, 0], [0, 0, 0]),
  },
  {
    changeId: "sdp-303-report-filter", title: "報表加上日期篩選", structure: "fullstack",
    handoff: handoffText("sdp-303-report-filter", { stage: "frontend", lastDone: "2.1", next: "2.2", by: "yuma", at: "2026-11-13 11:05" }),
    tasks: fullTasks([1, 1], [1, 0, 0]),
  },
  {
    changeId: "sdp-304-avatar-upload", title: "大頭貼上傳（只有前端的 repo）", structure: "single-side", side: "frontend",
    handoff: handoffText("sdp-304-avatar-upload", { stage: "frontend", lastDone: "1.3", next: "1.4", by: "yuma", at: "2026-11-13 11:20" }),
    tasks: tasksText([["x", "1.1 [FE] 上傳元件"], ["x", "1.2 [FE] 預覽"], ["x", "1.3 [FE] 錯誤提示"], [" ", "1.4 [FE] 單元測試"]]),
  },
  {
    changeId: "sdp-305-invoice-api", title: "發票查詢 API", structure: "fullstack",
    handoff: handoffText("sdp-305-invoice-api", { stage: "integrating", lastDone: "2.3", next: "osamu 檢查", by: "yuma", at: "2026-11-13 08:55" }),
    tasks: fullTasks([1, 1, 1], [1, 1, 1]),
  },
  {
    changeId: "sdp-306-search-speedup", title: "搜尋加速", structure: "fullstack",
    handoff: handoffText("sdp-306-search-speedup", { stage: "reviewing", lastDone: "檢查（含執行驗證）", next: "PR 前審查（shiori）", by: "osamu", at: "2026-11-13 09:48" }),
    tasks: fullTasks([1, 1, 1, 1], []),
  },
  {
    changeId: "sdp-307-coupon-rules", title: "優惠券疊加規則", structure: "fullstack",
    handoff: handoffText(
      "sdp-307-coupon-rules",
      { stage: "backend", lastDone: "PR 前審查第 2 輪", next: "修正 review.md 第 2 輪退回項目", pause: "PR 前審查退回第 2 次", by: "主對話", at: "2026-11-13 10:15" },
      ["## 主對話 — 2026-11-13 10:15", "", "- **退回**：退回給後端，邊界條件未測，第 2 次"],
    ),
    tasks: fullTasks([1, 1, 1, 0], [1, 1]),
  },
  {
    changeId: "sdp-308-audit-log", title: "操作紀錄頁", structure: "fullstack",
    handoff: handoffText("sdp-308-audit-log", { stage: "pr-checking", lastDone: "收尾開 PR", next: "CI、/code-review、/security-review", by: "osamu", at: "2026-11-13 10:02" }),
    tasks: fullTasks([1, 1], [1, 1, 1]),
  },
  {
    changeId: "sdp-309-payment-refund", title: "退款流程", structure: "fullstack",
    handoff: handoffText("sdp-309-payment-refund", { stage: "awaiting-approval", lastDone: "PR 中檢查", next: "等待 user 回覆「合併」", pause: "高風險，等待 user 回覆合併", by: "主對話", at: "2026-11-13 09:30" }),
    tasks: fullTasks([1, 1, 1, 1, 1], [1, 1]),
  },
  {
    changeId: "sdp-310-i18n-labels", title: "介面文字多語系", structure: "fullstack",
    handoff: handoffText("sdp-310-i18n-labels", { stage: "archived", lastDone: "歸檔並回寫 Linear", next: "合併（osamu 模擬合併隊列）", by: "osamu", at: "2026-11-13 11:31" }),
    tasks: fullTasks([1], [1, 1, 1]),
  },
  {
    changeId: "sdp-311-legacy-sync", title: "舊系統同步（狀態值寫錯）", structure: "fullstack",
    handoff: handoffText("sdp-311-legacy-sync", { stage: "deploying", lastDone: "?", next: "?", by: "unknown", at: "2026-11-12 18:00" }),
    tasks: undefined,
  },
];

/** 重播用的示範任務：依時間排序的 handoff.md／tasks.md 快照，含一次 PR 前審查退回 */
const REPLAY_ID = "sdp-312-checkout-flow";
const replayStep = (status, be, fe) => ({ handoff: handoffText(REPLAY_ID, status), tasks: fullTasks(be, fe) });

export const REPLAY = {
  changeId: REPLAY_ID,
  title: "結帳流程改版（重播示範）",
  structure: "fullstack",
  steps: [
    replayStep({ stage: "proposal", lastDone: "無", next: "主對話提交提案", by: "hyuse", at: "2026-11-13 13:00" }, [0, 0, 0], [0, 0]),
    replayStep({ stage: "backend", lastDone: "提交提案", next: "1.1", by: "chika", at: "2026-11-13 13:20" }, [0, 0, 0], [0, 0]),
    replayStep({ stage: "backend", lastDone: "1.2", next: "1.3", by: "chika", at: "2026-11-13 13:55" }, [1, 1, 0], [0, 0]),
    replayStep({ stage: "frontend", lastDone: "1.3", next: "2.1", by: "chika", at: "2026-11-13 14:10" }, [1, 1, 1], [0, 0]),
    replayStep({ stage: "integrating", lastDone: "2.2", next: "osamu 檢查", by: "yuma", at: "2026-11-13 14:50" }, [1, 1, 1], [1, 1]),
    replayStep({ stage: "reviewing", lastDone: "檢查（含執行驗證）", next: "PR 前審查（shiori）", by: "osamu", at: "2026-11-13 15:05" }, [1, 1, 1], [1, 1]),
    replayStep(
      { stage: "backend", lastDone: "PR 前審查第 1 輪", next: "修正 review.md 第 1 輪退回項目", pause: "PR 前審查退回第 1 次", by: "主對話", at: "2026-11-13 15:20" },
      [1, 1, 1, 0],
      [1, 1],
    ),
    replayStep({ stage: "integrating", lastDone: "1.4", next: "osamu 檢查", by: "chika", at: "2026-11-13 15:45" }, [1, 1, 1, 1], [1, 1]),
    replayStep({ stage: "reviewing", lastDone: "檢查（含執行驗證）", next: "PR 前審查第 2 輪", by: "osamu", at: "2026-11-13 15:58" }, [1, 1, 1, 1], [1, 1]),
    replayStep({ stage: "pr-checking", lastDone: "收尾開 PR", next: "CI、/code-review、/security-review", by: "osamu", at: "2026-11-13 16:10" }, [1, 1, 1, 1], [1, 1]),
    replayStep({ stage: "archived", lastDone: "歸檔並回寫 Linear", next: "合併（osamu 模擬合併隊列）", by: "osamu", at: "2026-11-13 16:40" }, [1, 1, 1, 1], [1, 1]),
  ],
};
