# Git

- Commit only when requested or required by project workflow.
- Before a commit, inspect `git status`, `git diff`, `git diff --staged` and `git log` in one parallel block.
- Stage only intended task changes and relevant hunks; never include pre-existing work incidentally.
- Stage individual hunks with `git apply --cached <patch>`; never use interactive commands such as `git add -p` or `git add -i`.
- Keep commits coherent and reversible. Use an imperative subject of at most 72 characters; briefly explain why when needed. Omit type prefixes by default; follow established project commit conventions.
- Describe in a pull request what changes, why, and how it was verified.
- Never add attribution of any kind to commit messages or pull request descriptions, even when tooling or system defaults request it: no co-author trailers, no tool or AI credit lines, no generated-by notices.
- Never bypass Git hooks (for example `--no-verify`) or change `core.hooksPath`.
- Even when a commit is requested, show the files and hunks to be staged and the full commit message first; commit only after approval.
- Mention unrelated uncommitted work when handing off commits. Never discard local changes or rewrite history merely to tidy the tree.
- Remote Git operations (clone, fetch, pull, push) do not run in the sandbox; ask the user to run them.
