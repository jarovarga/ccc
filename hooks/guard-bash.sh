#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks recursive deletion of broad paths, git push,
# Docker commands that destroy volumes, SQL that drops a database or table, and
# a call that runs gh together with another command.
#
# gh is excluded from the sandbox, but only when every command of the call is gh
# (see excludedCommands in settings.json). A piped or chained gh stays in the
# sandbox, where it cannot read its configuration or reach the network.
#
# It backs up the permission rules in settings.json: those match the text of a
# command and miss forms such as /bin/rm, xargs rm or git --no-pager push.
#
# The command is first reduced to the part the shell executes: quoted text,
# heredoc bodies and arithmetic are dropped, so a commit message that mentions
# "rm -rf" is not mistaken for a command, while the contents of $(...) and
# backticks are kept, because the shell runs them. It is then split into simple
# commands and each one is checked. SQL is the exception to dropping quoted text:
# a quoted string or heredoc that contains DROP DATABASE or DROP TABLE leaves a
# marker, which blocks when the same pipeline runs a SQL client.
#
# Limits: bash -c, eval, scripts and aliases are not followed, an empty pair of
# quotes inside a word hides it (g""it), and the body of an unquoted heredoc is
# not inspected although the shell expands $(...) in it. This is a safety net for
# mistakes, not a sandbox. The macOS Bash 3.2 is the target, so no associative
# arrays or case-conversion expansions.
set -euo pipefail

readonly SQL_DROP_MARKER=__SQLDROP__

