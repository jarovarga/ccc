# GitHub

- Read GitHub (issues, pull requests, gists, the API) with the `gh` CLI, which runs outside the sandbox.
- On an authentication error, ask the user to run `gh auth login` outside Claude Code; never handle a token.
- Run `gh` as a single command: no pipe, `&&`, `;` or `$(…)`, and no redirect other than to a file descriptor, such as `2>&1`; otherwise it stays in the sandbox and fails.
- Do not batch `gh` with other tool calls in one block.
- Write remote addresses in the SSH form (`git@github.com:<account>/<repository>.git`).
