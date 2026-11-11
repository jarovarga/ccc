---
paths:
  - "**/AGENTS.md"
  - "**/CLAUDE.local.md"
  - "**/CLAUDE.md"
  - "**/LOCAL.md"
  - "**/RTK.md"
  - "**/.claude/**"
  - "**/rules/**/*.md"
---

# Instructions

When creating or revising instructions for AI agents:

- Use imperative language for instructions (`Use`, `Check`, `Prefer`, `Do not`) and neutral declarative language for facts, definitions and context.
- Avoid first- and second-person phrasing (`I`, `my`, `you`, `your`) unless identity, ownership or preference is semantically important; prefer direct instructions over `you should`, `I want`, `I prefer` or `make sure to`.
- Keep procedures explicit, ordered and actionable, and the result concise and natural rather than mechanically converting every sentence into an imperative.
- Keep project-specific instructions in their projects.
- Add no unnecessary rules.

When revising existing instructions:

- Preserve all requirements, constraints, exceptions, paths, commands, terminology and technical meaning.
- Introduce no new rules, assumptions, abstractions or behaviour; do not weaken requirements or remove meaningful distinctions.
- Preserve the existing Markdown structure unless changing it clearly improves procedural clarity.
