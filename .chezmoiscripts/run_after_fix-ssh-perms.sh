#!/bin/sh
# chezmoi writes files with the box umask (002 here), which makes
# ~/.ssh group-writable and sshd StrictModes then rejects key auth.
# Re-apply the safe modes after every chezmoi apply.
if [ -d "$HOME/.ssh" ]; then
	chmod 700 "$HOME/.ssh"
	find "$HOME/.ssh" -type f -exec chmod 600 {} +
fi
exit 0
