# shellcheck shell=bash
# Splits a shell command into the simple commands that the shell runs, for the
# Bash hooks of the opt-in topics. It is sourced, never run, and installed as
# ~/.claude/hooks/lib/shell.sh next to the hooks that use it.
#
# The command is first reduced to the part the shell executes: quoted text,
# heredoc bodies and arithmetic are dropped, so a commit message or a title
# that contains "|" or an option is not mistaken for one, while $(...) and
# backticks start a command of their own, because the shell runs them.
#
# Limits: bash -c, eval, scripts and aliases are not followed. This is a safety
# net for mistakes, not a sandbox. The macOS Bash 3.2 is the target, so no
# associative arrays.

# awk program that prints the executable structure of a shell command, one
# simple command per line; a line holding only "|" joins the commands around it.
read -r -d '' SHELL_AWK_PROGRAM <<'AWK' || true
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
readonly SHELL_AWK_PROGRAM

readonly ASSIGNMENT_RE='^[A-Za-z_][A-Za-z0-9_]*='

# Prints the simple commands of a shell command, one per line, as words that
# the shell would see; a line holding only "|" joins the commands around it.
# Redirects stay as the words <, >, <<< and <<H. Argument: the command.
shell_segments() {
  awk "${SHELL_AWK_PROGRAM}" <<<"$1"
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

# Succeeds for a word that expands $IFS, which the shell turns into a space after
# the checks: gh${IFS}repo is one word here but two words when run.
has_ifs_expansion() {
  [[ $1 == *"\$IFS"* || $1 == *"\${IFS"* ]]
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
