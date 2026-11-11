# Code

## Formatting and validation

- Follow the project's `.editorconfig` and formatter settings.
- Target the language or platform version the project declares; use a newer feature only when the target supports it.
- Run relevant existing formatter, validator, linter, test and build commands from project configuration, using the command runner named in the project instructions.
- Never duplicate command definitions in agent instructions or invent scripts.
- Treat project formatter, linter and static-analysis configurations as authoritative.
- Never hide errors, disable rules, add inline exceptions or alter configuration merely to pass checks or invalid code.
- Do not add an incidental linter.
- At the start of work on a language, check whether the project configures its linter or validator.
- If the project configures none, flag it once in the report and continue; do not add one unasked.

## Changes

- Apply YAGNI: use the smallest sufficient solution and do not add handling for scenarios that cannot occur.
- Reuse existing components, tokens, helpers, tools, dependencies, frameworks, build systems and conventions.
- Add files, abstractions, dependencies or workflows only as the task needs them; avoid speculative features and unrelated refactoring.
- Normalise only touched code.
- Remove imports, variables and functions that the change orphaned; mention other dead code in the report instead of deleting it.
- Never leave debugging calls or output in committed code.
- Preserve public APIs, module boundaries and event semantics unless the task requires changes.
- Before renaming or removing a route, method, API, CSS class, ID, data attribute, custom property or configuration key, check applicable code, templates, styles, scripts, tests and analytics dependencies.
- Respect deliberate removals: restore removed code, behaviour or documentation only when requested by the task.

## Design

- Apply SOLID where it reduces real coupling or duplication: one responsibility per unit, narrow interfaces, injected dependencies and extension without modifying stable code.
- Do not add an interface or layer without a concrete need.
- Expose the smallest useful public API.
- Never pass a dependency container into a unit as a service locator.
- Read the environment once at bootstrap and inject configuration.
- Prefer modern standards-based solutions and native platform features over custom code or new dependencies.
- Keep cyclomatic complexity per function around 10 or below; split a unit when its complexity grows.
- Use guard clauses and early returns, or lookups and polymorphism, instead of long conditional chains.
- Use focused functions instead of nested conditions or loops.
- Name meaningful or repeated literals as constants or tokens; reuse existing ones before adding new ones.
- Optimise only with measured evidence; never trade maintainability for unproven micro-optimisation.
- When refactoring, preserve observable behaviour; do not modernise syntax or rename identifiers for style alone.

## Comments

- Comment on reasons: workarounds, accessibility, constraints or unusual calculations.
- Remove stale comments; avoid narrating obvious operations.
- Document public APIs (parameters, return values, relevant exceptions), not internals.

## Robustness

- Store and process times in UTC and convert them only for display; never assume a day has 86,400 seconds.
- Format dates and numbers through locale-aware APIs, never by manual string replacement.
- Use Unicode-aware string functions for text that can contain non-ASCII characters.
- Give every network call a timeout and handle its failure explicitly.
- Do not make network calls inside a database transaction.
- Catch exceptions only to handle or translate them.
- Never swallow errors.
- Check a return value that signals failure explicitly; never rely on truthiness.
- Release resources on every path, including failure.
- Wrap errors with their original cause and never let low-level or vendor errors cross a layer boundary.
- Catch broadly only at the entry-point boundary, to log and return a generic error.

## Input and output

- Validate input at the boundary.
- Escape output for its context by default; output unescaped markup only when deliberately required.
- Build SQL, URLs, shell commands and markup with parameter binding or structured APIs, never by concatenating input.
- Allow-list values that cannot be bound, such as table and column names, sort directions and shell commands.
- Never deserialise untrusted data with a native object serialiser; use JSON.
- Never let input supply a whole file path; accept only known-good names or indexes.
- Normalise a path before using it in file operations and reject a result outside the allowed base directory.

## Accessibility

- Meet WCAG 2.2 AA in user-facing interfaces.

## Testing

- Add focused regression coverage for meaningful behaviour changes if the project has tests, following existing test conventions.
- Cover changes to authentication, authorisation, input handling, secrets or personal data with a test if the project has tests.
- Avoid implementation-mirroring tests and tests for reversible formatting-only changes.
- In tests, never call live external services, and restore changed global state.
- Prefer real collaborators or handwritten fakes over mocks.
- Inject time when behaviour depends on it, or freeze it with the framework's test clock.
