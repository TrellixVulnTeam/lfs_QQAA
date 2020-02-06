#!/bin/bash

LFS=/lfs
cd "$LFS"
mkdir -p "$LFS/root"
exec chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/tools/bin:/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
		/tools/bin/bash --login

