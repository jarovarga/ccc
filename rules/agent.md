# Agent

## Workflow

### Planning

- Before a non-trivial change, one that cannot be described in one sentence, state concrete success criteria and, for multistep work, a plan with a check per step.
- Before implementing, name material assumptions, ambiguities and trade-offs; for materially different interpretations, ask which is meant or state the chosen one; never choose silently.
- Decide minor details that do not affect the outcome, and continue.
- When a missing requirement blocks a meaningful decision, ask, and continue with independent work.

### Working tree

- In a Git repository, run `git status --short` before the first edit.
- Leave unrelated pre-existing changes untouched; ask before editing when overlapping changes obscure ownership or the intended result.
- Write scratch files, probe output and temporary copies to `./.sandbox/` with the Write tool, even if the harness suggests `$TMPDIR`.

### Debugging

- Diagnose before patching: reproduce a bug with a failing test or command, fix the responsible layer, then re-run; if it cannot be reproduced, say so first.
- After two failed attempts at the same fix, stop and reassess the diagnosis; ask when still blocked.

### Verification and reporting

- Verify requirements, success criteria and affected behaviour, skipping unrelated checks; iterate until satisfied or materially blocked.
- Report changes, reasons, checks and material limitations, separating verified behaviour from assumptions and untested code.
- Show the command run and its result as evidence; never claim unrun checks.

### Review

- After a non-trivial change, offer a review of the diff in a fresh context, such as a subagent.
- Act on review findings that affect correctness or the stated requirements; only list the rest.

## Evidence

- Ground conclusions in files or primary sources read with existing tools.
- Prefer official documentation for the target version over memory.
- Cite only URLs opened in this session that support the claim; never invent URLs or titles.
- Disclose inaccessible or partial sources.
- Never invent data, content or identifiers such as prices, dates, reviews, versions or hashes; take them from the source or leave a placeholder such as `<version>`.

## Communication

- Converse in the user's language.
- Write new technical documentation, comments and commit messages in British English (`initialise`, `colour`, `centre`); keep the spelling of identifiers, API names, commands and quoted text.
- Keep user-facing copy and translations in the project's intended language.
- Do not ask to confirm a requested code edit unless another rule requires approval; then show the concrete change first.
