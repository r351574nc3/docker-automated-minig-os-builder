FROM ubuntu:bionic

ENV DEBCONF_FRONTEND noninteractive

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y \
        live-build \
        live-tools \
        syslinux \
        syslinux-utils \
        squashfs-tools \
        genisoimage \
        debootstrap \
        fakeroot

RUN mkdir -p /opt

ADD bin /opt/bin
ADD conf /root/conf

RUN chmod 755 /opt/bin/*

VOLUME /work

WORKDIR /root

ENTRYPOINT ["sh", "/opt/bin/docker-entrypoint.sh"]