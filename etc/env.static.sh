set -ex
PART=stat
LFS=/boot
DST=/static
LFS_DST=${LFS}${DST}
LFS_TGT=$(uname -m)-lfs-linux-gnu
LFS_SRC=${LFS_DST}/src
cd "${LFS_SRC}"
LFS_ARC=${LFS_SRC}/arc/lfs
LFS_BLD=${LFS_SRC}/src
set -- ${LFS_DST}/ / /usr /tools --
while [[ $1 != -- ]]; do
  i="$1";
  set "$@" ${1%/}/sbin ${1%/}/bin
  shift
done
shift
eval "$( IFS=:; echo XPATH="$*" )"
PATH="$XPATH"
export LFS LFS_TGT LFS_SRC LFS_ARC LFS_BLD PART
