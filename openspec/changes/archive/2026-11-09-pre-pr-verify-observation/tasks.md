# Tasks

## 1. 前置確認

- [x] 1.1 實際跑一次格式範例的截圖指令（`npx playwright screenshot …`，或 gen-story 已用的 chromium）對一個本機頁面截圖。確認三件事：產出的 PNG 能用 Read 開啟；指令不存在時的 exit code 與錯誤訊息；連線被拒時的錯誤訊息。據此寫定 design.md Decisions 3 的「工具不可用」和「產品問題」怎麼區分。驗證：把三種情況的實際 exit code 與訊息關鍵字寫進 `issue-integrator` A2，不寫猜測值。

## 2. Integrator（.claude/skills/issue-integrator/SKILL.md、agent-team/.claude/agents/osamu.md）

- [x] 2.1 改寫 A2 執行驗證：觀察點來源改成「repo `CLAUDE.md`＋本 change `design.md` 的 `## 執行驗證觀察點`」，報告分開列；repo 沒有執行驗證段時兩者都略過。驗證：對照 delta「Change-specific observation points in design.md」「Run verification not configured」。
- [x] 2.2 A2 新增截圖觀察點：用 `mktemp -d` 建暫存目錄、把 `{out}` 換成 `<暫存目錄>/<side>-<序號>.png`、Read 看圖，依「符合／明顯不符／無法確定／工具不可用」四種結果處置；退回時重現步驟寫截圖指令。暫存目錄路徑寫進 `handoff.md`。驗證：對照 delta 四個 Screenshot scenario，逐一確認 SKILL.md 有對應的處置文字。
- [x] 2.3 確認 A3 的報告格式（`handoff.md`「integrator — 檢查通過」一節）與 D 段重跑都涵蓋截圖結果與風險項；把「無法確定」的截圖列進回報主對話的風險清單。驗證：`grep -n "截圖" .claude/skills/issue-integrator/SKILL.md` 在 A2、A5（報告）、D 段都有命中。
- [x] 2.4 更新 `osamu.md`：邊界加一條「截圖指令寫入 worktree 外的暫存目錄，不算改檔；不可寫進 worktree」；回報段加「截圖觀察點結果（含略過與風險）」。驗證：`grep -n "截圖" agent-team/.claude/agents/osamu.md` 有命中邊界與回報兩處。

## 3. Architect（.claude/skills/issue-architect/SKILL.md、agent-team/.claude/agents/hyuse.md）

- [x] 3.1 在 `issue-architect` 步驟 3 新增「design.md：執行驗證觀察點」小節：每端一節 `## 執行驗證觀察點`，格式同 repo `CLAUDE.md`；只寫本次行為、預期描述要點名具體元素；沒有可觀察行為寫「無」與理由；repo 沒設定執行驗證時照寫並列為待確認問題。結束時回報加一項「執行驗證觀察點數（各端）」。驗證：對照 issue-architect-skill delta 三個 scenario。
- [x] 3.2 更新 `hyuse.md` 邊界與回報，提到 design.md 要有執行驗證觀察點。驗證：`grep -n "觀察點" agent-team/.claude/agents/hyuse.md` 有命中。

## 4. 文件（agent-team/CLAUDE.md、agent-team/docs/multi-agent-workflow.md、README.md）

- [x] 4.1 改寫 `agent-team/CLAUDE.md`「執行驗證」格式：加入截圖觀察點範例（含等待參數、`{out}` 佔位），刪掉「只寫終端機觀察得到的行為」，補注意事項（需要登入的頁面、headless 瀏覽器要先安裝、截圖存在 worktree 外）。驗證：格式範例的截圖指令與 1.1 實測過的指令一致。
- [x] 4.2 更新 `docs/multi-agent-workflow.md`：setup 清單的執行驗證項補「可加截圖觀察點」；升級指引補「既有 team-hq 手動更新 `CLAUDE.md` 執行驗證段」。README 的 integrator／architect 敘述視需要補「截圖」「觀察點」。驗證：`grep -n "截圖" agent-team/docs/multi-agent-workflow.md` 在 setup 與升級兩處都有命中。

## 5. 整合檢查

- [x] 5.1 執行 `openspec validate pre-pr-verify-observation --strict`，並逐條核對兩份 delta spec 的每個 scenario 在 SKILL.md 都找得到對應文字。驗證：validate 通過，核對清單無遺漏。
- [x] 5.2 用 `grep -rn "只寫終端機" agent-team .claude` 確認舊說法已全部移除；用 `grep -rn "觀察點" .claude/skills agent-team` 確認 architect、integrator、CLAUDE.md 三處用同一個節名 `## 執行驗證觀察點`。驗證：第一個 grep 無結果，第二個的節名一致。

## Workflow follow-up

- `/issue-solver pre-pr-verify-observation`：歸檔同步規格、開 PR。
