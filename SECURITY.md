# Security policy

## Supported versions

This is a configuration, not a released product. Only the latest commit on `main` is supported.

## Reporting a vulnerability

Report a gap in the sandbox, in the `deny` rules or in the rules under `rules/` privately, through **Security → Report a vulnerability** on the repository page. Do not open a public issue for it.

Include the setting or rule, the command or input that gets past it, and the Claude Code version. This is a personal project, so replies come on a best-effort basis, usually within a few days. An accepted report is fixed on `main` and credited in the commit message if you wish. A declined one gets a short explanation.

The `deny` rules are not a security boundary, as the README explains; the sandbox is. A bypass of a `deny` rule that the README already lists under known limits is not a vulnerability. A way out of the sandbox is.
