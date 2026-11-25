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

A topic has only the directories it needs.

## Usage

Start Claude Code in the checkout and paste this prompt, with the chosen topics or `all` in place of `<topics>`:

```text
Add the opt-in topics <topics> from opt-in/ to ~/.claude, following docs/opt-in.md. Copy each topic directory into the matching directory of ~/.claude and keep hook scripts executable. Merge the topic's settings.json into ~/.claude/settings.json: add missing array entries, skip duplicates and keep every other key. Do not copy README.md. Show the changes before writing, then list the requirements from each topic's README.md that I must meet myself.
```
