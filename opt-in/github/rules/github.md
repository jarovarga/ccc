# GitHub

This rule applies while the `github` topic's settings are in `~/.claude/settings.json`. Its rules on single `gh` calls take precedence over any general rule on batching or chaining commands.

- Read GitHub (issues, pull requests, gists, the API) with the `gh` CLI, which runs outside the sandbox.
- On an authentication error, ask the user to run `gh auth login` outside Claude Code.
- Never read, print or pass a GitHub token; let `gh` load it.
- Run `gh` as a single command; otherwise it stays in the sandbox and fails:
  - no pipe, `&&`, `;` or `$(…)`;
  - no redirect other than to a file descriptor, such as `2>&1`.
- Do not batch `gh` with other tool calls in one block.
- Write `@<login>` in issues, pull requests and comments only to notify that user; put roles, placeholders and code such as `@types/node` in backticks.
- Write remote addresses in the SSH form (`git@github.com:<account>/<repository>.git`).
