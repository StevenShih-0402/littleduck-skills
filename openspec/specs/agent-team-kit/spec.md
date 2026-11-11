# agent-team-kit Specification

## Purpose

提供多 Agent 開發工作流（architect、開發、integrator、reviewer）的兩種單一 repo 骨架與導入文件：fullstack（一個 repo 同時有前後端）與 single-side（一個 repo 只有一端、一個開發 Agent），讓專案從 repo 根目錄一次取得可直接修改的範本。

## Requirements

### Requirement: Agent team kit contents

Each kit variant SHALL consist of: a multi-agent workflow setup document, a `CLAUDE.md` template carrying the `## agent-team 設定` section, agent definition templates under `.claude/agents/`, a `/ship-issue` orchestration command under `.claude/commands/`, a write-scope hook script under `.claude/hooks/`, a `handoff.md` template, and a `review.md` template.

#### Scenario: Kit files present in repo

- **WHEN** the repository is checked out
- **THEN** each of `agent-team-fullstack/` and `agent-team-single-side/` contains the setup document, `CLAUDE.md`, its agent definition files, `ship-issue.md`, `guard-write-scope.sh`, a `handoff.md` template, and a `review.md` template

### Requirement: Kit is project-agnostic

Kit files MUST NOT contain company-specific repository names or absolute personal paths; subdirectories, base branch and worktree root SHALL appear as placeholders or defaults in the `## agent-team 設定` section, and kit files MUST NOT assume separate frontend, backend or team-hq repositories.

#### Scenario: No company bindings remain

- **WHEN** the kit files are searched for `ignsw`, `IngenuityOA`, or `tao_rui_projects`
- **THEN** no matches are found

#### Scenario: No multi-repository wording remains

- **WHEN** the kit files and role skills are searched for 「前端 repo」, 「後端 repo」 or `team-hq`
- **THEN** no matches are found

### Requirement: Kit does not affect this repo's own Claude Code session

Kit agent and command templates SHALL be stored outside this repo's `.claude/` directory so they are not loaded as active agents or commands when working in this repository.

#### Scenario: Working in this repo

- **WHEN** Claude Code is started at this repository's root
- **THEN** the kit's agent templates are not listed as available agents and `/ship-issue` is not an available command

### Requirement: Kit installs as a scaffold

When installed, kit files SHALL be created at the target repository root, and any kit file that already exists in the target MUST be left unchanged and reported as skipped.

#### Scenario: Fresh scaffold

- **WHEN** a kit is installed into a directory without these files
- **THEN** `CLAUDE.md`, `.claude/agents/*.md`, `.claude/commands/ship-issue.md`, `.claude/hooks/guard-write-scope.sh`, the setup document and the `handoff.md` template are created

#### Scenario: Customized files preserved

- **WHEN** a kit is installed into a directory where `.claude/agents/` already holds an edited agent file of the same name
- **THEN** that file's content is unchanged after install
- **AND** the installer output lists it as skipped

### Requirement: Agent templates are skipped when the target already defines agents

When a kit is installed and the target's `.claude/agents/` already contains at least one agent definition (`*.md`, any file name) before the install starts, the installer MUST NOT create any of the kit's agent definition templates, and SHALL report each template it did not create together with the reason. Other kit files keep the skip-if-present behaviour.

#### Scenario: Re-run after renaming agents

- **WHEN** a kit was installed, every agent definition in `.claude/agents/` was renamed (for example `hyuse.md` to `hikaru.md`), and the same kit selection is run again
- **THEN** no agent definition with a template file name (such as `hyuse.md` or `chika.md`) is created
- **AND** the renamed agent definitions are unchanged
- **AND** the installer output lists each template agent definition as skipped because `.claude/agents/` already has agent definitions

#### Scenario: Agents directory missing or empty

- **WHEN** a kit is installed into a target whose `.claude/agents/` does not exist or contains no `*.md` file
- **THEN** every agent definition template of that kit is created

#### Scenario: Other scaffold files still created when absent

- **WHEN** a kit is run again on a target that has renamed agent definitions but no `.claude/commands/ship-issue.md`
- **THEN** `.claude/commands/ship-issue.md` is created

### Requirement: Handoff template carries a status block

The kit's `handoff.md` template SHALL contain a `## 狀態` block whose fields (stage, last completed, next step, pause reason, updated by and when) are edited in place, separate from the append-only per-role log below it. Stage values SHALL be `proposal`, `backend`, `frontend`, `integrating`, `reviewing`, `pr-checking`, `awaiting-approval` or `archived`.

