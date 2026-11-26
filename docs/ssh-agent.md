# SSH agent

A persistent `ssh-agent` on macOS, so that commits can be signed with an SSH key inside the Claude Code sandbox.

A LaunchAgent starts `ssh-agent` at login on a fixed socket, `~/.local/run/ssh-agent.sock`, and loads the keys whose passphrases Keychain holds. Unlike the socket that launchd assigns by default, a fixed path can be allowed in the sandbox.

> [!warning]
> Every sandboxed command can use the keys in the agent through the allowed socket, not only to sign but also to log in over SSH. The closed network of the sandbox limits the latter, but the keys are no longer kept out of the sandbox.

## Create the LaunchAgent

```bash
mkdir -p ~/Library/LaunchAgents
nano ~/Library/LaunchAgents/local.ssh-agent.plist
```

`-D` keeps `ssh-agent` in the foreground so that launchd supervises it, `KeepAlive` starts it again when it stops, `sleep 1` gives the socket time to appear before `ssh-add` runs, and `&amp;` is the XML escape for `&`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>local.ssh-agent</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>mkdir -p "$HOME/.local/run"; rm -f "$HOME/.local/run/ssh-agent.sock"; /usr/bin/ssh-agent -D -a "$HOME/.local/run/ssh-agent.sock" &amp; sleep 1; SSH_AUTH_SOCK="$HOME/.local/run/ssh-agent.sock" /usr/bin/ssh-add --apple-load-keychain; wait</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
```

## Load the agent and store the key

Storing the passphrase once with `--apple-use-keychain` lets the LaunchAgent load the key at every login.

```bash
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/local.ssh-agent.plist
SSH_AUTH_SOCK=~/.local/run/ssh-agent.sock ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

`launchctl load ~/Library/LaunchAgents/local.ssh-agent.plist` does the same; `man launchctl` lists it among the legacy subcommands.

## Allow the socket in the sandbox

Add the socket to `~/.claude/settings.json`; the `~` form works:

```json
{
  "sandbox": {
    "network": {
      "allowUnixSockets": ["~/.local/run/ssh-agent.sock"]
    }
  }
}
```

The path depends on this setup, so it is not in the `settings.json` of this repository.

## Point Git at the agent

Add this to the shell start-up file, such as `~/.zshrc`:

```bash
export SSH_AUTH_SOCK="$HOME/.local/run/ssh-agent.sock"
```

> [!note]
> The Bash commands of Claude Code may not inherit `SSH_AUTH_SOCK`, for example because of `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`. Check with `echo "${SSH_AUTH_SOCK:-unset}"` in a Claude Code session; when it prints `unset`, pass the variable to the command, as in `SSH_AUTH_SOCK=~/.local/run/ssh-agent.sock git commit`.

## Verify signatures

`git log --show-signature` matches a signature to its signer through `~/.config/git/allowed_signers`, which `sandbox.filesystem.allowRead` in `settings.json` lets sandboxed Git read.
