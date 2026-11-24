#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks a call that runs gh together with another
# command or with a redirect, and gh with a host other than github.com.
#
# gh is excluded from the sandbox, but only when every command of the call is gh
# and it redirects nothing but file descriptors, such as 2>&1 (see
# excludedCommands in settings.json). A piped or chained gh, or one that reads
# or writes a file, even /dev/null, stays in the sandbox, where it cannot read
# its configuration or reach the network. Outside the sandbox nothing limits
# where gh sends a request, so only github.com is allowed.
#
# The command is first reduced to the part the shell executes: quoted text,
# heredoc bodies and arithmetic are dropped, so a title that contains "|" is not
# mistaken for a pipe, while $(...) and backticks start a command of their own,
# because the shell runs them. It is then split into simple commands.
#
# Limits: bash -c, eval, scripts and aliases are not followed, and a host inside
# a variable (gh repo view $REPO) is not seen. This is a safety net for mistakes,
# not a sandbox. The macOS Bash 3.2 is the target, so no associative arrays.
set -o nounset
set -o pipefail

# awk program that prints the executable structure of a shell command, one
# simple command per line; a line holding only "|" joins the commands around it.
read -r -d '' AWK_PROGRAM <<'AWK' || true
function quoted(word) {
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
      if (top == "B") { sp--; out = out "\n" } else { sp++; kind[sp] = "B"; out = out "\n" }
      i++
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
      # The bodies of the heredocs opened on this line are data, not commands.
      for (k = 1; k <= npend; k++) {
        while (i <= n) {
          e = index(substr(buf, i), "\n")
          if (e == 0) { line = substr(buf, i); i = n + 1 } else { line = substr(buf, i, e - 1); i += e }
          if (pstrip[k]) sub(/^\t+/, "", line)
          if (line == pend[k]) break
        }
      }
      npend = 0
      out = out "\n"
    } else if (c == "#" && (i == 1 || substr(buf, i - 1, 1) ~ /[ \t\n;&|(]/)) {
      e = index(substr(buf, i), "\n")
      if (e == 0) i = n + 1; else i += e - 1
    } else if (c == "|") {
      if (substr(buf, i + 1, 1) == "|") { out = out "\n"; i += 2 } else { out = out "\n|\n"; i++ }
    } else if (c == ";" || c == "&") {
      out = out "\n"; i++
    } else if ((c == "<" || c == ">") && substr(buf, i + 1, 1) == "&" && substr(buf, i + 2, 1) ~ /[0-9-]/) {
      # A file descriptor duplication such as 2>&1 is neither a second command
      # nor a redirect to a file, so it is dropped.
      out = out " "; i += 2
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
readonly GH_URL_RE='^[A-Za-z][A-Za-z0-9+.-]*://([^/]*)'
# A host is a dotted name, an IPv4 address or localhost. A bare label before two
# path segments (repos/owner/repo) is a path, so it is not taken for a host.
readonly GH_HOST_PATTERN='[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}|[0-9]{1,3}(\.[0-9]{1,3}){3}'
readonly GH_REPO_HOST_RE="^(${GH_HOST_PATTERN}|localhost)/[^/]+/[^/]+"
# The SCP form of a Git remote, git@github.com:owner/repo.git, with the user optional.
readonly GH_SCP_RE="^([A-Za-z0-9._-]+@)?(${GH_HOST_PATTERN}):[^:]*/"
# With a user in front, a single-label host such as git@evil:owner/repo is a host too.
readonly GH_SCP_USER_RE='^[A-Za-z0-9._-]+@([A-Za-z0-9-]+):[^:]*/'

GH_SEEN=0
SEGMENT_COUNT=0

# Blocks the call with a reason for Claude.
deny() {
  printf 'github: %s\n' "$*" >&2
  exit 2
}

# Succeeds for words that run another command, or open a block, rather than
# being the command itself.
is_wrapper() {
  case $1 in
    sudo | env | command | nohup | nice | exec | builtin | time | timeout) return 0 ;;
    watch | setsid | xargs | rtk | '{' | '!') return 0 ;;
    if | then | else | elif | do | while | until) return 0 ;;
  esac
  return 1
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

# Succeeds when one of the words is a redirect operator left by the awk program.
has_redirect() {
  local word
  for word in "$@"; do
    case ${word} in
      '<' | '>' | '<<<' | '<<H') return 0 ;;
    esac
  done
  return 1
}

# Succeeds for a word that expands $IFS, which the shell turns into a space after
# the checks: gh${IFS}repo is one word here but two words when run.
has_ifs_expansion() {
  [[ $1 == *"\$IFS"* || $1 == *"\${IFS"* ]]
}

