#!/bin/bash -x
# SnappyData CloudFormation script

printf "\n# `date` -------------------------------------------------- #\n" >> status.log

mkdir -p /snappydata/downloads
cd /snappydata/downloads
printf "Moved to downloads dir $?\n" >> status.log

ZEPPELIN_DIR=zeppelin-0.6.1-bin-netinst

SNAPPYDATA_URL=`cat snappydata-url.txt`
SNAPPYDATA_TAR_NAME=`echo ${SNAPPYDATA_URL} | cut -d'/' -f 9`
SNAPPYDATA_DIR=`echo ${SNAPPYDATA_TAR_NAME%.tar.gz}`
printf "SnappyData dir ${SNAPPYDATA_DIR} $?\n" >> status.log

INTERPRETER_URL=`cat interpreter-url.txt`
INTERPRETER_JAR_NAME=`echo ${INTERPRETER_URL} | cut -d'/' -f 9`
printf "SnappyData interpreter name ${INTERPRETER_JAR_NAME} $?\n" >> status.log
SNAPPY_INTERPRETER_DIR=${ZEPPELIN_DIR}/interpreter/snappydata

NOTEBOOK_URL=`cat notebook-url.txt`

if [[ ! -e /etc/hosts.orig ]]; then
  mv /etc/hosts /etc/hosts.orig
  printf "Backed up /etc/hosts $?\n" >> status.log
fi
cat /etc/hosts.orig | grep -v 127.0.0.1 > /etc/hosts
PRIVATE_IP=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`
PUBLIC_HOSTNAME=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname`
printf "\n${PRIVATE_IP} ${PUBLIC_HOSTNAME} \n" >> /etc/hosts
printf "\n${PRIVATE_IP} localhost \n" >> /etc/hosts
printf "Modified /etc/hosts $?\n" >> status.log

mkdir -p ~/.ssh
if [[ ! -e ~/.ssh/id_rsa ]]; then
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  printf "Enabled passwordless-ssh $?\n" >> status.log
fi

# ----------------------------------

# Download and extract snappydata distribution
if [[ ! -d ${SNAPPYDATA_DIR} ]]; then
  wget ${SNAPPYDATA_URL}
  printf "Downloaded snappydata distribution $?\n" >> status.log
  tar -xf ${SNAPPYDATA_TAR_NAME}
  printf "Extracted snappydata distribution $?\n" >> status.log
fi

# Download and extract the notebook
rm -rf notebook.tar.gz notebook/
wget ${NOTEBOOK_URL}
tar -xf notebook.tar.gz
printf "Extracted notebook $?\n" >> status.log

cp -R notebook/* ${ZEPPELIN_DIR}/notebook/

# Configure snappydata cluster
printf "${PUBLIC_HOSTNAME} -peer-discovery-address=${PUBLIC_HOSTNAME} -jmx-manager=true -jmx-manager-start=true\n  "  > ${SNAPPYDATA_DIR}/conf/locators
printf "${PUBLIC_HOSTNAME} -client-bind-address=${PUBLIC_HOSTNAME} -locators=${PUBLIC_HOSTNAME}:10334 -client-port=1528\n" > ${SNAPPYDATA_DIR}/conf/servers
printf "${PUBLIC_HOSTNAME} -client-bind-address=${PUBLIC_HOSTNAME} -locators=${PUBLIC_HOSTNAME}:10334 -client-port=1529\n" >> ${SNAPPYDATA_DIR}/conf/servers
printf "${PUBLIC_HOSTNAME} -locators=${PUBLIC_HOSTNAME}:10334 -zeppelin.interpreter.enable=true \n" > ${SNAPPYDATA_DIR}/conf/leads

if [[ ! -e ${SNAPPY_INTERPRETER_DIR}/${INTERPRETER_JAR_NAME} ]]; then
  wget ${INTERPRETER_URL}
  printf "Downloaded Zeppelin Interpreter for SnappyData $?\n" >> status.log

  mkdir -p ${SNAPPY_INTERPRETER_DIR}
  printf "Created directory for Zeppelin SnappyData Interpreter $?\n" >> status.log

  cp ${INTERPRETER_JAR_NAME} ${SNAPPYDATA_DIR}/jars/
  printf "Copied interpreter jar to SnappyData jars dir $?\n" >> status.log

  cp -a ${SNAPPYDATA_DIR}/jars/. ${SNAPPY_INTERPRETER_DIR}/
  printf "Copied SnappyData jars to interpreter directory $?\n" >> status.log

  mv ${INTERPRETER_JAR_NAME} ${SNAPPY_INTERPRETER_DIR}/
  printf "Moved interpreter jar to its dir $?\n" >> status.log
fi

# Start the single node snappydata cluster
bash ${SNAPPYDATA_DIR}/sbin/snappy-start-all.sh
printf "Started SnappyData cluster $?\n" >> status.log

find ${ZEPPELIN_DIR}/notebook -type f -print0 | xargs -0 sed -i "s/localhost/${PUBLIC_HOSTNAME}/g"

# Start Apache Zeppelin server
bash ${ZEPPELIN_DIR}/bin/zeppelin-daemon.sh start
printf "Started Zeppelin server $?\n" >> status.log


