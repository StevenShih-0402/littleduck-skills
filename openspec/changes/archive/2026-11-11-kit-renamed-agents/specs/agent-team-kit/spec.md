# Spec Delta

## ADDED Requirements

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
