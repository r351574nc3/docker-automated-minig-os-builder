FROM fedora:27


RUN dnf -y update \
    && dnf groupinstall -y "Development Tools" \
    && dnf -y install kernel-devel \
    && dnf -y install pykickstart \
    && dnf -y install livecd-tools 

RUN mkdir -p /kickstarts /opt/bin

ADD bin /opt/bin

RUN chmod -R 755 /opt/bin

VOLUME /kickstarts

WORKDIR /kickstarts

ENTRYPOINT ["/opt/bin/run.sh"]

CMD [ 'default.ks' ]