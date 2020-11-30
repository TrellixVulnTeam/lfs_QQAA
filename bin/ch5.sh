#!/bin/bash

if ((!$UID)); then
  echo >&2 "Don't run me as root!"
  exit 1
fi
mkdir -vp $LFS_DST $LFS_SRC
ln -vsf . ${LFS_DST}/share

alias good=true
good && test "${LFS}${LFS_DST}/" -ef "${LFS_DST}/" || alias good=false
good && test "${LFS_DST}/share/" -ef "${LFS_DST}/" || alias good=false
good || exit 1

source bin/env.ch5.sh
source bin/func.sh
generic_config() {
  ./configure --prefix=$LFS_DST
};
init_functions="$(compgen -A function|sort)"
# 5.4. Binutils-2.32 - Pass 1
binutils_builddir() {
  dir="$pkg/build$pass"
};
binutils_1_config() {
  ../configure --prefix=$LFS_DST          \
               --with-sysroot=$LFS        \
               --with-lib-path=$LFS_DST/lib \
               --target=$LFS_TGT          \
               --disable-nls              \
               --disable-werror 
}
binutils_1_preinstall() {
  case $(uname -m) in
    x86_64) mkdir -pv $LFS_DST ${LFS_DST}/lib && ln -fsv lib ${LFS_DST}/lib64 ;;
  esac
};
add_pkg binutils_1
# 5.5. GCC-9.2.0 - Pass 1
gcc_builddir() {
  dir=gcc/build$pass
};
gcc_1_preconfig() {
  cd $LFS_BLD/$pkg
  if ! test -d mpfr; then
    tar -xf ${LFS_ARC}/mpfr-4.0.2.tar.xz
    mv -v mpfr-4.0.2 mpfr
  fi
  if ! test -d gmp; then
    tar -xf ${LFS_ARC}/gmp-6.1.2.tar.xz
    mv -v gmp-6.1.2 gmp
  fi
  if ! test -d mpc; then
    tar -xf ${LFS_ARC}/mpc-1.1.0.tar.gz
    mv -v mpc-1.1.0 mpc
  fi
  for file in gcc/config/{linux,i386/linux{,64}}.h
  do
    rm -f $file.orig
    cp -uv $file{,.orig}
    {
      sed -e "s@/lib\(64\)\?\(32\)\?/ld@${LFS_DST}&@g" -e "s@/usr@${LFS_DST}@g" $file.orig

      echo '#undef STANDARD_STARTFILE_PREFIX_1'
      echo '#undef STANDARD_STARTFILE_PREFIX_2'
      echo "#define STANDARD_STARTFILE_PREFIX_1 \"${LFS_DST}/lib/\""
      echo '#define STANDARD_STARTFILE_PREFIX_2 ""'
    } > $file
    touch $file.orig
  done
  case $(uname -m) in
    x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
  esac
}
gcc_1_config() {
  ../configure                                       \
      --target=$LFS_TGT                              \
      --prefix=$LFS_DST
      --with-glibc-version=2.11                      \
      --with-sysroot=$LFS                            \
      --with-newlib                                  \
      --without-headers                              \
      --with-local-prefix=$LFS_DST                   \
      --with-native-system-header-dir=${LFS_DST}/include \
      --disable-nls                                  \
      --disable-shared                               \
      --disable-multilib                             \
      --disable-decimal-float                        \
      --disable-threads                              \
      --disable-libatomic                            \
      --disable-libgomp                              \
      --disable-libquadmath                          \
      --disable-libssp                               \
      --disable-libvtv                               \
      --disable-libstdcxx                            \
      --enable-languages=c,c++ 
}
add_pkg gcc_1
# 5.6. Linux-5.2.8 API Headers
linux_config() {
  make mrproper
}
linux_build() {
  true
}
linux_install() {
  make INSTALL_HDR_PATH=dest headers_install
  cp -rv dest/include/* ${LFS_DST}/include
}
add_pkg linux
# 5.7. Glibc-2.30
glibc_builddir() {
  dir=$pkg/build
}
glibc_config() {
  ../configure                             \
        --prefix=${LFS_DST}                    \
        --host=$LFS_TGT                    \
        --build=$LFS_TGT                   \
        --enable-kernel=3.2                \
        --with-headers=${LFS_DST}/include 
};
glibc_test() {
  echo 'int main(){}' > dummy.c
  $LFS_TGT-gcc dummy.c
  readelf -l a.out | grep ": ${LFS_DST}"
  rm -v dummy.c a.out
};
glibc_build() {
  make PARALLELMFLAGS=-j6
}
add_pkg glibc
# 5.8. Libstdc++ from GCC-9.2.0
libstdcxx_builddir() {
  dir=gcc/build_cxx
  if test ! -d gcc; then
    echo >&2 gcc should already be unpacked
    pwd >&2
    exit 1
  fi
  mkdir -p $LFS_BLD/$dir
};
libstdcxx_config() {
  ../libstdc++-v3/configure           \
      --host=$LFS_TGT                 \
      --prefix=${LFS_DST}                 \
      --disable-multilib              \
      --disable-nls                   \
      --disable-libstdcxx-threads     \
      --disable-libstdcxx-pch         \
      --with-gxx-include-dir=${LFS_DST}/$LFS_TGT/include/c++/9.2.0 
};
add_pkg libstdcxx
# 5.9. Binutils-2.32 - Pass 2
binutils_2_config() {
  CC=$LFS_TGT-gcc                \
  AR=$LFS_TGT-ar                 \
  RANLIB=$LFS_TGT-ranlib         \
  ../configure                   \
      --prefix=${LFS_DST}            \
      --disable-nls              \
      --disable-werror           \
      --with-lib-path=${LFS_DST}/lib \
      --with-sysroot 
};
binutils_2_postinstall() {
  make -C ld clean
  make -C ld LIB_PATH=/usr/lib:/lib
  mv -v ${LFS_DST}/bin/ld{,-old}
  ln -sv ld-old ${LFS_DST}/bin/ld
  cp -v ld/ld-new ${LFS_DST}/bin
};
add_pkg binutils_2
# 5.10. GCC-9.2.0 - Pass 2
gcc_2_builddir() {
  dir="$pkg/build_2"
}
gcc_2_preconfig() {
  cd $LFS_BLD/$pkg
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
}
gcc_2_config() {
  CC=$LFS_TGT-gcc                                    \
  CXX=$LFS_TGT-g++                                   \
  AR=$LFS_TGT-ar                                     \
  RANLIB=$LFS_TGT-ranlib                             \
  ../configure                                       \
      --prefix=${LFS_DST}                                \
      --with-local-prefix=${LFS_DST}                     \
      --with-native-system-header-dir=${LFS_DST}/include \
      --enable-languages=c,c++                       \
      --disable-libstdcxx-pch                        \
      --disable-multilib                             \
      --disable-bootstrap                            \
      --disable-libgomp 
};
gcc_2_postinstall() {
  ln -sv gcc ${LFS_DST}/bin/cc
};
gcc_2_test() {
  echo 'int main(){}' > dummy.c
  cc dummy.c
  readelf -l a.out | grep ': ${LFS_DST}'
};
add_pkg gcc_2
# 5.11. Tcl-8.6.9
tcl_builddir() {
  dir=tcl/unix
};
tcl_postinstall() {
  chmod -v u+w ${LFS_DST}/lib/libtcl8.6.so
  make install-private-headers
  ln -sfv tclsh8.6 ${LFS_DST}/bin/tclsh
};
add_pkg tcl
# 5.12. Expect-5.45.4
expect_preconfig() {
  cp -v configure{,.orig}
  sed 's:/usr/local/bin:/bin:' configure.orig > configure
}
expect_config() {
  ./configure --prefix=${LFS_DST}       \
              --with-tcl=${LFS_DST}/lib \
              --with-tclinclude=${LFS_DST}/include 
};
expect_install() {
  make SCRIPTS="" install
};
add_pkg expect
# 5.13. DejaGNU-1.6.2
# 5.14. M4-1.4.18
m4_preconfig() {
 sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
 echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
 };
add_pkg m4
# 5.15. Ncurses-6.1
ncurses_preconfig() {
  sed -i s/mawk// configure
};
ncurses_config() {
  ./configure --prefix=${LFS_DST} \
              --with-shared   \
              --without-debug \
              --without-ada   \
              --enable-widec  \
              --enable-overwrite 
};
ncurses_postinstall() {
  ln -fvs libncursesw.so ${LFS_DST}/lib/libncurses.so
  ln -fvs libncursesw.a ${LFS_DST}/lib/libncurses.a
};
add_pkg ncurses
# 5.16. Bash-5.0
bash_config() {
  ./configure --prefix=${LFS_DST} --without-bash-malloc --enable-static-link
};
bash_postinstall() {
  ln -sfv bash ${LFS_DST}/bin/sh
};
add_pkg bash
# 5.17. Bison-3.4.1
add_pkg bison
# 5.18. Bzip2-1.0.8
bzip2_config() {
  true;
};
bzip2_install() {
  make PREFIX=${LFS_DST} install
}
add_pkg bzip2
# 5.19. Coreutils-8.31
coreutils_config() {
  ./configure --prefix=${LFS_DST} --enable-install-program=hostname 
};
add_pkg coreutils
# 5.20. Diffutils-3.7
diffutils_config() {
  ./configure --prefix=${LFS_DST}
};
add_pkg diffutils
# 5.21. File-5.37
add_pkg file
# 5.22. Findutils-4.6.0
findutils_preconfig() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
  sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
  echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
}
add_pkg findutils
# 5.23. Gawk-5.0.1
add_pkg gawk
# 5.24. Gettext-0.20.1
gettext_config() {
  ./configure --disable-shared 
}
gettext_install() {
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} ${LFS_DST}/bin
};
add_pkg gettext
# 5.25. Grep-3.3
add_pkg grep
# 5.26. Gzip-1.10
add_pkg gzip
# 5.27. Make-4.2.1
make_unpack() {
  local arc
  local pkg=make-4
  archive_name
  pkg=make
  test -f "$arc" || return 1
  generic_unpack
}
make_preconfig() {
  sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
}
make_config() {
  ./configure --prefix=${LFS_DST} --without-guile 
}
add_pkg make
# 5.28. Patch-2.7.6
add_pkg patch
# 5.29. Perl-5.30.0
perl_config() {
  sh Configure -des -Dprefix=${LFS_DST} -Dlibs=-lm -Uloclibpth -Ulocincpth
}
perl_install() {
  cp -v perl cpan/podlators/scripts/pod2man ${LFS_DST}/bin
  mkdir -pv ${LFS_DST}/lib/perl5/5.30.0
  cp -Rv lib/* ${LFS_DST}/lib/perl5/5.30.0
};
add_pkg perl
# 5.30. Python-3.7.4
python_unpack() {
  local arc
  local pkg=Python
  archive_name Python
  pkg=python
  test -f "$arc" || return 1;
  generic_unpack
};
python_preconfig() {
  sed -i '/def add_multiarch_paths/a \        return' setup.py
}
python_config() {
  ./configure --prefix=${LFS_DST} --without-ensurepip 
}
add_pkg python
# 5.31. Sed-4.7
add_pkg sed
# 5.32. Tar-1.32
add_pkg tar
# 5.33. Texinfo-6.6
add_pkg texinfo
# 5.34. Xz-5.2.4
add_pkg xz
# 5.35. Stripping
post_build_all() {
  cd $LFS_SRC
  test -e .post_build_all.done && return 0
  find ${LFS_DST}{lib,libexec} -name \*.la -delete
  strip --strip-debug ${LFS_DST}/lib/*
  /usr/bin/strip --strip-unneeded ${LFS_DST}/{,s}bin/*
  rm -rf ${LFS_DST}/{info,man,doc}
  serdate > .post_build_all.done
};
# XXX Rsync
rsync_config() {
  ./configure --prefix=${LFS_DST} --disable-ipv6 
};
add_pkg rsync
# XXX Vim:
vim_preconfig() {
 echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
}
vim_postinstall() {
  ln -sfv vim ${LFS_DST}/bin/vi
  for L in  ${LFS_DST}/man/{,*/}man1/vim.1; do
    ln -sfv vim.1 $(dirname $L)/vi.1
  done
}
add_pkg vim
run_build;
