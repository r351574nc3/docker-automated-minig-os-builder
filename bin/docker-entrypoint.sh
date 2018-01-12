#!/bin/bash

export DIB_BLOCK_DEVICE_CONFIG='- local_loop:
    name: image0
    size: 7.5GiB
    mkfs:
      name: mkfs_root
      mount:
        mount_point: /
        fstab:
          options: "defaults"
          fsck-passno: 1'
exec disk-image-create --mkfs-options '-J size=32' -t raw "$@" && cp image.raw /work