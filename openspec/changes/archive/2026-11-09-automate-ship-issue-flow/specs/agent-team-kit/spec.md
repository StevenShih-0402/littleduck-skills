# Spec Delta

## MODIFIED Requirements

### Requirement: Handoff template carries a status block

The kit's `handoff.md` template SHALL contain a `## 狀態` block whose fields (stage, last completed, next step, pause reason, updated by and when) are edited in place, separate from the append-only per-role log below it. Stage values SHALL be `proposal`, `backend`, `frontend`, `integrating`, `reviewing`, `pr-checking`, `awaiting-approval` or `archived`.

#### Scenario: Template read

- **WHEN** the kit's `handoff-template.md` is read
- **THEN** it contains a `## 狀態` block with the five fields above the append-only log section
- **AND** its stage comment lists `reviewing`, `pr-checking` and `awaiting-approval` between `integrating` and `archived`, and does not list `ready-to-archive`

### Requirement: Orchestration commits the approved proposal and passes parameters

The kit's `/ship-issue` command SHALL resolve every user decision (primary issue, code, label, branch, change-id, affected repos) before dispatching, pass each agent the parameters its skill expects, and, once the architect reports no open questions, commit only `openspec/changes/<change-id>` in each affected worktree as `wip(<ISSUE-ID>): 提案` and push it before dispatching development agents, without waiting for a proposal approval. Change-ids SHALL be lowercase.

#### Scenario: Proposal approved

- **WHEN** the architect returns with no open questions
- **THEN** each affected worktree has a pushed commit containing only the change directory, and its `git status --porcelain` is empty before the backend or frontend agent starts
- **AND** the orchestrator does not stop to ask the user to approve the proposal

#### Scenario: Architect has open questions

- **WHEN** the architect returns with open questions
- **THEN** the orchestrator asks the user, passes the answers back to the architect, and commits the proposal only after no open questions remain

#### Scenario: Integrator dispatched

- **WHEN** `/ship-issue` dispatches the integrator
- **THEN** the prompt contains the change-id, both worktree paths, both base branches and whether this run is 「檢查」, 「收尾」, 「歸檔」 or 「合併」

### Requirement: Review template records each round

The kit SHALL provide a `review.md` template that records one section per review round, each carrying the round's stage (before the PR or on the PR), scope, the review commands run, a findings table, and the round result. The template MUST NOT carry a shadow-mode field or a user-judgement column.

#### Scenario: Review template read

- **WHEN** the kit's `review-template.md` is read
- **THEN** it contains a per-round section with the stage, scope, review commands, a findings table including severity, confidence and handling, and a result line
- **AND** it has no 「user 判定」 column and no shadow-mode field

### Requirement: Orchestration runs code review after the integrator check

After the integrator check passes and before the finish phase, `/ship-issue` SHALL, per affected side, prepare a git-ignored `review-diff.patch`, dispatch the reviewer with the change directory and the patch to review requirement and test coverage against the spec, and write every finding into `review.md`. The built-in `/code-review` MUST NOT run in this pre-PR review; it runs on the PR instead.

#### Scenario: Review scope prepared for a read-only reviewer

- **WHEN** `/ship-issue` dispatches the reviewer before the PR
- **THEN** a `review-diff.patch` exists for each side, is listed in `.gitignore`, is never committed, and is passed to the reviewer, because the reviewer cannot read git diffs itself

#### Scenario: Built-in code-review is not shadowed

- **WHEN** the kit is installed
- **THEN** no skill named `code-review` is created that would replace the built-in command and its effort/`--fix`/`ultra` options

#### Scenario: High-severity high-confidence finding returns

- **WHEN** a review round records a finding that is both high severity and high confidence
- **THEN** that side's stage goes back to `backend` or `frontend`, the return is counted together with the integrator check returns and the PR check returns under the same per-target limit of 2, and a third such return stops for the user instead

#### Scenario: Code-review effort bounded

- **WHEN** `/ship-issue` runs the pre-PR review
- **THEN** it does not run the built-in `/code-review`; effort rules for `/code-review` apply only to the PR checks

#### Scenario: Shadow mode reports without returning

- **WHEN** any issue runs through `/ship-issue`, including the first ones after installation
- **THEN** there is no shadow mode: findings that are both high severity and high confidence return immediately, and no finding waits for a user judgement

