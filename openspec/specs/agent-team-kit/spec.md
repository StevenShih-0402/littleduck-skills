# agent-team-kit Specification

## Purpose

提供多 Agent 開發工作流（architect / backend / frontend / integrator 四角色）的建置文件與 team-hq 資料夾骨架，讓使用者在新的協作中樞專案一次取得可直接修改的範本。

## Requirements

### Requirement: Agent team kit contents

The repository SHALL provide an agent team kit consisting of: a multi-agent workflow setup document, a team-hq `CLAUDE.md`, four agent definition templates under `.claude/agents/` (architect, backend, frontend, integrator), a `/ship-issue` orchestration command under `.claude/commands/`, a write-scope hook script under `.claude/hooks/`, and a `handoff.md` template.

#### Scenario: Kit files present in repo

- **WHEN** the repository is checked out
- **THEN** the kit source directory contains the setup document, `CLAUDE.md`, four agent definition files, `ship-issue.md`, `guard-write-scope.sh`, and a `handoff.md` template

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

The kit's `handoff.md` template SHALL contain a `## 狀態` block whose fields (stage, last completed, next step, pause reason, updated by and when) are edited in place, separate from the append-only per-role log below it. Stage values SHALL be `proposal`, `backend`, `frontend`, `integrating` or `archived`.

#### Scenario: Template read

- **WHEN** the kit's `handoff-template.md` is read
- **THEN** it contains a `## 狀態` block with the five fields above the append-only log section

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

The kit's `/ship-issue` command SHALL resolve every user decision (primary issue, code, label, branch, change-id, affected repos) before dispatching, pass each agent the parameters its skill expects, and, when the user approves the proposal, commit only `openspec/changes/<change-id>` in each affected worktree as `wip(<ISSUE-ID>): 提案核准` and push it before dispatching development agents. Change-ids SHALL be lowercase.

#### Scenario: Proposal approved

- **WHEN** the user replies 「核准」 at checkpoint 1
- **THEN** each affected worktree has a pushed commit containing only the change directory, and its `git status --porcelain` is empty before the backend or frontend agent starts

#### Scenario: Integrator dispatched

- **WHEN** `/ship-issue` dispatches the integrator
- **THEN** the prompt contains the change-id, both worktree paths, both base branches and whether this run is 「檢查」 or 「歸檔」