# awk program that prints the executable structure of a shell command, one
# simple command per line. A line holding only "|" joins the commands around it
# into one pipeline.
read -r -d '' AWK_PROGRAM <<'AWK' || true
function quoted(word,   lower) {
  lower = tolower(word)
  if (lower ~ /drop[ \t\n]+(database|table)/) return " __SQLDROP__ "
  if (word == "" || word ~ /[ \t\n]/) return "\"\""
  gsub(/[;&|()<>`]/, "_", word)
  return word
}
# Returns the position after the arithmetic expression that starts at pos with "((".
function skip_arithmetic(pos,   depth, ch) {
  depth = 0
  while (pos <= n) {
    ch = substr(buf, pos, 1)
    pos++
    if (ch == "(") depth++
    else if (ch == ")") { depth--; if (depth == 0) break }
  }
  return pos
}
{ buf = buf $0 "\n" }
END {
  n = length(buf)
  i = 1
  sp = 0
  npend = 0
  while (i <= n) {
    c = substr(buf, i, 1)
    top = (sp > 0) ? kind[sp] : "N"
    if (top == "D") {
      if (c == "\\") { dtext[sp] = dtext[sp] substr(buf, i + 1, 1); i += 2 }
      else if (c == "\"") { w = hasc[sp] ? "" : dtext[sp]; sp--; out = out quoted(w); i++ }
      else if (substr(buf, i, 3) == "$((") { hasc[sp] = 1; i = skip_arithmetic(i + 1) }
      else if (c == "$" && substr(buf, i + 1, 1) == "(") {
        hasc[sp] = 1; sp++; kind[sp] = "C"; depth[sp] = 0; out = out "\n"; i += 2
      }
      else if (c == "`") { hasc[sp] = 1; sp++; kind[sp] = "B"; out = out "\n"; i++ }
      else { dtext[sp] = dtext[sp] c; i++ }
      continue
    }
    if (c == "\\") {
      nx = substr(buf, i + 1, 1)
      if (nx == "\n") out = out " "
      else if (nx ~ /[;&|()<>` \t]/) out = out "_"
      else out = out nx
      i += 2
    } else if (c == "'") {
      j = index(substr(buf, i + 1), "'")
      if (j == 0) { w = substr(buf, i + 1); i = n + 1 } else { w = substr(buf, i + 1, j - 1); i += j + 1 }
      out = out quoted(w)
    } else if (c == "$" && substr(buf, i + 1, 1) == "'") {
      i += 2; w = ""
      while (i <= n) {
        ch = substr(buf, i, 1)
        if (ch == "\\") { w = w substr(buf, i + 1, 1); i += 2 }
        else if (ch == "'") { i++; break }
        else { w = w ch; i++ }
      }
      out = out quoted(w)
    } else if (c == "\"") {
      sp++; kind[sp] = "D"; dtext[sp] = ""; hasc[sp] = 0; i++
    } else if (substr(buf, i, 3) == "$((") {
      i = skip_arithmetic(i + 1); out = out " 0 "
    } else if (substr(buf, i, 2) == "((" && (i == 1 || substr(buf, i - 1, 1) ~ /[ \t\n;&|(]/)) {
      i = skip_arithmetic(i); out = out " 0 "
    } else if (c == "$" && substr(buf, i + 1, 1) == "(") {
      sp++; kind[sp] = "C"; depth[sp] = 0; out = out "\n"; i += 2
    } else if (c == "`") {
      if (top == "B") sp--; else { sp++; kind[sp] = "B" }
      out = out "\n"; i++
    } else if (c == "(") {
      if (top == "C") depth[sp]++
      out = out "\n"; i++
    } else if (c == ")") {
      if (top == "C") { if (depth[sp] > 0) depth[sp]--; else sp-- }
      out = out "\n"; i++
    } else if (substr(buf, i, 3) == "<<<") {
      out = out " <<< "; i += 3
    } else if (substr(buf, i, 2) == "<<") {
      i += 2; strip = 0
      if (substr(buf, i, 1) == "-") { strip = 1; i++ }
      while (substr(buf, i, 1) ~ /[ \t]/) i++
      q = substr(buf, i, 1); d = ""
      if (q == "'" || q == "\"") {
        j = index(substr(buf, i + 1), q)
        if (j == 0) { d = substr(buf, i + 1); i = n + 1 } else { d = substr(buf, i + 1, j - 1); i += j + 1 }
      } else {
        if (q == "\\") i++
        while (i <= n && substr(buf, i, 1) !~ /[ \t\n;&|()<>]/) { d = d substr(buf, i, 1); i++ }
      }
      npend++; pend[npend] = d; pstrip[npend] = strip; out = out " <<H "
    } else if (c == "\n") {
      i++
      body = ""
      for (k = 1; k <= npend; k++) {
        while (i <= n) {
          e = index(substr(buf, i), "\n")
          if (e == 0) { line = substr(buf, i); i = n + 1 } else { line = substr(buf, i, e - 1); i += e }
          if (pstrip[k]) sub(/^\t+/, "", line)
          if (line == pend[k]) break
          body = body " " line
        }
      }
      npend = 0
      if (tolower(body) ~ /drop[ \t]+(database|table)/) out = out " __SQLDROP__ "
      out = out "\n"
    } else if (c == "#" && (i == 1 || substr(buf, i - 1, 1) ~ /[ \t\n;&|(]/)) {
      e = index(substr(buf, i), "\n")
      if (e == 0) i = n + 1; else i += e - 1
    } else if (c == "|") {
      if (substr(buf, i + 1, 1) == "|") { out = out "\n"; i += 2 } else { out = out "\n|\n"; i++ }
    } else if (c == ";" || c == "&") {
      out = out "\n"; i++
    } else if (c == "<" || c == ">") {
      out = out " " c " "; i++
    } else {
      out = out c; i++
    }
  }
  printf "%s", out
}
AWK
readonly AWK_PROGRAM

readonly ASSIGNMENT_RE='^[A-Za-z_][A-Za-z0-9_]*='
readonly REDIRECT_RE='^[0-9]*[<>]+(.*)$'
readonly WORKING_DIRECTORY_RE="^\\\$(PWD|\\{PWD\\})\$"
readonly VARIABLE_ROOT_RE='^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?(/|/\*)$'

CWD=""
SQL_CLIENT=0
SQL_DROP=0
GH_SEEN=0
SEGMENT_COUNT=0

deny() {
  printf 'guard-bash: %s\n' "$1" >&2
  exit 2
}

# Succeeds for words that run another command, or open a block, rather than
# being the command itself.
is_wrapper() {
  case $1 in
    sudo | env | command | nohup | nice | exec | builtin | time | timeout) return 0 ;;
    watch | setsid | xargs | '{' | '!') return 0 ;;
    if | then | else | elif | do | while | until) return 0 ;;
  esac
  return 1
}

is_recursive_flag() {
  case $1 in
    --recursive) return 0 ;;
    -[!-]*) [[ $1 == *[rR]* ]] ;;
    *) return 1 ;;
  esac
}

