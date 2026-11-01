## MODIFIED Requirements

### Requirement: Agent team kit contents

The repository SHALL provide an agent team kit consisting of: a multi-agent workflow setup document, a team-hq `CLAUDE.md`, four agent definition templates under `.claude/agents/` (architect, backend, frontend, integrator), a `/ship-issue` orchestration command under `.claude/commands/`, a write-scope hook script under `.claude/hooks/`, and a `handoff.md` template.

#### Scenario: Kit files present in repo

- **WHEN** the repository is checked out
- **THEN** the kit source directory contains the setup document, `CLAUDE.md`, four agent definition files, `ship-issue.md`, `guard-write-scope.sh`, and a `handoff.md` template

## ADDED Requirements

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

The kit's `/ship-issue` command SHALL resolve every user decision (primary issue, code, label, branch, change-id, affected repos) before dispatching, pass each agent the parameters its skill expects, and, when the user approves the proposal, commit only `openspec/changes/<change-id>` in each affected worktree as `wip(<ISSUE-ID>): 提案核准` and push it before dispatching development agents. Change-ids SHALL be lowercase.

#### Scenario: Proposal approved

- **WHEN** the user replies 「核准」 at checkpoint 1
- **THEN** each affected worktree has a pushed commit containing only the change directory, and its `git status --porcelain` is empty before the backend or frontend agent starts

#### Scenario: Integrator dispatched

- **WHEN** `/ship-issue` dispatches the integrator
- **THEN** the prompt contains the change-id, both worktree paths, both base branches and whether this run is 「檢查」 or 「歸檔」