#### Scenario: Template read

- **WHEN** the kit's `handoff-template.md` is read
- **THEN** it contains a `## 狀態` block with the five fields above the append-only log section
- **AND** its stage comment lists `reviewing`, `pr-checking` and `awaiting-approval` between `integrating` and `archived`, and does not list `ready-to-archive`

### Requirement: Backend agent uses backend-processor and the lint hook

The fullstack kit's backend agent definition SHALL instruct the agent to run `/backend-processor` inside the declared backend subdirectory, treat the `handoff.md` status block as the source of progress, and register the post-edit lint hook shipped with `backend-processor` as a PostToolUse hook and the write-scope hook with role `backend` as a PreToolUse hook, both for `Write|Edit` with paths under `$CLAUDE_PROJECT_DIR`.

#### Scenario: Agent definition read

- **WHEN** the fullstack kit's backend agent definition is read
- **THEN** it references `/backend-processor`, the hook `$CLAUDE_PROJECT_DIR/.claude/skills/backend-processor/hooks/post-edit-lint.sh`, and `guard-write-scope.sh backend`
- **AND** it contains no `<backend-repo>` placeholder

### Requirement: Setup document explains installing backend-processor

Each kit's setup document SHALL state that `backend-processor` is installed together with the other role skills at the repository root by the kit's installer option, and that no `.claude/` directory may be created inside the backend or frontend subdirectory because duplicated skills would load.

#### Scenario: Setup document read

- **WHEN** the setup document's checklist is read
- **THEN** it gives the installer command for the kit's option and does not ask for a separate `backend-processor` install into another repository

### Requirement: Architect, frontend and integrator agents use the bundled skills

The kits' architect, frontend (or single-side developer) and integrator agent definitions SHALL follow `issue-architect`, the side's processor skill and `issue-integrator` from the repository's `.claude/skills/`. The developer definitions SHALL register the processor skill's lint hook as PostToolUse; the architect and integrator definitions SHALL register the write-scope hook as PreToolUse with their role name. All use matcher `Write|Edit` and paths under `$CLAUDE_PROJECT_DIR`.

#### Scenario: Frontend agent definition read

- **WHEN** the fullstack kit's frontend agent definition is read
- **THEN** it references `.claude/skills/frontend-processor/SKILL.md`, the hook `.claude/skills/frontend-processor/hooks/post-edit-lint.sh` under `$CLAUDE_PROJECT_DIR`, and `guard-write-scope.sh frontend`

#### Scenario: Integrator agent definition read

- **WHEN** a kit's integrator agent definition is read
- **THEN** its frontmatter registers `guard-write-scope.sh integrator` for `Write|Edit` and its body points to `issue-integrator`

### Requirement: Write-scope hook limits architect and integrator writes

The kit's write-scope hook SHALL read the hook JSON from stdin, normalise `tool_input.file_path`, and exit 2 with a reason unless the path is allowed for the given role: for `architect`, any path inside an `openspec/` directory; for `integrator`, `handoff.md` or `.linear.md` directly under an active or archived change directory, or any path under `openspec/specs/`. It SHALL exit 0 when the tool call has no file path and exit 2 for an unknown role.

#### Scenario: Architect writes code

- **WHEN** the hook runs as `architect` for `src/app/views.py`
- **THEN** it exits 2 and explains that the architect only writes under `openspec/`

#### Scenario: Path traversal

- **WHEN** the hook runs as `architect` for `repo/openspec/../src/app.py`
- **THEN** it exits 2

#### Scenario: Integrator edits tasks

- **WHEN** the hook runs as `integrator` for `openspec/changes/eng-1-x/tasks.md`
- **THEN** it exits 2

#### Scenario: Integrator updates the handoff

- **WHEN** the hook runs as `integrator` for `openspec/changes/eng-1-x/handoff.md`
- **THEN** it exits 0

### Requirement: Orchestration commits the approved proposal and passes parameters

The kit's `/ship-issue` command SHALL resolve every user decision (primary issue, code, label, branch, change-id, affected sides) before dispatching, pass each agent the parameters its skill expects, and, once the architect reports no open questions, commit only `openspec/changes/<change-id>` in the worktree as `wip(<ISSUE-ID>): 提案` and push it before dispatching development agents, without waiting for a proposal approval. Change-ids SHALL be lowercase.

#### Scenario: Proposal approved

