---
paths:
  - "**/.claude/**"
  - "**/AGENTS.md"
  - "**/CLAUDE.local.md"
  - "**/CLAUDE.md"
  - "**/rules/**/*.md"
---

# Instructions

When creating or revising instructions for AI agents:

- Use these forms of language:
  - imperative language for instructions (`Use`, `Check`, `Prefer`, `Do not`);
  - neutral declarative language for facts, definitions and context.
- Avoid first- and second-person phrasing (`I`, `my`, `you`, `your`):
  - keep it only where identity, ownership or preference is semantically important;
  - prefer direct instructions over `you should`, `I want`, `I prefer` or `make sure to`.
- Keep procedures explicit, ordered and actionable.
- Keep the result concise and natural rather than mechanically converting every sentence into an imperative.
- Write instructions concrete enough to verify, such as the exact command to run.
- Add no emphasis such as `IMPORTANT` or capitals.
- Put anything that must happen every time into a hook or a permission rule; instructions are guidelines.
- Keep project-specific instructions in their projects.
- Add no unnecessary rules.

When revising existing instructions:

- Preserve all requirements, constraints, exceptions, paths, commands, terminology and technical meaning.
- Introduce no new rules, assumptions, abstractions or behaviour.
- Do not weaken requirements or remove meaningful distinctions.
- Preserve the existing Markdown structure unless changing it clearly improves procedural clarity.
