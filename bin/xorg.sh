#!/bin/bash

if (($UID)); then
  echo >&2 "Run me as root!"
  exit 1
fi
source bin/func.sh
source bin/env.xorg.sh
set -e
pre_build_all() {
  if test -e /usr/lib/X11 ; then
    echo >&2 "fix your shit!";
    exit 2
  fi
#  set -- "$@" ${XPRE}/lib/X11/. /usr/lib/X11/.
  set -- "$@" ${XPRE}/lib/pkgconfig/. ${XPRE}/share/pkgconfig/.
  while (($#)); do 
    if [ -d $1 ] && [ -d $2 ] && [ $1 -ef $2 ]; then
     	shift 2; 
      else
	ls -ld $1 $2 $(dirname $1) $(dirname $2)
      echo fix "$1" "$2"
      exit 1
    fi
  done
#  ln -sf  ${XPRE}/include/X11 /usr/include/X11
};
post_build_all() {
 echo "done!"
}
generic_config() {
  report ./configure ${XCFG}
};
init_functions="$(compgen -A function|sort)"

####
####  Packages Below
#### 
add_pkg util-macros
xorgproto_builddir() {
  dir="$pkg/build"
};
xorgproto_build() {
  meson --prefix=$XPRE .. && ninja
};
xorgproto_install() {
  ninja install
  install -vdm 755 $XPRE/share/doc/xorgproto-2019.1
  install -vm 644 ../[^m]*.txt ../PM_spec \
    $XPRE/share/doc/xorgproto-2019.1

};
xorgproto_config() {
  true;
};
add_pkg xorgproto
add_pkg libX11
add_pkg libXext
libXt_unpack() {
  arc=$LFS_ARC/libXt-1.2.0.tar.bz2
  generic_unpack;
};
libXt_config() {
  ./configure $XCFG \
    --with-appdefaultdir=/etc/X11/app-defaults
};
add_pkg libXt
add_pkg libXmu
add_pkg libXau
add_pkg libXdmcp
add_pkg xcb-proto
add_pkg libfontenc
add_pkg mkfontscale
libxcb_preconfig() {
  sed -i "s/pthread-stubs//" configure 
}
libxcb_config()
{
  ./configure $XCFG \
    --without-doxygen \
    --docdir='${datadir}'/doc/libxcb-1.13.1 &&
  echo
};
add_pkg libxcb

add_pkg font-util
add_pkg encodings
add_pkg font-alias
add_pkg font-adobe-utopia-type1
add_pkg font-bh-ttf
add_pkg font-bh-type1
add_pkg font-ibm-type1
add_pkg font-misc-ethiopic
font-xfree86-type1_postinstall() {
	install -v -d -m755 /usr/share/fonts &&
	ln -svfn $XPRE/share/fonts/X11/OTF /usr/share/fonts/X11-OTF &&
	ln -svfn $XPRE/share/fonts/X11/TTF /usr/share/fonts/X11-TTF
}
add_pkg font-xfree86-type1
add_pkg xtrans
add_pkg libFS
libICE_config() {
  ./configure $XCFG ICE_LIBS=-lpthread
}
add_pkg libICE
add_pkg libSM
add_pkg libXScrnSaver

libXfont2_config() {
  ./configure $XCFG --disable-devel-docs;
};
add_pkg libXfont2
add_pkg libXpm
add_pkg libXaw
add_pkg libXfixes
add_pkg libXrender
add_pkg libXcomposite
add_pkg libXcursor
add_pkg libXdamage
add_pkg libXft
add_pkg libXi
add_pkg libXinerama
add_pkg libXrandr
add_pkg libXres
add_pkg libXtst
add_pkg libXv
add_pkg libXvMC
add_pkg libXxf86dga
add_pkg libXxf86vm
add_pkg libdmx
add_pkg libxkbfile
add_pkg libxshmfence
mesa_builddir() {
  dir=$pkg/build
}
mesa_config() {
 meson --prefix=/usr/X11 -Dbuildtype=release -Ddri-drivers=i915 -Dgallium-drivers= -Dglx=dri -Dvalgrind=false ..
}
mesa_build() {
  ninja
}
mesa_install() {
  ninja install;
};
add_pkg mesa



xorg-server_config() {
 ./configure \
   $XCFG            \
   --enable-glamor         \
   --enable-suid-wrapper   \
   --with-xkb-output=/var/lib/xkb
}
add_pkg xorg-server

####
####  Packages Above
#### 
run_build;
