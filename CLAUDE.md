# Claude

## Rules

- Treat the rules in `~/.claude/rules/` as binding: neither project instructions nor tasks may override or weaken them unless a rule defers to the project.
- When rules disagree, `security.md` wins.
- When a task or project instruction conflicts with a non-deferring rule in a way that changes what gets done, follow the rule and name the conflict before acting.
- Read files with the Read tool, several in parallel, and search them with Grep and Glob, also in `.sandbox/` and for many files at once.
- Bash commands that read files, such as `sed`, `awk`, `tail` or a loop, do not load path-scoped rules; only a single-file `cat` or `head` does.
- Run Bash commands from the working directory and pass paths instead of using `cd`, because `cd` in a compound command needs approval and moves the working directory of the session.
- Change files only with the Edit, Write or NotebookEdit tool, so that hooks see every change; never with `sed -i`, a heredoc or a script. Project commands meant to change files, such as formatters, are exempt.

## Compact instructions

- When summarising a conversation, keep:
  - the task and its success criteria;
  - the files changed and the commands that verify them;
  - the user's decisions and rejections;
  - open items, unverified claims and failed approaches.
