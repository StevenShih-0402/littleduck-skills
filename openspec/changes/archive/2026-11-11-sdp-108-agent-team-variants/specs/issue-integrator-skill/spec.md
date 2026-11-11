## MODIFIED Requirements

### Requirement: Check and archive are separate runs

`issue-integrator` SHALL run exactly one of a check, a finish, an archive, or a merge as stated by the dispatching prompt. In a check run, when all checks pass the skill SHALL set the stage to `reviewing` and stop so the orchestrator can run the pre-PR review; it MUST NOT recut commits or open a PR in a check run. It MUST NOT archive unless the prompt states the PR checks passed, and for a high-risk change that the user replied 「合併」.

#### Scenario: Archive without approval

- **WHEN** the prompt asks to archive without stating the PR checks passed
- **THEN** the skill stops without archiving

#### Scenario: High-risk archive without approval

- **WHEN** the prompt states the change is high risk but does not state the user replied 「合併」
- **THEN** the skill stops without archiving

#### Scenario: Passing check hands off to review

- **WHEN** a check run passes every check
- **THEN** the stage is set to `reviewing` and the skill stops without recutting commits or opening a PR

#### Scenario: Unknown run mode

- **WHEN** the prompt names a run mode other than check, finish, archive, or merge
- **THEN** the skill stops and reports rather than guessing

### Requirement: Checks are executed, not trusted

In a check run the skill SHALL stop unless the stage is `integrating`, then itself run, for each affected side inside its declared subdirectory, the tests, lint, type-check and migrations forward and backward when present (commands from the repository `CLAUDE.md` or `design.md`), the run verification described in the repository `CLAUDE.md` when present, and `openspec validate`. It MUST NOT accept a previous agent's report instead, and SHALL ask the user to start any required service that is down.

#### Scenario: Previous agent claimed tests pass

- **WHEN** `handoff.md` says all tests passed
- **THEN** the skill still runs the tests and reports its own result

#### Scenario: Fullstack checks per subdirectory

- **WHEN** a fullstack change affects both sides with backend subdirectory `backend/` and frontend subdirectory `frontend/`
- **THEN** the backend commands run in `backend/`, the frontend commands run in `frontend/`, and a failure is returned to the agent of the side whose command failed

#### Scenario: Run verification configured

- **WHEN** the repository `CLAUDE.md` gives a start command and observation points
- **THEN** the skill starts the product, checks each observation point, stops what it started, and fails the check when an observation point does not hold

#### Scenario: Run verification not configured

- **WHEN** the repository `CLAUDE.md` gives no start command for run verification
- **THEN** the skill records run verification as skipped in `handoff.md` and the report, and does not fail the check for that reason

#### Scenario: Change-specific observation points in design.md

- **WHEN** run verification is configured and `design.md` lists observation points for this change
- **THEN** the skill checks those points in the same run as the repository's own points, and lists each one's result separately in `handoff.md` and the report

#### Scenario: Screenshot observation point matches

- **WHEN** an observation point gives a screenshot command and an expected screen, and the screenshot taken while the product runs clearly shows the expected screen
- **THEN** the point passes, and the screenshot is saved outside the worktree so it is never committed

#### Scenario: Screenshot clearly does not match

- **WHEN** the screenshot shows a blank page, an error page, or lacks an element the expected screen names
- **THEN** the check fails and returns to the developer agent of the side that owns the screen, with the screenshot command as the reproduction step

#### Scenario: Screenshot result uncertain

- **WHEN** the skill cannot tell from the screenshot whether the expected screen is shown
- **THEN** the point does not fail the check, and the skill records it as a risk in `handoff.md` with the screenshot path so the pre-PR review can see it

#### Scenario: Screenshot tool unavailable

- **WHEN** the screenshot command is not installed or its browser cannot start in this environment
- **THEN** the skill records that point as skipped with the error message, and does not fail the check for that reason

### Requirement: Consistency checks

The check SHALL verify that `tasks.md` has no unchecked items except annotated env-blocked ones, `openapi.yaml` matches the implemented routes, the worktree is clean and level with its remote branch, breaking changes keep the old endpoint, `proposal.md` was not changed by developers, and the spec sync gate passes as described in `spec-sync-gate`.

#### Scenario: Contract mismatch

- **WHEN** an implemented route's response field is absent from `openapi.yaml`
- **THEN** the check fails, names the route and field, and returns to the backend agent

### Requirement: Failures are returned with a counted reason

On any failure the skill SHALL append an integrator section to `handoff.md` with the return count, target agent role, reason and reproduction command, set the stage back to `backend`, `frontend` or `proposal` according to the target, commit only `handoff.md`, push, and report whom to return to. When the count for the same target would exceed 2 it SHALL instead report that the user must decide. It MUST NOT fix code itself.

