#!/bin/bash


test -z "$*" && set "etc/env.ch5.sh"
source "$1"
shift
cd "$LFS"
mkdir -p "root"
set -- ${LFS}/ ${DST}/ /usr/local/ /usr / --
while test "$1" != "--"; do
  echo "$@" $'\n'
  test -d "${1}sbin/" && set "$@" "${1}sbin"
  test -d "${1}bin/" && set "$@" "${1}bin"
  shift
done
exec sudo chroot "$LFS"       \
  ${LFS_DST}/bin/env -i           \
  HOME=/root                  \
  TERM="$TERM"                \
  PS1='(lfs chroot) \u:\w\$ ' \
  PATH=/usr/sbin:/usr/bin:/sbin:/bin:${LFS_DST}/bin \
  ${LFS_DST}/bin/bash --login

