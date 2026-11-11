# Proposal

## Why

`install.sh` 的 `agent-team-fullstack`／`agent-team-single-side` 骨架是「同名檔不存在才建立」。專案改過 Agent 名稱後（例：`hikaru`／`yasumi`、`gintoki`／`kagura`），重跑 installer 時 `.claude/agents/hyuse.md`、`chika.md` 等範本檔名都不存在，於是又被建立一次，專案同時有兩套 Agent。SDP-108 實作時已實際發生，當時靠手動刪除與文件提醒處理；本變更（SDP-126）從 installer 根本解決。

## What Changes

- 安裝 kit 時，若目標專案的 `.claude/agents/` **在安裝前**已有任何 Agent 定義（`*.md`，不論檔名），就不建立任何範本名稱的 Agent 定義，並在輸出逐檔說明略過原因。
- `.claude/agents/` 不存在、或裡面沒有 `*.md` 時（第一次安裝），照舊建立全部範本 Agent 定義。
- 其他骨架檔（`ship-issue.md`、hook、範本、`CLAUDE.md`、文件）維持「同名檔不存在才建立」，行為不變。
- `tests/install.test.sh` 補「改名後重跑不會多出範本 Agent」與「`.claude/agents/` 為空時照舊建立」的情境。
- README 與兩份 kit 的 `CLAUDE.md`、`docs/multi-agent-workflow.md` 中「重跑後要手動刪除範本名稱定義檔」的提醒，改為描述新行為。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `agent-team-kit`：新增「目標已有 Agent 定義時不建立範本 Agent 定義」的需求；既有「Kit installs as a scaffold」的同名檔略過行為不變。

## Impact

- 程式：`install.sh` 的 `install_kit`。
- 測試：`tests/install.test.sh`。
- 文件：`README.md`、`agent-team-fullstack/CLAUDE.md`、`agent-team-single-side/CLAUDE.md`、兩份 `docs/multi-agent-workflow.md`。
- 相容性：已安裝 kit 的專案重跑時只會「少建立」檔案，不會覆寫或刪除任何既有檔案；無 API 影響。
