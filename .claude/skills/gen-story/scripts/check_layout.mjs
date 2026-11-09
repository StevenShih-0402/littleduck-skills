// .claude/skills/gen-story/scripts/check_layout.mjs
// 逐頁檢查 gen-story 導覽投影片的版面（超框、超出畫布）與內容密度（缺少主視覺、對話或文字過多），有問題即以 exit 1 結束。
//
// 用法：node check_layout.mjs <story.html> [--shots <輸出目錄>]
//   playwright 預設從目前專案的 node_modules 載入；設 PLAYWRIGHT_FROM=<repo 根目錄> 可改從他處載入。
//   chromium 用 ~/.cache/ms-playwright 已安裝的版本。
//
// 規則（任一條違反即列出並以 exit code 1 結束）：
//   1. 文字的實際排版範圍必須落在每一個「有外框的祖先」之內（有背景色或邊框的區塊，例：卡片、對話泡泡、程式碼框、表格格子）。
//   2. 不得出現需要捲動才看得到的內容（scrollWidth／scrollHeight 大於可視範圍）。
//   3. 內容不得超出 16:9 畫布，也不得壓到頁尾進度列（畫布底部 64px）。
//   以下為內容規則（以圖表為主），封面頁（section.slide.cover）不檢查：
//   4. 缺少主視覺：頁面內沒有任何圖形元件（VISUAL_SELECTORS）。
//   5. 對話過多：對話泡泡超過 MAX_BUBBLES 則。
//   6. 文字過多：圖形元件以外的說明文字（去除空白後）超過 MAX_PROSE 字；
//      標題、kicker、標籤、程式碼說明列與泡泡內的角色名不計入。
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

// 內容規則門檻；調整時 SKILL.md 的「內容規則」與「檢查版面」要同步改。
const MAX_PROSE = 150;
const MAX_BUBBLES = 3;
const VISUAL_SELECTORS = [".flow", ".vs", ".lanes", ".branch", ".stats", "table.t", ".matrix", ".tree", ".codebox", "ol.steps", ".cast"];
const PROSE_EXCLUDE = ["h1", "h2", ".kicker", ".tag", ".cap", ".bubble b.n"];

const playwrightRoot = process.env.PLAYWRIGHT_FROM ?? process.cwd();
let chromium;
try {
  ({ chromium } = createRequire(join(playwrightRoot, "package.json"))("playwright"));
} catch {
  console.error("找不到 playwright：請在目前專案安裝（例：npm i -D playwright），或以 PLAYWRIGHT_FROM 指向已安裝 playwright 的 repo 根目錄。");
  console.error(`嘗試的解析根目錄：${playwrightRoot}`);
  process.exit(2);
}

