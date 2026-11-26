# Code

Rules for writing and changing code in any language, with hooks that protect files a package manager or Git manages and that enforce the rule of `security.md` against inline exceptions.

## Effect

- Claude reads the relevant documentation, configuration and code before editing.
- Claude follows the project's formatter, linter and target version, and runs the project's own checks.
- Changes stay minimal and reuse what the project already has.
- Code follows rules for design, comments, robustness, input and output, accessibility and testing.
- The project's framework or coding standard takes precedence over these rules.
- Edit, Write and NotebookEdit cannot:
  - add an inline suppression of a linter or static analyser, such as `eslint-disable`, `@phpstan-ignore` or `# shellcheck disable`;
  - change a lock file (`composer.lock`, `package-lock.json`), a file in `vendor/` at the project root or in `node_modules/` at any depth, or anything in `.git/`.

> [!note]
> The hooks are a safety net and fail open: a fault in them, such as a hook script without the execute permission, lets the edit through without a visible error. They do not see writes through Bash. A Write or NotebookEdit counts every suppression in its content, also one that the file already had, so in a file that holds suppressions as test data, such as `tests/opt-in/code.test.sh`, a Write or an Edit that adds one is blocked; the user makes that change.

## Contents

| Path | Purpose |
| --- | --- |
| `hooks/code-paths.sh` | Hook that blocks edits of lock files, dependency directories and `.git/`. |
| `hooks/code-suppressions.sh` | Hook that blocks edits that add an inline suppression. |
| `rules/code.md` | Rules for writing and changing code. |
| `settings.json` | Registration of both hooks for Edit, Write and NotebookEdit. |

## Requirements

- Install `jq`; without it the hooks fail with a non-blocking error and check nothing.

## Tests

Run with the main tests. The test is named after the topic: `code.test.sh`.