# Prints the path with a leading ~ or $HOME replaced by the home directory, when known.
expand_home() {
  local path=$1 home=${HOME:-}
  local tilde="~" variable="\$HOME" braced="\${HOME}"
  if [[ -z ${home} ]]; then
    printf '%s' "${path}"
    return 0
  fi
  case ${path} in
    "${tilde}" | "${tilde}"/*) printf '%s%s' "${home%/}" "${path#"${tilde}"}" ;;
    "${variable}" | "${variable}"/*) printf '%s%s' "${home%/}" "${path#"${variable}"}" ;;
    "${braced}" | "${braced}"/*) printf '%s%s' "${home%/}" "${path#"${braced}"}" ;;
    *) printf '%s' "${path}" ;;
  esac
}

# Prints the path with "." and ".." resolved lexically. A relative path is made
# absolute with the working directory when that is known.
normalise_path() {
  local rest=$1 part stack="" prefix=""
  if [[ ${rest} == /* ]]; then
    prefix=/
  elif [[ -n ${CWD} && ${rest} != "~"* && ${rest} != "\$"* ]]; then
    prefix=/
    rest=${CWD}/${rest}
  fi

  while [[ -n ${rest} ]]; do
    part=${rest%%/*}
    if [[ ${rest} == */* ]]; then
      rest=${rest#*/}
    else
      rest=""
    fi
    case ${part} in
      "" | .) ;;
      ..)
        if [[ ${stack} == */* && ${stack} != ..* ]]; then
          stack=${stack%/*}
        elif [[ -n ${stack} && ${stack} != .. && ${stack} != ../* ]]; then
          stack=""
        elif [[ -z ${prefix} ]]; then
          stack=${stack:+${stack}/}..
        fi
        ;;
      *) stack=${stack:+${stack}/}${part} ;;
    esac
  done
  printf '%s%s' "${prefix}" "${stack}"
}

# Succeeds for a path whose recursive deletion would wipe far more than the
# task can need: the filesystem root, a top-level system directory, a home
# directory, the working directory or any directory above it, a bare wildcard,
# or a variable followed by a slash, which becomes the root when it is empty.
is_broad_path() {
  local path=$1 base normalised
  if [[ ${path} =~ ${VARIABLE_ROOT_RE} || ${path} =~ ${WORKING_DIRECTORY_RE} ]]; then
    return 0
  fi
  base=${path%/}
  base=${base%/\*}
  base=${base%/}
  if [[ ${path} == /* && -z ${base} ]]; then
    return 0
  fi
  case ${base} in
    "*" | ".*" | ..) return 0 ;;
  esac

  normalised=$(normalise_path "$(expand_home "${base}")")
  case ${normalised} in
    "" | / | "~") return 0 ;;
    /Users/* | /home/*) [[ ${normalised#/*/} != */* ]] && return 0 ;;
  esac
  if [[ ${normalised} == /* && ${normalised#/} != */* ]]; then
    return 0
  fi
  if [[ -n ${HOME:-} && ${normalised} == "${HOME%/}" ]]; then
    return 0
  fi
  if [[ ${normalised} == /* && -n ${CWD} && (${CWD} == "${normalised}" || ${CWD} == "${normalised}"/*) ]]; then
    return 0
  fi
  return 1
}

# Arguments: rm and its arguments.
check_rm() {
  local arg recursive=0 end_of_options=0 skip_next=0
  shift

  for arg in "$@"; do
    case ${arg} in
      --) break ;;
      --no-preserve-root) deny "rm --no-preserve-root is never needed. Delete specific paths instead." ;;
    esac
    if is_recursive_flag "${arg}"; then
      recursive=1
    fi
  done
  ((recursive)) || return 0

  for arg in "$@"; do
    if ((skip_next)); then
      skip_next=0
      continue
    fi
    if ((!end_of_options)); then
      case ${arg} in
        --)
          end_of_options=1
          continue
          ;;
        -*) continue ;;
      esac
    fi
    if [[ ${arg} =~ ${REDIRECT_RE} ]]; then
      if [[ -z ${BASH_REMATCH[1]} ]]; then
        skip_next=1
      fi
      continue
    fi
    if is_broad_path "${arg}"; then
      deny "recursive rm on '${arg}' is too broad. Name the specific directory to delete."
    fi
  done
}

# Arguments: git and its arguments. Pushing is left to the user, so any push is
# blocked, whatever its flags; the subcommand is the first word that is not an option.
check_git() {
  local arg skip_next=0
  shift

  for arg in "$@"; do
    if ((skip_next)); then
      skip_next=0
      continue
    fi
    case ${arg} in
      -C | -c | --git-dir | --work-tree | --namespace) skip_next=1 ;;
      -*) ;;
      push) deny "pushing is left to the user. Ask them to run it, for example with '! git push'." ;;
      *) return 0 ;;
    esac
  done
}

# Arguments: docker (or docker-compose) and its arguments.
check_docker() {
  local arg compose=0 down=0 volume=0 system=0
  if [[ ${1##*/} == docker-compose ]]; then
    compose=1
  fi
  shift

  for arg in "$@"; do
    case ${arg} in
      compose) compose=1 ;;
      down) if ((compose)); then down=1; fi ;;
      volume) volume=1 ;;
      system) system=1 ;;
      rm | remove | prune)
        if ((volume)); then
          deny "docker volume ${arg} deletes data permanently. Ask the user to run it."
        fi
        ;;
      -v)
        if ((down)); then
          deny "docker compose down -v deletes the volumes and their data. Run it without -v, or ask the user."
        fi
        ;;
      --volumes)
        if ((down || system)); then
          deny "--volumes deletes the volumes and their data. Run the command without it, or ask the user."
        fi
        ;;
      psql | mysql | mariadb | sqlite3) SQL_CLIENT=1 ;;
    esac
  done
  return 0
}

