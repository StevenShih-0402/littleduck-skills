# Spec Delta

## MODIFIED Requirements

### Requirement: Check and archive are separate runs

`issue-integrator` SHALL run exactly one of a check, a finish, an archive, or a merge as stated by the dispatching prompt. In a check run, when all checks pass the skill SHALL set each affected side's stage to `reviewing` and stop so the orchestrator can run the pre-PR review; it MUST NOT recut commits or open PRs in a check run. It MUST NOT archive unless the prompt states the PR checks passed, and for a high-risk change that the user replied 「合併」.

#### Scenario: Archive without approval

- **WHEN** the prompt asks to archive without stating the PR checks passed
- **THEN** the skill stops without archiving

#### Scenario: High-risk archive without approval

- **WHEN** the prompt states the change is high risk but does not state the user replied 「合併」
- **THEN** the skill stops without archiving

#### Scenario: Passing check hands off to review

- **WHEN** a check run passes every check
- **THEN** each affected side's stage is set to `reviewing` and the skill stops without recutting commits or opening a PR

#### Scenario: Unknown run mode

- **WHEN** the prompt names a run mode other than check, finish, archive, or merge
- **THEN** the skill stops and reports rather than guessing

### Requirement: Checks are executed, not trusted

In a check run the skill SHALL stop unless every affected side's stage is `integrating`, then itself run each side's tests, lint, type-check, migrations forward and backward when present (commands from that repo's `CLAUDE.md` or `design.md`), the run verification described in that repo's `CLAUDE.md` when present, and `openspec validate`. It MUST NOT accept a previous agent's report instead, and SHALL ask the user to start any required service that is down.

#### Scenario: Previous agent claimed tests pass

- **WHEN** `handoff.md` says all tests passed
- **THEN** the skill still runs the tests and reports its own result

#### Scenario: Run verification configured

- **WHEN** the repo's `CLAUDE.md` gives a start command and observation points
- **THEN** the skill starts the product, checks each observation point, stops what it started, and fails the check when an observation point does not hold

#### Scenario: Run verification not configured

- **WHEN** the repo's `CLAUDE.md` gives no start command for run verification
- **THEN** the skill records run verification as skipped in `handoff.md` and the report, and does not fail the check for that reason

### Requirement: Passing changes are recut, pushed with lease, and opened as PRs

In a finish run, dispatched only after the pre-PR review has passed, the skill SHALL, per side, record the current HEAD, soft-reset to the merge-base with the base branch passed in (or, when a PR already exists, to the HEAD recorded at the previous finish, so earlier commits keep their SHAs), recommit by feature following `issue-solver`, verify `git diff <old> HEAD` is empty (restoring the old HEAD otherwise), push with `--force-with-lease=<branch>:<old>`, open or reuse a PR against that base, and append the `review.md` PR-note findings to the PR body. It MUST NOT use plain `--force`, and SHALL set each side's stage to `pr-checking`.

#### Scenario: Lease rejected

- **WHEN** the remote branch moved since the recorded HEAD
- **THEN** the push is rejected and the skill stops without retrying with `--force`

#### Scenario: Recut changes content

- **WHEN** the recut tree differs from the old HEAD
- **THEN** the skill resets back to the old HEAD and stops

#### Scenario: Review notes carried into the PR

- **WHEN** `review.md` lists findings marked as PR notes
- **THEN** the opened or reused PR body includes those findings

#### Scenario: Finish after a PR-stage return

- **WHEN** a finish run happens while the PR already exists and `handoff.md` records the previous finish HEAD
- **THEN** only the commits after that HEAD are recut, so the previous finish HEAD stays an ancestor and later review rounds can use it as the start of their range

#### Scenario: Stage after opening the PR

- **WHEN** the finish run opens or reuses both PRs
- **THEN** each side's stage is `pr-checking`

### Requirement: Archive syncs specs and writes back Linear

In an archive run the skill SHALL archive each side at its worktree root via `openspec-archive-change`, choosing to sync specs, validate specs, set the archived `handoff.md` stage to `archived` and `.linear.md` stage to `archived`, commit as `chore(openspec): 歸檔 <change-id>（<ISSUE-ID>）` and push normally, then write back Linear following `issue-processor` and `issue-solver` with separate backend and frontend sections. The archive run SHALL NOT merge.

#### Scenario: Archive completed

- **WHEN** both sides archive successfully
- **THEN** each branch has one additional archive commit pushed without force, and the primary issue's state is left to automation

## ADDED Requirements

### Requirement: Merge run simulates a merge queue

In a merge run, dispatched only after the archive run, the skill SHALL for each side fetch the base, rebase the branch onto the latest base when the base has moved, rerun that side's checks, push with `--force-with-lease`, and wait for the PR's CI to finish. Only after both sides pass SHALL it merge with `gh pr merge --merge`, backend first, then frontend.

#### Scenario: Base moved and checks still pass

- **WHEN** the base gained new commits after the PR was opened and the rebased branch passes its checks and CI
- **THEN** the branch is pushed with lease and merged after the other side has also passed

#### Scenario: Rebase conflict

- **WHEN** the rebase onto the latest base conflicts
- **THEN** the skill aborts the rebase, leaves the branch as it was, merges nothing, and reports the conflicting files

#### Scenario: Checks fail after rebase

- **WHEN** the rebased branch fails a check or CI
- **THEN** nothing is merged, the side is not returned to its developer because the change is already archived, and the skill reports the failure for the user to decide

#### Scenario: Merge run before archive

- **WHEN** the prompt asks to merge but the change directory has not been archived
- **THEN** the skill stops without merging

### Requirement: Merge completes the Linear flow

After a successful merge run, the skill SHALL leave the primary issue's state to the Linear automation and set each sub-issue to the same state as the primary issue. It MUST NOT delete branches or worktrees.

#### Scenario: Sub-issues follow the primary issue

- **WHEN** both PRs are merged and the primary issue moves to its completed state
- **THEN** every sub-issue listed in `.linear.md` is set to that state, and the branches and worktrees still exist
