# Code

Where the project's framework or coding standard prescribes its own equivalent of a rule here, follow it. For input handling, output escaping and security tests, an equivalent must give at least the same protection.

## Formatting and validation

- Treat the project's `.editorconfig`, formatter, linter and static-analysis configurations as authoritative.
- Target the language or platform version the project declares, and use a newer feature only when the target supports it.
- Run project commands with the command runner named in the project instructions.
- In agent instructions, refer to the project configuration for command definitions; never copy them.
- Run and document only the scripts that the project's configuration defines; never invent one.
- At the start of work on a language, check whether the project configures its linter or validator; if it configures none, flag it once in the report and continue, and do not add one unasked.

## Input and output

- Build SQL, URLs, shell commands and markup with parameter binding or structured APIs, never by concatenating input; allow-list values that cannot be bound, such as table and column names, sort directions and shell commands.
- Output unescaped markup only where the task or the project requires raw markup, and say so in a comment.
- Never deserialise untrusted data with a native object serialiser; use JSON.
- Never let input supply a whole file path; accept only known-good names or indexes.
- Normalise a path before using it in file operations and reject a result outside the allowed base directory.

## Robustness

- Store and process times in UTC and convert them only for display; never assume a day has 86,400 seconds.
- Give every network call a timeout and handle its failure explicitly.
- Wrap errors with their original cause and never let low-level or vendor errors cross a layer boundary.

## Changes

- Before the first code edit in a project, read its `README.md` and the documentation relevant to the change.
- Use the smallest sufficient solution: add files, abstractions, interfaces, dependencies, workflows or handling only for a concrete need of the task, without speculative features or unrelated refactoring.
- Reuse existing components, tokens, helpers, tools, dependencies, frameworks, build systems and conventions.
- Normalise only the lines and blocks that the change edits.
- Handle dead code as follows:
  - remove imports, variables and functions that the change orphaned;
  - mention other dead code in the report instead of deleting it.
- Before renaming or removing any of these, check applicable code, templates, styles, scripts, tests and analytics dependencies:
  - a route, method or API;
  - a CSS class, ID, data attribute or custom property;
  - a configuration key.
- Respect deliberate removals: restore removed code, behaviour or documentation only when requested by the task.

## Design

- Pass a unit its individual dependencies, not a dependency container used as a service locator.
- Read the environment once at bootstrap and inject configuration.
- Prefer modern standards-based solutions and native platform features over custom code or new dependencies.
- Keep cyclomatic complexity per function around 10 or below; split a unit when its complexity grows.
- Use guard clauses and early returns, or lookups and polymorphism, instead of long conditional chains.
- When refactoring, preserve observable behaviour; do not modernise syntax or rename identifiers for style alone.

## Comments

- Comment on reasons: workarounds, accessibility, constraints or unusual calculations.
- Remove stale comments; avoid narrating obvious operations.
- Document public APIs (parameters, return values, relevant exceptions), not internals.

## Accessibility

- Meet WCAG 2.2 AA in user-facing interfaces.

## Testing

- If the project has tests, add focused regression coverage for meaningful behaviour changes, following existing test conventions, and cover every change to authentication, authorisation, input handling, secrets or personal data with a test.
- Avoid implementation-mirroring tests and tests for reversible formatting-only changes.
- In tests, never call live external services, and restore changed global state.
- Prefer real collaborators or handwritten fakes over mocks.
- Inject time when behaviour depends on it, or freeze it with the framework's test clock.
