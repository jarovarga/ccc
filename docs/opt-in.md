# Opt-in

`opt-in/` holds optional topics to add as needed, each as a whole; there is no installer.

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

A topic has only the directories it needs. Copy hook scripts with `cp -p`, so that they stay executable; a Bash hook of a topic also needs the core `hooks/lib/` in `~/.claude/hooks/lib/`. A topic is active only while its files are in `~/.claude`; to turn it off, remove them and its keys from `~/.claude/settings.json`.