- **WHEN** the architect returns with no open questions
- **THEN** the worktree has a pushed commit containing only the change directory, and its `git status --porcelain` is empty before a developer agent starts
- **AND** the orchestrator does not stop to ask the user to approve the proposal

#### Scenario: Architect has open questions

- **WHEN** the architect returns with open questions
- **THEN** the orchestrator asks the user, passes the answers back to the architect, and commits the proposal only after no open questions remain

#### Scenario: Integrator dispatched

- **WHEN** `/ship-issue` dispatches the integrator
- **THEN** the prompt contains the change-id, the worktree path, the base branch and whether this run is 「檢查」, 「收尾」, 「歸檔」 or 「合併」

### Requirement: Reviewer agent is read-only and follows custom-review

The kits' reviewer agent definition SHALL declare read-only tools (`Read, Grep, Glob` only — no `Write`, `Edit`, `Bash`, or orchestration tools), a reasoning-strong model, and point its body to the `custom-review` skill in the repository's `.claude/skills/`. The definition SHALL state that the reviewer only reports and never modifies, approves, or merges, and that its findings are written into `review.md` by the orchestrator.

#### Scenario: Reviewer definition read

- **WHEN** a kit's reviewer agent definition is read
- **THEN** its frontmatter lists exactly `Read, Grep, Glob` as tools and references `.claude/skills/custom-review/SKILL.md`
- **AND** its body states the reviewer does not write, approve, or merge

### Requirement: Review template records each round

The kit SHALL provide a `review.md` template that records one section per review round, each carrying the round's stage (before the PR or on the PR), scope, the review commands run, a findings table, and the round result. The template MUST NOT carry a shadow-mode field or a user-judgement column.

#### Scenario: Review template read

- **WHEN** the kit's `review-template.md` is read
- **THEN** it contains a per-round section with the stage, scope, review commands, a findings table including severity, confidence and handling, and a result line
- **AND** it has no 「user 判定」 column and no shadow-mode field

### Requirement: Orchestration runs code review after the integrator check

After the integrator check passes and before the finish phase, `/ship-issue` SHALL prepare one git-ignored `review-diff.patch` for the worktree, dispatch the reviewer once with the change directory and the patch to review requirement and test coverage against the spec, and write every finding into `review.md`. The built-in `/code-review` MUST NOT run in this pre-PR review; it runs on the PR instead.

#### Scenario: Review scope prepared for a read-only reviewer

- **WHEN** `/ship-issue` dispatches the reviewer before the PR
- **THEN** one `review-diff.patch` exists in the change directory, is listed in `.gitignore`, is never committed, and is passed to the reviewer, because the reviewer cannot read git diffs itself

#### Scenario: Built-in code-review is not shadowed

- **WHEN** a kit is installed
- **THEN** no skill named `code-review` is created that would replace the built-in command and its effort/`--fix`/`ultra` options

#### Scenario: High-severity high-confidence finding returns

- **WHEN** a review round records a finding that is both high severity and high confidence
- **THEN** the stage goes back to `backend` or `frontend` for the side the finding belongs to, the return is counted together with the integrator check returns and the PR check returns under the same per-target limit of 2, and a third such return stops for the user instead

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

Each kit's `CLAUDE.md` template and setup document SHALL document that review rules are placed by nature across three tiers: the linter/formatter, the repository's `CLAUDE.md`, and the `custom-review` skill.

#### Scenario: Classification documented

- **WHEN** a kit's `CLAUDE.md` template is read
- **THEN** it maps mechanical rules to the linter, judgement conventions to the repository `CLAUDE.md` plus built-in `/code-review`, and spec coverage to `custom-review`

### Requirement: Orchestration has no fixed user checkpoints

`/ship-issue` SHALL run from the proposal through the merge without stopping for a fixed user checkpoint. It SHALL stop for the user only when a question cannot be resolved from the issue or code, a return limit is exceeded, a merge conflict or other blocker occurs, a spec-sync exemption needs confirmation, or the change is classified high risk.

#### Scenario: Low-risk issue runs end to end

- **WHEN** a low-risk issue passes every pre-PR and PR check on the first try
- **THEN** `/ship-issue` opens the PR, archives, and merges without asking the user anything after the initial parameters

#### Scenario: Spec-sync exemption needs confirmation

- **WHEN** the integrator check passes only because `handoff.md` declares a spec-sync exemption
- **THEN** the orchestrator asks the user to confirm each exemption before continuing, and sends the side back to its developer when the user rejects one

### Requirement: Orchestration runs four checks on the opened PR

