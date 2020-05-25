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
pcre2_config() {
 ./configure --prefix=/usr                       \
             --docdir=/usr/share/doc/pcre2-10.33 \
             --enable-unicode                    \
             --enable-jit                        \
             --enable-pcre2-16                   \
             --enable-pcre2-32                   \
             --enable-pcre2grep-libz             \
             --enable-pcre2grep-libbz2           \
             --enable-pcre2test-libreadline      \
             --disable-static 
}
# Git
git_config() {
 ./configure --prefix=/usr --with-gitconfig=/etc/gitconfig 
};
add_pkg git
openssh_config() {
  ./configure --prefix=/usr           \
    --sysconfdir=/etc/ssh             \
    --with-md5-passwords              \
    --with-privsep-path=/var/lib/sshd
}
add_pkg openssh
# libtasn1
libtasn1_config() {
 ./configure --prefix=/usr --disable-static 
};
add_pkg libtasn1
# p11-kit
p11-kit_preconfig() {
 sed '20,$ d' -i trust/trust-extract-compat.in &&
 cat >> trust/trust-extract-compat.in << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Generate a new trust store
/usr/sbin/make-ca -f -g
EOF
}
add_pkg p11-kit
p11-kit_config() {
 ./configure --prefix=/usr     \
             --sysconfdir=/etc \
             --with-trust-paths=/etc/pki/anchors 
}
add_pkg p11-kit
# libunistring
libunistring_config() {
 ./configure --prefix=/usr    \
             --disable-static \
             --docdir=/usr/share/doc/libunistring-0.9.10 
};
add_pkg libunistring
# nettle
nettle_config() {
 ./configure --prefix=/usr --disable-static 
};
add_pkg nettle
# GnuTLS
gnutls_config() {
 ./configure --prefix=/usr \
             --docdir=/usr/share/doc/gnutls-3.6.9 \
             --disable-guile \
             --with-default-trust-store-pkcs11="pkcs11:"
}
add_pkg gnutls
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
