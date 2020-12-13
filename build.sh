#!/bin/bash

set -e

CONFIG=${CONFIG:-config.debug}
BINDIR=$(realpath ${BINDIR:-./build})

[ ! -d $BINDIR ] && mkdir $BINDIR > /dev/null
cp $CONFIG $BINDIR/.config
touch $BINDIR/initramfs-empty.txt
make -C linux/ O=$BINDIR ARCH=x86 oldconfig
make -C linux/ O=$BINDIR ARCH=x86 -j $(nproc) | tee ./build.log
