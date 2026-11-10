<!-- docs/remote-control.md -->
<!-- Claude Code Remote Control 的啟動、手機端操作與限制說明（SDP-112） -->

# Remote Control：用手機監看與派任務

Remote Control 讓手機的 Claude app（或 claude.ai/code）連到本機的 Claude Code。Claude 與所有指令都在這台電腦上執行，手機只負責顯示畫面和送出訊息。

本 repo 用 `.claude/scripts/remote-control.sh` 把 server 掛在背景的 tmux 裡。關掉終端機 server 也會繼續執行，手機隨時可以看進度、開新 session 派任務。同一支腳本也放在 code_city、littleduck-skills、littleduck_website、luke、mygo_v2_anon。

## 前置條件

| 項目 | 需求 |
|------|------|
| 帳號 | 用 claude.ai 訂閱帳號登入（Pro／Max／Team／Enterprise）。API key 不行。用 `claude auth status` 確認 `authMethod` 是 `claude.ai` |
| 組織設定 | Team／Enterprise 需要 Owner 在 claude.ai 的 Claude Code 管理設定開啟 Remote Control（預設關閉） |
| 套件 | `tmux`（`sudo apt install tmux`）、Claude Code CLI |
| 環境變數 | 不能設 `ANTHROPIC_API_KEY`、`ANTHROPIC_AUTH_TOKEN`、`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`、`DISABLE_GROWTHBOOK`。`ANTHROPIC_BASE_URL` 只能不設，或指向 `https://api.anthropic.com` |

腳本的 `start` 會逐項檢查上面的條件，不符時列出全部問題並結束，不會啟動 server。組織設定無法在本機檢查，沒開的話手機上會看不到 session。

## 首次啟動

```bash
.claude/scripts/remote-control.sh start    # 在背景 tmux（rc-littleduck-skills）啟動 server
.claude/scripts/remote-control.sh attach   # 接回畫面
```

接回畫面後：

1. 第一次在這個 repo 啟動時，會問 `Enable Remote Control? (y/n)`，回答 `y`。如果這個資料夾還沒信任過，也會先問是否信任。
2. 按空白鍵顯示 QR code，用手機掃描就會開啟 Claude app 並連上。之後在 app 的 Code 分頁就看得到名為 `littleduck-skills` 的 session。
3. 按 `Ctrl-b` 再按 `d` 離開 tmux。server 會繼續在背景執行。

## 日常操作

| 指令 | 作用 |
|------|------|
| `.claude/scripts/remote-control.sh` 或 `… start` | 啟動。已在執行時只會提示，不會重複啟動 |
| `… status` | 執行中印出「執行中」，結束碼為 0；沒執行時結束碼為 1 |
| `… stop` | 先送 Ctrl-C 讓 server 正常結束，5 秒內沒結束就強制關掉 tmux session |
| `… attach` | 接回畫面。如果已經在 tmux 裡，會改成切換過去 |

在 repo 的任何子目錄執行都可以，腳本會自動找到 repo 根目錄。

## 手機端操作

- **看進度**：在 app 的 Code 分頁點進 `littleduck-skills` 的 session，可以看到即時輸出、git 變更的 diff，以及 subagent／workflow 的進度。
- **派新任務**：在 `littleduck-skills` 底下開新 session。新 session 在 repo 根目錄執行，跟在終端機開 `claude` 一樣，可以直接輸入任務或 slash command。
- **權限提示**：手機開的 session 預設用 `auto` 權限模式，由 auto mode 判斷哪些動作要問你。需要確認時，提示會推播到手機，在手機上回答即可。權限提示和 AskUserQuestion 會一直等你回答，不會逾時。
- **切換權限模式**：手機上可以切到 Manual、Accept edits 或 Plan，但不能切到 bypass permissions。

## 建議開啟的使用者層設定

下面這些設定存在 `~/.claude/settings.json`，腳本不會動，需要的話自己開：

- 在任一 session 執行 `/config`，打開 **Push when actions required**（需要你確認時推播）與 **Push when Claude decides**。
- 如果希望平常在終端機開的互動 session 也自動連上手機，在 `/config` 把 **Enable Remote Control for all sessions** 設為 `true`（對應設定 `remoteControlAtStartup`）。這個設定寫在專案的 `.claude/settings.json` 會被忽略，只有使用者層有效。

## 限制

- **電腦要保持開機和連線**：Windows 睡眠或 WSL2 斷網時，session 會離線。電腦醒著但離線約 10 分鐘，server 會自己結束，tmux session 也一起消失，這時 `status` 會回報未執行，重新執行 `start` 即可。
- **接回剛停掉的 session**：server 停止後約 4 小時內，可以手動執行 `claude remote-control --continue` 接回原本的 session（腳本沒有包這個功能）。
- **資料流向**：本機只往外連（HTTPS 443），不開任何對外的 port。檔案留在本機，但連線期間的對話內容和工具輸出（可能包含檔案內容）會存在 Anthropic 的伺服器。
- **一個 repo 一個 server**：tmux session 名稱固定為 `rc-<repo 目錄名>`。在 `wt/` 下的 worktree 執行時，會用 worktree 的目錄名另外開一個 server。

官方文件：<https://code.claude.com/docs/en/remote-control.md>
