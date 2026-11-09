# agent-team-kit Specification

## Purpose

提供多 Agent 開發工作流（architect / backend / frontend / integrator 四角色）的建置文件與 team-hq 資料夾骨架，讓使用者在新的協作中樞專案一次取得可直接修改的範本。

## Requirements

### Requirement: Agent team kit contents

The repository SHALL provide an agent team kit consisting of: a multi-agent workflow setup document, a team-hq `CLAUDE.md`, five agent definition templates under `.claude/agents/` (architect, backend, frontend, integrator, reviewer), a `/ship-issue` orchestration command under `.claude/commands/`, a write-scope hook script under `.claude/hooks/`, a `handoff.md` template, and a `review.md` template.

#### Scenario: Kit files present in repo

- **WHEN** the repository is checked out
- **THEN** the kit source directory contains the setup document, `CLAUDE.md`, five agent definition files, `ship-issue.md`, `guard-write-scope.sh`, a `handoff.md` template, and a `review.md` template

### Requirement: Kit is project-agnostic

Kit files MUST NOT contain company-specific repository names or absolute personal paths; repository locations SHALL appear as placeholders the user fills in.

#### Scenario: No company bindings remain

- **WHEN** the kit files are searched for `ignsw`, `IngenuityOA`, or `tao_rui_projects`
- **THEN** no matches are found
- **AND** repository paths appear as placeholders such as `<backend-repo>`

### Requirement: Kit does not affect this repo's own Claude Code session

Kit agent and command templates SHALL be stored outside this repo's `.claude/` directory so they are not loaded as active agents or commands when working in this repository.

#### Scenario: Working in this repo

- **WHEN** Claude Code is started at this repository's root
- **THEN** the kit's agent templates are not listed as available agents and `/ship-issue` is not an available command

### Requirement: Kit installs as a scaffold

When installed, kit files SHALL be created at the target root mirroring the team-hq layout, and any kit file that already exists in the target MUST be left unchanged and reported as skipped.

#### Scenario: Fresh scaffold

- **WHEN** the kit is installed into a directory without these files
- **THEN** `CLAUDE.md`, `.claude/agents/*.md`, `.claude/commands/ship-issue.md`, the setup document and the `handoff.md` template are created

#### Scenario: Customized files preserved

- **WHEN** the kit is installed into a directory where `.claude/agents/` already holds an edited agent file of the same name
- **THEN** that file's content is unchanged after install
- **AND** the installer output lists it as skipped

### Requirement: Handoff template carries a status block

The kit's `handoff.md` template SHALL contain a `## 狀態` block whose fields (stage, last completed, next step, pause reason, updated by and when) are edited in place, separate from the append-only per-role log below it. Stage values SHALL be `proposal`, `backend`, `frontend`, `integrating`, `reviewing`, `pr-checking`, `awaiting-approval` or `archived`.

#### Scenario: Template read

- **WHEN** the kit's `handoff-template.md` is read
- **THEN** it contains a `## 狀態` block with the five fields above the append-only log section
- **AND** its stage comment lists `reviewing`, `pr-checking` and `awaiting-approval` between `integrating` and `archived`, and does not list `ready-to-archive`

### Requirement: Backend agent uses backend-processor and the lint hook

The kit's backend agent definition SHALL instruct the agent to run `/backend-processor`, treat the `handoff.md` status block as the source of progress, and register the post-edit lint hook shipped with `backend-processor` as a PostToolUse hook for `Write|Edit`, with the backend repository path as a placeholder.

#### Scenario: Agent definition read

- **WHEN** the kit's backend agent definition is read
- **THEN** it references `/backend-processor` and the hook script path under `<backend-repo>/.claude/skills/backend-processor/hooks/`

### Requirement: Setup document explains installing backend-processor

The kit's setup document SHALL state that `backend-processor` is installed into the backend repository with the installer's single-skill option, and how to register the lint hook outside the agent definition.

#### Scenario: Setup document read

- **WHEN** the setup document's checklist is read
- **THEN** it includes the installer command for `backend-processor` targeting `<backend-repo>`

### Requirement: Architect, frontend and integrator agents use the bundled skills

The kit's architect, frontend and integrator agent definitions SHALL follow `issue-architect`, `frontend-processor` and `issue-integrator` from the team-hq `.claude/skills/`. The frontend definition SHALL register the skill's lint hook as PostToolUse; the architect and integrator definitions SHALL register the write-scope hook as PreToolUse with their role name. Both use matcher `Write|Edit` and paths under `$CLAUDE_PROJECT_DIR`.

#### Scenario: Frontend agent definition read

- **WHEN** the kit's `yuma.md` is read
- **THEN** it references `.claude/skills/frontend-processor/SKILL.md` and the hook `.claude/skills/frontend-processor/hooks/post-edit-lint.sh` under `$CLAUDE_PROJECT_DIR`

#### Scenario: Integrator agent definition read

- **WHEN** the kit's `osamu.md` is read
- **THEN** its frontmatter registers `guard-write-scope.sh osamu` for `Write|Edit` and its body points to `issue-integrator`

### Requirement: Write-scope hook limits architect and integrator writes

The kit's write-scope hook SHALL read the hook JSON from stdin, normalise `tool_input.file_path`, and exit 2 with a reason unless the path is allowed for the given role: for `hyuse`, any path inside an `openspec/` directory; for `osamu`, `handoff.md` or `.linear.md` directly under an active or archived change directory, or any path under `openspec/specs/`. It SHALL exit 0 when the tool call has no file path and exit 2 for an unknown role.

#### Scenario: Architect writes code

- **WHEN** the hook runs as `hyuse` for `src/app/views.py`
- **THEN** it exits 2 and explains that the architect only writes under `openspec/`

#### Scenario: Path traversal

- **WHEN** the hook runs as `hyuse` for `repo/openspec/../src/app.py`
- **THEN** it exits 2

#### Scenario: Integrator edits tasks

- **WHEN** the hook runs as `osamu` for `openspec/changes/eng-1-x/tasks.md`
- **THEN** it exits 2

#### Scenario: Integrator updates the handoff

- **WHEN** the hook runs as `osamu` for `openspec/changes/eng-1-x/handoff.md`
- **THEN** it exits 0

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

### Requirement: Reviewer agent is read-only and follows custom-review

The kit's reviewer agent definition SHALL declare read-only tools (`Read, Grep, Glob` only — no `Write`, `Edit`, `Bash`, or orchestration tools), a reasoning-strong model, and point its body to the `custom-review` skill in the team-hq `.claude/skills/`. The definition SHALL state that the reviewer only reports and never modifies, approves, or merges, and that its findings are written into `review.md` by the orchestrator.

#### Scenario: Reviewer definition read

- **WHEN** the kit's `shiori.md` is read
- **THEN** its frontmatter lists exactly `Read, Grep, Glob` as tools and references `.claude/skills/custom-review/SKILL.md`
- **AND** its body states the reviewer does not write, approve, or merge

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

### Requirement: Review rules are classified across three places

The kit's team-hq `CLAUDE.md` and setup document SHALL document that review rules are placed by nature across three tiers: the linter/formatter, each repo's `CLAUDE.md`, and the `custom-review` skill.

#### Scenario: Classification documented

- **WHEN** the team-hq `CLAUDE.md` is read
- **THEN** it maps mechanical rules to the linter, judgement conventions to repo `CLAUDE.md` plus built-in `/code-review`, and spec coverage to `custom-review`

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
