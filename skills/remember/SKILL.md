---
name: remember
description: Turns an instruction of the user into a rule and adds it to the local rules or the project.
argument-hint: "<instruction>"
disable-model-invocation: true
---

# Remember

Instruction: $ARGUMENTS

If the instruction is empty, ask the user for it and stop.

1. Choose the target by scope:
   - one project: that project's `CLAUDE.md` or a file in its `.claude/rules/`;
   - one language or type of file: `~/.claude/rules/local/<name>.md`, with `paths` frontmatter that matches those files, so that it loads only for them;
   - every project and every file: `~/.claude/rules/local/local.md`, which loads in every session.
2. Read the target file, if it exists, and compare the instruction with it and with the loaded rules:
   - if a rule already covers it, quote that rule with its path and stop;
   - if a rule contradicts it, show both and propose a replacement instead of an addition.
3. Read `~/.claude/rules/instructions.md` and write the rule as it prescribes: one list item, or a section with a heading when several items belong together.
4. If the target is `~/.claude/rules/local/local.md` and it would exceed 2 KB with the rule, say so and propose which rules to move into a file with `paths` or to remove.
5. Show the path of the target file and the exact text to add, with the frontmatter and the first-level heading when the file does not exist yet.
6. Write it with the Edit tool, or the Write tool for a new file; the user approves the write in the permission prompt. For a target in a project, write only when the user asks. Change no other file.
7. If the write is refused, report the error and give no workaround.
