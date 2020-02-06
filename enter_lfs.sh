#!/bin/bash

LFS=/lfs
cd "$LFS"
mkdir -p "$LFS/root"
exec chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin:/tools/bin \
		/tools/bin/bash --login

