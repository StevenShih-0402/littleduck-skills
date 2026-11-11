## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Only high-severity high-confidence findings recommend a return

The review SHALL recommend 「退回」 only for findings that are both high severity and high confidence; every other finding that holds up SHALL be recommended as 「PR 備註」.

#### Scenario: Medium severity with high confidence

- **WHEN** a finding is medium severity and the reviewer has code evidence for it
- **THEN** its recommended action is 「PR 備註」
