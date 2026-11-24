# Agents

The subagents in `agents/`. The [subagents documentation](https://code.claude.com/docs/en/sub-agents) describes every frontmatter key in full.

## Explore

Replaces the built-in `Explore` subagent, which Claude uses for broad searches across a codebase. It reports findings as `path:line` with a short excerpt, keeps verified facts apart from inferences, and lists what it searched without finding.

| Key | Value | Effect |
| --- | --- | --- |
| `name` | `Explore` | Overrides the built-in subagent of the same name. |
| `description` | — | Tells Claude when to use the subagent and how broad a search to ask for. |
| `tools` | `Read`, `Grep`, `Glob` | The subagent can read and search files, but not change them or run commands. |
| `model` | `haiku` | Searches run on Haiku instead of the model of the main conversation. |
| `color` | `cyan` | The colour of the subagent in the interface. |
