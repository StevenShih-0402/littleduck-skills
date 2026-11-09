# Tasks

## 1. 前置確認

- [x] 1.1 依 Claude Code 官方文件確認內建 `/security-review` 能否指定目標（路徑／範圍）、能否以 `claude -p` 在指定目錄非互動執行；依 design.md Decisions 5 的優先序選定做法，結論寫進 `ship-issue.md` 的 PR 中檢查段。驗證：`ship-issue.md` 寫明實際採用的呼叫方式與替代方案。
- [x] 1.2 確認 `gh pr checks` 在「沒有任何 check」與「check 失敗」時的輸出與 exit code，並決定等待上限的寫法（`--watch` 搭配逾時）。驗證：`ship-issue.md` 的 CI 段寫明三種結果（全綠、失敗、無 CI）各自的判讀方式。

## 2. `/ship-issue` 改寫（agent-team/.claude/commands/ship-issue.md）

- [x] 2.1 更新 frontmatter description 與開頭說明：拿掉「兩個人工檢查點」，改列「停下條件」清單（design.md Decisions 1）。驗證：`grep -n 檢查點 agent-team/.claude/commands/ship-issue.md` 不再出現「檢查點 1／2」。
- [x] 2.2 改寫提案段：Hyuse 沒有待確認問題時，直接提交 `wip(<ISSUE-ID>): 提案` 並推送，接著派工開發。Hyuse 退回後修完，回到提交步驟而不是檢查點。驗證：對照 delta spec「Orchestration commits the approved proposal and passes parameters」的三個 scenario。
- [x] 2.3 改寫 Osamu 檢查段：通過後若回報免同步聲明，當下用 AskUserQuestion 請 user 逐條確認；不同意就視同檢查失敗退回。驗證：對照 spec-sync-gate delta「Integrator finds an exempted target」。
- [x] 2.4 改寫 PR 前審查段（原 5.5）：只產 patch、派 Shiori「審查模式」、寫 `review.md`。不跑 `/code-review`，移除 shadow mode 與「計數與切換」。第 2 輪起範圍改為 `git diff <上輪 SHA> HEAD`，並把前幾輪 `review.md` 傳給 Shiori。驗證：`grep -n "shadow" ship-issue.md` 無結果；對照 delta「Orchestration runs code review after the integrator check」「Review rounds converge」。
- [x] 2.5 新增 PR 中檢查段（Osamu 收尾開 PR 後）：CI → `/code-review`（effort 明寫，高風險 `high`，禁 `max`/`ultra`/`--fix`/`--comment`）→ 命中高風險樣式時 `/security-review` → 派 Shiori「評定模式」→ 寫 `review.md`、退回或列 PR 備註 → 以 `gh pr comment` 把本輪 PR 備註留言到各端 PR。驗證：對照 delta「Orchestration runs four checks on the opened PR」的四個 scenario。
- [x] 2.6 新增按風險審批段：依 team-hq `CLAUDE.md` 的風險分級判定。高風險時把各端狀態改為 `awaiting-approval` 並 commit／push，向 user 摘要高風險檔案、發現、PR 連結，等回覆「合併」。低／中直接往下。驗證：對照 delta「Orchestration classifies risk and gates only high risk」。
- [x] 2.7 改寫歸檔段與新增合併段：PR 中檢查通過（高風險則已回覆「合併」）後派 Osamu「歸檔」，再派 Osamu「合併」。最終報告包含合併的 PR、風險等級、PR 備註、移除 worktree 的提醒。合併段回報衝突時停下交給 user。驗證：對照 delta「Orchestration archives and merges after the PR checks」。
- [x] 2.8 統一退回計數說明：Osamu 檢查、PR 前審查、CI、PR 中評定、合併隊列共用「同一目標 2 次」上限。驗證：`ship-issue.md` 只有一處定義退回上限，其他段落引用它。

## 3. Integrator（.claude/skills/issue-integrator/SKILL.md、agent-team/.claude/agents/osamu.md）

- [x] 3.1 檢查段新增執行驗證：讀 repo `CLAUDE.md` 的「## 執行驗證」，依序啟動、就緒檢查、逐一驗證觀察點、停止。沒有這一段就在 `handoff.md` 與報告記「略過」。驗證：對照 delta「Checks are executed, not trusted」的兩個執行驗證 scenario。
- [x] 3.2 收尾段把階段改設 `pr-checking`；PR 已存在時只重切上次收尾 HEAD 之後的 commit，並把本次收尾 HEAD 記進 `handoff.md`（增量審查的起點），回報對象改為「主對話進行 PR 中檢查」，刪除檢查點 2 的字樣。驗證：`grep -n "ready-to-archive\|檢查點" .claude/skills/issue-integrator/SKILL.md` 無結果。
- [x] 3.3 歸檔段前置條件改為「prompt 寫明 PR 檢查已通過；高風險時另寫明 user 已回覆合併」（合併隊列失敗改為停下交給 user，不會再回到歸檔）。驗證：對照 delta「Check and archive are separate runs」的 scenario。
- [x] 3.4 新增 D 段「合併」：確認已歸檔 → 各端 fetch、需要時 rebase 並 `--force-with-lease` 推送 → 重跑檢查 → 等 CI → 兩端都綠才先後端、再前端合併（合併方式取 team-hq `CLAUDE.md`，預設 `--merge`）→ sub-issue 狀態同步主 issue。rebase 衝突就 `git rebase --abort` 並停下；rebase 後檢查或 CI 失敗也停下交給 user，不退回開發者（change 已歸檔）。驗證：對照 delta「Merge run simulates a merge queue」「Merge completes the Linear flow」的所有 scenario。
- [x] 3.5 改寫護欄：允許 `--force-with-lease` 的情境加上合併段的 rebase；「不 merge PR」改為「只在 D 段 merge，禁止 `--admin` 與繞過失敗的檢查」；不刪分支與 worktree。驗證：護欄段逐條對應 design.md Decisions 9。
- [x] 3.6 更新 `osamu.md` 的 description、tools（確認有 `mcp__linear__save_issue` 可同步 sub-issue 狀態）、邊界與回報，反映「檢查／收尾／歸檔／合併」四段。驗證：`grep` 確認 description 含四段名稱，且邊界段寫明 merge 的前置條件。