#### Scenario: Weaker findings become PR notes

- **WHEN** a review round records findings that are not both high severity and high confidence
- **THEN** they are marked 「PR 備註」, no return happens, and the flow continues without asking the user

## ADDED Requirements

### Requirement: Orchestration has no fixed user checkpoints

`/ship-issue` SHALL run from the proposal through the merge without stopping for a fixed user checkpoint. It SHALL stop for the user only when a question cannot be resolved from the issue or code, a return limit is exceeded, a merge conflict or other blocker occurs, a spec-sync exemption needs confirmation, or the change is classified high risk.

#### Scenario: Low-risk issue runs end to end

- **WHEN** a low-risk issue passes every pre-PR and PR check on the first try
- **THEN** `/ship-issue` opens the PR, archives, and merges without asking the user anything after the initial parameters

#### Scenario: Spec-sync exemption needs confirmation

- **WHEN** the integrator check passes only because `handoff.md` declares a spec-sync exemption
- **THEN** the orchestrator asks the user to confirm each exemption before continuing, and sends the side back to its developer when the user rejects one

### Requirement: Orchestration runs four checks on the opened PR

After the integrator opens the PR, `/ship-issue` SHALL, per affected side: wait for the PR's CI checks to finish; run the built-in `/code-review` on the branch range; run the built-in `/security-review` when the diff matches a high-risk file pattern; and have the reviewer rate every `/code-review` and `/security-review` finding. Findings SHALL be recorded in `review.md` and posted to the PR as one comment.

#### Scenario: CI fails

- **WHEN** a required PR check fails
- **THEN** the failure is recorded as a return to that side's developer, counted under the shared per-target limit

#### Scenario: Repository has no CI

- **WHEN** the PR reports no checks
- **THEN** the run records that CI was skipped and continues

#### Scenario: PR code-review effort bounded

- **WHEN** `/ship-issue` runs the built-in `/code-review` for a side
- **THEN** it states the effort level explicitly, raises it to `high` when high-risk files are present, and never uses `max`/`ultra`, `--fix`, or `--comment`

#### Scenario: Security review skipped for ordinary changes

- **WHEN** no changed path matches a high-risk file pattern
- **THEN** `/security-review` is not run and `review.md` records it as not applicable

### Requirement: Orchestration classifies risk and gates only high risk

After the PR checks pass, `/ship-issue` SHALL classify the change as low, medium, or high risk using the criteria in team-hq `CLAUDE.md`. Low and medium SHALL continue automatically. High SHALL set the stage to `awaiting-approval`, report the high-risk files, findings and PR links, and continue only after the user replies 「合併」.

#### Scenario: High-risk change waits

- **WHEN** the change touches a file matching a high-risk pattern
- **THEN** the orchestrator stops and does not dispatch the archive or merge until the user replies 「合併」

#### Scenario: Medium-risk change continues

- **WHEN** the change is classified medium risk
- **THEN** the orchestrator records the classification and dispatches the archive without asking the user

### Requirement: Review rounds converge

From the second review round of a change, `/ship-issue` SHALL limit the reviewer and `/code-review` to the changes made since the last reviewed commit, and SHALL pass the earlier rounds' findings so that the same finding is not reported again. The reviewer SHALL report all occurrences of the same kind of defect in one round.

#### Scenario: Second round after a return

- **WHEN** a developer fixes a returned finding and the change is reviewed again
- **THEN** the review scope is the diff from the last reviewed commit to the new head, and findings already recorded in earlier rounds are not reported again

### Requirement: Orchestration archives and merges after the PR checks

When the PR checks pass and any required high-risk approval is given, `/ship-issue` SHALL dispatch the integrator to archive and then to merge. Merging SHALL happen in backend-then-frontend order, and the run SHALL end with a report of the merged PRs, the risk level, the PR notes and a reminder to remove the worktrees.

#### Scenario: Both sides merge

- **WHEN** the archive succeeds and both sides pass the simulated merge queue
- **THEN** the backend PR is merged before the frontend PR and the user receives one final report

#### Scenario: Merge blocked

- **WHEN** the integrator reports a rebase conflict or a check failure during the merge run
- **THEN** the orchestrator stops and reports to the user without merging the remaining side
