---
paths:
  - "**/*.{bash,sh}"
---

# Bash

These rules apply to Bash scripts; keep a script that runs under `sh`, such as in an image without Bash, POSIX-compliant.

- Start scripts with `#!/usr/bin/env bash`.
- Set `set -o nounset` and `set -o pipefail`.
- Check failures explicitly and exit with a meaningful exit code.
- Quote every expansion (`"${var}"`).
- Pass command arguments as arrays, never as concatenated strings.
- Declare constants `readonly` in `UPPER_SNAKE_CASE`.
- Declare function variables `local`.
- Create temporary files and directories with `mktemp`.
- Remove temporary files and directories with `trap '…' EXIT`.
- Create a file that holds a secret under `umask 077`.
- Redirect stdin from `/dev/null` for commands that do not need it, such as `docker exec -i`, so that they do not consume input meant for a later prompt.
- Default confirmations of destructive actions to no (`y/N`), so that Enter or a closed stdin declines.
- When `shellcheck` is available, run it on changed scripts.
