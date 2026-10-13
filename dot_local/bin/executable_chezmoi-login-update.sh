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
log=$HOME/.cache/chezmoi-update.log
# keep the log bounded: trim to the last 200 lines once it passes 100 KB
if [ -f "$log" ] && [ "$(wc -c < "$log")" -gt 102400 ]; then
    tail -n 200 "$log" > "$log.tmp" && mv "$log.tmp" "$log"
fi
# Nobody is there to answer: a locally modified file makes chezmoi ask
# whether to overwrite it, on the tty by default, and the background job
# would wait forever. --no-tty moves the prompt to stdin, where /dev/null
# answers EOF: that file is left alone (and logged), --keep-going applies
# the rest. Settle it by hand with chezmoi diff / apply / re-add.
{
    echo "=== $(date)"
    chezmoi update --no-tty --keep-going
    echo "=== exit=$?"
} >> "$log" 2>&1 < /dev/null
