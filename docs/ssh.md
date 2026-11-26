# SSH

A persistent `ssh-agent` on macOS and SSH commit signing that also work inside the Claude Code sandbox, for an existing key such as `~/.ssh/id_ed25519`.

A LaunchAgent starts `ssh-agent` at login on a fixed socket, `~/.local/run/ssh-agent.sock`, and loads the keys whose passphrases Keychain holds. Unlike the socket that launchd assigns by default, a fixed path can be allowed in the sandbox.

> [!warning]
> Every sandboxed command can use the keys in the agent through the allowed socket, not only to sign but also to log in over SSH. The closed network of the sandbox limits the latter, but the keys are no longer kept out of the sandbox.

## Persistent agent

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

Start it; `launchctl load` does the same, but `man launchctl` lists it among the legacy subcommands:

```bash
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/local.ssh-agent.plist
```

Point shells at it in the shell start-up file, such as `~/.zshrc`:

```bash
export SSH_AUTH_SOCK="$HOME/.local/run/ssh-agent.sock"
```

## Load the key

Store the passphrase in Keychain once; the LaunchAgent then loads the key at every login. This also adds the key to the agent, so a separate `ssh-add` is not needed.

```bash
SSH_AUTH_SOCK=~/.local/run/ssh-agent.sock ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Do not start another agent with `eval "$(ssh-agent -s)"`: it gets a random socket, and a key loaded into it is not available in the sandbox.

## GitHub

Add `~/.ssh/id_ed25519.pub` in GitHub under Settings → SSH and GPG keys twice: as an authentication key, for `git push` and `ssh`, and as a signing key, so that signed commits show as verified. Then test the connection; in Claude Code, run it with `!`, because the sandbox has no network:

```bash
ssh -T git@github.com
```

## Commit signing

Sign every commit and tag with the key instead of GPG. `user.signingkey` names the public key; Git signs with the matching private key in the agent.

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

Git verifies SSH signatures only against the allowed signers file, whose lines each hold a principal and a public key; the format is in `ssh-keygen(1)` under ALLOWED SIGNERS. Add the key once, with the email of the commits as the principal:

```bash
mkdir -p ~/.config/git
printf '%s namespaces="git" %s\n' "$(git config user.email)" "$(cut -d ' ' -f 1,2 ~/.ssh/id_ed25519.pub)" >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
git log --show-signature -1
```

## Sandbox

Allow the socket in `~/.claude/settings.json`; the `~` form works:

```json
{
  "sandbox": {
    "network": {
      "allowUnixSockets": ["~/.local/run/ssh-agent.sock"]
    }
  }
}
```

The path depends on this setup, so it is not in the `settings.json` of this repository. That file already lets sandboxed Git read `~/.config/git/allowed_signers` through `sandbox.filesystem.allowRead`.

> [!note]
> The Bash commands of Claude Code may not inherit `SSH_AUTH_SOCK`, for example because of `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`. Check with `echo "${SSH_AUTH_SOCK:-unset}"` in a Claude Code session; when it prints `unset`, pass the variable to the command, as in `SSH_AUTH_SOCK=~/.local/run/ssh-agent.sock git commit`.
