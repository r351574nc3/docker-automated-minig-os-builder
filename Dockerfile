FROM debian:stretch 

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
    && pip install diskimage-builder \
    && mkdir -p /opt/bin

ADD bin/* /opt/bin

WORKDIR /work

ENTRYPOINT ["bash", "/opt/bin/docker-entrypoint.sh"]
