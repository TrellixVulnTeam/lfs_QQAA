#!/bin/bash
# vim: ts=2 sw=2

LFS=/lfs
cd "$LFS"
sudo chroot \
	"$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/ls -l /usr/sbin/sshd
