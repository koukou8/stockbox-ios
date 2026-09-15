# Codex project setup

This directory contains the Codex-side adaptation of the existing Claude Code setup.

The Claude workflow remains in `.claude/` unchanged. Codex project instructions live in the repository root `AGENTS.md`, and role-specific workflow references live here.

| Claude source | Codex adaptation |
| --- | --- |
| `.claude/agents/planner.md` | `docs/codex/planner.md` |
| `.claude/agents/generator.md` | `docs/codex/generator.md` |
| `.claude/agents/evaluator.md` | `docs/codex/evaluator.md` |
| `.claude/agents/aidesigner-frontend.md` and `.claude/commands/aidesigner.md` | `docs/codex/aidesigner-frontend.md` |

`.claude/launch.json` is intentionally not copied as an active Codex setting because it is Claude-specific launch configuration. Equivalent commands remain documented in `README.md` and can be run from Codex's terminal.
