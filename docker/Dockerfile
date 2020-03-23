FROM centos:centos6

MAINTAINER TIBCO Software Inc.

USER root

RUN yum -y install epel-release nss_wrapper gettext && \
    yum -y install curl which tar sudo openssh-server openssh-clients passwd supervisor bind-utils nc wget && \
    yum -y install java-1.8.0-openjdk && \
    yum clean all -y

RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ENV PATH $PATH:$JAVA_HOME/bin

ARG TARFILE_LOC=https://github.com/SnappyDataInc/snappydata/releases/download/v1.2.0/snappydata-1.2.0-bin.tar.gz

RUN mkdir -p /opt/tmp-build/ /opt/tmp-extrd/

ADD ${TARFILE_LOC} /opt/tmp-build/ 

RUN export build_dir=$(ls /opt/tmp-build/) && \
    echo ${build_dir} | grep "tar.gz" && \
    tar -C /opt/tmp-extrd -xf /opt/tmp-build/${build_dir}  || mv /opt/tmp-build/${build_dir} /opt/tmp-extrd/${build_dir} && \
    export build_dir=$(ls /opt/tmp-extrd/) && \
    mv /opt/tmp-extrd/${build_dir} /opt/snappydata && \
    wget -q -O /opt/snappydata/jars/gcs-connector-latest-hadoop2.jar https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-latest-hadoop2.jar && \
    chgrp -R 0 /opt/snappydata && \
    chmod -R g+rw /opt/snappydata && \
    find /opt/snappydata -type d -exec chmod g+x {} + && \
    rm -rf /opt/tmp-build /opt/tmp-extrd && \
    wget -q -O /usr/local/bin/start https://raw.githubusercontent.com/SnappyDataInc/snappy-cloud-tools/master/docker/start && \
    chmod o+x /usr/local/bin/start 

WORKDIR /opt/snappydata

EXPOSE 5050

CMD ["/usr/local/bin/start", "all"]

