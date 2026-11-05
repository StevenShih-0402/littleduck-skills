# Spec Delta

## MODIFIED Requirements

### Requirement: Agent team kit contents

The repository SHALL provide an agent team kit consisting of: a multi-agent workflow setup document, a team-hq `CLAUDE.md`, five agent definition templates under `.claude/agents/` (architect, backend, frontend, integrator, reviewer), a `/ship-issue` orchestration command under `.claude/commands/`, a write-scope hook script under `.claude/hooks/`, a `handoff.md` template, and a `review.md` template.

#### Scenario: Kit files present in repo

- **WHEN** the repository is checked out
- **THEN** the kit source directory contains the setup document, `CLAUDE.md`, five agent definition files, `ship-issue.md`, `guard-write-scope.sh`, a `handoff.md` template, and a `review.md` template

### Requirement: Handoff template carries a status block

The kit's `handoff.md` template SHALL contain a `## 狀態` block whose fields (stage, last completed, next step, pause reason, updated by and when) are edited in place, separate from the append-only per-role log below it. Stage values SHALL be `proposal`, `backend`, `frontend`, `integrating`, `reviewing`, `ready-to-archive` or `archived`.

#### Scenario: Template read

- **WHEN** the kit's `handoff-template.md` is read
- **THEN** it contains a `## 狀態` block with the five fields above the append-only log section
- **AND** its stage comment lists `reviewing` and `ready-to-archive` between `integrating` and `archived`

### Requirement: Orchestration commits the approved proposal and passes parameters

The kit's `/ship-issue` command SHALL resolve every user decision (primary issue, code, label, branch, change-id, affected repos) before dispatching, pass each agent the parameters its skill expects, and, when the user approves the proposal, commit only `openspec/changes/<change-id>` in each affected worktree as `wip(<ISSUE-ID>): 提案核准` and push it before dispatching development agents. Change-ids SHALL be lowercase.

#### Scenario: Proposal approved

- **WHEN** the user replies 「核准」 at checkpoint 1
- **THEN** each affected worktree has a pushed commit containing only the change directory, and its `git status --porcelain` is empty before the backend or frontend agent starts

#### Scenario: Integrator dispatched

- **WHEN** `/ship-issue` dispatches the integrator
- **THEN** the prompt contains the change-id, both worktree paths, both base branches and whether this run is 「檢查」, 「收尾」 or 「歸檔」

## ADDED Requirements

### Requirement: Reviewer agent is read-only and follows custom-review

The kit's reviewer agent definition SHALL declare read-only tools (`Read, Grep, Glob` only — no `Write`, `Edit`, `Bash`, or orchestration tools), a reasoning-strong model, and point its body to the `custom-review` skill in the team-hq `.claude/skills/`. The definition SHALL state that the reviewer only reports and never modifies, approves, or merges, and that its findings are written into `review.md` by the orchestrator.

#### Scenario: Reviewer definition read

- **WHEN** the kit's `shiori.md` is read
- **THEN** its frontmatter lists exactly `Read, Grep, Glob` as tools and references `.claude/skills/custom-review/SKILL.md`
- **AND** its body states the reviewer does not write, approve, or merge

### Requirement: Review template records each round

The kit SHALL provide a `review.md` template that records one section per review round, each carrying the round's mode, scope, the `/code-review` command run, a findings table, and the round result.

#### Scenario: Review template read

- **WHEN** the kit's `review-template.md` is read
- **THEN** it contains a per-round section with the mode, scope, `/code-review` command, a findings table including severity, confidence and a user-judgement column, and a result line

### Requirement: Orchestration runs code review after the integrator check

After the integrator check passes and before the finish phase, `/ship-issue` SHALL, per affected side, prepare a git-ignored `review-diff.patch`, run the built-in `/code-review`, dispatch the reviewer with the change directory and the `/code-review` findings, and write every finding into `review.md`.

#### Scenario: Review scope prepared for a read-only reviewer

- **WHEN** `/ship-issue` dispatches the reviewer
- **THEN** a `review-diff.patch` exists for each side, is listed in `.gitignore`, is never committed, and is passed to the reviewer, because the reviewer cannot read git diffs itself

#### Scenario: Code-review effort bounded

- **WHEN** `/ship-issue` runs the built-in `/code-review` for a side
- **THEN** it raises the effort level when high-risk files from the configurable pattern list are present, and never uses `max`/`ultra`, `--fix`, or `--comment`

#### Scenario: Built-in code-review is not shadowed

- **WHEN** the kit is installed
- **THEN** no skill named `code-review` is created that would replace the built-in command and its effort/`--fix`/`ultra` options

#### Scenario: High-severity high-confidence finding returns

- **WHEN** a review round records a finding that is both high severity and high confidence
- **THEN** that side's stage goes back to `backend` or `frontend`, the return is counted together with the integrator check returns under the same per-target limit of 2, and a third such return stops for the user instead

#### Scenario: Shadow mode reports without returning

- **WHEN** the run is within the first N shadow-mode issues
- **THEN** review findings are recorded for the user to judge at checkpoint 2 and no automatic return happens
- **AND** after N issues the user is asked whether to switch to auto-return

### Requirement: Review rules are classified across three places

The kit's team-hq `CLAUDE.md` and setup document SHALL document that review rules are placed by nature across three tiers: the linter/formatter, each repo's `CLAUDE.md`, and the `custom-review` skill.

#### Scenario: Classification documented

- **WHEN** the team-hq `CLAUDE.md` is read
- **THEN** it maps mechanical rules to the linter, judgement conventions to repo `CLAUDE.md` plus built-in `/code-review`, and spec coverage to `custom-review`
