# Spec Delta

## ADDED Requirements

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
