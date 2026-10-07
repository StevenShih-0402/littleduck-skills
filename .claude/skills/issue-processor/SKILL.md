---
name: issue-processor
description: 依 OpenSpec 提案完成實作：讀交接檔 → 建 <label>/<ISSUE-ID>-<code> 分支 → /opsx:apply → 依 change_template 把任務清單與解決過程回填 Linear。Use when the user invokes /issue-processor with an OpenSpec change name.
---

# Skill: Issue Processor

三段式 Linear → OpenSpec 流程的**第二段**：把 `issue-reader` 產出的提案實作完成，並把實作結果寫回 Linear。

| 階段 | Skill | 呼叫方式 |
|------|-------|----------|
| 1. 讀 issue → 提案 | `issue-reader` | `/issue-reader SDP-99` |
| **2. 實作**（本 skill） | `issue-processor` | `/issue-processor <提案名稱>` |
| 3. 歸檔 + PR | `issue-solver` | `/issue-solver <提案名稱>` |

**呼叫方式**：`/issue-processor ocr-size-limit-and-version-api`

**本 skill 不 commit、不 push、不歸檔**——那是 `issue-solver` 的事。實作完成後工作區會留著未 commit 的變更，這是預期狀態。

**parent / sub-issue 結構**：交接檔的 `issues` 是**主 issue**（最上層），只回頭補 `> 更動摘要` 引言區塊；`# 實作完成` 則**寫在每一張 `sub_issues`**。本階段沒有狀態變化，
兩層都維持 In Progress。

---

## 前置準備

1. **Linear MCP 工具是 deferred**，先載入 schema 才能呼叫：

   ```
   ToolSearch("select:mcp__linear__get_issue,mcp__linear__save_issue")
   ```

   若 Linear MCP 未連線，**中止並請 user 先執行 `/mcp` → `linear` → `Authenticate`**。

2. 讀取 `linear/change_template.md`（**每次都要實際讀檔，不要憑記憶套格式**），步驟 5 回填要用。

3. 確認在專案根目錄（`.mcp.json`、`openspec/`、`pyproject.toml` 所在；greenfield 階段 `pyproject.toml` 可能由本 change 建立）。

---

## 步驟 1：解析參數並讀交接檔

- 參數為 **OpenSpec change 名稱**。沒給就用 `openspec list --json` 列出進行中的 change，
  以 **AskUserQuestion** 讓 user 選，**不要自行猜**。
- 讀 `openspec/changes/<change>/.linear.md` 取得 `issues` / `primary_issue` / `sub_issues` / `code` /
  `label` / `branch` / `stage`。舊格式交接檔沒有 `sub_issues` 欄位時，視同 `-`（無 sub-issue）。

**交接檔不存在時**（例：change 不是由 `/issue-reader` 產生）：

1. 用 **AskUserQuestion** 問 user 對應的 Linear issue 代號與分支前綴（label 轉小寫）；
2. 用 `mcp__linear__get_issue` 確認該 issue 是否有 parent 或 sub-issue：**有 parent 就用
   AskUserQuestion 問 user 要以 parent 還是這張為主 issue**（同 `issue-reader` 步驟 2-1，不要自行決定）；
   有 sub-issue 則把它們填進 `sub_issues`；
3. 依 `issue-reader` 的格式**補寫一份 `.linear.md`**（`stage: proposed`）後再往下走，
   `branch` 一律組成 `<label>/<ISSUE-ID>-<code>`。

**`stage` 已是 `applied` 或 `archived`**：代表這個 change 已跑過本 skill，**停下來回報**並問 user 是要
續作未完成的 tasks 還是重跑，不要默默重來。

## 步驟 2：確認提案完整

- `openspec status --change "<change>" --json` 確認 artifacts 齊全（`proposal` / `design` / `specs` / `tasks`）。
- 有缺就**停下來回報**，建議先回去跑 `/issue-reader` 或 `/opsx:propose`，不要邊實作邊補提案。

## 步驟 3：建分支

**先建分支再改任何檔案**：

```bash
git switch -c <branch>          # 交接檔的 branch，例：feature/SDP-99-version-api
```

- 分支名**必須含 Linear issue ID**（`<label>/<ISSUE-ID>-<code>`）。交接檔的 `branch` 若不合此格式
  （舊格式、手寫的），**先修正交接檔再建分支**——Linear 的 GitHub automation 靠分支名認 issue，
  格式不對就不會在開 PR 時自動轉 In Review。
- 若當前不在 `main` 或工作區不乾淨，**停下來回報**，不要自行 stash 或跨分支帶著改動走。
- 若分支已存在（重跑情境），`git switch <branch>` 切過去即可，並在報告中說明是續作。

## 步驟 4：執行 `/opsx:apply`

執行 `/opsx:apply <change 名稱>`，照該 change 的 `tasks.md` 逐項完成、逐項打勾。

本專案是**單人本機自用的 Python CLI 工具**（`ollama_tools`）：`src/` 佈局、以 `pyproject.toml`
管相依、CLI 走標準庫 `argparse`，**無 CI、無 docker、無 pants、無 monorepo 子專案**。
實作期間遵守 `openspec/changes/<change>/design.md` 的技術決策，幾個最容易踩的：

