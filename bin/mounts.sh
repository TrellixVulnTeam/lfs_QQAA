LFS=/lfs
mountpoint $LFS/dev || mount -vt devfs $LFS/dev
mountpoint $LFS/dev/pts || mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mountpoint $LFS/proc || mount -vt proc proc $LFS/proc
mountpoint $LFS/sys || mount -vt sysfs sysfs $LFS/sys
mountpoint $LFS/run || mount -vt tmpfs tmpfs $LFS/run
