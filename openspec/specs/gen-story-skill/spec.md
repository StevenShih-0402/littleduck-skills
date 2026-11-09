# gen-story-skill Specification

## Purpose
收錄並發佈通用、專案無關的 `gen-story` skill，把一個 OpenSpec 變更做成對話劇本式的單檔 HTML 導覽投影片，讓使用者不必逐行讀 diff 就能掌握這次改了什麼、程式長怎樣、在系統上怎麼看到更動。

## Requirements

### Requirement: gen-story skill is available in this repo

The repository SHALL contain the `gen-story` skill under `.claude/skills/gen-story/`, including its `SKILL.md`, the slide template `assets/story-template.html`, and the layout-check script `scripts/check_layout.mjs`, so that any project installing skills from this repo receives it. The skill SHALL be installable on its own with no cross-skill dependencies, matching the `gen-html` installation behaviour.

#### Scenario: Skill files present after checkout

- **WHEN** the repository is checked out
- **THEN** `.claude/skills/gen-story/SKILL.md`、`.claude/skills/gen-story/assets/story-template.html` 與 `.claude/skills/gen-story/scripts/check_layout.mjs` 都存在

#### Scenario: Installable as a standalone skill

- **WHEN** 使用者以安裝指令選擇 `gen-story`（或 `all`）安裝到外部專案
- **THEN** 安裝器把 `.claude/skills/gen-story/` 完整複製到目標專案，且不因它而連帶安裝其他 skill
- **AND** README 的可選項表列出 `gen-story` 一列

### Requirement: gen-story produces a conversational-script HTML walkthrough of an OpenSpec change

Invoked as `/gen-story <change-id>`, the skill SHALL locate the named OpenSpec change, read its planning artifacts and code diff, and produce one single-file HTML walkthrough whose slides use short role dialogue to explain the decisions and the actual code of the change.

#### Scenario: Produces the walkthrough HTML

- **WHEN** 使用者在裝好本 skill 的專案執行 `/gen-story <change-id>`，且該 change-id 存在於專案的 OpenSpec 變更
- **THEN** skill 產出單檔 HTML 到目前專案的 `docs/story/<change-id>.html`，檔名即 change-id
- **AND** 內容涵蓋固定骨架章節（封面、登場人物、問題與決策、實作、實際操作、檢查結果與待決事項、檔案地圖），沒有內容的章節省略

#### Scenario: Change id not found

- **WHEN** 指定的 change-id 在專案的 OpenSpec 變更（含歸檔）中都找不到
- **THEN** skill 停下並回報找不到，不產生 HTML

### Requirement: gen-story content is grounded in the project's real artifacts

The walkthrough SHALL use only the project's actual code and recorded facts: code snippets copied verbatim from source files with their path and line numbers, hands-on verification steps, and numbers taken from the change's own records. It SHALL NOT embed screenshots or invent code, and SHALL be written in Traditional Chinese.

#### Scenario: Code shown is real and attributed

- **WHEN** 投影片引用程式碼
- **THEN** 內容取自專案原始檔案原文（可節錄），並標示檔案路徑與行號，不使用虛構或改寫過的程式

#### Scenario: Includes hands-on steps and sourced figures

- **WHEN** 撰寫「實際操作」與「檢查結果」章節
- **THEN** 列出怎麼啟動、點哪裡、會看到什麼；測試數與差異等數字取自變更自身的紀錄，沒實際驗證過的步驟明確標註

### Requirement: gen-story is project-agnostic

The skill SHALL work in any project that uses OpenSpec without project-specific hardcoding. It SHALL discover the change under the current project's `openspec/changes/<change-id>/` (and the archive `openspec/changes/archive/*-<change-id>/`), detect the base branch from git to compute the diff, require only `proposal.md`/`design.md`/`tasks.md` and read `handoff.md`/`review.md`/`.linear.md`/`openapi.yaml` only when present, and treat dialogue roles as project-dependent.

#### Scenario: Runs in a plain OpenSpec project

- **WHEN** 專案只有 OpenSpec 變更而沒有 agent-team 產物（無 `handoff.md`／`review.md`／`.linear.md`）
- **THEN** skill 仍能以 `proposal.md`／`design.md`／`tasks.md` 與程式碼 diff 產出導覽，不因缺少選用檔案而失敗

#### Scenario: No hardcoded project paths, repos, branches, or roles

- **WHEN** 檢視 skill 的檔案
- **THEN** 不含寫死的專案路徑、repo 名稱或 base 分支；對話角色不強制固定五角——模板保留 agent-team 的角色樣式，並說明非 agent-team 專案可用旁白／單一敘事者

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
