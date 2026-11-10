# Tasks

## 1. architect 逐案標示關鍵模組

- [x] 1.1 在 `.claude/skills/issue-architect/SKILL.md` 產出 `design.md` 的步驟加入 `## 變異測試目標` 區塊：列本次變更的關鍵模組/路徑（權限、狀態機等），無則寫「無」並說明，且不選工具/指令/閾值；驗證：grep SKILL.md 含「變異測試目標」且文中明示「不選工具/指令/閾值」。
- [x] 1.2 在同一 skill 要求對實作關鍵模組的 `tasks.md` 任務點名為變異測試目標；驗證：SKILL.md 的 tasks 產出說明含該點名規則，且與 `openspec/specs/issue-architect-skill/spec.md` 的 Design designates mutation-test targets 三個 scenario 一致。

## 2. integrator 檢查段執行變異測試並記錄

- [x] 2.1 在 `.claude/skills/issue-integrator/SKILL.md` 的 check 段加入「對 `design.md` 變異測試目標跑變異測試」一項：指令/閾值取自該 repo `CLAUDE.md`、未設定或目標為「無」記 skipped/不適用且不阻斷、低於閾值依既有 counted-return 退回（重現指令＝變異指令）；驗證：grep SKILL.md check 段含變異測試步驟與 skipped/退回兩條分支。
- [x] 2.2 在同一 skill 的 check 段要求把各模組變異結果（分數/是否達閾值/skipped/不適用）寫入 `handoff.md` integrator 區塊與報告；驗證：SKILL.md 明載該記錄落點，且與 `openspec/specs/issue-integrator-skill/spec.md` 的 Mutation testing / Mutation results 兩個 Requirement 全部 scenario 一致。

## 3. team-hq 文件同步

- [x] 3.1 在 `agent-team/CLAUDE.md` 的「層層把關」說明加入變異測試這道關卡（屬 integrator 檢查段、只針對 architect 標示的關鍵模組、指令/閾值來自各 repo `CLAUDE.md`、開發與 reviewer 不跑）；驗證：grep 該檔含變異測試且標明位於 integrator 檢查段。
- [x] 3.2 在 agent-team 的 setup 文件載明「專案以在自身 `CLAUDE.md` 提供變異指令與閾值來啟用，未提供則該檢查 skipped 且不阻斷」；驗證：grep setup 文件含該啟用說明，且與 `openspec/specs/agent-team-kit/spec.md` 的 Team-hq docs place the mutation-testing check 兩個 scenario 一致。

## 4. 規格與整體驗證

- [x] 4.1 執行 `openspec validate mutation-testing-in-agent-flow --strict` 並通過；驗證：指令零錯誤。
- [x] 4.2 比對三份 delta spec 的每個 scenario 是否都在對應 SKILL.md / 文件中有落點，無遺漏；驗證：逐 scenario 對照表無缺口。
