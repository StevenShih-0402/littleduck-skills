# Spec Delta

## MODIFIED Requirements

### Requirement: Check and archive are separate runs

`issue-integrator` SHALL run exactly one of a check, a finish, or an archive as stated by the dispatching prompt. In a check run, when all checks pass the skill SHALL set each affected side's stage to `reviewing` and stop so the orchestrator can run code review; it MUST NOT recut commits or open PRs in a check run. It MUST NOT archive unless the prompt states the user replied 「歸檔」.

#### Scenario: Archive without approval

- **WHEN** the prompt asks to archive without stating the user approved
- **THEN** the skill stops without archiving

#### Scenario: Passing check hands off to review

- **WHEN** a check run passes every check
- **THEN** each affected side's stage is set to `reviewing` and the skill stops without recutting commits or opening a PR

#### Scenario: Unknown run mode

- **WHEN** the prompt names a run mode other than check, finish, or archive
- **THEN** the skill stops and reports rather than guessing

### Requirement: Passing changes are recut, pushed with lease, and opened as PRs

In a finish run, dispatched only after code review has passed, the skill SHALL, per side, record the current HEAD, soft-reset to the merge-base with the base branch passed in, recommit by feature following `issue-solver`, verify `git diff <old> HEAD` is empty (restoring the old HEAD otherwise), push with `--force-with-lease=<branch>:<old>`, open or reuse a PR against that base, and append the `review.md` PR-note findings to the PR body. It MUST NOT use plain `--force`, and SHALL set each side's stage to `ready-to-archive`.

#### Scenario: Lease rejected

- **WHEN** the remote branch moved since the recorded HEAD
- **THEN** the push is rejected and the skill stops without retrying with `--force`

#### Scenario: Recut changes content

- **WHEN** the recut tree differs from the old HEAD
- **THEN** the skill resets back to the old HEAD and stops

#### Scenario: Review notes carried into the PR

- **WHEN** `review.md` lists findings marked as PR notes
- **THEN** the opened or reused PR body includes those findings
