#!/bin/sh -x

lb clean
lb config \
        --distribution xenial \
        --debian-installer false \
        --mode ubuntu \
        --apt-recommends false \
        --syslinux-theme ubuntu-xenial \
        --archive-areas "main multiverse restricted" \
        --bootappend-live "boot=live components hostname=miner username=minor" \
    && echo build-essential > config/package-lists/build.list.chroot \
    && echo curl > config/package-lists/web.list.chroot \
    && mkdir -p config/bootloaders \
    && mkdir -p config/hooks/normal \
    && mkdir -p config/includes.chroot/etc/default 

#        --debootstrap-options "--include=apt-transport-https,gnupg2,ca-certificates" \
#    && mkdir -p config/archives \
#        --firmware-chroot false \
#    && echo docker-ce > config/package-lists/docker.list.chroot \
#    && echo rocm-opencl rocm-opencl-dev rocm-dev rocm-libs rocm-dkms > config/package-lists/rocm.list.chroot \

# cp conf/{chroot,common,binary} config

cat > config/includes.chroot/etc/default/grub <<EOF
GRUB_TIMEOUT=0
EOF

#cp -rf conf/archives/t* config/archives/
cp -rf conf/inc* config
cp -rf conf/bootloaders/ext* config/bootloaders
cp -rf conf/hooks/normal/* config/hooks/normal
chmod -R 755 config/hooks/

find config/bootloaders
find config/hooks


lb build

ls -l
cp *iso /work
#    && cp -rf conf/bootloaders/* config/bootloaders \
 