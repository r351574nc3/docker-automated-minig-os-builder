#!/bin/bash

export DIB_RELEASE=xenial
export DIB_IMAGE_ROOT_FS_UUID=fcb1b666-3e7e-4f9d-b703-b2f7039165bc
export ELEMENTS_PATH=elements
export DIB_DEV_USER_USERNAME=miner
export DIB_DEV_USER_PASSWORD=miner
export DIB_DEV_USER_PWDLESS_SUDO=1
#export DIB_BLOCK_DEVICE_CONFIG='- local_loop:
#    name: image0
#    size: 10.5GiB
#    mkfs:
#      name: mkfs_root
#      uuid: fcb1b666-3e7e-4f9d-b703-b2f7039165bc
#      label: root
#      mount:
#        mount_point: /
#        fstab:
#          options: "defaults"
#          fsck-passno: 1'
# disk-image-create --image-size=8Gb --mkfs-options '-J size=16' -t raw ubuntu-minimal bootloader
exec disk-image-create --image-size=8Gb --mkfs-options '-J size=16' -t raw "$@" 
