# Codex project setup

This directory documents the Codex-side adaptation of the existing Claude Code setup.

The Claude workflow remains in `.claude/` unchanged. Codex project instructions live in the repository root `AGENTS.md`, and reusable role-specific instructions live in `.agents/skills/`:

| Claude source | Codex adaptation |
| --- | --- |
| `.claude/agents/planner.md` | `.agents/skills/planner/SKILL.md` |
| `.claude/agents/generator.md` | `.agents/skills/generator/SKILL.md` |
| `.claude/agents/evaluator.md` | `.agents/skills/evaluator/SKILL.md` |
| `.claude/agents/aidesigner-frontend.md` and `.claude/commands/aidesigner.md` | `.agents/skills/aidesigner-frontend/SKILL.md` |

`.claude/launch.json` is intentionally not copied as an active Codex setting. It is Claude-specific launch configuration. The equivalent commands remain documented in `README.md` and can be run from Codex's terminal.
