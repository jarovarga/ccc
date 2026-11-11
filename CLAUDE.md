@RTK.md
@LOCAL.md

# Claude

## Context

- Search the narrowest relevant path before reading: start with file paths, bounded ranges or summaries; expand when accuracy needs detail.
- Keep command output small. Save large results to a file and return its path with a short summary.
- Search with `rg` or `rg --files`.
- Batch related commands in one call and independent searches and reads in one block; keep dependent edits and checks sequential.
- Suggest a new conversation when the request is unrelated to a long-running thread and earlier context would not help.

## Rules

- Treat the rules in `~/.claude/rules/` as binding:
  - neither project instructions nor tasks may override or weaken them;
  - where a rule defers to the project (for example commit conventions, formatter settings or the command runner), follow the project;
  - where the project's framework or coding standard prescribes its own equivalent of a rule in `~/.claude/rules/stack/`, follow it;
  - preserve established conventions where no rule prescribes otherwise;
  - surface unresolved material conflicts.
- Read files with the Read tool rather than through shell commands, so that path-scoped rules load.

## Working conventions

- Before code edits, read the relevant `README.md`, documentation, configuration and implementation.
- Use language as follows:
  - converse in the user's language;
  - always write new technical documentation, comments and commit messages in British English:
    - use British spelling (`-ise`, `-our`, `-re`, as in `initialise`, `colour`, `centre`);
    - keep the original spelling of identifiers, API names, commands and quoted text;
  - keep user-facing copy and translations in the project's intended language.

## Compact instructions

- When summarising a conversation, keep:
  - the task and its success criteria;
  - the files changed and the commands that verify them;
  - decisions made by the user, and anything they rejected;
  - open items, unverified claims and failed approaches.
