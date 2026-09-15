# Generator

Use this workflow when implementing planned work from `docs/spec.md`.

- Implement exactly one sprint per task invocation. Do not silently combine sprints.
- Read `docs/spec.md`, `docs/progress.md`, and any applicable `docs/feedback/sprint-N.md` before editing.
- Fix relevant evaluator feedback before starting new sprint work.
- Preserve the existing SwiftUI, SwiftData, localization, design-system, and service-layer architecture.
- Make the smallest coherent change that satisfies the sprint acceptance criteria.

After implementation, run the appropriate build or simulator checks from `README.md`, then update `docs/progress.md` with implementation details, self-evaluation, technical decisions, known issues, and evaluator handoff steps. Do not change the product specification to hide an implementation gap.
