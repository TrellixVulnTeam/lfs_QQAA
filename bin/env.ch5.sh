PART=ch5
LFS=/boot
LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS_DST=/tools
LFS_SRC=${LFS_DST}/src
LFS_ARC=${LFS_SRC}/arc/lfs
LFS_BLD=${LFS_SRC}/src
PATH=${LFS_BLD}/bin:/bin:/usr/bin
export LFS LFS_TGT LFS_SRC LFS_ARC LFS_BLD PART LFS_DST
