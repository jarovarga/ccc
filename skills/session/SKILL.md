---
name: session
description: Saves the state of the work to .sandbox/context.md so that a new session can continue it, or resumes from that file.
argument-hint: "save [focus] | resume"
disable-model-invocation: true
---

# session

Arguments: $ARGUMENTS

When the first argument is `save`, follow "Save", with any further arguments as the focus. When it is `resume`, follow "Resume". Otherwise ask with AskUserQuestion whether to save or resume.

## Save

Write the state of the current work to `.sandbox/context.md` in the working directory, so that a new session can continue without this conversation. When the arguments name a focus, put it first and leave out unrelated threads.

1. Run `git status --short --branch` and `git rev-parse --short HEAD` once each. Outside a Git repository, skip the Git parts below.
2. If `.sandbox/context.md` exists, read it and ask with AskUserQuestion whether to replace it, extend it or stop.
3. Write `.sandbox/context.md` with the Write tool, in British English, with these sections:
   - `Next step`: the one concrete action to take first.
   - One section per point listed under "Compact instructions" in CLAUDE.md, which is the single source for what a summary keeps.
   - `State`: the branch, the commit and the uncommitted files from step 1, with the files changed in this session marked.
4. Mark every claim as verified, with the command and its result, or as unverified. Refer to code as `path:line` instead of copying it, and to commits, plans, issues and pull requests by hash, path or URL instead of repeating their content. Keep the file under about 60 lines. Leave out secrets and personal data.
5. Run `git status --short .sandbox/context.md`. If it lists the file, it is not ignored: tell the user to add `.sandbox/` to their global Git ignore file, and do not edit that file yourself.
6. Tell the user to run `/clear` and then `/session resume`. Write nothing else and do not commit.

## Resume

1. Read `.sandbox/context.md`. If it does not exist, say so and stop.
2. Run `git status --short --branch` and `git rev-parse --short HEAD` once each, and compare their output with `State`. Outside a Git repository, skip this step.
3. Report the differences, or that there are none, and the `Next step`.
4. If there are differences, ask with AskUserQuestion whether to continue with the `Next step`, or stop. Otherwise continue with the `Next step`.