const args = process.argv.slice(2);
const file = args[0];
const shotsDir = args.includes("--shots") ? args[args.indexOf("--shots") + 1] : null;
if (!file) {
  console.error("用法：node check_layout.mjs <story.html> [--shots <輸出目錄>]");
  process.exit(2);
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
const url = pathToFileURL(resolve(file)).href;
await page.goto(url);
await page.evaluate(() => document.fonts.ready);
const total = await page.evaluate(() => document.querySelectorAll(".slide").length);
if (shotsDir) mkdirSync(shotsDir, { recursive: true });

const problems = [];
for (let n = 1; n <= total; n++) {
  await page.goto(`${url}#s${n}`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(350); // 等換頁動畫結束
  const found = await page.evaluate(() => {
    const TOL = 1.5;
    const out = [];
    const slide = document.querySelector(".slide.active");
    const deck = document.getElementById("deck");
    const scale = deck.getBoundingClientRect().width / deck.offsetWidth;
    const sRect = slide.getBoundingClientRect();
    const footerTop = sRect.bottom - 64 * scale;

    const describe = (el) => {
      const cls = typeof el.className === "string" && el.className.trim() ? "." + el.className.trim().split(/\s+/).join(".") : "";
      return el.tagName.toLowerCase() + cls;
    };
    const boxed = (el) => {
      const cs = getComputedStyle(el);
      if (cs.display === "inline" || cs.display === "contents") return false;
      const bg = cs.backgroundColor;
      const hasBg = bg && bg !== "transparent" && !/rgba\(.*,\s*0\)$/.test(bg);
      const hasBorder = ["Top", "Right", "Bottom", "Left"].some(
        (s) => parseFloat(cs[`border${s}Width`]) > 0 && cs[`border${s}Style`] !== "none",
      );
      return hasBg || hasBorder || cs.backgroundImage !== "none";
    };

    // 規則 2：需要捲動的區塊
    slide.querySelectorAll("*").forEach((el) => {
      const cs = getComputedStyle(el);
      if (cs.display === "inline") return;
      if (el.scrollWidth > el.clientWidth + 1 && /(auto|scroll|hidden)/.test(cs.overflowX)) {
        out.push({ rule: "需要捲動", where: describe(el), px: el.scrollWidth - el.clientWidth, text: el.textContent.trim().slice(0, 40) });
      }
      if (el.scrollHeight > el.clientHeight + 1 && /(auto|scroll|hidden)/.test(cs.overflowY) && el !== slide) {
        out.push({ rule: "需要捲動（垂直）", where: describe(el), px: el.scrollHeight - el.clientHeight, text: el.textContent.trim().slice(0, 40) });
      }
    });

    // 規則 1、3：逐一文字節點比對外框
    const walker = document.createTreeWalker(slide, NodeFilter.SHOW_TEXT);
    const seen = new Set();
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      if (!node.textContent.trim()) continue;
      const parent = node.parentElement;
      if (!parent || parent.closest("script,style,aside")) continue;
      const range = document.createRange();
      range.selectNodeContents(node);
      for (const r of range.getClientRects()) {
        if (r.width === 0 || r.height === 0) continue;
        for (let el = parent; el && el !== slide.parentElement; el = el.parentElement) {
          const isSlide = el === slide;
          if (!isSlide && !boxed(el)) continue;
          const b = el.getBoundingClientRect();
          const over = Math.max(b.left - r.left, r.right - b.right, b.top - r.top, r.bottom - b.bottom);
          if (over > TOL) {
            const key = describe(el) + "|" + node.textContent.trim().slice(0, 30);
            if (!seen.has(key)) {
              seen.add(key);
              out.push({ rule: isSlide ? "超出畫布" : "文字超出外框", where: describe(el), px: Math.round(over / scale), text: node.textContent.trim().slice(0, 40) });
            }
          }
        }
        if (r.bottom > footerTop + TOL && !parent.closest("#footer")) {
          const key = "footer|" + node.textContent.trim().slice(0, 30);
          if (!seen.has(key)) {
            seen.add(key);
            out.push({ rule: "壓到頁尾", where: describe(parent), px: Math.round((r.bottom - footerTop) / scale), text: node.textContent.trim().slice(0, 40) });
          }
        }
      }
    }
    return out;
  });
  found.forEach((p) => problems.push({ slide: n, ...p }));

  // 規則 4～6：內容密度（以圖表為主）
  const content = await page.evaluate(({ maxProse, maxBubbles, visuals, exclude }) => {
    const out = [];
    const slide = document.querySelector(".slide.active");
    if (slide.classList.contains("cover")) return out;
    const visualSel = visuals.join(",");
    if (!slide.querySelector(visualSel)) {
      out.push({ rule: "缺少主視覺", where: "section.slide", px: "0 個圖形元件", text: slide.dataset.name || "" });
    }
    const bubbles = slide.querySelectorAll(".say .bubble").length;
    if (bubbles > maxBubbles) {
      out.push({ rule: "對話過多", where: ".chat", px: `${bubbles} 則（上限 ${maxBubbles}）`, text: slide.dataset.name || "" });
    }
    const skipSel = [visualSel, ...exclude, "script", "style", "aside"].join(",");
    let prose = 0;
    const walker = document.createTreeWalker(slide, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      const parent = node.parentElement;
      if (!parent || parent.closest(skipSel)) continue;
      prose += node.textContent.replace(/\s+/g, "").length;
    }
    if (prose > maxProse) {
      out.push({ rule: "文字過多", where: "section.slide", px: `${prose} 字（上限 ${maxProse}）`, text: slide.dataset.name || "" });
    }
    return out;
  }, { maxProse: MAX_PROSE, maxBubbles: MAX_BUBBLES, visuals: VISUAL_SELECTORS, exclude: PROSE_EXCLUDE });
  content.forEach((p) => problems.push({ slide: n, ...p }));
  if (shotsDir) await page.screenshot({ path: `${shotsDir}/s${String(n).padStart(2, "0")}.png` });
}
await browser.close();

if (problems.length === 0) {
  console.log(`✅ ${total} 頁版面檢查通過`);
} else {
  for (const p of problems) console.log(`❌ 第 ${p.slide} 頁｜${p.rule}｜${p.where}｜${typeof p.px === "number" ? p.px + "px" : p.px}｜${p.text}`);
  console.log(`共 ${problems.length} 處問題`);
  process.exit(1);
}
