#!/usr/bin/env bash
# Checks the output of the status line command for sample input.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly STATUS_LINE="${CCC_ROOT}/hooks/statusline.sh"
readonly GREEN=$'\033[38;2;78;186;101m' YELLOW=$'\033[38;2;255;193;7m'
readonly RED=$'\033[38;2;255;107;128m' DIM=$'\033[2m' RESET=$'\033[0m'

# Fails unless the status line prints exactly the expected line for the JSON
# input; colours stay off unless the third argument is "colour".
assert_line() {
  local input=$1 expected=$2 mode=${3:-plain} actual status=0
  if [[ "${mode}" == colour ]]; then
    actual=$(env -u NO_COLOR "${BASH}" -- "${STATUS_LINE}" <<<"${input}") \
      || status=$?
  else
    actual=$(NO_COLOR=1 "${BASH}" -- "${STATUS_LINE}" <<<"${input}") \
      || status=$?
  fi
  if [[ "${status}" -ne 0 ]]; then
    fail "exit ${status} for ${input}"
    return
  fi
  [[ "${actual}" == "${expected}" ]] \
    || fail "got '${actual}', expected '${expected}' for ${input}"
}

# The countdown depends on the clock, so each reset lies 30 seconds inside a
# minute and a slow run cannot change the printed minutes.
now=$(date +%s) || exit 1

begin 'empty input prints nothing'
assert_line '{}' ''

begin 'session start without usage'
assert_line '{"model": {"display_name": "Opus 5.5"},
  "effort": {"level": "high"}, "cost": {"total_cost_usd": 0},
  "context_window": {"used_percentage": null}}' \
  "Opus 5.5 · ● high · \$0.00"

begin 'all fields in order'
assert_line '{"model": {"display_name": "Opus 5.5"},
  "effort": {"level": "medium"}, "cost": {"total_cost_usd": 0.1},
  "context_window": {"used_percentage": 3},
  "rate_limits": {
    "five_hour": {"used_percentage": 17, "resets_at": '"$((now + 14430))"'},
    "seven_day": {"used_percentage": 83}}}' \
  "Opus 5.5 · ◐ medium · ○ 3% · ◔ 5h 17% 4h00m · ◕ 7d 83% · \$0.10"

begin 'fast mode'
assert_line '{"model": {"display_name": "Opus 5.5"}, "fast_mode": true}' \
  'Opus 5.5 fast'

begin 'effort glyphs'
for pair in 'low ○' 'medium ◐' 'high ●' 'xhigh ◉' 'max ◈'; do
  assert_line '{"effort": {"level": "'"${pair%% *}"'"}}' \
    "${pair#* } ${pair%% *}"
done
assert_line '{"effort": {"level": "other"}}' 'other'

begin 'circle filled by quarters'
for pair in '12 ○' '13 ◔' '37 ◔' '38 ◑' '62 ◑' '63 ◕' '87 ◕' '88 ●'; do
  assert_line '{"context_window": {"used_percentage": '"${pair%% *}"'}}' \
    "${pair#* } ${pair%% *}%"
done
assert_line '{"context_window": {"used_percentage": 12.6}}' '◔ 13%'

begin 'countdown to the 5-hour reset'
assert_line '{"rate_limits": {"five_hour": {"used_percentage": 17,
  "resets_at": '"$((now + 2730))"'}}}' '◔ 5h 17% 45m'
assert_line '{"rate_limits": {"five_hour": {"used_percentage": 17,
  "resets_at": '"$((now - 60))"'}}}' '◔ 5h 17%'

begin 'cost in cents'
assert_line '{"cost": {"total_cost_usd": 1.234}}' "\$1.23"
assert_line '{"cost": {"total_cost_usd": 12.5}}' "\$12.50"

begin 'colours by level'
assert_line '{"context_window": {"used_percentage": 69}}' \
  "${GREEN}◕${RESET} 69%" colour
assert_line '{"rate_limits": {"seven_day": {"used_percentage": 70}}}' \
  "${YELLOW}◕${RESET} 7d 70%" colour
assert_line '{"rate_limits": {"five_hour": {"used_percentage": 90}}}' \
  "${RED}●${RESET} 5h 90%" colour
assert_line '{"effort": {"level": "xhigh"}, "cost": {"total_cost_usd": 0}}' \
  "◉ xhigh · ${DIM}\$0.00${RESET}" colour

finish
