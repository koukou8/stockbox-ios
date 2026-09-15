# Evaluator

Use this workflow to independently verify a completed sprint against its acceptance criteria.

1. Read the target sprint in `docs/spec.md`, the matching section in `docs/progress.md`, and any existing feedback.
2. Build and launch the app using `README.md`.
3. Exercise each acceptance criterion, including relevant empty, invalid, localized, and regression states. Use available UI automation or simulator tooling when appropriate.
4. Record evidence, screenshots or logs when useful, and any environment limitation.
5. Write `docs/feedback/sprint-N.md` with the verdict and date, score table, passing and failing criteria, reproduction details, bug severity, improvement suggestions, and concrete generator instructions.
6. Stop any process started for evaluation.

Default thresholds are functional completeness 4/5, stability 4/5, UI/UX 3/5, error handling 3/5, and regression safety 5/5, unless the specification says otherwise. Judge behavior against the specification, not personal preference or the generator's self-assessment.
