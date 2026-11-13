#!/usr/bin/env bash
# PostToolUse hook for Bash. Appends every command to ~/.claude/logs/bash.jsonl
# as one JSON object per line: UTC time, working directory and command. Run
# hooks/bash-patterns.sh to see which commands recur.
#
# Commands can contain secrets, so the file is private (mode 600) and common
# secret forms are redacted on a best-effort basis: assignments (also quoted)
# to names containing token, secret, password, passwd, key or auth, password,
# token and key options, URL credentials, bearer and basic tokens, auth headers
# and well-known token prefixes. Other forms are not recognised, so the log is
# not safe to share. It is never rotated; delete it when it gets too large.
#
# PostToolUse delivers the command with &, < and > HTML-escaped, which would
# hide heredocs and pipelines from bash-patterns.sh, so they are restored first.
set -euo pipefail

umask 077
readonly LOG_DIR=${HOME}/.claude/logs
readonly LOG_FILE=${LOG_DIR}/bash.jsonl

input=$(cat)
mkdir -p -- "${LOG_DIR}"

jq -c '
  def redact:
    gsub("(?<name>[A-Za-z0-9_]*(token|secret|passw(or)?d|key|auth)[A-Za-z0-9_]*)=(\"[^\"]*\"|\u0027[^\u0027]*\u0027|[^ \"\u0027]+)"; "\(.name)=<redacted>"; "i")
    | gsub("(?<option>--?[A-Za-z-]*(token|secret|passw(or)?d|key|auth)[A-Za-z-]*)(?<sep>[ =])(\"[^\"]*\"|\u0027[^\u0027]*\u0027|[^ \"\u0027]+)"; "\(.option)\(.sep)<redacted>"; "i")
    | gsub("(?<client>mysql[a-z]*( [^|;&\n]*?)? -p)[^ ]+"; "\(.client)<redacted>")
    | gsub("(?<scheme>[A-Za-z][A-Za-z0-9+.-]*://)[^ /@:]+:[^ /@]+@"; "\(.scheme)<redacted>@")
    | gsub("(?<scheme>Bearer|Basic) [A-Za-z0-9._~+/=-]+"; "\(.scheme) <redacted>"; "i")
    | gsub("(?<header>(Authorization|X-Api-Key|X-Auth-Token|Cookie)): [^\"\u0027]*"; "\(.header): <redacted>"; "i")
    | gsub("(ghp_|gho_|github_pat_|sk-|xox[bap]-|AKIA)[A-Za-z0-9_-]{8,}"; "<redacted>");
  select((.tool_input.command // "") != "")
  | {
      time: (now | todate),
      cwd: .cwd,
      command: (
        .tool_input.command
        | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&amp;"; "&")
        | redact
      )
    }
' <<<"${input}" >>"${LOG_FILE}"
