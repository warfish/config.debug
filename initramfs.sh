#!/bin/bash

INITRAMFS_ROOT=$(realpath ${INITRAMFS_ROOT:-./initramfs})
BUSYBOX_PATH=$(realpath ${BUSYBOX_PATH:-/bin/busybox})

[ -d $INITRAMFS_ROOT ] && rm -rf $INITRAMFS_ROOT

mkdir -p $INITRAMFS_ROOT/{bin,dev,etc,lib,proc,root,sbin,sys,/usr/bin,/usr/sbin,/usr/share} 
pushd $INITRAMFS_ROOT > /dev/null

ln -s lib lib64

# Copy busybox
[ -f "$BUSYBOX_PATH" ] || { echo Busybox is not installed; exit -1; }
cp $BUSYBOX_PATH bin/
chmod +x bin/busybox

# Copy external non-static binaries
DYNBINS="bash lspci lscpu lstopo numactl htop strace"
for b in $DYNBINS; do
	binpath=$(which $b)
	[ -z "$binpath" ] && { echo $b is not installed; exit -1; }

	cp $binpath bin/
	for f in $(ldd $binpath | cut -d '(' -f 1 | cut -d '>' -f 2 | grep -v vdso); do
		cp $f lib/
	done
done

# terminfo
cp -R /etc/terminfo etc/
cp -R /lib/terminfo lib/
cp -R /usr/share/terminfo usr/share

# Add console devices
sudo mknod -m 622 dev/console c 5 1
sudo mknod -m 622 dev/tty0 c 4 0

# Build /init script
cat >init <<-EOF
	#!/bin/busybox sh

	/bin/busybox --install -s

	mount -t proc proc /proc
	mount -t sysfs sysfs /sys
	mount -t debugfs debugfs /sys/kernel/debug
	mount -t tracefs tracefs /sys/kernel/debug/tracing

	exec /bin/bash -i
	EOF
chmod +x init

# Make the initramfs image
find . | cpio -H newc -o > ../initramfs.cpio
popd > /dev/null
