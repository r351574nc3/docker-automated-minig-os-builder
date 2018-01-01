#!/bin/sh

mkdir -p work/chroot
cd work

debootstrap --include="apt-transport-https,gnupg2,ca-certificates" --arch=amd64 --variant=minbase xenial chroot

mount --bind /dev chroot/dev

cp /etc/hosts chroot/etc/hosts
cp /etc/resolv.conf chroot/etc/resolv.conf
cp /etc/apt/sources.list chroot/etc/apt/sources.list

