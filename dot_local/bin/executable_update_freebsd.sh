#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR: Need to run as root" >&2
	exit 1
fi

set -e

# Include the time so a second run on the same day does not collide
be=$(date +%Y-%m-%d-%H%M)
mp=$(mktemp -d)

chroot="env HOME=/root LC_ALL=C chroot ${mp}"

# Best effort and idempotent: runs on success, on failure (set -e) and on
# signals, so a failed build never leaves nullfs/devfs/BE mounts behind
cleanup() {
	umount "${mp}/dev" 2>/dev/null || true
	umount "${mp}/usr/src" 2>/dev/null || true
	bectl umount "$be" 2>/dev/null || true
	rmdir "$mp" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

bectl create "$be"
bectl mount "$be" "$mp"
mount -t nullfs /usr/src "${mp}/usr/src"
mount -t devfs devfs "${mp}/dev"

${chroot} git -C /usr/src pull
${chroot} make -C /usr/src -s -j24 buildworld buildkernel
${chroot} etcupdate -s /usr/src -p
${chroot} make -C /usr/src -s -j16 installkernel
${chroot} make -C /usr/src -s -j16 installworld
${chroot} etcupdate -s /usr/src
# Interactive shell to review/fix leftovers; its exit status (e.g. after a
# failed last command) must not abort the update
${chroot} /bin/sh || true

# Unmount before activating, then disarm the EXIT trap
cleanup
trap - EXIT
bectl activate -t "$be"
