# Tasks

> 驗證一律在 scratchpad 的空目錄進行，並以 dash（`sh`）執行；「模擬 pipe」指在該目錄執行 `sh -s -- <參數> < <repo>/install.sh`。

## 1. 便宜檢查前移

- [x] 1.1 調整 `install.sh` 參數處理順序（design D1）：「目標目錄不存在」在取得來源之前就結束；缺選項／`--help`／`--list` 與選項名稱驗證需要可選清單，移到來源確定之後（實作時發現原寫法與既有 spec「缺選項須列出可選清單」衝突，以 spec 為準，design D1 已同步修正）。驗證：本地執行無參數、`--help`、`--list`、`all /no/such/dir`、`no-such-skill` 的輸出與退出碼和 HEAD 版逐字相同；模擬 pipe 且 `PATH` 無 `curl`/`wget` 時，`all /no/such/dir` 報目標不存在而非缺工具

## 2. 遠端來源

- [x] 2.1 實作本地／遠端判定（`REPO_DIR` 下同時有 `install.deps` 與 `.claude/skills/` 才算本地）與遠端下載：`curl -fsSL` 優先、`wget` 次之，下載 `codeload.github.com/StevenShih-0402/littleduck-skills/tar.gz/${LITTLEDUCK_REF:-main}` 到 `mktemp -d` 暫存目錄，先存檔再 `tar -xzf`、各自檢查退出碼，以唯一子目錄作為 `REPO_DIR`（design D2）。驗證：模擬 pipe 跑 `all`，再從本地 clone 對另一個空目錄跑 `all`，兩者 `diff -r` 無差異
- [x] 2.2 以 `trap` 在 `EXIT`／`INT`／`TERM` 清除暫存目錄（design D3）。驗證：成功、下載失敗、選項不合法、SIGPIPE、SIGTERM 中斷後，以專用 `TMPDIR` 確認無殘留（實作時補上 HUP／PIPE trap 與「先設 trap 再 mktemp」）
- [x] 2.3 失敗處理：缺 `curl`/`wget`、缺 `tar`、下載或解壓失敗時印出原因（下載失敗時附本地 clone 的替代用法）並以非零結束。驗證：`LITTLEDUCK_REF=no-such-branch` 與 `PATH` 只含必要指令而缺 `curl`/`wget` 兩種情況都以非零結束，且 `find <目標> -mindepth 1` 無輸出
- [x] 2.4 `LITTLEDUCK_REF` 與輸出訊息（design D4）：遠端時摘要的來源顯示 `github.com/StevenShih-0402/littleduck-skills@<ref>`，`usage` 顯示一行安裝指令格式而非 `sh`。驗證：模擬 pipe 跑 `draw-mermaid`，輸出含 `@main`，目標只出現 `draw-mermaid` skill 與 `CLAUDE.md`；模擬 pipe 跑 `no-such-skill`，印出一行指令格式的用法、可選清單，並以非零結束且目標無檔案
- [x] 2.5 回歸：本地 clone 執行 `draw-mermaid`、`issue-reader`、`all`、`agent-team`、重跑 `all` 的行為與改動前相同（不產生暫存目錄、無巢狀副本）；以 `PATH` 無 `curl`/`wget` 執行本地 `all` 成功且結果與 rsync 版相同，確認本地模式不需下載（本機無 strace）

## 3. 文件

- [x] 3.1 更新 `README.md`：以一行遠端安裝指令為主要用法（單一 skill／`all`／`agent-team` 範例、指定目標路徑時的 `sh -s -- all /path` 寫法）、`LITTLEDUCK_REF` 固定版本、「先下載、檢視再執行」的兩步寫法、所需工具（`curl` 或 `wget`、`tar`）；本地 clone 用法與 tab 補齊移到進階段落並註明補齊只適用本地。驗證：在空 scratchpad 目錄照 README 原文逐條實跑全部 9 條指令（含 `--list`／`--help`／`LITTLEDUCK_REF`／先檢視再執行）皆成功；合併前 raw URL 仍是舊版腳本，以 `curl` 包裝器把 raw `install.sh` 導向工作樹版本、其餘請求走真的 curl（合併後的實機確認見下方 follow-up）
- [x] 3.2 更新 `install.sh` 檔頭的用法註解，加入一行遠端指令與 `LITTLEDUCK_REF` 說明。驗證：`sh -n install.sh` 通過，`--help` 輸出與檔頭描述一致

## Workflow follow-up

- `/issue-processor remote-install` 完成實作並回填 Linear。
- `/issue-solver remote-install` 歸檔、同步 specs、開 PR。
- 合併到 `main` 後，在一台沒有 clone 的環境照 README 用 `curl … | sh -s -- all` 實跑一次，確認 raw URL 上的腳本是新版。
