#!/bin/bash

if (($UID)); then
  echo >&2 "Run me as root!"
  exit 1
fi
set -e
source bin/func.sh
source bin/env.blfs.sh
screen_config() {
 ./configure --prefix=/usr                     \
             --infodir=/usr/share/info         \
             --mandir=/usr/share/man           \
             --with-socket-dir=/run/screen     \
             --with-pty-group=5                \
             --with-sys-screenrc=/etc/screenrc
	   }
screen_preconfig() {
 sed -i -e "s%/usr/local/etc/screenrc%/etc/screenrc%" {etc,doc}/* 
}
add_pkg screen

tcl_builddir() {
  dir=tcl/unix
};
tcl_postinstall() {
  chmod -v u+w /usr/lib/libtcl8.6.so
  make install-private-headers
  ln -sfv tclsh8.6 /usr/bin/tclsh
};
add_pkg tcl
# 5.12. Expect-5.45.4
expect_preconfig() {
  cp -v configure{,.orig}
  sed 's:/usr/local/bin:/bin:' configure.orig > configure
}
expect_config() {
  ./configure --prefix=/usr       \
              --with-tcl=/usr/lib \
              --with-tclinclude=/usr/include 
};
expect_install() {
  make SCRIPTS="" install
};
add_pkg expect
# XXX strace
add_pkg strace
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
libpng_preconfig() {
  gzip -cd ${LFS_ARC}libpng-*-apng.patch.gz | patch -p1
};
libpng_config() {
  ./configure --prefix=/usr --disable-static;
};
libpng_postinstall() {
  mkdir -v /usr/share/doc/libpng-1.6.37 &&
    cp README libpng-manual.txt /usr/share/doc/libpng-1.6.37
};
add_pkg libpng
pixman_config() {
  true;
};
pixman_builddir() {
  dir=$pkg/build
};
pixman_build() {
  meson --prefix=/usr .. && ninja ;
};
pixman_install() {
  ninja install
};
add_pkg pixman
make-ca_config() {
	true;
};
make-ca_postinstall() {
	install -vdm755 /etc/ssl/local
};
add_pkg make-ca
freetype_preconfig() {
 sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

 sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
     -i include/freetype/config/ftoption.h 
};
freetype_config() {
  ./configure --prefix=/usr --enable-freetype-config --disable-static;
};
add_pkg freetype
fontconfig_preconfig() {
  rm -f src/fcobjshash.h
}
fontconfig_config() {
./configure \
  --prefix=/usr        \
  --sysconfdir=/etc    \
  --localstatedir=/var \
  --disable-docs       \
  --docdir=/usr/share/doc/fontconfig-2.13.1
}
add_pkg fontconfig
libuv_preconfig() {
  autoreconf || true
  automake --add-missing || true
  autoreconf
  bash autogen.sh
}
add_pkg libuv
curl_config() {
 ./configure --prefix=/usr                           \
             --disable-static                        \
             --enable-threaded-resolver              \
             --with-ca-path=/etc/ssl/certs
}
add_pkg curl
add_pkg libarchive
cmake_preconfig() {
  sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake
}
cmake_config() {
 ./bootstrap --prefix=/usr        \
             --system-libs        \
             --mandir=/share/man  \
             --no-system-jsoncpp  \
             --no-system-librhash \
             --docdir=/share/doc/cmake-3.15.2 
}
cmake_build() {
  make -j 8;
}
add_pkg cmake



run_build;
