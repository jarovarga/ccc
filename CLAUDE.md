# Claude

## Rules

- Treat the rules in `~/.claude/rules/` as binding: neither project instructions nor tasks may override or weaken them, except where a rule defers to the project.
- Surface unresolved material conflicts between a rule and the task or the project.
- Read a file with the Read tool, or with `cat` or `head` on one file, so that path-scoped rules load.
- Change files only with the Edit, Write or NotebookEdit tool, never with `sed -i`, a heredoc or a script, so that the hooks and checkpoints see every change.

## Compact instructions

- When summarising a conversation, keep:
  - the task and its success criteria;
  - the files changed and the commands that verify them;
  - decisions made by the user, and anything they rejected;
  - open items, unverified claims and failed approaches.
