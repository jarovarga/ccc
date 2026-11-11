# RTK

## Command output

Bash commands are transparently rewritten through `rtk` (Rust Token Killer), which strips boilerplate from the output without changing command behaviour or exit codes and keeps errors, failures and what is needed to act.

- Treat the output as complete; do not re-run for more detail.
- When a truncated result carries a recovery hint and the elided part is needed, read it with `rtk recall <hash>`.

## Commands

- Run `rtk bypass <cmd>` for unfiltered but tracked execution, only when the output is empty despite expected output, inconsistent with the exit code or unparseable.
- Use `RTK_DISABLED=1 <cmd>` to skip RTK for one command.
