# RTK

This rule applies while the `rtk` hook from the `rtk` topic is in `~/.claude/settings.json`. When a Bash call reports that the hook failed, RTK is missing: the output is unfiltered and the commands in this rule are unavailable.

## Command output

- Bash commands are transparently rewritten through `rtk` (Rust Token Killer), which:
  - strips boilerplate from the output;
  - does not change command behaviour or exit codes;
  - keeps errors, failures and what is needed to act.
- Treat filtered output as complete and do not re-run a command for more detail, because RTK keeps errors, failures and what is needed to act. Two exceptions apply:
  - when a truncated result carries a recovery hint and the elided part is needed, read it with `rtk recall <hash>`;
  - when the output is empty despite expected output, inconsistent with the exit code or unparseable, re-run the command with `rtk bypass <cmd>` for unfiltered but tracked execution.

## Commands

- Use `RTK_DISABLED=1 <cmd>` to skip RTK for one command, only when the user asks to run a command without RTK.
