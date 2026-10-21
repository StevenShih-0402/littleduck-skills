# Spec Delta

## Purpose

讓任何安裝本 repo 的專案都能取得 `draw-mermaid` skill，以一致的選圖、畫法與渲染驗證準則繪製 mermaid 圖表。

## ADDED Requirements

### Requirement: draw-mermaid skill is available in this repo

The repository SHALL contain the `draw-mermaid` skill under `.claude/skills/draw-mermaid/`, including its `SKILL.md` and an executable `scripts/render.sh` that renders every mermaid block of a markdown file in both default and dark themes.

#### Scenario: Skill files present

- **WHEN** the repository is checked out
- **THEN** `.claude/skills/draw-mermaid/SKILL.md` and `.claude/skills/draw-mermaid/scripts/render.sh` exist
- **AND** `render.sh` has the executable bit set

#### Scenario: Skill is discoverable after install

- **WHEN** a project that installed `draw-mermaid` asks Claude Code to draw or review a mermaid diagram
- **THEN** the `draw-mermaid` skill is resolvable by name and its guidance is loaded

### Requirement: draw-mermaid content is project-agnostic

The skill content MUST NOT reference company-specific projects, repositories, issue identifiers, or absolute personal paths; placement guidance SHALL be expressed with generic paths relative to the consuming project.

#### Scenario: No source-project bindings remain

- **WHEN** the skill files are searched for `ignsw`, `IngenuityOA`, `tao_rui_projects`, or `IGN-` identifiers
- **THEN** no matches are found

### Requirement: render script reports failures

The render script SHALL exit with a non-zero status when any mermaid block fails to render or when the static check finds hard-coded colors or code-style node IDs, and exit zero otherwise.

#### Scenario: Invalid mermaid block

- **WHEN** `render.sh` is run on a markdown file containing a syntactically invalid mermaid block
- **THEN** it prints which block failed and exits non-zero

#### Scenario: Valid diagrams

- **WHEN** `render.sh` is run on a markdown file whose mermaid blocks are valid and follow the color and node-ID rules
- **THEN** it writes default and dark SVGs for each block and exits zero
