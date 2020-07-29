PART=xc
LFS=/
LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS_SRC=/usr/src/lfs
LFS_ARC=${LFS_SRC}/arc/${PART}
LFS_BLD=${LFS_SRC}/src/${PART}
LFS_DST=${LFS}
XPRE="${LFS_DST}usr/X11"
XCFG="--prefix=${XPRE}"
XCFG="${XCFG} --sysconfdir=/etc"
XCFG="${XCFG} --localstatedir=/var"
#XCFG="${XCFG} --disable-static"
PATH="${XPRE}/sbin:${XPRE}/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11/bin"

XORG_PREFIX="${XPRE}"
XORG_CONFIG="${XCFG}"

export XPRE XCFG
export XORG_PREFIX XORG_CONFIG
export LFS LFS_BLD LFS_TGT LFS_SRC LFS_ARC LFS_DST PATH PART
test -n "$PKG_CONFIG_PATH" && PKG_CONFIG_PATH="$PKG_CONFIG_PATH:"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}/usr/X11/lib/pkgconfig"
