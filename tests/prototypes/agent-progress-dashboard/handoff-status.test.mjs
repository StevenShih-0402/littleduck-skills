// tests/prototypes/agent-progress-dashboard/handoff-status.test.mjs
// 驗證 handoff-status.js 依規格把 handoff.md／tasks.md 轉成看板進度資料

import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  buildLane,
  buildProgress,
  countTasks,
  mapStage,
  parsePause,
  parseStatus,
  pickChangeDir,
  roleForStage,
} from "../../../prototypes/agent-progress-dashboard/handoff-status.js";

const handoffWith = (lines, history = "") =>
  ["# Handoff：sdp-1-demo", "", "## 狀態", "", "<!-- 註解 -->", "", ...lines, "", "---", "", history].join("\n");

const stageOnly = (stage, pauseReason = "無") =>
  handoffWith([`- **階段**：${stage}`, "- **最後完成**：無", "- **下一步**：無", `- **暫停原因**：${pauseReason}`, "- **更新**：x — 2026-11-13 00:00"]);

const currentCell = (progress) => progress.lane.find((cell) => cell.state === "current");

describe("parseStatus：讀狀態區塊", () => {
  it("依欄位名讀出五個欄位，忽略行尾註解", () => {
    // Arrange
    const text = handoffWith([
      "- **階段**：backend <!-- proposal | backend -->",
      "- **最後完成**：1.2",
      "- **下一步**：1.3",
      "- **暫停原因**：無",
      "- **更新**：chika — 2026-11-13 14:20",
    ]);

    // Act
    const status = parseStatus(text);

    // Assert
    assert.deepEqual(status, {
      stage: "backend",
      lastDone: "1.2",
      next: "1.3",
      pauseReason: null,
      updatedBy: "chika",
      updatedAt: "2026-11-13 14:20",
    });
  });

  it("欄位順序不同也能讀出", () => {
    // Arrange
    const text = handoffWith([
      "- **更新**：osamu — 2026-11-13 09:00",
      "- **暫停原因**：無",
      "- **階段**：integrating",
      "- **下一步**：檢查",
      "- **最後完成**：2.3",
    ]);

    // Act
    const status = parseStatus(text);

    // Assert
    assert.equal(status.stage, "integrating");
    assert.equal(status.updatedBy, "osamu");
  });

  it("只採用狀態區塊內的值，不被下方角色紀錄的同名欄位覆蓋", () => {
    // Arrange
    const text = handoffWith(
      ["- **階段**：reviewing", "- **最後完成**：檢查", "- **下一步**：PR 前審查", "- **暫停原因**：無", "- **更新**：osamu — 2026-11-13 10:00"],
      "## 後端（chika）— 2026-11-12 10:00\n\n- **階段**：backend\n- **做了什麼**：…",
    );

    // Act
    const status = parseStatus(text);

    // Assert
    assert.equal(status.stage, "reviewing");
  });

  it("沒有狀態區塊時回傳 null", () => {
    // Arrange
    const text = "# Handoff：sdp-1-demo\n\n## 後端（chika）\n\n- **做了什麼**：…";

    // Act
    const status = parseStatus(text);

    // Assert
    assert.equal(status, null);
  });
});

describe("無法辨識的階段要明示", () => {
  it("未知階段值顯示無法辨識並保留原始值", () => {
    // Act
    const stage = mapStage("deploying");

    // Assert
    assert.deepEqual(stage, { key: "unknown", label: "無法辨識", raw: "deploying" });
  });

  it("缺少狀態區塊時該 change 無法辨識、原始值為空，階段列沒有目前位置", () => {
    // Arrange
    const input = { changeId: "sdp-2-bad", structure: "fullstack", handoff: "# Handoff\n\n沒有狀態" };

    // Act
    const progress = buildProgress(input);

    // Assert
    assert.equal(progress.stage.key, "unknown");
    assert.equal(progress.stage.raw, "");
    assert.equal(currentCell(progress), undefined);
  });

  it("一筆無法辨識不影響其他 change", () => {
    // Arrange
    const inputs = [
      { changeId: "sdp-2-bad", structure: "fullstack", handoff: stageOnly("deploying") },
      { changeId: "sdp-3-ok", structure: "fullstack", handoff: stageOnly("proposal") },
    ];

    // Act
    const results = inputs.map(buildProgress);

    // Assert
    assert.equal(results[0].stage.key, "unknown");
    assert.equal(results[1].stage.label, "提案");
  });
});

describe("handoff 階段對應畫面階段", () => {
  const cases = [
    ["proposal", "提案"],
    ["backend", "開發"],
    ["frontend", "開發"],
    ["integrating", "檢查"],
    ["reviewing", "PR 前審查"],
    ["pr-checking", "PR 中檢查"],
    ["awaiting-approval", "等待審批"],
    ["archived", "合併隊列"],
  ];
  for (const [raw, label] of cases) {
    it(`${raw} → ${label}`, () => {
      // Act
      const stage = mapStage(raw);

      // Assert
      assert.equal(stage.label, label);
    });
  }

  it("開發階段標示端別", () => {
    // Act
    const stage = mapStage("frontend");

    // Assert
    assert.equal(stage.label, "開發");
    assert.equal(stage.side, "frontend");
  });
});

