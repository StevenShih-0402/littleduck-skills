## ADDED Requirements

### Requirement: gen-html skill is available in this repo

The repository SHALL contain the `gen-html` skill under `.claude/skills/gen-html/`, migrated from the source monorepo, including its `SKILL.md` and `template.html`, so that any project installing skills from this repo receives generative HTML diagram/flowchart generation.

#### Scenario: Skill files present after migration

- **WHEN** the repository is checked out
- **THEN** `.claude/skills/gen-html/SKILL.md` and `.claude/skills/gen-html/template.html` exist and match the source skill's content

#### Scenario: Skill is discoverable as a slash command

- **WHEN** a user in a project that has this skill installed invokes `/gen-html <topic>`
- **THEN** the `gen-html` skill is resolved and runs, producing a single-file HTML page per its SKILL.md spec