## 4. Reviewer（.claude/skills/custom-review/SKILL.md、agent-team/.claude/agents/shiori.md）

- [x] 4.1 `custom-review` 加入兩種模式：審查模式（規格＋patch，不含 `/code-review` 發現）、評定模式（再加 `/code-review` 與 `/security-review` 發現，只評級不重審）。不明模式就停下。驗證：對照 custom-review-skill delta 的 scenario。
- [x] 4.2 `custom-review` 加入收斂規則：只審本輪給的 diff、不重提前幾輪已記錄的發現、同類問題一次列出所有位置。驗證：對照 delta「Later rounds review only new changes」。
- [x] 4.3 更新 `shiori.md`：開工參數加入「模式」與「前幾輪 review.md」，刪除「不取代檢查點 2」，改為「不核准、不合併；高風險由 user 審批」。驗證：`grep -n 檢查點 agent-team/.claude/agents/shiori.md` 無結果。

## 5. 範本與架構師用語

- [x] 5.1 改寫 `agent-team/openspec/review-template.md`：每輪記錄階段（PR 前／PR 中）、範圍（含已審到的 SHA）、實際執行的審查指令、`/security-review` 是否適用、發現表（拿掉「user 判定」欄）、結果；移除 shadow 相關說明。驗證：對照 delta「Review template records each round」。
- [x] 5.2 改寫 `agent-team/openspec/handoff-template.md` 的階段註解與可選值：`… → reviewing → pr-checking → awaiting-approval → archived`，移除 `ready-to-archive`。驗證：對照 delta「Handoff template carries a status block」。
- [x] 5.3 更新 `.claude/skills/issue-architect/SKILL.md` 的狀態區塊用語：下一步改為「等待主對話提交提案」，不再寫「等待檢查點 1 核准」。驗證：`grep -n 檢查點 .claude/skills/issue-architect/SKILL.md` 無結果。

## 6. 文件同步

- [x] 6.1 更新 `agent-team/CLAUDE.md`：交接規則（無固定檢查點、階段清單、共用退回上限）、審查規則三分法（`/code-review` 移到 PR 中）、移除 shadow mode、新增「風險分級」表、合併方式與 CI 等待上限設定、說明各 repo `CLAUDE.md` 的「## 執行驗證」格式。驗證：`grep -n "shadow\|檢查點" agent-team/CLAUDE.md` 無結果，且含風險分級表。
- [x] 6.2 更新 `agent-team/docs/multi-agent-workflow.md`：目標與流程圖改成新流程（依 `draw-mermaid` 準則重畫並渲染驗證）、檢查點與風險表、Phase 4／5 的完成標準、範本重點表、既有 team-hq 的升級步驟。驗證：文件不再出現「檢查點 1／2」，mermaid 以 `render.sh` 渲染成功。
- [x] 6.3 更新 `spec-sync/README.md`：多 Agent 流程的免同步聲明改為 Osamu 檢查後由主對話當下確認。驗證：`grep -n 檢查點 spec-sync/README.md` 無結果。
- [x] 6.4 更新 `README.md`：agent-team 敘述改為全自動流程（PR 前兩檢查、PR 中四檢查、高風險審批、合併隊列），並加入既有 team-hq 的升級注意事項。驗證：README 提到升級時要先移除舊骨架檔。

## 7. 整合驗證

- [x] 7.1 掃描本次修改的 kit 與 skill 檔，確認沒有專屬字串或個人絕對路徑。驗證：`grep -rEi 'ignsw|IngenuityOA|tao_rui_projects|/home/steven' agent-team .claude/skills/issue-integrator .claude/skills/custom-review` 無輸出。
- [x] 7.2 對空目錄跑 `install.sh agent-team <tmp>`，確認新版 `ship-issue.md`、`osamu.md`、`shiori.md`、兩份範本都到位，且裝出來的檔案沒有「檢查點」「shadow」殘留。驗證：安裝輸出與 grep 結果。
- [x] 7.3 `openspec validate automate-ship-issue-flow --strict` 通過。

## Workflow follow-up

- 實作完成後依 `issue-solver` 做規格漏寫檢查、`/opsx:archive` 同步規格並歸檔、切 commit、push、開 PR。
- 建議另開 issue：審核題庫評分與誤報率統計（Anthropic 的審查優化）；合併後的功能開關、逐步上線、觀察與回滾準則寫進 `CLAUDE.md`。
