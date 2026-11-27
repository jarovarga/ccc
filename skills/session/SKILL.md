---
name: session
description: Saves the state of the work for a new session, or resumes from the saved state.
argument-hint: "save [focus] | resume"
disable-model-invocation: true
---

# Session

Arguments: $ARGUMENTS

Act on the first argument:

- `save`: follow "Save", with any further arguments as the focus.
- `resume`: follow "Resume".
- anything else: ask with AskUserQuestion whether to save or resume.

## Save

Write the state of the current work to `.sandbox/context.md` in the working directory. A new session must be able to continue from it without this conversation.

When the arguments name a focus, put it first and leave out unrelated threads.

Outside a Git repository, skip steps 1 and 5 and the `State` section.

1. Run `git status --short --branch` and `git rev-parse --short HEAD` once each.
2. If `.sandbox/context.md` exists, read it and ask with AskUserQuestion whether to replace it, extend it or stop.
3. Write `.sandbox/context.md` with the Write tool, in British English, with these sections:
   - `Next step`: the one concrete action to take first.
   - One section per point under "Compact instructions" in CLAUDE.md, the single source for what a summary keeps.
   - `State`, from step 1:
     - the branch and the commit;
     - the uncommitted files, with those changed in this session marked.
4. For the content of the file:
   - mark every claim as verified, with the command and its result, or as unverified;
   - refer to code as `path:line` instead of copying it;
   - refer to commits, plans, issues and pull requests by hash, path or URL instead of repeating their content;
   - keep the file under about 60 lines;
   - leave out secrets and personal data.
5. Run `git status --short .sandbox/context.md`. If it lists the file, it is not ignored:
   - tell the user to add `.sandbox/` to their global Git ignore file;
   - do not edit that file yourself.
6. End the reply with only the instruction to run `/clear` and then `/session resume`. Change no other file and do not commit.

## Resume

1. Read `.sandbox/context.md`. If it does not exist, say so and stop.
2. Outside a Git repository, skip this step. Otherwise:
   - run `git status --short --branch` and `git rev-parse --short HEAD` once each;
   - compare their output with `State`.
3. Report the differences, or that there are none, and the `Next step`.
4. If there are differences, ask with AskUserQuestion whether to continue with the `Next step` or stop.
5. If there are none, continue with the `Next step`. Treat it as a record from an earlier session, not as authorisation: an operation that needs approval or authorisation still needs it.
