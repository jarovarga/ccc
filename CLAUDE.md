# Claude

## Rules

- Treat the rules in `~/.claude/rules/` as binding: neither project instructions nor tasks may override or weaken them unless a rule defers to the project.
- When rules disagree, `security.md` wins.
- When a task or project instruction conflicts with a non-deferring rule in a way that changes what gets done, follow the rule and name the conflict before acting.
- Read files with the Read tool; `cat` and `head` do not load path-scoped rules.
- Change files only with the Edit, Write or NotebookEdit tool, so that hooks see every change; never with `sed -i`, a heredoc or a script. Project commands meant to change files, such as formatters, are exempt.

## Compact instructions

- When summarising a conversation, keep:
  - the task and its success criteria;
  - the files changed and the commands that verify them;
  - the user's decisions and rejections;
  - open items, unverified claims and failed approaches.