describe("依結構決定顯示的階段列", () => {
  it("fullstack 開發分後端、前端兩格，目前位置在後端", () => {
    // Arrange
    const input = { changeId: "sdp-4", structure: "fullstack", handoff: stageOnly("backend") };

    // Act
    const progress = buildProgress(input);

    // Assert
    const labels = progress.lane.map((cell) => cell.label);
    assert.deepEqual(labels, ["提案", "後端", "前端", "檢查", "PR 前審查", "PR 中檢查", "等待審批", "合併隊列"]);
    assert.equal(currentCell(progress).label, "後端");
    assert.equal(progress.lane[0].state, "done");
    assert.equal(progress.lane[2].state, "todo");
  });

  it("single-side 只有一格開發並標示宣告端", () => {
    // Arrange
    const input = { changeId: "sdp-5", structure: "single-side", side: "frontend", handoff: stageOnly("frontend") };

    // Act
    const progress = buildProgress(input);

    // Assert
    const labels = progress.lane.map((cell) => cell.label);
    assert.deepEqual(labels, ["提案", "開發（前端）", "檢查", "PR 前審查", "PR 中檢查", "等待審批", "合併隊列"]);
    assert.equal(currentCell(progress).label, "開發（前端）");
  });

  it("buildLane 只依結構產生格子，不含狀態", () => {
    // Act
    const lane = buildLane({ structure: "single-side", side: "backend" });

    // Assert
    assert.equal(lane[1].label, "開發（後端）");
  });
});

describe("退回與暫停的呈現", () => {
  it("退回標示次數，目前位置在開發（後端）", () => {
    // Arrange
    const input = { changeId: "sdp-6", structure: "fullstack", handoff: stageOnly("backend", "PR 前審查退回第 2 次") };

    // Act
    const progress = buildProgress(input);

    // Assert
    assert.deepEqual(progress.pause, { reason: "PR 前審查退回第 2 次", returned: true, returnCount: 2 });
    assert.equal(currentCell(progress).label, "後端");
  });

  it("一般暫停不標示退回", () => {
    // Act
    const pause = parsePause("高風險，等待 user 回覆合併");

    // Assert
    assert.deepEqual(pause, { reason: "高風險，等待 user 回覆合併", returned: false, returnCount: null });
  });

  it("暫停原因為「無」時沒有暫停", () => {
    // Arrange
    const input = { changeId: "sdp-7", structure: "fullstack", handoff: stageOnly("reviewing") };

    // Act
    const progress = buildProgress(input);

    // Assert
    assert.equal(progress.pause, null);
  });
});

describe("任務完成度", () => {
  it("只有 x 算完成，fullstack 依 [BE]／[FE] 分計", () => {
    // Arrange
    const tasks = [
      "# Tasks",
      "## 1. 後端",
      "- [x] 1.1 [BE] 建 API",
      "- [ X ] 1.2 [BE] 寫測試",
      "## 2. 前端",
      "- [~] 2.1 [FE] 切版",
      "- [ ] 2.2 [FE] 串接",
      "說明文字不計入",
    ].join("\n");

    // Act
    const count = countTasks(tasks);

    // Assert
    assert.deepEqual(count, { done: 2, total: 4, backend: { done: 2, total: 2 }, frontend: { done: 0, total: 2 } });
  });

  it("空的 [] 讀作未完成", () => {
    // Act
    const count = countTasks("- [] 1.1 待辦\n- [x] 1.2 完成");

    // Assert
    assert.equal(count.done, 1);
    assert.equal(count.total, 2);
  });

  it("沒有 tasks.md 時完成度為 null，不影響階段顯示", () => {
    // Arrange
    const input = { changeId: "sdp-8", structure: "fullstack", handoff: stageOnly("integrating") };

    // Act
    const progress = buildProgress(input);

    // Assert
    assert.equal(progress.tasks, null);
    assert.equal(progress.stage.label, "檢查");
  });
});

describe("已歸檔 change 的讀取位置", () => {
  it("只存在於 archive 時讀歸檔目錄，change-id 去掉日期前綴", () => {
    // Arrange
    const dirs = ["openspec/changes/archive/2026-11-13-sdp-1-demo", "openspec/changes/archive/2026-11-10-other"];

    // Act
    const picked = pickChangeDir(dirs, "sdp-1-demo");

    // Assert
    assert.deepEqual(picked, { dir: "openspec/changes/archive/2026-11-13-sdp-1-demo", changeId: "sdp-1-demo", archived: true });
  });

  it("未歸檔與歸檔位置都存在時以未歸檔為準", () => {
    // Arrange
    const dirs = ["openspec/changes/archive/2026-11-13-sdp-1-demo", "openspec/changes/sdp-1-demo"];

    // Act
    const picked = pickChangeDir(dirs, "sdp-1-demo");

    // Assert
    assert.deepEqual(picked, { dir: "openspec/changes/sdp-1-demo", changeId: "sdp-1-demo", archived: false });
  });

  it("兩處都找不到時回傳 null", () => {
    // Act
    const picked = pickChangeDir(["openspec/changes/archive/2026-11-13-sdp-1-demo-v2"], "sdp-1-demo");

    // Assert
    assert.equal(picked, null);
  });
});

describe("階段對應負責角色", () => {
  const cases = [
    ["proposal", "architect"],
    ["backend", "backend"],
    ["frontend", "frontend"],
    ["integrating", "integrator"],
    ["reviewing", "reviewer"],
    ["pr-checking", "orchestrator"],
    ["awaiting-approval", "user"],
    ["archived", "integrator"],
  ];
  for (const [raw, role] of cases) {
    it(`${raw} 由 ${role} 負責`, () => {
      // Arrange
      const stage = mapStage(raw);

      // Act
      const result = roleForStage(stage);

      // Assert
      assert.equal(result, role);
    });
  }

  it("無法辨識的階段沒有負責角色", () => {
    // Arrange
    const stage = mapStage("deploying");

    // Act
    const result = roleForStage(stage);

    // Assert
    assert.equal(result, null);
  });
});
