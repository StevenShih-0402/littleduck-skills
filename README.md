# littleduck-skills

可重複使用的 Claude Code skills 集中 repo，並提供一行指令讓其他專案安裝／更新這些 skill。

## 內含資產

- `.claude/skills/` — 所有 skill：
  - `issue-reader` / `issue-processor` / `issue-solver` — 三段式 Linear → OpenSpec 流程
  - `openspec-*` — OpenSpec 提案／實作／歸檔／同步
  - `gen-html` — 用單檔 HTML 產生架構圖、流程圖、比較表等
- `.claude/commands/` — `opsx` 等 slash 指令
- `linear/` — Linear 回填模板（question / analyze / change）

## 安裝 / 更新到其他專案

在你的目標專案根目錄執行（指向本 repo 的 `install.sh`）：

```sh
/path/to/littleduck-skills/install.sh
```

或明確指定目標專案路徑：

```sh
/path/to/littleduck-skills/install.sh /path/to/your-project
```

未給路徑時預設安裝到目前工作目錄（`$PWD`）。腳本會把本 repo 的下列資產同步進目標專案：

| 來源（本 repo） | 目標專案 |
|------|------|
| `.claude/skills/` | `<專案>/.claude/skills/` |
| `.claude/commands/` | `<專案>/.claude/commands/` |
| `linear/` | `<專案>/linear/` |

**可重複執行**：再跑一次即就地更新到最新版本，不會產生重複或巢狀副本。缺少的目標目錄會自動建立。

> 注意：安裝會以本 repo 的版本覆寫目標專案中同名的受管資產，請勿在目標專案直接修改這些檔案。
