#!/bin/bash

test -z "$*" && set "etc/env.ch5.sh"
source "$1"
shift
cd "$LFS"
mkdir -p root
chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
