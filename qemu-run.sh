#!/bin/bash

set -ex

QEMU=$(realpath ${QEMU:-/usr/bin/qemu-system-x86_64})
KERNEL=$(realpath ${KERNEL:-./build/arch/x86/boot/bzImage})
INITRAMFS=$(realpath ${INITRAMFS:-initramfs.cpio})
CMDLINE="console=ttyS0 nokaslr initcall_debug $CMDLINE_EXTRA" 

$QEMU \
	-cpu host \
	-enable-kvm \
	-name test$i,debug-threads=on \
	-kernel $KERNEL \
	-initrd $INITRAMFS \
	-append "$CMDLINE" \
	-nographic \
	-smp 2,threads=2 \
	-m 256M \
	-s
