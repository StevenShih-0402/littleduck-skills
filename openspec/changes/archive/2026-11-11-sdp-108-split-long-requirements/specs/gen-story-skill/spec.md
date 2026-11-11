## MODIFIED Requirements

### Requirement: gen-story is read-only and verifies slide layout

The skill SHALL only read the project and SHALL NOT modify the working tree, commit, or auto-publish; its only write is the generated story HTML.

#### Scenario: No writes beyond the output HTML

- **WHEN** skill 執行完畢
- **THEN** 除了寫出 `docs/story/<change-id>.html` 外，不修改任何原始檔、不建立 commit、不自動發布

#### Scenario: Layout check flags broken slides

- **WHEN** 對產出的 HTML 執行版面檢查腳本，而某一頁文字超出外框、需要捲動、超出畫布或壓到頁尾
- **THEN** 腳本以非零狀態結束並指出問題頁；全部通過時以零狀態結束

#### Scenario: Layout check flags text-heavy slides

- **WHEN** 對產出的 HTML 執行版面檢查腳本，而某一非封面頁沒有任何圖形元件，或圖形元件以外的說明文字超過上限
- **THEN** 腳本以非零狀態結束，指出問題頁、違反的規則與實際字數

## ADDED Requirements

### Requirement: Layout check rejects broken or text-heavy slides

The skill SHALL provide a layout-check step that renders each slide and fails when content overflows its frame, needs scrolling, exceeds the canvas, or collides with the footer, or when a non-cover slide lacks a visual component or exceeds the prose-length limit.

#### Scenario: Cover slide without a visual component

- **WHEN** 版面檢查遇到沒有圖形元件的封面頁
- **THEN** 不因此判為失敗；其他非封面頁仍要有圖形元件

### Requirement: Layout check resolves playwright from the project

The layout-check step SHALL resolve the playwright runtime from the current project's `node_modules` by default, and SHALL use the location in the `PLAYWRIGHT_FROM` environment variable when it is set.

#### Scenario: Playwright installed elsewhere

- **WHEN** `PLAYWRIGHT_FROM` 指向另一個已安裝 playwright 的目錄
- **THEN** 版面檢查腳本改從該位置載入 playwright
