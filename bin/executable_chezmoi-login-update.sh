#!/bin/sh
# Run chezmoi update at most once every 24h, triggered from zlogin
# (hook lives in the prezto fork's runcoms/zlogin).

# The dotfiles remote may be SSH: without a running agent the pull
# cannot authenticate. Skip this cycle; the next login retries and the
# 24h window is not consumed. On macOS launchd always sets SSH_AUTH_SOCK;
# on the other boxes prezto's ssh module starts the agent in zshrc, which
# runs before zlogin — including after a reboot, when it prompts for the
# key passphrase.
[ -n "$SSH_AUTH_SOCK" ] || exit 0

stamp=$HOME/.cache/chezmoi-last-update
if [ ! -f "$stamp" ]; then
    touch "$stamp"   # first run ever: claim the slot, update starts tomorrow
    exit 0
fi
[ -z "$(find "$stamp" -mtime +0 2>/dev/null)" ] && exit 0

touch "$stamp"   # claim early: concurrent logins cannot race
{
    echo "=== $(date)"
    chezmoi update
    echo "=== exit=$?"
} >> "$HOME/.cache/chezmoi-update.log" 2>&1
