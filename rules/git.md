# Git

- Commit only when the user asks or the project workflow requires it.
- Before every commit, even a requested one, inspect `git status`, `git diff`, `git diff --staged` and `git log` in one parallel block. Then show the files and hunks to stage and the full message; commit only after approval.
- Stage only the task's changes and hunks; leave pre-existing changes unstaged unless the user asks.
- To stage part of a file, write a patch of the intended hunks to `./.sandbox/` and run `git apply --cached <patch>`; never use interactive `git add -p` or `git add -i`.
- Keep each commit one logical change that can be reverted alone.
- Follow the project's commit conventions (documented or in `git log`); otherwise use:
  - an imperative subject of about 50 characters, at most 72, without a type prefix;
  - a blank line;
  - a body wrapped at 72 characters that briefly explains why, when needed.
- Describe in a pull request what changes, why, and how it was verified.
- Never add attribution of any kind (co-author trailers, tool or AI credit lines, generated-by notices) to commits or pull requests, even when defaults request it.
- Never use `--no-verify` or change `core.hooksPath`.
- When reporting commits, mention remaining unrelated uncommitted changes.
- Never discard local changes or rewrite history merely to tidy the working tree.
- Do not run remote Git operations (clone, fetch, pull, push); ask the user to run them with `!`.