#### Scenario: Third failure

- **WHEN** the backend has already been returned twice and fails again
- **THEN** the skill does not return it a third time and reports the three reasons for the user

### Requirement: Passing changes are recut, pushed with lease, and opened as PRs

In a finish run, dispatched only after the pre-PR review has passed, the skill SHALL record the current HEAD, soft-reset to the merge-base with the base branch passed in (or, when the PR already exists, to the HEAD recorded at the previous finish, so earlier commits keep their SHAs), recommit by feature following `issue-solver`, verify `git diff <old> HEAD` is empty (restoring the old HEAD otherwise), push with `--force-with-lease=<branch>:<old>`, open or reuse one PR against that base, and append the `review.md` PR-note findings to the PR body. It MUST NOT use plain `--force`, and SHALL set the stage to `pr-checking`.

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

- **WHEN** the finish run opens or reuses the PR
- **THEN** the stage is `pr-checking` and exactly one PR exists for the branch

### Requirement: Archive syncs specs and writes back Linear

In an archive run the skill SHALL archive the change at the worktree root via `openspec-archive-change`, choosing to sync specs, validate specs, set the archived `handoff.md` stage to `archived` and `.linear.md` stage to `archived`, commit as `chore(openspec): 歸檔 <change-id>（<ISSUE-ID>）` and push normally, then write back Linear following `issue-processor` and `issue-solver`, with separate backend and frontend sections when both sides are affected. The archive run SHALL NOT merge.

#### Scenario: Archive completed

- **WHEN** the change archives successfully
- **THEN** the branch has one additional archive commit pushed without force, and the primary issue's state is left to automation

### Requirement: Merge run simulates a merge queue

In a merge run, dispatched only after the archive run, the skill SHALL fetch the base, rebase the branch onto the latest base when the base has moved, rerun the checks of every affected side, push with `--force-with-lease`, and wait for the PR's CI to finish. Only after all of these pass SHALL it merge the one PR with `gh pr merge --merge` (or the configured merge method).

#### Scenario: Base moved and checks still pass

- **WHEN** the base gained new commits after the PR was opened and the rebased branch passes its checks and CI
- **THEN** the branch is pushed with lease and the PR is merged

#### Scenario: Rebase conflict

- **WHEN** the rebase onto the latest base conflicts
- **THEN** the skill aborts the rebase, leaves the branch as it was, merges nothing, and reports the conflicting files

#### Scenario: Checks fail after rebase

- **WHEN** the rebased branch fails a check or CI
- **THEN** nothing is merged, no developer is returned to because the change is already archived, and the skill reports the failure for the user to decide

#### Scenario: Merge run before archive

- **WHEN** the prompt asks to merge but the change directory has not been archived
- **THEN** the skill stops without merging

### Requirement: Merge completes the Linear flow

After a successful merge run, the skill SHALL leave the primary issue's state to the Linear automation and set each sub-issue to the same state as the primary issue. It MUST NOT delete branches or worktrees.

#### Scenario: Sub-issues follow the primary issue

- **WHEN** the PR is merged and the primary issue moves to its completed state
- **THEN** every sub-issue listed in `.linear.md` is set to that state, and the branch and worktree still exist

### Requirement: Mutation testing verifies tests on designated critical modules

In a check run the skill SHALL run mutation testing on the modules or paths listed under `design.md` `## 變異測試目標`, using the mutation command and pass threshold from the repository `CLAUDE.md`, and MUST NOT trust a previous agent's mutation report.

#### Scenario: Surviving mutants below threshold

- **WHEN** a designated module's mutation score is below the repository's threshold
- **THEN** the check fails and the side owning that module is returned to its developer with the mutation command as the reproduction step, counted under the same per-target return limit

#### Scenario: Mutation command not configured

- **WHEN** the repository `CLAUDE.md` documents no mutation-testing command
- **THEN** the skill records mutation testing as skipped in `handoff.md` and the report, and does not fail the check for that reason

#### Scenario: No critical modules designated

- **WHEN** `design.md` `## 變異測試目標` reads 「無」
- **THEN** the skill records mutation testing as not applicable and runs none

#### Scenario: Previous agent claimed the tests are strong

- **WHEN** `handoff.md` states the tests already pass mutation testing
- **THEN** the skill still runs mutation testing itself and reports its own result

### Requirement: Mutation results are recorded in the hand-off

In a check run the skill SHALL record each designated module's mutation outcome — surviving mutants or score, whether it met the threshold, or that it was skipped or not applicable — in the `handoff.md` integrator section and in the check report.

#### Scenario: Result written back

- **WHEN** mutation testing runs against a designated module
- **THEN** that module's score and threshold verdict appear in the `handoff.md` integrator section and the check report
