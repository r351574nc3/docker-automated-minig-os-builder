#!/bin/sh -x

lb clean
lb config \
        --distribution stretch \
        --archive-areas "main contrib non-free" \
        --debian-installer false \
        --debootstrap-options "--include=apt-transport-https,gnupg2,ca-certificates" \
        --bootappend-live "boot=live components hostname=miner username=minor" \
    && echo build-essential > config/package-lists/build.list.chroot \
    && echo curl > config/package-lists/web.list.chroot \
    && mkdir -p config/bootloaders \
    && mkdir -p config/hooks/normal \
    && mkdir -p config/includes.chroot/etc/default

#    && mkdir -p config/archives \
#        --firmware-chroot false \
#    && echo docker-ce > config/package-lists/docker.list.chroot \
#    && echo rocm-opencl rocm-opencl-dev rocm-dev rocm-libs rocm-dkms > config/package-lists/rocm.list.chroot \


cat > config/includes.chroot/etc/default/grub <<EOF
GRUB_TIMEOUT=0
EOF

#cp -rf conf/archives/* config/archives/
cp -rf conf/bootloaders/iso* config/bootloaders
cp -rf conf/hooks/normal/* config/hooks/normal
chmod -R 755 config/hooks/

find config/bootloaders
find config/hooks


lb build

ls -l
cp *iso /work
#    && cp -rf conf/bootloaders/* config/bootloaders \
 