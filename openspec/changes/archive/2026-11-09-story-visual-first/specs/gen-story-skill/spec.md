# Spec Delta

## ADDED Requirements

### Requirement: gen-story slides are visual-first

Every slide except the cover SHALL carry at least one main visual drawn in HTML/CSS (a flow, table, comparison, lane, branch, stat tile, matrix, file tree, code block, or step list) and SHALL keep its prose short. Content that can be expressed as a diagram or table SHALL be drawn rather than written as bullet text, and slides SHALL stay within the documented dialogue and prose limits.

#### Scenario: Non-cover slide has a main visual

- **WHEN** skill 產出一份導覽
- **THEN** 封面以外的每一頁都至少含一個圖形元件作為主視覺，不出現只有卡片與條列文字的頁面

#### Scenario: Prose stays within limits

- **WHEN** 某一頁的對話與說明文字
- **THEN** 對話泡泡則數、每則字數與整頁說明文字字數都不超過 `SKILL.md` 寫明的上限；放不下就改畫成圖或拆頁，不縮小字級

#### Scenario: Diagram preferred over bullet text

- **WHEN** 要表達的內容是流程、前後比較、分支決策、數量或對照
- **THEN** 依 `SKILL.md` 的「內容類型 → 圖表元件」對照表選用對應元件呈現，而不是寫成條列文字

### Requirement: gen-story template provides visual components

The slide template SHALL provide, in addition to its existing flow, table, matrix, and file-tree components, HTML/CSS components for a before/after comparison, a swimlane or sequence, a branching decision, and stat tiles. These components SHALL use no images, and `SKILL.md` SHALL document each component's class and when to use it.

#### Scenario: New components usable without images

- **WHEN** 撰寫者在投影片使用前後對照、泳道／時序、分支決策或數字磁磚元件
- **THEN** 模板內建的樣式即可正確排版呈現，不需要額外圖片或外部函式庫

#### Scenario: Components documented in SKILL.md

- **WHEN** 撰寫者查閱 `SKILL.md` 的元件表
- **THEN** 每個圖表元件都列出 class 名稱與適用的內容類型

## MODIFIED Requirements

### Requirement: gen-story is read-only and verifies slide layout

The skill SHALL only read the project and SHALL NOT modify the working tree, commit, or auto-publish. It SHALL provide a layout-check step that renders each slide and fails when content overflows its frame, needs scrolling, exceeds the canvas, collides with the footer, or (on any non-cover slide) lacks a visual component or exceeds the prose-length limit; the playwright runtime SHALL resolve from the current project's `node_modules` by default and be overridable via the `PLAYWRIGHT_FROM` environment variable.

#### Scenario: No writes beyond the output HTML

- **WHEN** skill 執行完畢
- **THEN** 除了寫出 `docs/story/<change-id>.html` 外，不修改任何原始檔、不建立 commit、不自動發布

#### Scenario: Layout check flags broken slides

- **WHEN** 對產出的 HTML 執行版面檢查腳本，而某一頁文字超出外框、需要捲動、超出畫布或壓到頁尾
- **THEN** 腳本以非零狀態結束並指出問題頁；全部通過時以零狀態結束

#### Scenario: Layout check flags text-heavy slides

- **WHEN** 對產出的 HTML 執行版面檢查腳本，而某一非封面頁沒有任何圖形元件，或圖形元件以外的說明文字超過上限
- **THEN** 腳本以非零狀態結束，指出問題頁、違反的規則與實際字數