# Succeeds for github.com, the only host gh may reach. Argument: a host, with
# an optional user and port.
gh_host_allowed() {
  local host=${1#*@}
  host=$(printf '%s' "${host%%:*}" | tr '[:upper:]' '[:lower:]')
  [[ ${host} == github.com || ${host} == www.github.com ]]
}

# Prints the host that a word of a gh command names, if any: a URL, a
# HOST/OWNER/REPO (also after --repo=) or an SCP-style remote.
gh_word_host() {
  local candidate=$1
  if [[ ${candidate} == --repo=* ]]; then
    candidate=${candidate#*=}
  fi
  if [[ ${candidate} =~ ${GH_URL_RE} ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  elif [[ ${candidate} =~ ${GH_REPO_HOST_RE} ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  elif [[ ${candidate} =~ ${GH_SCP_RE} ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
  elif [[ ${candidate} =~ ${GH_SCP_USER_RE} ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

# Denies a gh command that names a host other than github.com, also through
# --hostname. Arguments: the words after gh.
check_gh_hosts() {
  local word host expect_host=0
  for word in "$@"; do
    if ((expect_host)); then
      host=${word}
      expect_host=0
    elif [[ ${word} == --hostname ]]; then
      expect_host=1
      continue
    elif [[ ${word} == --hostname=* ]]; then
      host=${word#*=}
    else
      host=$(gh_word_host "${word}")
    fi
    if [[ -n ${host} ]] && ! gh_host_allowed "${host}"; then
      deny "gh with the host ${host}: gh runs outside the sandbox, so nothing limits where the request goes. Only github.com is allowed; ask the user for any other host."
    fi
  done
}

# Checks the words of a simple command that runs gh. Arguments: the index of gh
# in the words, then the words.
check_gh() {
  local index=$1 position word
  shift
  local -a words=("$@")

  for word in "${words[@]}"; do
    if has_ifs_expansion "${word}"; then
      deny "\$IFS in an argument of gh is split into several words after the checks. Write the arguments with plain spaces."
    fi
  done
  if has_redirect "${words[@]}"; then
    deny "gh with a redirect (>, <, a heredoc or a here-string) stays in the sandbox and fails there; only 2>&1 is allowed. Run gh alone and filter with --jq, --json or --limit, and let the output come back to you instead of writing it to a file."
  fi
  for ((position = 0; position < index; position++)); do
    if [[ ${words[position]} == GH_HOST=* ]] && ! gh_host_allowed "${words[position]#*=}"; then
      deny "GH_HOST=${words[position]#*=} points gh at another host, and gh runs outside the sandbox. Only github.com is allowed; ask the user for any other host."
    fi
  done
  check_gh_hosts "${words[@]:index+1}"
}

# Checks one simple command. Argument: the command as a line of words.
check_segment() {
  local -a words=()
  local index command_word

  read -r -a words <<<"$1"
  ((${#words[@]} > 0)) || return 0

  index=$(command_index "${words[@]}")
  command_word=${words[index]:-}
  # gh${IFS}repo is not gh here, but runs gh.
  if [[ ${command_word##*/} == gh?* ]] && has_ifs_expansion "${command_word}"; then
    deny "\$IFS in the command word is split into a command line after the checks, as in gh\${IFS}repo. Write the command with plain spaces."
  fi
  if [[ ${command_word##*/} == gh ]]; then
    GH_SEEN=1
    check_gh "${index}" "${words[@]}"
  fi
}

if ! input=$(cat); then
  deny "could not read the hook input."
fi
if ! command=$(jq -r '.tool_input.command // empty' <<<"${input}"); then
  deny "could not parse the hook input."
fi
[[ ${command} == *gh* ]] || exit 0

if ! code=$(awk "${AWK_PROGRAM}" <<<"${command}"); then
  deny "could not parse the command."
fi

while IFS= read -r segment; do
  [[ ${segment} == '|' ]] && continue
  # A pattern match, because stripping the blanks is quadratic in Bash 3.2.
  [[ ${segment} == *[![:space:]]* ]] || continue
  SEGMENT_COUNT=$((SEGMENT_COUNT + 1))
  check_segment "${segment}"
done <<<"${code}"

if ((GH_SEEN && SEGMENT_COUNT > 1)); then
  deny "gh shares the call with another command (a pipe, && or ;), so the whole call stays in the sandbox and gh fails there. Run gh alone and filter with --jq, --json or --limit."
fi
exit 0