| 項目 | 規範 |
|------|------|
| 相依管理 | runtime 相依一律加進 `pyproject.toml`（例：`ollama` 套件）；**維持 design 的最小相依原則**——CLI 用 `argparse`（標準庫）、讀 Git 用 `subprocess` 呼 `git log`（**不引 GitPython**），別順手多裝套件。裝相依用 `uv`（`uv add`／`uv sync`） |
| 測試 | 在專案虛擬環境內跑 `pytest`（`uv run pytest`），**不需 docker、不需 pants**。測試要能在**沒有本地 Ollama 服務、沒有 `LINEAR_API_KEY`** 的情況下通過——外部來源（Ollama／Git／Linear）一律 **mock 或以 fixture 注入**，不要在測試裡真的打 `localhost:11434` 或 Linear API |
| 外部服務未就緒 | 本地 Ollama 未啟動、無 Linear token 時，**提示 user 自行處理，不要代為啟動服務或處理憑證**；受此阻擋而無法實機驗證的部分，照 env-blocked 流程註記 |
| lint / format | 跑 `uv run ruff format` + `uv run ruff check`（本專案的 lint 工具）。**只動本次 change 碰到的檔案**，不要對整個 repo 做越界 autofix；`ruff check --fix` 僅在確認範圍限於本次改動時才用 |
| 註解 | 一律**繁體中文** |
| 版本 | 版本號**以 `pyproject.toml` 的 `version` 為單一來源**。change 若含版本 bump，改 `pyproject.toml` 即可；`README.md` / `CHANGELOG.md` **存在時**才同步補一列，**不存在就不要為此新建檔案**（greenfield 階段多半還沒有） |

> greenfield 注意：某項工具（ruff 設定、測試骨架、`pyproject.toml` 的 dev 相依）**若本 change 之前還沒建立**，
> 就依 `tasks.md` 把它一併建起來（這本來就是提案的一部分），不要因為「專案還沒有」就跳過 lint／測試。

若 `tasks.md` 有項目因環境限制做不到（本地 Ollama 未起、無 Linear token、無法實機驗證等），
**在 `tasks.md` 就地註記原因（env-blocked）**，不要默默打勾，也不要因此停掉其餘任務。

## 步驟 5：回填實作結果

依 `linear/change_template.md`，用 `mcp__linear__save_issue` 更新 description。
**有 sub-issue 時，寫入分兩層**（延續 `issue-reader` 步驟 5 的分層）：

| 落點 | 做什麼 |
|------|--------|
| **主 issue**（交接檔 `issues` 每一張） | **只回頭補 analyze 區塊開頭的兩個引言**（`issue-reader` 留的佔位），**不加** `# 實作完成` 區塊 |
| **每一張 sub-issue**（`sub_issues`） | 以水平線 `---` 接在既有內容之後，寫 `# 實作完成（日期）`，內容**只限該 sub-issue 範圍**的任務 |

沒有 sub-issue 的一般 issue：兩件事都做在同一張（`# 實作完成` 接在 question + analyze 之後）。

- `# 實作完成（日期）`：**列出該範圍 `tasks.md` 的內容**（讓閱覽者一眼看出完成了哪些任務，含未完成項
  與原因），清單底下簡短說明更動的範圍與重點。日期用絕對日期。跨多張 sub-issue 的任務寫在最相關那張，
  其餘以代號交叉引用，不要整段複製。
- `> 更動摘要`（主 issue）：人類易讀的重點描述，涵蓋**全部 sub-issue** 的成果。
  sub-issue；確實沒有就寫「無」。

**狀態維持 In Progress**（主 issue 與 sub-issue 皆是）——轉狀態是 `issue-solver` 開 PR 之後的事。

## 步驟 6：更新交接檔

把 `.linear.md` 的 `stage` 改為 `applied`。若步驟 3 實際使用的分支名與交接檔不同，一併更正 `branch`。

---

## 完成後的報告

必須包含：

- change 名稱與對應 issue（有 sub-issue 時說明主 issue 補了哪兩個引言、哪幾張 sub-issue 各自寫了實作完成）
- 分支名（已建立／已切換）
- `tasks.md` 完成度（幾項完成、哪幾項未完成及原因）
- 測試與 lint 的實際結果（**跑了什麼、結果如何；跳過就說跳過**，不要粉飾）
- 已回填的 Linear issue
- **下一步指令**：`/issue-solver <change 名稱>`

---

## 護欄

- **本 skill 到實作 + 回填為止**：不要 `git commit`、不要 `git push`、不要 `/opsx:archive`、不要開 PR。
- **先建分支再改檔案**，絕不在 `main` 上直接實作。
- 遇到「tasks 語意不清」「實作揭露設計問題」→ **停下來回報並建議更新 artifact**，不要靠猜測往下做。
- 對 Linear 的寫入是對外可見的動作：只改 description，**不要順手改 assignee、priority、project、label**。
- **不要把 `# 實作完成` 寫進帶 sub-issue 的主 issue**，也**不要把引言區塊寫進 sub-issue**；
  本階段不動任何 issue 的狀態。
- 若 user 在流程中途要求改變做法，以 user 當下的指示為準，並在最終報告說明偏離了哪一步。