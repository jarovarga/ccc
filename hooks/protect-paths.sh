#!/usr/bin/env bash
# PreToolUse hook for Edit, Write and NotebookEdit. Blocks changes to dependency directories
# and lock files, which belong to a package manager. Environment files are not
# handled here: the deny rules in settings.json already cover them.
#
# Directories are matched against the path relative to the project (the cwd of
# the session), so a checkout that happens to live under a directory named
# "vendor" is not blocked as a whole.
set -euo pipefail

deny() {
  printf 'protect-paths: %s\n' "$*" >&2
  exit 2
}

input=$(cat)
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"${input}")
cwd=$(jq -r '.cwd // empty' <<<"${input}")
[[ -n ${file} ]] || exit 0

# Refuse unnormalised paths, which could hide the real target from the checks below.
if [[ ${file} == */../* || ${file} == */.. ]]; then
  deny "the path ${file} contains '..'. Use a normalised absolute path."
fi

relative=${file}
if [[ -n ${cwd} && ${file} == "${cwd}"/* ]]; then
  relative=${file#"${cwd}"/}
fi

# macOS volumes are usually case-insensitive, so Composer.lock is the same file.
base=$(tr '[:upper:]' '[:lower:]' <<<"${file##*/}")
relative=$(tr '[:upper:]' '[:lower:]' <<<"${relative}")
case ${base} in
  composer.lock | package-lock.json)
    deny "${base} is generated." \
      "Change dependencies through Composer or npm so the lock file stays consistent."
    ;;
esac

case /${relative}/ in
  */vendor/* | */node_modules/*)
    deny "${relative} is a dependency directory managed by Composer or npm." \
      "Change the project's own code or the dependency through the package manager."
    ;;
esac
