LFS=/lfs
set -e
for i in dev dev/pts proc sys; do
  mkdir -p $LFS/$i
done
mountpoint $LFS/dev ||
  mount --bind /dev $LFS/dev
mountpoint $LFS/dev/pts || 
  mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mountpoint $LFS/proc/ ||
  mount -vt proc proc $LFS/proc
mountpoint $LFS/sys/ ||
  mount -vt sysfs sysfs $LFS/sys
