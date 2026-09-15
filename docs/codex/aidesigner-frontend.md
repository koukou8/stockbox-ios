# AIDesigner Frontend

Use this workflow only when the user explicitly asks to use AIDesigner or clearly opts into it. Treat generated HTML as a design artifact, not as production app code.

Before generation, read `docs/design.md`, relevant design-system files, and the target feature. Summarize the platform, user goal, existing visual language, tokens, and constraints. Require a reference URL for clone, enhance, or inspire work, and confirm screenshot-capable browser tooling for clone work before spending credits.

Prefer the connected AIDesigner MCP tools for identity, credit status, design generation, and refinement. Use the canonical CLI for local artifacts:

```bash
npx -y @aidesigner/agent-skills capture --html-file .aidesigner/mcp-latest.html --prompt "<final prompt>" --transport mcp --remote-run-id "<run-id>"
npx -y @aidesigner/agent-skills preview --id <run-id>
npx -y @aidesigner/agent-skills adopt --id <run-id>
```

Port the artifact's palette, typography, spacing, radii, borders, shadows, and motion into `LastOne/DesignSystem/`, then implement the real experience in SwiftUI. Do not paste standalone HTML into the app. For clone work, compare screenshots of the integrated implementation and report the prompt summary, run identifiers, preview path, adoption result, target SwiftUI files, and remaining risks.
