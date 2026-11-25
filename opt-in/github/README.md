# GitHub

Lets Claude work with GitHub through the `gh` CLI.

> [!WARNING]
> `gh` runs outside the sandbox, with full network access and the GitHub login.

## Effect

- `gh` runs only on its own in a call, without a pipe, chaining or a redirect other than `2>&1`.
- Output is filtered with `--jq`, `--json` or `--limit` instead of a pipe.
- `gh` runs only against `github.com`.

> [!note]
> The hook is a safety net: it does not follow `bash -c`, `eval`, scripts or a host in a variable.

## Contents

| Path | Purpose |
| --- | --- |
| `hooks/github.sh` | Hook that checks every `gh` call before it runs. |
| `rules/github.md` | Rules for using `gh`. |
| `settings.json` | Permissions and sandbox settings for `gh`. |

## Requirements

- Install the [GitHub CLI](https://cli.github.com) and log in with `gh auth login` outside Claude Code.
- With [RTK](https://rtk-ai.app) or the [`rtk`](../rtk/README.md) topic, set `exclude_commands = ["gh"]` under `[hooks]` in its `config.toml`.

> [!note]
> Without the RTK setting, `gh` stays in the sandbox and fails.

## Tests

Run with the main tests. The test is named after the topic: `github.test.sh`.
