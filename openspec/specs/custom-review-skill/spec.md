# custom-review-skill Specification

## Purpose

提供多 Agent 流程 reviewer（Shiori）的通用審查方法 skill：對照 OpenSpec 規格審查前後端 diff 的需求覆蓋、測試覆蓋、契約一致、邊界與邏輯，並評定內建 `/code-review` 每條發現的嚴重度與信心度；只回報、不修改、不審風格。

## Requirements

### Requirement: Reviewer works from prepared inputs and stops when any is missing

`custom-review` SHALL take from the dispatching prompt, for each affected side: the change directory (`proposal.md`, `tasks.md`, `specs/`, `openapi.yaml`), a prepared diff file of the whole branch against its base, the relevant `CLAUDE.md` files, and the built-in `/code-review` findings for that side (or a marker that there were none). It MUST stop and report when any of these is missing rather than reading the repository's git state itself, because the reviewer is read-only.

#### Scenario: Missing diff file

- **WHEN** the prompt names a change directory but no prepared diff file for that side
- **THEN** the skill stops and reports the missing input without producing a verdict

#### Scenario: No code-review findings supplied

- **WHEN** the prompt states there were no `/code-review` findings for a side
- **THEN** the skill still reviews that side's requirement, test, contract, edge-case and logic coverage

### Requirement: Review checks requirement and test coverage against the change

The review SHALL verify that every acceptance criterion in `proposal.md`, every `### Requirement` / `#### Scenario` in the change's delta specs, and every `tasks.md` item is both implemented in the diff and covered by a test; that the implementation matches `openapi.yaml` (paths, methods, fields, types, status codes) where the change has an API; and that both sides' `openapi.yaml` are identical when the change spans two repositories.

#### Scenario: Scenario without a test

- **WHEN** a delta spec scenario is implemented but no test exercises it
- **THEN** the review records a finding naming that scenario

#### Scenario: Contract drift

- **WHEN** an implemented response field is absent from `openapi.yaml`
- **THEN** the review records a contract finding with the file and line

### Requirement: Review looks for edge-case and logic defects, not style

The review SHALL look for edge cases (null, empty collection, insufficient permission, timezone, concurrency) and logic defects (reversed conditions, missing states, N+1 queries, race conditions). It MUST NOT report code style, naming, or formatting (the linter's job) and MUST NOT report reuse, simplification, or efficiency observations.

#### Scenario: Style issue ignored

- **WHEN** the diff contains an inconsistently named variable but no behavioural defect
- **THEN** the review does not record it as a finding

#### Scenario: Reversed condition found

- **WHEN** a guard clause uses the opposite comparison to what the scenario requires
- **THEN** the review records a high-severity logic finding

### Requirement: Every finding is rated and only strong findings recommend a return

For each finding — its own and each supplied `/code-review` finding — the review SHALL record source (reviewer or `/code-review`), severity (high/medium/low), confidence (high/medium/low), file and line, the corresponding requirement (task id, Requirement › Scenario, or none), a description stating input → wrong result, and a recommended action. It SHALL recommend 「退回」 only for findings that are both high severity and high confidence; all others SHALL be recommended as 「PR 備註」.

#### Scenario: High severity but low confidence

- **WHEN** a finding is high severity but the reviewer has no code evidence for it
- **THEN** its recommended action is 「PR 備註」, not 「退回」

#### Scenario: Code-review finding judged invalid

- **WHEN** a supplied `/code-review` finding does not hold up against the diff
- **THEN** the review marks it invalid with a reason rather than passing it through

### Requirement: Reviewer only reports

`custom-review` MUST NOT modify any file, commit, push, approve, or merge; its output is a per-side findings table handed back for the orchestrator to write into `review.md`.

#### Scenario: Review completes

- **WHEN** the skill finishes a review
- **THEN** no file under either worktree changed and the result is returned as findings for the orchestrator to record