# Succeeds for the options of a wrapper that take a separate value, such as
# sudo -u <user> or nice -n <count>.
is_wrapper_value_option() {
  case $1 in
    -u | -g | -n | -C | -s | -d | -I | -L | -P | -S | -a | -k | -h | -R | -U) return 0 ;;
    --user | --group | --signal | --kill-after | --adjustment | --chdir) return 0 ;;
    --max-args | --max-procs | --delimiter | --arg-file | --replace) return 0 ;;
  esac
  return 1
}

# Succeeds for a word that only configures the wrapper in front of it: an option
# or a number such as the duration of timeout. Anything else is the command.
is_wrapper_argument() {
  [[ $1 == -* || $1 =~ ^[0-9][0-9.]*[smhd]?$ ]]
}

# Prints the index of the command a simple command runs, after its leading
# assignments and wrappers. Arguments: the words of the command.
command_index() {
  local count=$# index=0 after_wrapper=0
  local -a words=("$@")

  while ((index < count)); do
    if [[ ${words[index]} =~ ${ASSIGNMENT_RE} ]]; then
      :
    elif is_wrapper "${words[index]}"; then
      after_wrapper=1
    elif ((after_wrapper)) && is_wrapper_argument "${words[index]}"; then
      if is_wrapper_value_option "${words[index]}"; then
        index=$((index + 1))
      fi
    else
      break
    fi
    index=$((index + 1))
  done
  printf '%s' "${index}"
}

# Checks one simple command. Argument: the command as a line of words.
# SQL_DROP only counts when it comes from the SQL client itself or from a
# command that feeds it, so a search for "drop table" after the client is allowed.
check_segment() {
  local -a words=()
  local count index word has_marker=0 prior_client=${SQL_CLIENT}

  read -r -a words <<<"$1"
  count=${#words[@]}
  ((count > 0)) || return 0

  for word in "${words[@]}"; do
    if [[ ${word} == "${SQL_DROP_MARKER}" ]]; then
      has_marker=1
    fi
  done

  SQL_CLIENT=0
  index=$(command_index "${words[@]}")
  if ((index < count)); then
    case ${words[index]##*/} in
      rm) check_rm "${words[@]:index}" ;;
      git) check_git "${words[@]:index}" ;;
      docker | docker-compose) check_docker "${words[@]:index}" ;;
      gh) GH_SEEN=1 ;;
      psql | mysql | mariadb | sqlite3) SQL_CLIENT=1 ;;
    esac
  fi

  if ((has_marker && (SQL_CLIENT || !prior_client))); then
    SQL_DROP=1
  fi
  if ((prior_client)); then
    SQL_CLIENT=1
  fi
  return 0
}

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"${input}")
CWD=$(jq -r '.cwd // empty' <<<"${input}")
[[ -n ${command} ]] || exit 0
# The working directory by another name: treat $(pwd) and `pwd` as $PWD.
command=${command//\$(pwd)/\$PWD}
command=${command//\`pwd\`/\$PWD}
# A file descriptor redirect such as 2>&1 is not a second command.
command=${command//>&/>}

code=$(awk "${AWK_PROGRAM}" <<<"${command}")
# What follows find -exec is a command of its own.
for exec_option in -exec -execdir -ok -okdir; do
  code=${code// ${exec_option} /$'\n'}
done

previous_was_pipe=0
while IFS= read -r segment; do
  if [[ ${segment} == '|' ]]; then
    previous_was_pipe=1
    continue
  fi
  [[ -n ${segment//[[:space:]]/} ]] || continue
  if ((!previous_was_pipe)); then
    SQL_CLIENT=0
    SQL_DROP=0
  fi
  previous_was_pipe=0
  SEGMENT_COUNT=$((SEGMENT_COUNT + 1))

  check_segment "${segment}"
  if ((SQL_CLIENT && SQL_DROP)); then
    deny "the command drops a database or table. Ask the user to run destructive SQL themselves."
  fi
done <<<"${code}"

if ((GH_SEEN && SEGMENT_COUNT > 1)); then
  deny "gh shares the call with another command (a pipe, && or ;), so the whole call stays in the sandbox and gh fails there. Run gh alone and filter with --jq, --json or --limit."
fi
