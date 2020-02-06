PART=xc
LFS=/
LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS_SRC=/usr/src/lfs
LFS_ARC=${LFS_SRC}/arc/${PART}
LFS_BLD=${LFS_SRC}/src/${PART}
LFS_DST=${LFS}
XORG_PREFIX=${LFS_DST}/usr/X11/
XORG_CONFIG="--prefix=$XARG_PREFIX --sysconfdir=/etc"
XORG_CONFIG="$XORG_CONFIG --localstatedir=/var"
XORG_CONFIG="$XORG_CONFIG --disable-static"
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/X11/bin
export XORG_PREFIX XORG_CONFIG
export LFS LFS_BLD LFS_TGT LFS_SRC LFS_ARC LFS_DST PATH PART
