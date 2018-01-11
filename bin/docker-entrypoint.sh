#!/bin/sh

set -x

lb clean
lb config \
        --distribution xenial \
        --debian-installer false \
        --mode ubuntu \
        --hooks *miner* \
        --archive-areas "main restricted universe multiverse" \
        --syslinux-theme live-build \
#        --linux-flavours "compute-rocm-rel-1.6-180" \
        --initramfs casper \
        --initramfs-compression lzma \
    && echo apt-utils curl syslinux-utils apt-transport-https gnupg2 ca-certificates xz-utils > config/package-lists/image.list.chroot \
    && echo apt-utils apt-transport-https gnupg2 xz-utils extlinux syslinux-utils isolinux syslinux gfxboot-theme-ubuntu syslinux-themes-ubuntu > config/package-lists/image.list.binary \
    && echo build-essential > config/package-lists/build.list.chroot \
    && echo curl > config/package-lists/web.list.chroot \
    && mkdir -p config/archives \
    && mkdir -p config/bootloaders \
    && mkdir -p config/hooks/normal \
    && mkdir -p chroot/root/lb_chroot_hooks \
    && mkdir -p config/includes.chroot/etc/default 

#        --bootappend-live "boot=live components hostname=miner username=minor" \
#        --linux-flavours "compute-rocm-rel-1.6-180" \
#       --apt-recommends false \
#        --archive-areas "main multiverse restricted" \
#        --debootstrap-options "--include=apt-transport-https,gnupg2,ca-certificates" \
#        --firmware-chroot false \
#    && echo docker-ce > config/package-lists/docker.list.chroot \
#    && echo rocm-opencl rocm-opencl-dev rocm-dev rocm-libs rocm-dkms > config/package-lists/rocm.list.chroot \

# cp conf/{chroot,common,binary} config

cat > config/includes.chroot/etc/default/grub <<EOF
GRUB_TIMEOUT=0
EOF

cp -rf conf/archives/t* config/archives/
cp -rf conf/inc* config
#cp -rf conf/bootloaders/iso* config/bootloaders
#cp -rf conf/hooks/normal/* config/hooks/normal
cp -rf conf/hooks/* config/hooks/
#cp config/hooks/normal/* chroot/root/lb_chroot_hooks/
chmod -R 755 config/hooks/

find config/bootloaders
find config/hooks


lb build

ls -l
cp *iso /work
#    && cp -rf conf/bootloaders/* config/bootloaders \
 