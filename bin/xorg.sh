#!/bin/bash

if (($UID)); then
  echo >&2 "Run me as root!"
  exit 1
fi
set -e
source bin/func.sh
source bin/env.blfs.sh
tcl_builddir() {
  dir=tcl/unix
};
tcl_postinstall() {
  chmod -v u+w /usr/lib/libtcl8.6.so
  make install-private-headers
  ln -sfv tclsh8.6 /usr/bin/tclsh
};
add_pkg tcl
# XXX strace
add_pkg strace
# XXX sudo
add_pkg sudo
post_build_all() {
 echo "done!"
}
generic_config() {
  ./configure --prefix=/usr/
};
init_functions="$(compgen -A function|sort)"
add_pkg tcl
# XXX strace
add_pkg strace
# XXX sudo
sudo_config() {
 ./configure --prefix=/usr              \
             --libexecdir=/usr/lib      \
             --with-secure-path         \
             --with-all-insults         \
             --with-env-editor          \
             --docdir=/usr/share/doc/sudo-1.8.27 \
             --with-passprompt="[sudo] password for %p: "
};
sudo_postinstall() {
 ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0
};
add_pkg sudo
# XXX wget
wget_config() {
 ./configure --prefix=/usr      \
             --sysconfdir=/etc  \
             --with-ssl=openssl
};
add_pkg wget
# XXX git
run_build;
