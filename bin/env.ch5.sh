PART=ch5
LFS=/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS_SRC=/lfs/usr/src/lfs
LFS_ARC=${LFS_SRC}/arc/lfs
LFS_BLD=${LFS_SRC}/src/$PART
LFS_DST=/static
PATH=/tools/bin:/bin:/usr/bin
export LFS LFS_TGT LFS_SRC LFS_ARC LFS_BLD PART
