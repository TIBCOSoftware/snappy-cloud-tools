#!/bin/bash -x
# SnappyData CloudFormation script

mkdir -p /snappydata/downloads
cd /snappydata/downloads
printf "# `date` Moved to downloads dir $?\n" >> status.log

# Initialize various variables.
ZEPPELIN_DIR=zeppelin-0.6.1-bin-netinst

SNAPPYDATA_URL=`cat snappydata-url.txt`
SNAPPYDATA_TAR_NAME=`echo ${SNAPPYDATA_URL} | cut -d'/' -f 9`
SNAPPYDATA_DIR=`echo ${SNAPPYDATA_TAR_NAME%.tar.gz}`
printf "# `date` SnappyData dir ${SNAPPYDATA_DIR} $?\n" >> status.log

INTERPRETER_URL=`cat interpreter-url.txt`
INTERPRETER_JAR_NAME=`echo ${INTERPRETER_URL} | cut -d'/' -f 9`
printf "# `date` SnappyData interpreter name ${INTERPRETER_JAR_NAME} $?\n" >> status.log
SNAPPY_INTERPRETER_DIR=${ZEPPELIN_DIR}/interpreter/snappydata

NOTEBOOK_URL=`cat notebook-url.txt`

# Edit /etc/hosts so that the cluster is available outside the VPC.
if [[ ! -e /etc/hosts.orig ]]; then
  mv /etc/hosts /etc/hosts.orig
  printf "# `date` Backed up /etc/hosts $?\n" >> status.log
fi
cat /etc/hosts.orig | grep -v 127.0.0.1 > /etc/hosts
PRIVATE_IP=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`
if [[ $? -eq 0 ]]; then
  PUBLIC_HOSTNAME=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname`
  printf "\n${PRIVATE_IP} ${PUBLIC_HOSTNAME} \n" >> /etc/hosts
  printf "${PRIVATE_IP} localhost \n\n" >> /etc/hosts
  printf "# `date` Modified /etc/hosts $?\n" >> status.log
fi

# Generate ssh keys for passwordless-ssh
mkdir -p ~/.ssh
if [[ ! -e ~/.ssh/id_rsa ]]; then
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  printf "# `date` Enabled passwordless-ssh $?\n" >> status.log
fi

# Download and extract snappydata distribution
if [[ ! -d ${SNAPPYDATA_DIR} ]]; then
  wget ${SNAPPYDATA_URL}
  printf "# `date` Downloaded snappydata distribution $?\n" >> status.log
  tar -xf ${SNAPPYDATA_TAR_NAME}
  printf "# `date` Extracted snappydata distribution $?\n" >> status.log
fi

# Download and extract the notebook
rm -rf notebook.tar.gz notebook/
wget ${NOTEBOOK_URL}
tar -xf notebook.tar.gz
sed -i "s/<value>snappydata<\/value>/<value>Quickstart<\/value>/" "notebook/Quickstart/Quickstart.json"
sed -i "s/<value><\/value>/<value>Quickstart<\/value>/" "notebook/Quickstart/Quickstart.json"
printf "# `date` Extracted notebook $?\n" >> status.log

# Copy the notebook to Zeppelin and update the local hostname.
cp -R notebook/* ${ZEPPELIN_DIR}/notebook/
find ${ZEPPELIN_DIR}/notebook -type f -print0 | xargs -0 sed -i "s/localhost/${PUBLIC_HOSTNAME}/g"

# Set -Xmx for the server
INST_TYPE=`curl http://169.254.169.254/latest/meta-data/instance-type`
XMX_VALUE=`grep ${INST_TYPE} server-memory.txt | grep -o "[0-9]*$"`

if [[ $? -ne 0 ]]; then
  XMX_OPT=""
else
  XMX_OPT="-J-Xmx${XMX_VALUE}g"
fi

# Configure snappydata cluster
printf "localhost -jmx-manager=true -jmx-manager-start=true\n"  > ${SNAPPYDATA_DIR}/conf/locators
printf "localhost -client-bind-address=${PUBLIC_HOSTNAME} -locators=${PUBLIC_HOSTNAME}:10334 -client-port=1528 ${XMX_OPT}\n" > ${SNAPPYDATA_DIR}/conf/servers
printf "localhost -locators=localhost:10334 -zeppelin.interpreter.enable=true \n" > ${SNAPPYDATA_DIR}/conf/leads
printf "# `date` Configured SnappyData cluster $?\n" >> status.log

# Download interpreter jar and copy the relevant jars where needed.
if [[ ! -e ${SNAPPY_INTERPRETER_DIR}/${INTERPRETER_JAR_NAME} ]]; then
  wget ${INTERPRETER_URL}
  printf "# `date` Downloaded Zeppelin Interpreter for SnappyData $?\n" >> status.log

  mkdir -p ${SNAPPY_INTERPRETER_DIR}
  printf "# `date` Created directory for Zeppelin SnappyData Interpreter $?\n" >> status.log

  cp ${INTERPRETER_JAR_NAME} ${SNAPPYDATA_DIR}/jars/
  printf "# `date` Copied interpreter jar to SnappyData jars dir $?\n" >> status.log

  cp -a ${SNAPPYDATA_DIR}/jars/. ${SNAPPY_INTERPRETER_DIR}/
  printf "# `date` Copied SnappyData jars to interpreter directory $?\n" >> status.log

  mv ${INTERPRETER_JAR_NAME} ${SNAPPY_INTERPRETER_DIR}/
  printf "# `date` Moved interpreter jar to its dir $?\n" >> status.log
fi


# Skip interpreter.json, if it exists.
if [[ -e ${ZEPPELIN_DIR}/conf/interpreter.json ]]; then
  mv ${ZEPPELIN_DIR}/conf/interpreter.json ${ZEPPELIN_DIR}/conf/interpreter.json.bak
fi


cp ${ZEPPELIN_DIR}/conf/zeppelin-env.sh.template ${ZEPPELIN_DIR}/conf/zeppelin-env.sh
printf "\n export ZEPPELIN_INTP_MEM=\"-Xmx6g -XX:MaxPermSize=512m\"" >> ${ZEPPELIN_DIR}/conf/zeppelin-env.sh

# Start Apache Zeppelin server
bash ${ZEPPELIN_DIR}/bin/zeppelin-daemon.sh start
CLUSTER_STARTED=`echo $?`

printf "# `date` Started Zeppelin server ${CLUSTER_STARTED}\n" >> status.log

# Check if we need to shutdown the instance after some time.
wget http://169.254.169.254/latest/dynamic/instance-identity/document
grep 605015649645 document
if [[ $? -eq 0 ]]; then
  grep jags-snappy-key /root/.ssh/authorized_keys
  if [[ $? -ne 0 ]]; then
    shutdown -h 120 &
    printf "# `date` Shutting down this instance in 120 minutes from now.\n" >> status.log
  fi
fi

exit ${CLUSTER_STARTED}

