# LastOne Codex Project Instructions

## Scope and precedence

- These instructions apply to the entire repository.
- User instructions take precedence over this file.
- Keep the existing `.claude/` configuration intact. It is a supported Claude Code workflow and must not be deleted, renamed, or rewritten as part of Codex work.
- Prefer small, reviewable changes that match the existing SwiftUI and service-layer patterns.

## Project context

LastOne is a local-first iOS app for tracking household, food, and pet-item stock. The canonical product and design documents are:

- `docs/spec/lastone-app.md`
- `docs/design.md`
- `docs/spec.md`
- `docs/progress.md`

The app uses Swift, SwiftUI, SwiftData, iOS 17+, String Catalog localization, and no external package dependencies. Build and simulator instructions are in `README.md` and `scripts/build.sh`.

## Working rules

1. Read the relevant specification and nearby implementation before editing.
2. Preserve existing user changes and unrelated worktree changes.
3. Keep views focused on presentation and user interaction. Put state transitions, persistence, import/export, analytics, and entitlement behavior behind the existing service/protocol boundaries.
4. Use the design tokens and reusable components in `LastOne/DesignSystem/` instead of introducing one-off styling.
5. Put user-facing strings in `LastOne/Resources/Localizable.xcstrings` and expose them through `LastOne/Localization/LOStrings.swift`.
6. Do not add SDK dependencies or change the product scope unless the user explicitly requests it.
7. Keep comments short and explain only non-obvious decisions.

## Verification

- For Swift or project-file changes, run `./scripts/build.sh` when the environment allows it.
- For behavior changes, follow the relevant simulator scenario in `docs/progress.md` and capture evidence when useful.
- For UI work, inspect both English and Japanese states when the change affects localized content.
- Do not claim a check passed unless it was actually run. Record environment blockers clearly.

## Codex workflow roles

The former Claude agents have been adapted as Codex workflow references under `docs/codex/`:

- `docs/codex/planner.md`: turn a short product idea into `docs/spec.md`.
- `docs/codex/generator.md`: implement exactly one sprint, then update `docs/progress.md`.
- `docs/codex/evaluator.md`: verify acceptance criteria independently and write `docs/feedback/sprint-N.md`.
- `docs/codex/aidesigner-frontend.md`: use AIDesigner only when the user opts into that workflow, then port the design into the real project.

Codex does not need Claude's `model`, `tools`, or `mcpServers` frontmatter; available tools are selected by the current Codex environment.
