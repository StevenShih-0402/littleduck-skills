## ADDED Requirements

### Requirement: Check and archive are separate runs

`issue-integrator` SHALL run either a check or an archive as stated by the dispatching prompt, and MUST NOT archive unless the prompt states the user replied 「歸檔」.

#### Scenario: Archive without approval

- **WHEN** the prompt asks to archive without stating the user approved
- **THEN** the skill stops without archiving

### Requirement: Checks are executed, not trusted

In a check run the skill SHALL stop unless every affected side's stage is `integrating`, then itself run each side's tests, lint, type-check, migrations forward and backward when present (commands from that repo's `CLAUDE.md` or `design.md`) and `openspec validate`. It MUST NOT accept a previous agent's report instead, and SHALL ask the user to start any required service that is down.

#### Scenario: Previous agent claimed tests pass

- **WHEN** `handoff.md` says all tests passed
- **THEN** the skill still runs the tests and reports its own result

### Requirement: Consistency checks

The check SHALL verify that both `tasks.md` have no unchecked items except annotated env-blocked ones, both `openapi.yaml` files are identical and match the implemented routes, `.linear.md` files agree apart from `stage`, both worktrees are clean and level with their remote branch, breaking changes keep the old endpoint, `proposal.md` was not changed by developers, and the spec sync gate passes as described in `spec-sync-gate`.

#### Scenario: Contract mismatch

- **WHEN** the frontend `openapi.yaml` differs from the backend one
- **THEN** the check fails and names the differing lines

### Requirement: Failures are returned with a counted reason

On any failure the skill SHALL append an integrator section to the failing side's `handoff.md` with the return count, target agent, reason and reproduction command, set that side's stage back to `backend`, `frontend` or `proposal`, commit only that `handoff.md`, push, and report whom to return to. When the count for the same target would exceed 2 it SHALL instead report that the user must decide. It MUST NOT fix code itself.

#### Scenario: Third failure

- **WHEN** the backend has already been returned twice and fails again
- **THEN** the skill does not return it a third time and reports the three reasons for the user

### Requirement: Passing changes are recut, pushed with lease, and opened as PRs

When all checks pass the skill SHALL, per side, record the current HEAD, soft-reset to the merge-base with the base branch passed in, recommit by feature following `issue-solver`, verify `git diff <old> HEAD` is empty (restoring the old HEAD otherwise), push with `--force-with-lease=<branch>:<old>`, and open or reuse a PR against that base. It MUST NOT use plain `--force`, and SHALL set the stage note to 「等待 user 回覆歸檔」.

#### Scenario: Lease rejected

- **WHEN** the remote branch moved since the recorded HEAD
- **THEN** the push is rejected and the skill stops without retrying with `--force`

#### Scenario: Recut changes content

- **WHEN** the recut tree differs from the old HEAD
- **THEN** the skill resets back to the old HEAD and stops

### Requirement: Archive syncs specs and writes back Linear

In an archive run the skill SHALL archive each side at its worktree root via `openspec-archive-change`, choosing to sync specs, validate specs, set the archived `handoff.md` stage to `archived` and `.linear.md` stage to `archived`, commit as `chore(openspec): 歸檔 <change-id>（<ISSUE-ID>）` and push normally, then write back Linear following `issue-processor` and `issue-solver` with separate backend and frontend sections.

#### Scenario: Archive completed

- **WHEN** both sides archive successfully
- **THEN** each branch has one additional archive commit pushed without force, and the primary issue's state is left to automation
