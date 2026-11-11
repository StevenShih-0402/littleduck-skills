# custom-review-skill Specification

## Purpose

提供多 Agent 流程 reviewer 的通用審查方法 skill：對照 OpenSpec 規格審查 diff 的需求覆蓋、測試覆蓋、契約一致、邊界與邏輯，並評定內建 `/code-review` 每條發現的嚴重度與信心度；只回報、不修改、不審風格。

## Requirements

### Requirement: Reviewer works from prepared inputs and stops when any is missing

`custom-review` SHALL run in one of two modes named by the dispatching prompt. In review mode it SHALL take the change directory (`proposal.md`, `tasks.md`, `specs/`, `openapi.yaml`), one prepared diff file, and the repository `CLAUDE.md`. In rating mode it SHALL take the same inputs plus the `/code-review` and `/security-review` findings. It MUST stop and report when any input is missing, because the reviewer is read-only.

#### Scenario: Missing diff file

- **WHEN** the prompt names a change directory but no prepared diff file
- **THEN** the skill stops and reports the missing input without producing a verdict

#### Scenario: No code-review findings supplied

- **WHEN** the prompt names review mode and supplies no `/code-review` findings
- **THEN** the skill still reviews requirement, test, contract, edge-case and logic coverage

#### Scenario: Unknown mode

- **WHEN** the prompt names neither review mode nor rating mode
- **THEN** the skill stops and reports rather than guessing

### Requirement: Review checks requirement and test coverage against the change

The review SHALL verify that every acceptance criterion in `proposal.md`, every `### Requirement` / `#### Scenario` in the change's delta specs, and every `tasks.md` item is both implemented in the diff and covered by a test; and that the implementation matches `openapi.yaml` (paths, methods, fields, types, status codes) on both the backend and the frontend side where the change has an API. Each finding SHALL name the side (`[BE]` or `[FE]`) it belongs to.

#### Scenario: Scenario without a test

- **WHEN** a delta spec scenario is implemented but no test exercises it
- **THEN** the review records a finding naming that scenario and its side

#### Scenario: Contract drift

- **WHEN** an implemented response field is absent from `openapi.yaml`
- **THEN** the review records a contract finding with the file and line

#### Scenario: Frontend uses a field the contract lacks

- **WHEN** a fullstack diff has frontend code reading a response field that `openapi.yaml` does not define
- **THEN** the review records a `[FE]` contract finding with the file and line

### Requirement: Review looks for edge-case and logic defects, not style

The review SHALL look for edge cases (null, empty collection, insufficient permission, timezone, concurrency) and logic defects (reversed conditions, missing states, N+1 queries, race conditions). It MUST NOT report code style, naming, or formatting (the linter's job) and MUST NOT report reuse, simplification, or efficiency observations.

#### Scenario: Style issue ignored

- **WHEN** the diff contains an inconsistently named variable but no behavioural defect
- **THEN** the review does not record it as a finding

#### Scenario: Reversed condition found

- **WHEN** a guard clause uses the opposite comparison to what the scenario requires
- **THEN** the review records a high-severity logic finding

### Requirement: Every finding is rated and only strong findings recommend a return

For each finding — its own in review mode, and each supplied `/code-review` or `/security-review` finding in rating mode — the review SHALL record source, severity (high/medium/low), confidence (high/medium/low), file and line, the corresponding requirement (task id, Requirement › Scenario, or none), a description stating input → wrong result, and a recommended action.

#### Scenario: High severity but low confidence

- **WHEN** a finding is high severity but the reviewer has no code evidence for it
- **THEN** its recommended action is 「PR 備註」, not 「退回」

#### Scenario: Code-review finding judged invalid

- **WHEN** a supplied `/code-review` finding does not hold up against the diff
- **THEN** the review marks it invalid with a reason rather than passing it through

#### Scenario: Security finding rated

- **WHEN** rating mode receives a `/security-review` finding with a concrete exploit path in the diff
- **THEN** the review rates it high severity, and recommends 「退回」 when the confidence is also high

### Requirement: Reviewer only reports

`custom-review` MUST NOT modify any file, commit, push, approve, or merge; its output is a per-side findings table handed back for the orchestrator to write into `review.md`.

#### Scenario: Review completes

- **WHEN** the skill finishes a review
- **THEN** no file under either worktree changed and the result is returned as findings for the orchestrator to record

### Requirement: Later rounds review only new changes

When the prompt supplies earlier review rounds, `custom-review` SHALL review only the diff given for this round, MUST NOT report a finding already recorded in an earlier round (including those marked invalid or not adopted), and SHALL list every occurrence of the same kind of defect in one finding instead of spreading them over rounds.

#### Scenario: Repeated finding suppressed

- **WHEN** an earlier round already recorded a finding at the same place with the same cause
- **THEN** this round does not report it again

#### Scenario: Same defect in several files

- **WHEN** the same wrong call pattern appears in three files of the diff
- **THEN** the review reports one finding that lists all three locations

### Requirement: Only high-severity high-confidence findings recommend a return

The review SHALL recommend 「退回」 only for findings that are both high severity and high confidence; every other finding that holds up SHALL be recommended as 「PR 備註」.

#### Scenario: Medium severity with high confidence

- **WHEN** a finding is medium severity and the reviewer has code evidence for it
- **THEN** its recommended action is 「PR 備註」
