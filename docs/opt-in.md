# Opt-in

`opt-in/` holds optional topics, each disabled by default and toggled as a whole.

## Layout

A topic mirrors the layout of `~/.claude`:

| Path | Purpose |
| --- | --- |
| `opt-in/<topic>/agents/` | Subagents, copied into `~/.claude/agents/`. |
| `opt-in/<topic>/hooks/` | Hook scripts, copied into `~/.claude/hooks/`. |
| `opt-in/<topic>/rules/` | Rules, copied into `~/.claude/rules/`. |
| `opt-in/<topic>/skills/` | Skills, copied into `~/.claude/skills/`. |
| `opt-in/<topic>/README.md` | What the topic does, its contents, requirements and tests; not installed. |
| `opt-in/<topic>/settings.json` | Only the keys of the topic, merged into `~/.claude/settings.json`. |
| `tests/opt-in/<topic>.test.sh` | Tests of the topic, run by `tests/run.sh`. |

A topic has only the directories it needs.
