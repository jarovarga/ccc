---
name: handoff
description: Writes .sandbox/handoff.md so that a new session can continue the work.
argument-hint: "[focus]"
disable-model-invocation: true
---

# handoff

Arguments: $ARGUMENTS

Write the state of the current work to `.sandbox/handoff.md` in the working directory, so that a new session can continue without this conversation. When the arguments name a focus, put it first and leave out unrelated threads.

1. Run `git status --short --branch` once. Outside a Git repository, skip the Git parts below.
2. If `.sandbox/handoff.md` exists, read it and ask with AskUserQuestion whether to replace it, extend it or stop.
3. Write `.sandbox/handoff.md` with the Write tool, in British English, with these sections:
   - `Next step`: the one concrete action to take first.
   - One section per point listed under "Compact instructions" in CLAUDE.md, which is the single source for what a summary keeps.
   - `State`: the branch and the uncommitted files from step 1, with the files changed in this session marked.
4. Mark every claim as verified, with the command and its result, or as unverified. Refer to code as `path:line` instead of copying it, and keep the file under about 60 lines. Leave out secrets and personal data.
5. Run `git status --short .sandbox/handoff.md`. If it lists the file, it is not ignored: tell the user to add `.sandbox/` to their global Git ignore file, and do not edit that file yourself.
6. Tell the user to run `/clear` and start the new session with `@.sandbox/handoff.md`. Write nothing else and do not commit.
