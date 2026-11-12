# Opt-in

Optional rules and settings for single projects. Nothing in this directory is loaded on its own: it is not under `rules/`, `CLAUDE.md` does not import it and it is not installed into `~/.claude/`. A project takes what it needs by copying it into its own `.claude/`.

Everything here, in `conventions/` and in `frameworks/`, is the author's own rules. It is kept as a template that shows how to write such rules, not as a standard to adopt.

## Difference from `rules/stack/`

`rules/stack/` holds what is true for a language wherever it is used, so it applies to every project and loads whenever a matching file is read. `opt-in/` holds what a project decides: a convention of its own or a framework. Two projects in the same language can choose differently, so the choice stays with the project.

## Contents

| Path | Holds |
| --- | --- |
| `conventions/` | One rule file with `paths` frontmatter per convention. |
| `frameworks/<framework>/` | `README.md`, `settings.json` and `rules/<framework>.md` for each framework. |

## Using a convention

Write the project's own rules in the same form as the files in `conventions/`. To use one as a starting point:

- copy the file from `conventions/` into the project's `.claude/rules/`;
- adjust its `paths` to the project's layout;
- change or remove every rule the project does not follow.

## Using a framework

Copy `rules/` of the framework into the project's `.claude/rules/` and merge its `settings.json` into the project's `.claude/settings.json`. The `README.md` of the framework gives the reasoning for each setting.
