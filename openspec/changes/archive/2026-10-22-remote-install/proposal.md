# Proposal

> 對應 Linear：SDP-70

## Why

目前 `install.sh` 以「腳本所在目錄」作為複製來源，使用者必須先 `git clone` 本 repo、記住 clone 的位置，才能把 skill 裝進其他專案。希望像 Claude Code 一樣，在任何電腦、任何資料夾貼上一行指令就完成安裝或更新；本 repo 已是公開的 GitHub repo（`StevenShih-0402/littleduck-skills`），具備直接從 GitHub 下載的條件。

## What Changes

- `install.sh` 新增**遠端模式**：偵測到腳本旁邊沒有 repo 資產（典型情況是以 `curl … | sh -s -- <選項>` 從 stdin 執行）時，自動從 GitHub 下載 repo 壓縮檔到暫存目錄，以其作為複製來源，安裝完畢後清除暫存檔。
- 提供一行安裝指令：
  `curl -fsSL https://raw.githubusercontent.com/StevenShih-0402/littleduck-skills/main/install.sh | sh -s -- <選項> [目標專案路徑]`
  選項、目標路徑預設值（`$PWD`）、相依展開、`CLAUDE.md` 不覆寫、`agent-team` 只 scaffold 等既有行為完全不變。
- 可用環境變數 `LITTLEDUCK_REF` 指定要下載的分支或 tag（預設 `main`），方便固定版本或測試未合併的分支。
- 下載工具優先 `curl`、其次 `wget`；兩者皆無、或缺少 `tar`、或下載失敗時，印出明確錯誤並以非零狀態結束，不寫入任何目標檔案。
- 從本地 clone 執行（`/path/to/littleduck-skills/install.sh …`）的既有用法不變，不會觸發下載。
- README 改以一行遠端安裝指令為主要用法，本地 clone 用法與 tab 補齊列為進階用法。

本次變更不屬於破壞性變更：既有呼叫方式全部保留，只新增一條入口。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `skill-installer`：新增「無須事先 clone、以一行指令從 GitHub 遠端安裝」的需求（含 ref 指定與下載失敗處理）；「Installer usage is documented」需求擴充為須記載遠端一行安裝指令。

## Impact

- `install.sh`：新增來源解析（本地／遠端）與下載、清理邏輯；其餘安裝流程不動。
- `README.md`：安裝章節改寫。
- 外部依賴：遠端模式需要 `curl` 或 `wget`，以及 `tar`；需能連線 `github.com` / `raw.githubusercontent.com`（`codeload.github.com`）。
- `completions/install.bash`：不變；tab 補齊仍只適用於本地 clone。
