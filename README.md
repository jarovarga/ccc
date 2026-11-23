# Claude Code Config (CCC)

```text
 ██████╗ ██████╗ ██████╗
██╔════╝██╔════╝██╔════╝
██║     ██║     ██║
██║     ██║     ██║
╚██████╗╚██████╗╚██████╗
 ╚═════╝ ╚═════╝ ╚═════╝
```

[![CI](https://github.com/jarovarga/ccc/actions/workflows/ci.yml/badge.svg)](https://github.com/jarovarga/ccc/actions/workflows/ci.yml)

A personal, user-level [Claude Code](https://code.claude.com) configuration.

## Tests

Quality assurance in Claude Code with this configuration instead of `~/.claude` (requires `jq`):

```bash
tests/qa.sh
```

Automated tests:

```bash
tests/run.sh
```

> [!note]
> Check `debug.log` for the output of failed tests.

| Test | Checks |
| --- | --- |
| `limit.test.sh` | The always-loaded instructions stay within the size limit. |
| `register.test.sh` | Only registered commands run outside the sandbox or skip the prompt. |
| `settings.test.sh` | The security settings keep their values. |

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## License

ISC, see [LICENSE](LICENSE).