After the integrator opens the PR, `/ship-issue` SHALL: wait for the PR's CI checks to finish; run the built-in `/code-review` on the branch range; run the built-in `/security-review` when the diff matches a high-risk file pattern; and have the reviewer rate every `/code-review` and `/security-review` finding. Findings SHALL be recorded in `review.md` and posted to the PR as one comment.

#### Scenario: CI fails

- **WHEN** a required PR check fails
- **THEN** the failure is recorded as a return to the developer of the side the failing check belongs to, counted under the shared per-target limit

#### Scenario: Repository has no CI

- **WHEN** the PR reports no checks
- **THEN** the run records that CI was skipped and continues

#### Scenario: PR code-review effort bounded

- **WHEN** `/ship-issue` runs the built-in `/code-review`
- **THEN** it states the effort level explicitly, raises it to `high` when high-risk files are present, and never uses `max`/`ultra`, `--fix`, or `--comment`

#### Scenario: Security review skipped for ordinary changes

- **WHEN** no changed path matches a high-risk file pattern
- **THEN** `/security-review` is not run and `review.md` records it as not applicable

### Requirement: Orchestration classifies risk and gates only high risk

After the PR checks pass, `/ship-issue` SHALL classify the change as low, medium, or high risk using the criteria in the repository `CLAUDE.md`. Low and medium SHALL continue automatically. High SHALL set the stage to `awaiting-approval`, report the high-risk files, findings and the PR link, and continue only after the user replies 「合併」.

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

When the PR checks pass and any required high-risk approval is given, `/ship-issue` SHALL dispatch the integrator to archive and then to merge the single PR, and the run SHALL end with a report of the merged PR, the risk level, the PR notes and a reminder to remove the worktree.

#### Scenario: Both sides merge

- **WHEN** the archive succeeds and the branch carrying both the backend and frontend changes passes the simulated merge queue
- **THEN** the one PR containing both sides is merged and the user receives one final report

#### Scenario: Merge blocked

- **WHEN** the integrator reports a rebase conflict or a check failure during the merge run
- **THEN** the orchestrator stops and reports to the user without merging

### Requirement: Team-hq docs place the mutation-testing check

Each kit's `CLAUDE.md` template 層層把關 section and setup document SHALL document mutation testing as a check that runs in the integrator check phase only, against the critical modules the architect designates in `design.md`, using the mutation command and threshold from the repository `CLAUDE.md`, skipped and non-blocking when none is documented. They SHALL state that the developer and reviewer agents do not run it.

#### Scenario: Check flow documented

- **WHEN** a kit's `CLAUDE.md` 層層把關 section is read
- **THEN** it lists mutation testing under the integrator check phase, scoped to the architect's designated critical modules, with the command and threshold coming from the repository `CLAUDE.md`

#### Scenario: Setup document names the per-repo config

- **WHEN** the setup document is read
- **THEN** it states that the repository enables mutation testing by documenting its mutation command and threshold in its `CLAUDE.md`, and that without it the check is skipped and non-blocking

### Requirement: Kit comes in fullstack and single-side variants

The repository SHALL provide two kit source directories, `agent-team-fullstack/` and `agent-team-single-side/`, both for a single repository that is also where Claude Code is started. The fullstack kit SHALL carry architect, backend, frontend, integrator and reviewer agent definitions; the single-side kit SHALL carry architect, one developer, integrator and reviewer definitions. The former three-repository kit MUST NOT remain in the repository.

#### Scenario: Variant directories present

- **WHEN** the repository is checked out
- **THEN** `agent-team-fullstack/` and `agent-team-single-side/` exist and `agent-team/` does not

#### Scenario: Single-side has one developer

- **WHEN** the single-side kit's `.claude/agents/` is listed
- **THEN** it contains exactly one developer agent definition and no separate backend and frontend definitions

### Requirement: Project declares its agent-team structure in CLAUDE.md

Each kit's `CLAUDE.md` template SHALL contain a `## agent-team 設定` section declaring the structure (`fullstack` or `single-side`), the base branch and the worktree root (default `wt/`). A fullstack declaration SHALL name the backend and frontend subdirectories; a single-side declaration SHALL name the side (`backend` or `frontend`) and its subdirectory (default `.`). Role skills and `/ship-issue` SHALL read this section instead of assuming repository paths.

#### Scenario: Fullstack declaration

- **WHEN** a project declares `結構: fullstack`, `後端子目錄: crates/` and `前端子目錄: web/`
- **THEN** the backend agent works and runs its checks under `crates/` and the frontend agent under `web/`

