FROM fedora:latest 

MAINTAINER Leo Przybylski (r351574nc3 at gmail.com)



RUN dnf update -y \
    && dnf dist-upgrade -y \
    && dnf install -y python3 python-pip qemu sudo syslinux  \
    && pip install diskimage-builder


ADD bin/* /opt/bin

WORKDIR /work

VOLUME /work

ENTRYPOINT ["bash", "/opt/bin/docker-entrypoint.sh"]
