#!/bin/bash

if (($UID)); then
  echo >&2 "Run me as root!"
  exit 1
fi
set -e
source bin/func.sh
source bin/env.ch6.sh
post_build_all() {
 rm -f /usr/lib/lib{bfd,opcodes}.a
 rm -f /usr/lib/libbz2.a
 rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
 rm -f /usr/lib/libltdl.a
 rm -f /usr/lib/libfl.a
 rm -f /usr/lib/libz.a
 find /usr/lib /usr/libexec -name \*.la -delete
 echo "done!"
}
generic_config() {
  ./configure --prefix=/usr/
};
init_functions="$(compgen -A function|sort)"
# 6.7. Linux-5.2.8 API Headers
linux_preconfig() {
  make mrproper
}
linux_config() {
  true;
};
linux_install() {
  make INSTALL_HDR_PATH=dest headers_install
  find dest/include \( -name .install -o -name ..install.cmd \) -delete
  cp -rv dest/include/* /usr/include
};
linux_build() {
  true;
};
add_pkg linux
# 6.8. Man-pages-5.02
man-pages_config() {
  true
}
add_pkg man-pages
# 6.9. Glibc-2.30
glibc_builddir() {
	dir=$pkg/build
}
glibc_preconfig() {
  cd $LFS_BLD/$pkg
  patch -Np1 -i $LFS_ARC/glibc-2.30-fhs-1.patch
  sed -i '/asm.socket.h/a# include <linux/sockios.h>' \
     sysdeps/unix/sysv/linux/bits/socket.h
  case $(uname -m) in
      i?86)   ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
      ;;
      x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
              ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
      ;;
  esac
}
glibc_config() {
	CC="gcc -ffile-prefix-map=/tools=/usr" \
	../configure --prefix=/usr                     \
		--disable-werror                       \
		--enable-kernel=3.2                    \
		--enable-stack-protector=strong        \
		--with-headers=/usr/include            \
		libc_cv_slibdir=/lib
} 
glibc_build() {
  make PARALLELMFLAGS=-j6
  touch /etc/ld.so.conf
  sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
}
glibc_test() {
  case $(uname -m) in
    i?86)   ln -sfnv $PWD/elf/ld-linux.so.2        /lib ;;
    x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
  esac
  sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
  #make check PARALLELMFLAGS=-j6
}
glibc_postinstall() {
  # set up files used by glibc
  cp -v ../nscd/nscd.conf /etc/nscd.conf
  mkdir -pv /var/cache/nscd
  cp -v $LFS_SRC/etc/{nsswitch.conf,ld.so.conf} /etc
 
  # replace linker symlink with one that searches /{usr/}lib
  ln -sf ld-new /tools/bin/ld
  ln -sf /tools/bin/{-old,-new}  /tools/$(uname -m)-pc-linux-gnu/bin/
  ln -sf ld-new   /tools/$(uname -m)-pc-linux-gnu/bin/ld

  gcc -dumpspecs | sed -e 's@/tools@@g'                   \
      -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
      -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
      `dirname $(gcc --print-libgcc-file-name)`/specs

  # install locale data
  rm -fr /usr/lib/locale
  mkdir -pv /usr/lib/locale
  localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
  localedef -i en_US -f ISO-8859-1 en_US
  localedef -i en_US -f UTF-8 en_US.UTF-8
  tar -xf $LFS_ARC/tzdata2019b.tar.gz

  # set up time zones
  ZONEINFO=/usr/share/zoneinfo
  rm -vfr $ZONEINFO
  mkdir -pv $ZONEINFO/{posix,right}

  set -- etcetera southamerica northamerica europe africa antarctica 
  set -- "$@" asia australasia backward pacificnew systemv
  for tz ; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
  done

  cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
  zic -d $ZONEINFO -p America/New_York
  unset ZONEINFO

  # 
}
add_pkg glibc
# 6.11. Zlib-1.2.11
zlib_postinstall() {
  mv -v /usr/lib/libz.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
};
add_pkg zlib
# 6.12. File-5.37
add_pkg file
# 6.13. Readline-8.0
readline_preconfig() {
  sed -i '/MV.*old/d' Makefile.in
  sed -i '/{OLDSUFF}/c:' support/shlib-install
}
readline_config() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/readline-8.0
      };
readline_build() {
  make SHLIB_LIBS="-L/tools/lib -lncursesw"
};
readline_install() {
  make SHLIB_LIBS="-L/tools/lib -lncursesw" install
}
readline_postinstall() {
  mv -v /usr/lib/lib{readline,history}.so.* /lib
  chmod -v u+w /lib/lib{readline,history}.so.*
  ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
  ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
  install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0
};
add_pkg readline
# 6.14. M4-1.4.18
m4_preconfig() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
  echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
};
add_pkg m4
# 6.15. Bc-2.1.3
bc_config() {
	PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
}
add_pkg bc
binutils_builddir() {
	dir=$pkg/build
}
binutils_preconfig() {
	cd $LFS_BLD/$pkg
	sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
}
binutils_config() {
  ../configure --prefix=/usr       \
               --enable-gold       \
               --enable-ld=default \
               --enable-plugins    \
               --enable-shared     \
               --disable-werror    \
               --enable-64-bit-bfd \
               --with-system-zlib
}
binutils_build() {
	make -j6 tooldir=/usr
}
binutils_install() {
	make tooldir=/usr install
}
add_pkg binutils
# 6.17. GMP-6.1.2
gmp_config() {
  ./configure --prefix=/usr    \
              --enable-cxx     \
              --disable-static \
              --docdir=/usr/share/doc/gmp-6.1.2
      };
gpm_build() {
	make
	make html
}
gpm_install() {
  make install
  make install-html
};
add_pkg gmp
#   6.18.1. Installation of MPFR
mpfr_config() {
  ./configure --prefix=/usr        \
              --disable-static     \
              --enable-thread-safe \
              --docdir=/usr/share/doc/mpfr-4.0.2
}
mpfr_build() {
  make
  make html
}
mpfr_install() {
  make install
  make install-html
}
add_pkg mpfr
# 6.19. MPC-1.1.0
mpc_config() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/mpc-1.1.0
      };
# 
#    Compile the package and generate the HTML documentation:
mpc_build() { 
  make
  make html
};
mpc_install() { 
  make install
  make install-html
};
add_pkg mpc
# 6.20. Shadow-4.7
shadow_preconfig() {
  sed -i 's/groups$(EXEEXT) //' src/Makefile.in
  find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
  find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
  find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
  sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
         -e 's@/var/spool/mail@/var/mail@' etc/login.defs
  sed -i 's/1000/999/' etc/useradd
}
shadow_config() {
  ./configure --sysconfdir=/etc --with-group-name-max-length=32
}
shadow_postinstall() {
  test -e /bin/passwd || mv -v /usr/bin/passwd /bin
  pwconv
  grpconv
}
add_pkg shadow
# 6.21. GCC-9.2.0
gcc_builddir(){
	dir=$pkg/build
}
gcc_preconfig() {
    cd $LFS_BLD/$pkg
    case $(uname -m) in
      x86_64)
	sed -e '/m64=/s/lib64/lib/' \
	    -i.orig gcc/config/i386/t-linux64
      ;;
    esac
}
gcc_config() {
  SED=sed                                     \
  ../configure --prefix=/usr/stow/gcc-9.2.0   \
               --enable-languages=c,c++       \
               --disable-multilib             \
               --disable-bootstrap            \
               --with-system-zlib
}
gcc_postinstall() {
  rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/9.2.0/include-fixed/bits/
  chown -v -R root:root \
      /usr/lib/gcc/*linux-gnu/9.2.0/include{,-fixed}
  chown -v -R root:root \
      /usr/lib/gcc/*linux-gnu/9.2.0/include{,-fixed}
  ln -sv ../usr/bin/cpp /lib
  ln -sv gcc /usr/bin/cc
  install -v -dm755 /usr/lib/bfd-plugins
  ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/9.2.0/liblto_plugin.so \
          /usr/lib/bfd-plugins/
}
add_pkg gcc
# 6.22. Bzip2-1.0.8
bzip2_preconfig() {
  patch -Np1 -i $LFS_ARC/bzip2-1.0.8-install_docs-1.patch
  sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
  sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
}
bzip2_config() {
	true;
}
bzip2_build() {
  make -f Makefile-libbz2_so
  make clean
};
bzip2_install() {
  make PREFIX=/usr install
}
bzip2_postinstall() {
  cp -v bzip2-shared /bin/bzip2
  cp -av libbz2.so* /lib
  ln -sfv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
  rm -v /usr/bin/{bunzip2,bzcat,bzip2}
  ln -sfv bzip2 /bin/bunzip2
  ln -sfv bzip2 /bin/bzcat
};
add_pkg bzip2
# 6.23. Pkg-config-0.29.2
pkg-config_config() {
  ./configure --prefix=/usr              \
              --with-internal-glib       \
              --disable-host-tool        \
              --docdir=/usr/share/doc/pkg-config-0.29.2
}
add_pkg pkg-config
# 6.24. Ncurses-6.1
ncurses_config() {
  ./configure --prefix=/usr           \
              --mandir=/usr/share/man \
              --with-shared           \
              --without-debug         \
              --without-normal        \
              --enable-pc-files       \
              --enable-widec
      }
ncurses_postinstall() {
  mv -v /usr/lib/libncursesw.so.6* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
  for lib in ncurses form panel menu ; do
      rm -vf                    /usr/lib/lib${lib}.so
      echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
      ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
  done
  rm -vf                     /usr/lib/libcursesw.so
  echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
  ln -sfv libncurses.so      /usr/lib/libcurses.so
};
add_pkg ncurses
# 6.25. Attr-2.4.48
attr_config() {
  ./configure --prefix=/usr     \
              --bindir=/bin     \
              --disable-static  \
              --sysconfdir=/etc \
              --docdir=/usr/share/doc/attr-2.4.48
}
attr_postinstall() {
  mv -v /usr/lib/libattr.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
};
add_pkg attr
# 6.26. Acl-2.2.53
acl_config() {
  ./configure --prefix=/usr         \
              --bindir=/bin         \
              --disable-static      \
              --libexecdir=/usr/lib \
              --docdir=/usr/share/doc/acl-2.2.53
}
acl_postinstall() {
  mv -v /usr/lib/libacl.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
}
add_pkg acl
# 6.27. Libcap-2.27
libcap_preconfig() {
  sed -i '/install.*STALIBNAME/d' libcap/Makefile
}
libcap_config() {
  true;
};
libcap_install() {
  make RAISE_SETFCAP=no lib=lib prefix=/usr install
  chmod -v 755 /usr/lib/libcap.so.2.27
}
libcap_postinstall() {
  mv -v /usr/lib/libcap.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
}
add_pkg libcap
# 6.28. Sed-4.7
sed_preconfig() {
  sed -i 's/usr/tools/'                 build-aux/help2man
  sed -i 's/testsuite.panic-tests.sh//' Makefile.in
};
sed_config() {
  ./configure --prefix=/usr --bindir=/bin
}
sed_build() {
  make
  make html
};
sed_install() {
  make install
  install -d -m755           /usr/share/doc/sed-4.7
  install -m644 doc/sed.html /usr/share/doc/sed-4.7
};
add_pkg sed
# 6.29. Psmisc-23.2
psmisc_postinstall() {
  mv -v /usr/bin/fuser   /bin
  mv -v /usr/bin/killall /bin
}
add_pkg psmisc
# 6.30. Iana-Etc-2.30
iana-etc_config() {
  true
}
add_pkg iana-etc
# 6.31. Bison-3.4.1
bison_preconfig() {
  sed -i '6855 s/mv/cp/' Makefile.in
};
bison_config() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.4.1
}
bison_build() {
  make -j1
};
add_pkg bison
# 6.32. Flex-2.6.4
flex_preconfig() {
  sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
};
flex_config() {
  HELP2MAN=/tools/bin/true \
  ./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
};
flex_postinstall() {
  ln -sv flex /usr/bin/lex
};
add_pkg flex
# 6.33. Grep-3.3
grep_config() {
  ./configure --prefix=/usr --bindir=/bin
}
add_pkg grep
# 6.34. Bash-5.0
bash_config() {
  ./configure --prefix=/usr                    \
              --docdir=/usr/share/doc/bash-5.0 \
              --without-bash-malloc            \
              --with-installed-readline
};
bash_postinstall() {
  mv -vf /usr/bin/bash /bin
  ln -sf bash /bin/sh
  cp -vf $LFS_SRC/etc/profile /etc
  report install --directory --mode=0755 --owner=root --group=root /etc/profile.d
};
add_pkg bash
# 6.35. Libtool-2.4.6
add_pkg libtool
# 6.36. GDBM-1.18.1
gdbm_config() {
  ./configure --prefix=/usr    \
              --disable-static \
              --enable-libgdbm-compat
};
add_pkg gdbm
# 6.37. Gperf-3.1
gperf_config() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
}
add_pkg gperf
# 6.38. Expat-2.2.7
expat_preconfig() {
  sed -i 's|usr/bin/env |bin/|' run.sh.in
};
expat_config() { 
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/expat-2.2.7
};
add_pkg expat
# 6.39. Inetutils-1.9.4
inetutils_config() {
  ./configure --prefix=/usr        \
              --localstatedir=/var \
              --disable-logger     \
              --disable-whois      \
              --disable-rcp        \
              --disable-rexec      \
              --disable-rlogin     \
              --disable-rsh        \
              --disable-servers
};
innetutils_postinstall() {
  mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
  mv -v /usr/bin/ifconfig /sbin
};
add_pkg inetutils
# 6.40. Perl-5.30.0
perl_preconfig() {
  echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
}
perl_config() {
  export BUILD_ZLIB=False
  export BUILD_BZIP2=0
  sh Configure -des -Dprefix=/usr                 \
                    -Dvendorprefix=/usr           \
                    -Dman1dir=/usr/share/man/man1 \
                    -Dman3dir=/usr/share/man/man3 \
                    -Dpager="/usr/bin/less -isR"  \
                    -Duseshrplib                  \
                    -Dusethreads
}
perl_postinstall() {
  unset BUILD_ZLIB BUILD_BZIP2
};
add_pkg perl
# 6.41. XML::Parser-2.44
XML::Parser_config() {
 perl Makefile.PL
}
XML::Parser_unpack() {
 local arc
 local pkg=XML-Parser
 archive_name
 pkg=XML::Parser
 test -f "$arc" || return 1
 generic_unpack 
};
add_pkg XML::Parser
# 6.42. Intltool-0.51.0
intltool_preconfig() {
  sed -i 's:\\\${:\\\$\\{:' intltool-update.in
};
add_pkg intltool
# 6.43. Autoconf-2.69
autoconf_preconfig() {
  sed '361 s/{/\\{/' -i bin/autoscan.in
};
add_pkg autoconf
# 6.44. Automake-1.16.1
automake_config() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
}
add_pkg automake
# 6.45. Xz-5.2.4
xz_config() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/xz-5.2.4
}
xz_postinstall() {
  mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
  mv -v /usr/lib/liblzma.so.* /lib
  ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
};
add_pkg xz
# 6.46. Kmod-26
kmod_config() {
  ./configure --prefix=/usr          \
              --bindir=/bin          \
              --sysconfdir=/etc      \
              --with-rootlibdir=/lib \
              --with-xz              \
              --with-zlib
}
kmod_postinstall() {
  for target in depmod insmod lsmod modinfo modprobe rmmod; do
    ln -sfv ../bin/kmod /sbin/$target
  done
  ln -sfv kmod /bin/lsmod
};
add_pkg kmod
# 6.47. Gettext-0.20.1
gettext_config() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/gettext-0.20.1
}
gettext_postinstall() {
  chmod -v 0755 /usr/lib/preloadable_libintl.so
};
add_pkg gettext
# 6.48. Libelf from Elfutils-0.177
libelf_unpack() {
 local arc
 local pkg=elfutils
 archive_name
 pkg=libelf
 test -f "$arc" || return 1
 generic_unpack 
};
libelf_install() {
  make -C libelf install
  install -vm644 config/libelf.pc /usr/lib/pkgconfig
};
add_pkg libelf
# 6.49. Libffi-3.2.1
libffi_preconfig() {
  sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
      -i include/Makefile.in
 
  sed -e '/^includedir/ s/=.*$/=@includedir@/' \
      -e 's/^Cflags: -I${includedir}/Cflags:/' \
      -i libffi.pc.in
};
libffi_config() {
  ./configure --prefix=/usr --disable-static --with-gcc-arch=native
};
add_pkg libffi
# 6.50. OpenSSL-1.1.1c
openssl_preconfig() {
  sed -i '/\} data/s/ =.*$/;\n    memset(\&data, 0, sizeof(data));/' \
    crypto/rand/rand_lib.c
};
openssl_config() {
  ./config --prefix=/usr         \
           --openssldir=/etc/ssl \
           --libdir=lib          \
           shared                \
           zlib-dynamic
};
openssl_install() {
  sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
  make MANSUFFIX=ssl install
};
add_pkg openssl
# 6.51. Python-3.7.4
python_unpack() {
  local arc
  local pkg=Python
  archive_name Python
  pkg=python
  test -f "$arc" || return 1;
  generic_unpack
};
python_config() {
  ./configure --prefix=/usr       \
              --enable-shared     \
              --with-system-expat \
              --with-system-ffi   \
              --with-ensurepip=yes
};
python_postinstall() {
  chmod -v 755 /usr/lib/libpython3.7m.so
  chmod -v 755 /usr/lib/libpython3.so
  ln -sfv pip3.7 /usr/bin/pip3
}
add_pkg python
# 6.52. Ninja-1.9.0
ninja_preconfig() {
  sed -i '/int Guess/a \
    int   j = 0;\
    char* jobs = getenv( "NINJAJOBS" );\
    if ( jobs != NULL ) j = atoi( jobs );\
    if ( j > 0 ) return j;\
  ' src/ninja.cc
};
ninja_config() {
  true;
};
ninja_build() {
  python3 configure.py --bootstrap
};
ninja_install() {
  install -vm755 ninja /usr/bin/
  install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
  install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
};
add_pkg ninja
# 6.53. Meson-0.51.1
meson_config() {
  true;
}
meson_build() {
  python3 setup.py build
};
meson_install() {
  python3 setup.py install --root=dest
  cp -rv dest/* /
};
add_pkg meson
# 6.54. Coreutils-8.31
coreutils_preconfig() {
  patch -Np1 -i $LFS_ARC/coreutils-8.31-i18n-1.patch
  sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
  autoreconf -fiv
};
coreutils_config() {
  FORCE_UNSAFE_CONFIGURE=1 ./configure \
              --prefix=/usr            \
              --enable-no-install-program=kill,uptime
};
coreutils_postintsall() {
  mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
  mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
  mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
  mv -v /usr/bin/chroot /usr/sbin
  mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
  sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
  mv -v /usr/bin/{head,nice,sleep,touch} /bin
};
add_pkg coreutils
# 6.55. Check-0.12.0
check_install() {
  make docdir=/usr/share/doc/check-0.12.0 install
};
check_postinstall() {
  sed -i '1 s/tools/usr/' /usr/bin/checkmk
};
add_pkg check
# 6.56. Diffutils-3.7
add_pkg diffutils
# 6.57. Gawk-5.0.1
gawk_preconfig() {
  sed -i 's/extras//' Makefile.in
};
add_pkg gawk
# 6.58. Findutils-4.6.0
findutils_preconfig() {
  sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
  sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
  echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
};
findutils_config() {
  ./configure --prefix=/usr --localstatedir=/var/lib/locate
};
findutils_postinstall() {
  mv -v /usr/bin/find /bin
  sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
}
add_pkg findutils
# 6.59. Groff-1.22.4
groff_build() {
  make -j1
};
add_pkg groff
# 6.60. GRUB-2.04
grub_config() {
  ./configure --prefix=/usr          \
              --sbindir=/sbin        \
              --sysconfdir=/etc      \
              --disable-efiemu       \
              --disable-werror
}
grub_postinstall() {
  mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
};
add_pkg grub
# 6.61. Less-551
less_config() {
  ./configure --prefix=/usr --sysconfdir=/etc
}
add_pkg less
# 6.62. Gzip-1.10
gzip_postinstall() {
  mv -v /usr/bin/gzip /bin
};
add_pkg gzip
# 6.63. IPRoute2-5.2.0
iproute2_preconfig() {
  sed -i /ARPD/d Makefile
  rm -fv man/man8/arpd.8
  sed -i 's/.m_ipt.o//' tc/Makefile
};
iproute2_install() {
  make DOCDIR=/usr/share/doc/iproute2-5.2.0 install
};
add_pkg iproute2
# 6.64. Kbd-2.2.0
kbd_preconfig() {
  patch -Np1 -i $LFS_ARC/kbd-2.2.0-backspace-1.patch
  sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
  sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
}
kbd_config() {
  PKG_CONFIG_PATH=/tools/lib/pkgconfig \
    ./configure --prefix=/usr --disable-vlock
};
add_pkg kbd
# 6.65. Libpipeline-1.5.1
add_pkg libpipeline
# 6.66. Make-4.2.1
make_preconfig() {
  sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
};
make_unpack() {
  local arc
  # there are other files that start make-, so disambiguate
  local pkg=make-4
  archive_name
  pkg=make
  test -f "$arc" || return 1
  generic_unpack
}
add_pkg make
# 6.67. Patch-2.7.6
add_pkg patch
# 6.68. Man-DB-2.8.6.1
man-db_config() {
  ./configure --prefix=/usr                        \
              --docdir=/usr/share/doc/man-db-2.8.6.1 \
              --sysconfdir=/etc                    \
              --disable-setuid                     \
              --enable-cache-owner=bin             \
              --with-browser=/usr/bin/lynx         \
              --with-vgrind=/usr/bin/vgrind        \
              --with-grap=/usr/bin/grap            \
              --with-systemdtmpfilesdir=           \
              --with-systemdsystemunitdir=
}
add_pkg man-db
# 6.69. Tar-1.32
tar_config() {
  FORCE_UNSAFE_CONFIGURE=1  \
  ./configure --prefix=/usr \
              --bindir=/bin
};
add_pkg tar
# 6.70. Texinfo-6.6
texinfo_config() {
  ./configure --prefix=/usr --disable-static
} 
texinfo_postinstall() {
  make TEXMF=/usr/share/texmf install-tex
};
add_pkg texinfo
# 6.71. Vim-8.1.1846
vim_preconfig() {
  echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
};
vim_postinstall() {
  ln -sv vim /usr/bin/vi
  for L in  /usr/share/man/{,*/}man1/vim.1; do
      ln -sv vim.1 $(dirname $L)/vi.1
  done
  ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1.1846
  cp $LFS_SRC/etc/vimrc /etc/
};
add_pkg vim
# 6.72. Procps-ng-3.3.15
procps-ng_config() {
  ./configure --prefix=/usr                            \
              --exec-prefix=                           \
              --libdir=/usr/lib                        \
              --docdir=/usr/share/doc/procps-ng-3.3.15 \
              --disable-static                         \
              --disable-kill
}
procps-ng_postinstall() {
  mv -v /usr/lib/libprocps.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
};
add_pkg procps-ng
# 6.73. Util-linux-2.34
util-linux_preconfig() {
  mkdir -pv /var/lib/hwclock
}
util-linux_config(){
  ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
              --docdir=/usr/share/doc/util-linux-2.34 \
              --disable-chfn-chsh  \
              --disable-login      \
              --disable-nologin    \
              --disable-su         \
              --disable-setpriv    \
              --disable-runuser    \
              --disable-pylibmount \
              --disable-static     \
              --without-python     \
              --without-systemd    \
              --without-systemdsystemunitdir
}
add_pkg util-linux
# 6.74. E2fsprogs-1.45.3
e2fsprogs_builddir() {
	dir=$pkg/build
}
e2fsprogs_config(){
  ../configure --prefix=/usr           \
               --bindir=/bin           \
               --with-root-prefix=""   \
               --enable-elf-shlibs     \
               --disable-libblkid      \
               --disable-libuuid       \
               --disable-uuidd         \
               --disable-fsck
};
e2fsprogs_postinstall() {
  make install-libs;
  chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
  gunzip -v /usr/share/info/libext2fs.info.gz
  install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
};
add_pkg e2fsprogs
# 6.75. Sysklogd-1.5.1
sysklogd_preconfig(){
  sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
  sed -i 's/union wait/int/' syslogd.c
};
sysklogd_install() {
  make BINDIR=/sbin install
};
sysklogd_config(){
  true;
}
sysklogd_postinstall(){
	cp $LFS_SRC/etc/syslog.conf /etc
}
add_pkg sysklogd
# 6.76. Sysvinit-2.95
sysvinit_preconfig(){
  patch -Np1 -i $LFS_ARC/sysvinit-2.95-consolidated-1.patch
};
sysvinit_config(){
  true;
};
add_pkg sysvinit
# 6.77. Eudev-3.2.8
eudev_config(){
  ./configure --prefix=/usr           \
              --bindir=/sbin          \
              --sbindir=/sbin         \
              --libdir=/usr/lib       \
              --sysconfdir=/etc       \
              --libexecdir=/lib       \
              --with-rootprefix=      \
              --with-rootlibdir=/lib  \
              --enable-manpages       \
              --disable-static
};
eudev_preconfig(){
  mkdir -pv /lib/udev/rules.d
  mkdir -pv /etc/udev/rules.d
};
eudev_postinstall() {
  tar -xvf $LFS_ARC/udev-lfs-20171102.tar.xz
  make -f udev-lfs-20171102/Makefile.lfs install
  udevadm hwdb --update
};
add_pkg eudev
lfs-bootscripts_config()
{
  true;
};
add_pkg lfs-bootscripts
#run_build;
printf '%s\n' $pkg_list
