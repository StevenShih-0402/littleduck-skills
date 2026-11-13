# Tasks

## 1. 解析模組（TDD）

- [x] 1.1 先寫 `tests/prototypes/agent-progress-dashboard/handoff-status.test.mjs`：涵蓋 spec「進度資料只來自 handoff.md 與 tasks.md」「無法辨識的階段要明示」的所有 Scenario，執行 `node --test tests/prototypes/` 確認失敗（已確認失敗）
- [x] 1.2 建立 `prototypes/agent-progress-dashboard/handoff-status.js`（ES module、無相依、檔頭兩行註解）實作狀態區塊解析，`node --test tests/prototypes/` 上述測試通過
- [x] 1.3 補「handoff 階段對應畫面階段」「依結構決定顯示的階段列」的測試後實作對照表與階段列（fullstack／single-side），測試通過
- [x] 1.4 補「退回與暫停的呈現」的測試後實作暫停原因判斷，測試通過
- [x] 1.5 補「任務完成度」的測試後實作 tasks.md 計數（含 `[BE]`／`[FE]` 分計），測試通過
- [x] 1.6 補「已歸檔 change 的讀取位置」的測試後實作 `pickChangeDir`，`node --test tests/prototypes/` 全部通過

## 2. 原型看板

- [x] 2.1 先載入 artifact-design skill，再建立 `prototypes/agent-progress-dashboard/index.html`：內嵌假 handoff.md／tasks.md 字串，匯入 `handoff-status.js` 產生卡片；以瀏覽器開啟（本機 `python3 -m http.server`）確認 spec「原型以假資料走同一條解析流程」列出的每種情境都有一張卡片、頁首有「示範資料」標示與已知限制說明（本機需以帶 charset=utf-8 的伺服器預覽，python3 -m http.server 不送 charset 會造成中文亂碼；Artifact 發佈時由外層 skeleton 補上）
- [x] 2.2 確認手機寬度（375px）無水平捲動、深色模式可讀（Playwright 截圖目視）
- [x] 2.3 以 Artifact 發佈（`files` 附上 `handoff-status.js`），開啟發佈後的頁面確認卡片正常渲染，並把連結回報 user（已發佈 https://claude.ai/artifact/1mrEEVmAMdqzQmT79BqbPd，index.html 與 handoff-status.js 兩檔皆在；發佈後的實際渲染需 user 開啟確認，本機 Playwright 已驗證同一份檔案；user 已於 2026-11-13 確認看過發佈後的畫面）

## 3. 文件與整合檢查

- [x] 3.1 在 README 加一段「Agent 進度看板原型」：用途、資料來源契約摘要、`node --test tests/prototypes/` 執行方式；確認 README 指令照抄可執行
- [x] 3.2 跑 `bash tests/install.test.sh` 確認 installer 行為不受新目錄影響（10 passed）

## Workflow follow-up

- 以 `/issue-solver sdp-156-agent-progress-dashboard` 歸檔並開 PR。
- user 看過 Artifact 原型後，另開 issue 決定本機應用程式的形式與是否加讀 PR 狀態。

## 4. RPG 基地畫面

- [x] 4.1 先補「階段對應負責角色」的測試（確認失敗）後在 `handoff-status.js` 實作 `roleForStage`，`node --test tests/prototypes/` 全部通過
- [x] 4.2 把示範資料抽成 `prototypes/agent-progress-dashboard/demo-data.js`（含重播快照），`index.html` 改為匯入；重新截圖確認卡片看板與抽出前一致（11 張卡片、階段相同）
- [x] 4.3 建立 `prototypes/agent-progress-dashboard/base.html`：工作站蛇行排列、每任務一角色、待查區、退回／暫停標記、點選顯示任務細節、重播控制；Playwright 截圖確認桌面與 375px 無水平捲動、重播後示範角色移到新工作站
- [x] 4.4 重新發佈卡片看板（附 `demo-data.js`），另發佈基地頁為新的 Artifact，確認兩者的檔案清單齊全，並在 README 補上基地頁說明（看板 https://claude.ai/artifact/1mrEEVmAMdqzQmT79BqbPd v2、基地 https://claude.ai/artifact/5py8hFeHUbFWvSkCVnTHQR，兩者皆含 handoff-status.js、demo-data.js）
- [x] 4.5 依 user 回饋（Linear 留言附參考圖）把基地頁改為雷達平面圖：拿掉說明段落、名冊、對話框與事件清單，角色改為幾何頭像＋引線標籤（功能圖示＋名字＋編號），沿走廊轉角移動並留下點狀軌跡；Playwright 確認桌面與 375px 無水平捲動、無錯誤、重播第 7 步示範角色回到後端且標示退回 ×1
