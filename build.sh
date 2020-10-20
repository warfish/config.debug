#!/bin/bash

set -x

CONFIG=${CONFIG:-config.debug}
BINDIR=$(realpath ${BINDIR:-./build})

mkdir $BINDIR > /dev/null
cp $CONFIG $BINDIR/.config
touch $BINDIR/initramfs-empty.txt
make -C linux/ O=$BINDIR ARCH=x86 oldconfig
make -C linux/ O=$BINDIR ARCH=x86 -j 12 bzImage | tee ./build.log

objcopy --only-keep-debug build/vmlinux build/vmlinux.debug
strip -s build/vmlinux
