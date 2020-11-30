#!/bin/bash

set -e
mkdir -pv /{dev,proc,sys,run}
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv  /usr/lib/pkgconfig

case $(uname -m) in
  x86_64) mkdir -pv /lib64 ;;
esac

mkdir -pv /var/{log,mail,spool}
test -h /var/run || ln -sv ../run /var/run
test -h /var/lock || ln -sv ../run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

ln -sfv /tools/bin/{bash,cat,chmod,dd,echo,ln,mkdir,pwd,rm,stty,touch} /bin
ln -sfv /tools/bin/{env,install,perl,printf}         /usr/bin
ln -sfv /tools/lib/libgcc_s.so{,.1}                  /usr/lib
ln -sfv /tools/lib/libstdc++.{a,so{,.6}}             /usr/lib

ln -sfv bash /bin/sh

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
