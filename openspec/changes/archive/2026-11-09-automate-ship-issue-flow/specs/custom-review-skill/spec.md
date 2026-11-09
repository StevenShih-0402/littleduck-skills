# Spec Delta

## MODIFIED Requirements

### Requirement: Reviewer works from prepared inputs and stops when any is missing

`custom-review` SHALL run in one of two modes named by the dispatching prompt. In review mode it SHALL take, for each affected side, the change directory (`proposal.md`, `tasks.md`, `specs/`, `openapi.yaml`), a prepared diff file, and the relevant `CLAUDE.md` files. In rating mode it SHALL take the same inputs plus the `/code-review` and `/security-review` findings per side. It MUST stop and report when any input is missing, because the reviewer is read-only.

#### Scenario: Missing diff file

- **WHEN** the prompt names a change directory but no prepared diff file for that side
- **THEN** the skill stops and reports the missing input without producing a verdict

#### Scenario: No code-review findings supplied

- **WHEN** the prompt names review mode and supplies no `/code-review` findings
- **THEN** the skill still reviews that side's requirement, test, contract, edge-case and logic coverage

#### Scenario: Unknown mode

- **WHEN** the prompt names neither review mode nor rating mode
- **THEN** the skill stops and reports rather than guessing

### Requirement: Every finding is rated and only strong findings recommend a return

For each finding — its own in review mode, and each supplied `/code-review` or `/security-review` finding in rating mode — the review SHALL record source, severity (high/medium/low), confidence (high/medium/low), file and line, the corresponding requirement (task id, Requirement › Scenario, or none), a description stating input → wrong result, and a recommended action. It SHALL recommend 「退回」 only for findings that are both high severity and high confidence; all others SHALL be recommended as 「PR 備註」.

#### Scenario: High severity but low confidence

- **WHEN** a finding is high severity but the reviewer has no code evidence for it
- **THEN** its recommended action is 「PR 備註」, not 「退回」

#### Scenario: Code-review finding judged invalid

- **WHEN** a supplied `/code-review` finding does not hold up against the diff
- **THEN** the review marks it invalid with a reason rather than passing it through

#### Scenario: Security finding rated

- **WHEN** rating mode receives a `/security-review` finding with a concrete exploit path in the diff
- **THEN** the review rates it high severity, and recommends 「退回」 when the confidence is also high

## ADDED Requirements

### Requirement: Later rounds review only new changes

When the prompt supplies earlier review rounds, `custom-review` SHALL review only the diff given for this round, MUST NOT report a finding already recorded in an earlier round (including those marked invalid or not adopted), and SHALL list every occurrence of the same kind of defect in one finding instead of spreading them over rounds.

#### Scenario: Repeated finding suppressed

- **WHEN** an earlier round already recorded a finding at the same place with the same cause
- **THEN** this round does not report it again

#### Scenario: Same defect in several files

- **WHEN** the same wrong call pattern appears in three files of the diff
- **THEN** the review reports one finding that lists all three locations
