#!/bin/bash

INITRAMFS_ROOT=$(realpath ${INITRAMFS_ROOT:-./initramfs})
BUSYBOX_PATH=$(realpath ${BUSYBOX_PATH:-/bin/busybox})

[ -d $INITRAMFS_ROOT ] && rm -rf $INITRAMFS_ROOT

mkdir -p $INITRAMFS_ROOT/{bin,dev,etc,lib,proc,root,sbin,sys,/usr/bin,/usr/sbin,/usr/share} 
pushd $INITRAMFS_ROOT > /dev/null

ln -s lib lib64

# Install busybox
[ -f "$BUSYBOX_PATH" ] || { echo Busybox is not installed; exit -1; }
cp $BUSYBOX_PATH bin/
chmod +x bin/busybox

for b in `busybox --list`; do
	# Symlink is explicitly relative
	ln -s busybox bin/$b
done

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

# Build /init script
cat >init <<-EOF
	#!/bin/sh

	mount -t proc none /proc
	mount -t sysfs none /sys
	mount -t devtmpfs none /dev
	mount -t debugfs none /sys/kernel/debug
	mount -t tracefs none /sys/kernel/debug/tracing

	exec /bin/bash -i
	EOF
chmod +x init

# Prepare fakeroot script and run it
fakeroot -- /bin/bash -c '
    # Add device for early console
    # will be overlayed by devtmpfs, but needed before we can mount it
    mknod -m 622 dev/console c 5 1;

    # Make the initramfs image
    find . | cpio -H newc -o > ../initramfs.cpio;
'

popd > /dev/null
