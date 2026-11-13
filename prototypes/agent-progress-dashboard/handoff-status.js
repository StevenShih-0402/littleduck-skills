// prototypes/agent-progress-dashboard/handoff-status.js
// 把 handoff.md「## 狀態」區塊與 tasks.md 文字解析成 Agent 進度看板用的資料（無相依、不碰檔案系統）

/** 狀態區塊的欄位名 → 輸出鍵 */
const STATUS_FIELDS = {
  階段: "stage",
  最後完成: "lastDone",
  下一步: "next",
  暫停原因: "pauseReason",
  更新: "updatedBy",
};

/** handoff 階段值 → 畫面階段 */
const STAGE_MAP = {
  proposal: { key: "proposal", label: "提案" },
  backend: { key: "develop", label: "開發", side: "backend" },
  frontend: { key: "develop", label: "開發", side: "frontend" },
  integrating: { key: "integrating", label: "檢查" },
  reviewing: { key: "reviewing", label: "PR 前審查" },
  "pr-checking": { key: "pr-checking", label: "PR 中檢查" },
  "awaiting-approval": { key: "awaiting-approval", label: "等待審批" },
  archived: { key: "merge-queue", label: "合併隊列" },
};

/** 取出「## 狀態」到下一個 `## ` 標題或水平線之間的文字；沒有就回傳 null */
function extractStatusBlock(text) {
  const lines = text.split(/\r?\n/);
  const start = lines.findIndex((line) => /^##\s+狀態\s*$/.test(line));
  if (start === -1) return null;
  const rest = lines.slice(start + 1);
  const end = rest.findIndex((line) => /^##\s/.test(line) || /^---\s*$/.test(line));
  return (end === -1 ? rest : rest.slice(0, end)).join("\n");
}

/** 去掉 HTML 註解與前後空白 */
function cleanValue(raw) {
  return raw.replace(/<!--[\s\S]*?-->/g, "").trim();
}

/**
 * 解析 handoff.md 的狀態區塊。
 * @param {string} handoffText handoff.md 全文
 * @returns {{stage:string,lastDone:string,next:string,pauseReason:string|null,updatedBy:string,updatedAt:string}|null}
 */
export function parseStatus(handoffText) {
  const block = extractStatusBlock(handoffText ?? "");
  if (block === null) return null;

  const status = { stage: "", lastDone: "", next: "", pauseReason: null, updatedBy: "", updatedAt: "" };
  for (const line of block.split("\n")) {
    const match = line.match(/^\s*-\s*\*\*(.+?)\*\*\s*[：:]\s*(.*)$/);
    if (!match || !(match[1] in STATUS_FIELDS)) continue;
    const key = STATUS_FIELDS[match[1]];
    const value = cleanValue(match[2]);
    if (key === "pauseReason") {
      status.pauseReason = value === "" || value === "無" ? null : value;
    } else if (key === "updatedBy") {
      // 格式：<名稱> — <YYYY-MM-DD HH:MM>
      const [who, when = ""] = value.split(/\s+[—–-]\s+/);
      status.updatedBy = who.trim();
      status.updatedAt = when.trim();
    } else {
      status[key] = value;
    }
  }
  return status;
}

/**
 * handoff 階段值轉成畫面階段；不在對照表中回傳 unknown 並保留原始值。
 * @param {string} stage handoff 階段值
 */
export function mapStage(stage) {
  const mapped = STAGE_MAP[stage];
  if (!mapped) return { key: "unknown", label: "無法辨識", raw: stage ?? "" };
  return { ...mapped };
}

/** 畫面階段 → 負責的 Agent 角色（開發階段依端別） */
const STAGE_ROLE = {
  proposal: "architect",
  integrating: "integrator",
  reviewing: "reviewer",
  "pr-checking": "orchestrator",
  "awaiting-approval": "user",
  "merge-queue": "integrator",
};

/**
 * 依畫面階段決定負責角色；無法辨識時回傳 null。
 * @param {{key:string,side?:string}} stage mapStage 的結果
 * @returns {"architect"|"backend"|"frontend"|"integrator"|"reviewer"|"orchestrator"|"user"|null}
 */
export function roleForStage(stage) {
  if (stage.key === "develop") return stage.side ?? null;
  return STAGE_ROLE[stage.key] ?? null;
}

const SIDE_LABEL = { backend: "後端", frontend: "前端" };

/**
 * 依結構產生階段列的格子（不含狀態）。
 * fullstack 開發拆成後端、前端兩格；single-side 只有一格並標示宣告端。
 * @param {{structure:"fullstack"|"single-side",side?:"backend"|"frontend"}} options
 * @returns {{key:string,label:string,side?:string,optional?:boolean}[]}
 */
export function buildLane({ structure, side }) {
  const develop =
    structure === "single-side"
      ? [{ key: "develop", side, label: `開發（${SIDE_LABEL[side] ?? "未宣告"}）` }]
      : [
          { key: "develop", side: "backend", label: "後端" },
          { key: "develop", side: "frontend", label: "前端" },
        ];
  return [
    { key: "proposal", label: "提案" },
    ...develop,
    { key: "integrating", label: "檢查" },
    { key: "reviewing", label: "PR 前審查" },
    { key: "pr-checking", label: "PR 中檢查" },
    // 只有高風險才會經過，低／中風險直接跳過
    { key: "awaiting-approval", label: "等待審批", optional: true },
    { key: "merge-queue", label: "合併隊列" },
  ];
}

/** 找出目前階段在階段列的位置；single-side 的開發格不比對端別 */
function findCurrentIndex(lane, stage, structure) {
  if (stage.key === "unknown") return -1;
  return lane.findIndex(
    (cell) => cell.key === stage.key && (cell.key !== "develop" || structure === "single-side" || cell.side === stage.side),
  );
}

/**
 * 解析暫停原因；「…退回第 N 次」視為退回並取出次數。
 * @param {string|null} reason 暫停原因，null 表示無
 */
export function parsePause(reason) {
  if (!reason) return null;
  const match = reason.match(/退回第\s*(\d+)\s*次/);
  return { reason, returned: Boolean(match), returnCount: match ? Number(match[1]) : null };
}

/**
 * 計算 tasks.md 的完成度：方框內只有 x（不分大小寫、可含空白）算完成，沒有方框的行不計。
 * @param {string|undefined|null} tasksText tasks.md 全文；沒有檔案時傳 undefined
 */
export function countTasks(tasksText) {
  if (tasksText == null) return null;
  const count = { done: 0, total: 0, backend: { done: 0, total: 0 }, frontend: { done: 0, total: 0 } };
  for (const line of tasksText.split(/\r?\n/)) {
    const match = line.match(/^\s*[-*]\s*\[([^\]]*)\]\s*(.*)$/);
    if (!match) continue;
    const done = match[1].trim().toLowerCase() === "x";
    const buckets = [count];
    if (/\[BE\]/.test(match[2])) buckets.push(count.backend);
    if (/\[FE\]/.test(match[2])) buckets.push(count.frontend);
    for (const bucket of buckets) {
      bucket.total += 1;
      if (done) bucket.done += 1;
    }
  }
  return count;
}

/**
 * 從 worktree 內的目錄清單挑出 change 的位置：未歸檔優先，否則找 archive/<日期>-<change-id>。
 * @param {string[]} dirs 相對於 worktree 根目錄的目錄路徑
 * @param {string} changeId change-id
 */
export function pickChangeDir(dirs, changeId) {
  const normalized = dirs.map((dir) => dir.replace(/\/+$/, ""));
  const active = `openspec/changes/${changeId}`;
  if (normalized.includes(active)) return { dir: active, changeId, archived: false };
  const archivedPattern = new RegExp(`^openspec/changes/archive/\\d{4}-\\d{2}-\\d{2}-${changeId.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`);
  const archived = normalized.find((dir) => archivedPattern.test(dir));
  return archived ? { dir: archived, changeId, archived: true } : null;
}

/**
 * 組出單一 change 的看板資料。
 * @param {{changeId:string,structure:"fullstack"|"single-side",side?:"backend"|"frontend",handoff:string,tasks?:string}} input
 */
export function buildProgress(input) {
  const status = parseStatus(input.handoff);
  const stage = mapStage(status ? status.stage : "");
  const cells = buildLane(input);
  const currentIndex = findCurrentIndex(cells, stage, input.structure);
  const lane = cells.map((cell, index) => ({
    ...cell,
    state: currentIndex === -1 ? "todo" : index < currentIndex ? "done" : index === currentIndex ? "current" : "todo",
  }));
  return {
    changeId: input.changeId,
    structure: input.structure,
    side: input.side ?? null,
    status,
    stage,
    lane,
    pause: parsePause(status ? status.pauseReason : null),
    tasks: countTasks(input.tasks),
  };
}
