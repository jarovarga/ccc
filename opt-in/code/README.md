# Code

Rules and hooks for writing and changing code in any language.

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
> The hooks are a safety net: they fail open, do not see writes through Bash, and count every suppression in a Write, also one the file already had.

## Contents

| Path | Purpose |
| --- | --- |
| `hooks/code-paths.sh` | Hook that blocks edits of lock files, dependency directories and `.git/`. |
| `hooks/code-suppressions.sh` | Hook that blocks edits that add an inline suppression. |
| `rules/code.md` | Rules for writing and changing code. |
| `settings.json` | Registration of both hooks for Edit, Write and NotebookEdit. |

## Requirements

- Install `jq`.
- Keep the hook scripts executable; otherwise they check nothing, without a visible error.

## Tests

Run with the main tests. The test is named after the topic: `code.test.sh`.
