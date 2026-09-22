#!/bin/sh

focus() {
	swaymsg "[app_id=\"${app_id}\"] focus" 2>&1
	return $?
}

unset app_id run terminal
while getopts c:C:t flag; do
	case ${flag} in
		c)
			app_id=$OPTARG
			;;
		C)
			run=$OPTARG
			;;
		t)
			terminal=1
			;;
		*)
			echo "ERROR"
			exit 1
	esac
done

[ -z "$app_id" ] && exit 0
[ -z "$run" ] && exit 0

if ! focus; then
	if [ -n "$terminal" ]; then
		alacritty --class $app_id -e $run &
	else
		$run &
	fi
	sleep 1
	focus
fi
