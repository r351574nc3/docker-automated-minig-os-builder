FROM fedora:27


RUN yum -y update \
    && yum -y install pykickstart \
    && yum -y install livecd-tools

RUN mkdir -p /kickstarts /opt/bin

ADD bin /opt/bin

RUN chmod -R 755 /opt/bin

VOLUME /kickstarts

WORKDIR /kickstarts

ENTRYPOINT ["/opt/bin/run.sh"]

CMD [ 'default.ks' ]