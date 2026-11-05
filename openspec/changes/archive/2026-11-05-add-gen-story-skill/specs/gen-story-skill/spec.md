# Spec Delta

## Purpose

收錄並發佈通用、專案無關的 `gen-story` skill，把一個 OpenSpec 變更做成對話劇本式的單檔 HTML 導覽投影片，讓使用者不必逐行讀 diff 就能掌握這次改了什麼、程式長怎樣、在系統上怎麼看到更動。

## ADDED Requirements

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

The skill SHALL only read the project and SHALL NOT modify the working tree, commit, or auto-publish. It SHALL provide a layout-check step that renders each slide and fails when content overflows its frame, needs scrolling, exceeds the canvas, or collides with the footer; the playwright runtime SHALL resolve from the current project's `node_modules` by default and be overridable via the `PLAYWRIGHT_FROM` environment variable.

#### Scenario: No writes beyond the output HTML

- **WHEN** skill 執行完畢
- **THEN** 除了寫出 `docs/story/<change-id>.html` 外，不修改任何原始檔、不建立 commit、不自動發布

#### Scenario: Layout check flags broken slides

- **WHEN** 對產出的 HTML 執行版面檢查腳本，而某一頁文字超出外框、需要捲動、超出畫布或壓到頁尾
- **THEN** 腳本以非零狀態結束並指出問題頁；全部通過時以零狀態結束
