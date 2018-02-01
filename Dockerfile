FROM ubuntu:xenial

MAINTAINER Leo Przybylski (r351574nc3 at gmail.com)


RUN apt-get update \
    && apt-get install -y \
        python-pip \
        python3 \
        python3-pip \
        qemu \ 
        curl \
        sudo \
        procps \
        kpartx \
        squashfs-tools \
        e2fsprogs \
        debootstrap \
        dkms \
        git \
        dosfstools \
        syslinux \
        syslinux-common \
        isolinux \
        genisoimage \
    && pip install --upgrade pip \
    && mkdir -p /opt/bin

RUN mkdir -p /tmp/build \
    && cd /tmp/build \
    && git clone https://git.openstack.org/openstack/diskimage-builder \
    && cd diskimage-builder \
    && pip install -e .

ADD bin/* /opt/bin

WORKDIR /work

VOLUME /work

ENTRYPOINT ["bash", "/opt/bin/docker-entrypoint.sh"]
