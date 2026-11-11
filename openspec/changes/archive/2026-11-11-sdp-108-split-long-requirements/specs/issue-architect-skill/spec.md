## MODIFIED Requirements

### Requirement: Tasks are tagged by side and design carries diagrams

Every task line SHALL start with `[BE]` or `[FE]`, all in the one `tasks.md`. In `fullstack`, `[BE]` tasks SHALL come before the `[FE]` tasks that depend on them, because developers run in that order; in `single-side`, every task SHALL carry the declared side's tag.

#### Scenario: Untagged task

- **WHEN** the skill drafts a task without a side tag
- **THEN** it is not written that way; every line in `tasks.md` begins with its tag

#### Scenario: Single-side frontend project

- **WHEN** the repository declares `結構: single-side` and `端: frontend`
- **THEN** every task in `tasks.md` begins with `[FE]`

## ADDED Requirements

### Requirement: Design carries data-flow and sequence diagrams

`design.md` SHALL contain at least one data-flow `flowchart` and one front/back `sequenceDiagram`, drawn after loading `draw-mermaid`; a change without front/back interaction MAY omit the sequence diagram only when `design.md` states why.

#### Scenario: Change without front/back interaction

- **WHEN** a single-side change has no front/back interaction
- **THEN** `design.md` still has a data-flow `flowchart`, and either a sequence diagram or a stated reason for omitting it