#### Scenario: Declaration missing

- **WHEN** `/ship-issue` runs in a project whose `CLAUDE.md` has no `## agent-team 設定` section
- **THEN** it stops before creating a worktree and tells the user which fields to add

### Requirement: Subdirectory fields may list several paths

In a fullstack declaration, the backend and frontend subdirectory fields MAY each list several paths separated by 「、」 or a comma. The first entry SHALL be the directory where that side's checks run, and every entry SHALL count as that side's writable scope.

#### Scenario: Workspace files at the repository root

- **WHEN** a project declares `後端子目錄：crates/、Cargo.toml、Cargo.lock`
- **THEN** backend checks run in `crates/`, and the backend agent may edit the root `Cargo.toml` and `Cargo.lock`

### Requirement: One worktree, one change directory and one PR per issue

`/ship-issue` SHALL create a single worktree `<worktree root>/<change-id>` from the declared base branch, and the whole flow SHALL use one change directory, one `openapi.yaml`, one `handoff.md`, one `review.md`, one `.linear.md` and one PR. It MUST NOT copy `openapi.yaml` between change directories.

#### Scenario: Fullstack issue touching both sides

- **WHEN** a fullstack issue changes an endpoint and a page
- **THEN** exactly one worktree and one change directory exist for the change-id, and exactly one PR is opened

### Requirement: Fullstack developers run in sequence in the shared worktree

In the fullstack variant `/ship-issue` SHALL dispatch the backend agent first when the change has `[BE]` tasks, and the frontend agent only after the backend agent has handed off, both in the same worktree. It MUST NOT run them in parallel.

#### Scenario: Both sides have tasks

- **WHEN** `tasks.md` has `[BE]` and `[FE]` tasks
- **THEN** the frontend agent is dispatched only after the status block shows the backend hand-off, and the worktree is clean before it starts

#### Scenario: Frontend-only change

- **WHEN** `tasks.md` has only `[FE]` tasks
- **THEN** the backend agent is not dispatched

### Requirement: Single-side developer follows the declared side

In the single-side variant the developer agent SHALL use `backend-processor` when the declared side is `backend` and `frontend-processor` when it is `frontend`, and every task SHALL carry that side's tag.

#### Scenario: Frontend side declared

- **WHEN** a single-side project declares `端: frontend`
- **THEN** the developer agent follows `frontend-processor` and the architect tags every task `[FE]`

### Requirement: Developer write scope is limited to its subdirectory in fullstack

The fullstack write-scope hook SHALL allow the `backend` role to write only under the declared backend subdirectory and the active change directory, and the `frontend` role only under the frontend subdirectory and the active change directory. Both MUST be denied writes under `openspec/changes/archive/` and elsewhere, with a reason naming the other side's agent role.

#### Scenario: Backend agent edits a frontend file

- **WHEN** the hook runs as `backend` for `wt/eng-1-x/web/src/App.tsx` with frontend subdirectory `web/`
- **THEN** it exits 2

#### Scenario: Frontend agent updates the handoff

- **WHEN** the hook runs as `frontend` for `wt/eng-1-x/openspec/changes/eng-1-x/handoff.md`
- **THEN** it exits 0

#### Scenario: Subdirectory field lists several paths

- **WHEN** the project declares `後端子目錄：crates/、Cargo.toml、Cargo.lock` and the hook runs as `backend` for the worktree's root `Cargo.toml`
- **THEN** it exits 0, while `Cargo.toml.bak` and any path under the frontend subdirectory exit 2

#### Scenario: Developer edits an archived change

- **WHEN** the hook runs as `backend` for a path under `openspec/changes/archive/`
- **THEN** it exits 2

### Requirement: Role skills and hook arguments do not name agents

Role skills installed by the kits MUST NOT contain agent names and SHALL refer to roles (architect, backend agent, frontend agent, developer agent, integrator, reviewer). The write-scope hook SHALL take a role name (`architect`, `integrator`, `backend`, `frontend`) rather than an agent name, so renaming agents only touches agent definitions and `/ship-issue`.

#### Scenario: Skills searched for agent names

- **WHEN** the installed role skills are searched case-insensitively for `hyuse`, `chika`, `yuma`, `osamu` or `shiori`
- **THEN** no matches are found

#### Scenario: Renamed agent calls the hook

- **WHEN** an agent definition renamed to `hikaru` registers `guard-write-scope.sh architect`
- **THEN** the hook applies the architect rules
