PART=ch6
LFS=/
LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS_SRC=/usr/src/lfs
LFS_ARC=${LFS_SRC}/arc/lfs
LFS_BLD=${LFS_SRC}/src/$PART
LFS_DST=${LFS}
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/tools/sbin:/tools/bin
export LFS LFS_BLD LFS_TGT LFS_SRC LFS_ARC LFS_DST PATH PART
