# Status line

The status line under the prompt, set by `statusLine` in `settings.json`. It shows the fields on one line, separated by `·`, and leaves out a field that Claude Code does not provide:

```text
Opus 5.5 · ◐ medium · ◔ 24% · ◑ 5h 52% 1h05m · ○ 7d 9% · $1.23
```

## Fields

| Field | Shows |
| --- | --- |
| Model | The model name, followed by `fast` in fast mode. |
| Effort | The reasoning effort with its glyph. |
| Context | The usage of the context window. |
| 5-hour limit | The usage of the session rate limit and the time until it resets. Subscribers only. |
| 7-day limit | The usage of the weekly rate limit. Subscribers only. |
| Cost | The session cost in US dollars, dimmed. |

## Effort

| Glyph | Level |
| --- | --- |
| `○` | `low` |
| `◐` | `medium` |
| `●` | `high` |
| `◉` | `xhigh` |
| `◈` | `max` |

## Usage

Each percentage is rounded and has a circle in front of it that fills by quarters and changes colour with the level:

| Glyph | Usage |
| --- | --- |
| `○` | Below 13% |
| `◔` | 13 to 37% |
| `◑` | 38 to 62% |
| `◕` | 63 to 87% |
| `●` | 88% and more |

| Colour | Usage |
| --- | --- |
| Green | Below 70% |
| Yellow | 70 to 89% |
| Red | 90% and more |

> [!tip]
> Set `NO_COLOR` to any value to show the status line without colours.
