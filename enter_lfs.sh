#!/bin/bash


test -z "$*" && set "bin/env.ch5.sh"
source "$1"
shift
cd "$LFS"
mkdir -p "$LFS/root"
exec sudo chroot "$LFS"       \
  ${LFS_DST}/bin/env -i           \
  HOME=/root                  \
  TERM="$TERM"                \
  PS1='(lfs chroot) \u:\w\$ ' \
  PATH=/usr/sbin:/usr/bin:/sbin:/bin:${LFS_DST}/bin \
  ${LFS_DST}/bin/bash --login

