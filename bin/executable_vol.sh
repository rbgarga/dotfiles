#!/bin/sh

action=$1

case "$action" in
	up)
		cmd="vol.volume=+0.1"
		;;
	down)
		cmd="vol.volume=-0.1"
		;;
	[0-9.]*)
		cmd="vol.volume=$action"
		;;
	mute)
		cmd="vol.mute=1"
		;;
	unmute)
		cmd="vol.mute=0"
		;;
	toggle)
		cmd="vol.mute=^"
		;;
	*)
		exit 1
esac

mixer $cmd >/dev/null 2>&1
