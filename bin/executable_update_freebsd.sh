#!/bin/sh

if [ $(id -u) -ne 0 ]; then
	echo "ERROR: Need to run as root" >&2
	exit 1
fi

set -e

be=$(date +%Y-%m-%d)
mp=$(mktemp -d)

chroot="env HOME=/root LC_ALL=C chroot ${mp}"

bectl create $be
bectl mount $be $mp
mount -t nullfs /usr/src ${mp}/usr/src
mount -t devfs devfs ${mp}/dev

${chroot} git -C /usr/src pull
${chroot} make -C /usr/src -s -j24 buildworld buildkernel
${chroot} etcupdate -s /usr/src -p
${chroot} make -C /usr/src -s -j16 installkernel
${chroot} make -C /usr/src -s -j16 installworld
${chroot} etcupdate -s /usr/src
${chroot} /bin/sh

umount ${mp}/usr/src
umount ${mp}/dev

bectl umount $be
bectl activate -t $be
