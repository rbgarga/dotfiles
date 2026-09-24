#!/bin/sh
# chezmoi writes files with the box umask (002 here), which makes
# ~/.ssh group-writable and sshd StrictModes then rejects key auth.
# Re-apply the safe modes after every chezmoi apply.
[ -d "$HOME/.ssh" ] && chmod 700 "$HOME/.ssh"
[ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"
[ -f "$HOME/.ssh/authorized_keys" ] && chmod 600 "$HOME/.ssh/authorized_keys"
exit 0
