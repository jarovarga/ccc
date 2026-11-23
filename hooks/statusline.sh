#!/usr/bin/env bash
# Status line command. Claude Code writes a JSON object to stdin and shows the
# output under the prompt. Nothing it prints reaches the model, so it costs no
# tokens and cannot invalidate the prompt cache.
#
# Shows on one line the model, the reasoning effort with the glyphs that
# Claude Code shows when the effort changes, the context window usage, the
# 5-hour (session) and 7-day (week) rate limits (subscribers only) with the
# time until the 5-hour reset, and the session cost.
#
# A field that the input lacks is left out.
set -euo pipefail

# Colours only when NO_COLOR is unset. Green, yellow and red are the success,
# warning and error colours of the dark Claude Code theme, in 24-bit colour.
if [[ -z "${NO_COLOR:-}" ]]; then
  colours=(
    --arg green $'\033[38;2;78;186;101m' --arg yellow $'\033[38;2;255;193;7m'
    --arg red $'\033[38;2;255;107;128m' --arg dim $'\033[2m'
    --arg reset $'\033[0m'
  )
else
  colours=(
    --arg green '' --arg yellow '' --arg red '' --arg dim '' --arg reset ''
  )
fi

input=$(cat)

jq -r "${colours[@]}" '
  def paint($colour): $colour + . + $reset;
  def pad: tostring | if length < 2 then "0" + . else . end;
  # Fill of the circle by quarters; the number always follows it.
  def circle:
    if . < 13 then "○" elif . < 38 then "◔" elif . < 63 then "◑"
    elif . < 88 then "◕" else "●" end;
  def level:
    if . >= 90 then $red elif . >= 70 then $yellow else $green end;
  # A percentage as a circle coloured by its level, the label and the number.
  def gauge($label):
    round | level as $colour
    | (circle | paint($colour)) + " " + $label + "\(.)%";
  def minutes:
    (. / 60 | floor) as $m
    | if $m >= 60 then "\($m / 60 | floor)h\($m % 60 | pad)m"
      else "\($m)m" end;
  def usd: (. * 100 | round) as $c | "$\($c / 100 | floor).\($c % 100 | pad)";
  def effort:
    {"low": "○", "medium": "◐", "high": "●", "xhigh": "◉", "max": "◈"}[.]
      as $glyph
    | (if $glyph then $glyph + " " else "" end) + .;

  (.fast_mode == true) as $fast
  | [
      (.model.display_name? | strings
        | . + (if $fast then " fast" else "" end)),
      (.effort.level? | strings | effort),
      (.context_window.used_percentage? | numbers | gauge("")),
      (.rate_limits.five_hour? | objects
        | (.used_percentage? | numbers | gauge("5h "))
          + ((.resets_at? | numbers | . - now | select(. > 0)
              | " " + minutes) // "")),
      (.rate_limits.seven_day.used_percentage? | numbers | gauge("7d ")),
      (.cost.total_cost_usd? | numbers | usd | paint($dim))
    ]
  | select(length > 0) | join(" · ")
' <<<"${input}"
