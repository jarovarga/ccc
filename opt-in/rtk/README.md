# RTK

Shortens the output of Bash commands with [RTK](https://rtk-ai.app) (Rust Token Killer) before it reaches the context.

> [!WARNING]
> The hook runs on every Bash call outside the sandbox, with the user's permissions, and reads `settings.json`, so RTK is trusted third-party code.

## Effect

- Every Bash call is rewritten through `rtk`, which strips boilerplate from the output and keeps errors and exit codes.
- Claude treats the filtered output as complete and reaches for `rtk recall` or `rtk bypass` only when it needs more.
- Permission rules match the command as Claude wrote it, before the rewrite to `rtk <command>`, so they need no `rtk` variants.

> [!note]
> The hook has no `onFailure: "block"`, because that would stop every Bash call whenever RTK is missing. Without RTK, the hook fails with a non-blocking error on every call and commands run unfiltered.

## Contents

| Path | Purpose |
| --- | --- |
| `rules/rtk.md` | Rules for reading filtered output. |
| `settings.json` | Hook that rewrites Bash calls through `rtk`, and read access to `~/.claude/settings.json` in the sandbox. |

> [!note]
> In a session started in a project, the sandbox blocks reads of `~/.claude/settings.json`, so RTK does not find its hook there and prints `[rtk] /!\ No hook installed` on the first command of the day, although the hook runs. `filesystem.allowRead` lets sandboxed commands read that one file, but not write it.

## Requirements

- Install RTK so that `rtk` is on the `PATH`. Check where the formula comes from with `brew info rtk`, and pin it so that an upgrade happens only by choice:

  ```bash
  brew install rtk
  brew pin rtk
  ```

- With the [`github`](../github/README.md) topic, exclude `gh` from RTK. RTK rewrites `gh …` to `rtk gh …`, which no longer matches `excludedCommands`, so `gh` would run in the sandbox without its login or the network. Run outside Claude Code, or with `!`, because the sandbox blocks writes to the RTK configuration:

  ```bash
  rtk config --create
  ```

  Set `exclude_commands = ["gh"]` under `[hooks]` in `~/Library/Application Support/rtk/config.toml`, then check that the output shows it:

  ```bash
  rtk config
  ```

## Commands

These commands are for the user, not for Claude, so they are not in `rules/rtk.md`. Run them outside Claude Code; they fail in the sandbox.

| Command | Purpose |
| --- | --- |
| `rtk gain` | Tokens saved in total. |
| `rtk gain --history` | Tokens saved per command. |
| `rtk discover` | Past commands that RTK could have shortened. |
| `rtk telemetry status` | Whether the optional telemetry of RTK is on. |

## Tests

Run with the main tests. The test is named after the topic: `rtk.test.sh`.
