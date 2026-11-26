---
paths:
  - "**/.claude/**"
  - "**/AGENTS.md"
  - "**/CLAUDE.local.md"
  - "**/CLAUDE.md"
  - "**/SKILL.md"
  - "**/agents/*.md"
  - "**/rules/**/*.md"
---

# Instructions

When creating or revising instructions for AI agents:

- Use these forms of language:
  - imperative language for instructions (`Use`, `Check`, `Prefer`, `Do not`);
  - neutral declarative language for facts, definitions and context.
- Avoid first- and second-person phrasing (`I`, `my`, `you`, `your`) unless identity, ownership or preference is semantically important; write direct instructions instead of `you should`, `I want`, `I prefer` or `make sure to`.
- Keep procedures explicit, ordered and actionable.
- Keep the result concise and natural rather than mechanically converting every sentence into an imperative.
- Write instructions concrete enough to verify, such as the exact command to run; name a project command by how it is invoked (`npm test`), not by copying its definition.
- Add no emphasis such as `IMPORTANT` or capitals.
- Enforce anything that must happen every time with a hook or a permission rule as well as an instruction, because Claude Code loads instructions as context and cannot guarantee that they are followed.
- Put an instruction that applies to one project only in that project's `CLAUDE.md` or `.claude/rules/`, not in `~/.claude`.
- Before adding a rule, check that no existing rule covers it and that Claude would act differently without it.

When revising existing instructions:

- Preserve all requirements, constraints, exceptions, paths, commands, terminology and technical meaning.
- Introduce no new rules, assumptions, abstractions or behaviour.
- Do not weaken requirements or remove meaningful distinctions.
- Preserve the existing Markdown structure unless changing it clearly improves procedural clarity.
