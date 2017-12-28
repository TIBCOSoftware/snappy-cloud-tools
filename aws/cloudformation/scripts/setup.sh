#!/bin/bash -x

#
# Copyright (c) 2017 SnappyData, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You
# may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License. See accompanying
# LICENSE file.
#

# SnappyData CloudFormation script

mkdir -p ${DOWNLOADS_DIR}
cd ${DOWNLOADS_DIR}
printf "# `date` Moved to downloads dir $?\n" >> status.log

# Initialize various variables.
SNAPPYDATA_TAR_NAME=`echo ${SNAPPYDATA_URL} | cut -d'/' -f 9`
SNAPPYDATA_EXTRACTED=`echo ${SNAPPYDATA_TAR_NAME%.tar.gz}`
printf "# `date` SnappyData tar name ${SNAPPYDATA_TAR_NAME} $?\n" >> status.log

INTERPRETER_JAR_NAME=`echo ${INTERPRETER_URL} | cut -d'/' -f 9`
printf "# `date` SnappyData interpreter name ${INTERPRETER_JAR_NAME} $?\n" >> status.log
SNAPPY_INTERPRETER_DIR=${ZEPPELIN_DIR}/interpreter/snappydata

PUBLIC_HOSTNAME=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname`
PRIVATE_IP=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`

# Generate ssh keys for passwordless-ssh
mkdir -p ~/.ssh
if [[ ! -e ~/.ssh/id_rsa ]]; then
  ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  printf "# `date` Enabled passwordless-ssh $?\n" >> status.log
fi

# Download and extract snappydata distribution
if [[ ! -d ${SNAPPYDATA_DIR} ]]; then
  wget -q ${SNAPPYDATA_URL}
  printf "# `date` Downloaded snappydata distribution $?\n" >> status.log
  tar -xf ${SNAPPYDATA_TAR_NAME}
  sudo mv ${SNAPPYDATA_EXTRACTED} ${SNAPPYDATA_DIR}
  printf "# `date` Extracted snappydata distribution $?\n" >> status.log
fi

# Download and extract the notebook
rm -rf notebook.tar.gz notebook/
wget -q ${NOTEBOOK_URL}
tar -xf notebook.tar.gz
printf "# `date` Extracted notebook $?\n" >> status.log

# Copy the notebook to Zeppelin and update the local hostname.
rm -rf ${ZEPPELIN_DIR}/notebook/*
mkdir -p ${ZEPPELIN_DIR}/notebook
cp -R notebook/* ${ZEPPELIN_DIR}/notebook/
find ${ZEPPELIN_DIR}/notebook -type f -print0 | xargs -0 sed -i "s/localhost/${PUBLIC_HOSTNAME}/g"

# Calculate heap and off-heap sizes.
# Set heap to be 8GB or 1/4th of considered memory, whichever is higher. Remaining for off-heap.
MYRAM=`free -gt | grep Total | awk '{print $2}'`
AVAIL=`echo $MYRAM \* 0.9 / 1 | bc`
HEAP=`echo $AVAIL \* 0.25 / 1 | bc`
HEAP=$(($HEAP < 8 ? 8 : $HEAP))
OFFHEAP=`echo $AVAIL - $HEAP | bc`
echo "RAM: $MYRAM, considered: $AVAIL, heap: $HEAP, off-heap: $OFFHEAP" >> memory-breakup.txt
HEAPSTR="-heap-size=${HEAP}g"

if [[ $OFFHEAP -le 0 ]]; then
  OFFHEAPSTR=""
else
  OFFHEAPSTR="-memory-size=${OFFHEAP}g"
fi

# Configure snappydata cluster
printf "${PRIVATE_IP} -client-bind-address=${PRIVATE_IP} -hostname-for-clients=${PUBLIC_HOSTNAME} \n"  > ${SNAPPYDATA_DIR}/conf/locators
printf "${PRIVATE_IP} -locators=${PRIVATE_IP}:10334 -client-bind-address=${PRIVATE_IP} -hostname-for-clients=${PUBLIC_HOSTNAME} ${HEAPSTR} ${OFFHEAPSTR} \n" > ${SNAPPYDATA_DIR}/conf/servers
printf "${PRIVATE_IP} -locators=${PRIVATE_IP}:10334 -client-bind-address=${PRIVATE_IP} -hostname-for-clients=${PUBLIC_HOSTNAME} ${HEAPSTR} ${OFFHEAPSTR} \n" >> ${SNAPPYDATA_DIR}/conf/servers
printf "${PRIVATE_IP} -locators=${PRIVATE_IP}:10334 -zeppelin.interpreter.enable=true -classpath=${SNAPPY_INTERPRETER_DIR}/${INTERPRETER_JAR_NAME} ${HEAPSTR} ${OFFHEAPSTR} \n" > ${SNAPPYDATA_DIR}/conf/leads
printf "# `date` Configured SnappyData cluster $?\n" >> status.log

# Assumes that aws jars are available in snappydata jars/ directory in the AMI. Else download them.

# Download interpreter jar and copy the relevant jars where needed.
if [[ ! -e ${SNAPPY_INTERPRETER_DIR}/${INTERPRETER_JAR_NAME} ]]; then
  wget -q ${INTERPRETER_URL}
  printf "# `date` Downloaded Zeppelin Interpreter for SnappyData $?\n" >> status.log

  mkdir -p ${SNAPPY_INTERPRETER_DIR}
  printf "# `date` Created directory for Zeppelin SnappyData Interpreter $?\n" >> status.log

  ln -s ${SNAPPYDATA_DIR}/jars/* ${SNAPPY_INTERPRETER_DIR}/
  printf "# `date` Created symlinks to SnappyData jars in interpreter directory $?\n" >> status.log

  mv ${INTERPRETER_JAR_NAME} ${SNAPPY_INTERPRETER_DIR}/
  printf "# `date` Moved interpreter jar to its dir $?\n" >> status.log

  # ln -s ${SNAPPY_INTERPRETER_DIR}/${INTERPRETER_JAR_NAME} ${SNAPPYDATA_DIR}/jars/
  # printf "# `date` Created symlink for interpreter jar in SnappyData jars dir $?\n" >> status.log
fi

# Set SPARK_DNS_HOST to public hostname so that SnappyData Pulse UI links work fine.
echo "SPARK_PUBLIC_DNS=${PUBLIC_HOSTNAME}" >> ${SNAPPYDATA_DIR}/conf/spark-env.sh

# Start the single node snappydata cluster
bash ${SNAPPYDATA_DIR}/sbin/snappy-start-all.sh > cluster-status.log
RUNNING=`grep -ic running cluster-status.log`

printf "# `date` Started SnappyData cluster, running ${RUNNING}\n" >> status.log

if [[ ${RUNNING} -ne 4 ]]; then
  exit 1
fi

# Set default homescreen page in Apache Zeppelin
sed -i "/<name>zeppelin.notebook.homescreen<\/name>/{n;s/<value>/<value>${HOMESCREEN}/}" ${ZEPPELIN_DIR}/conf/zeppelin-site.xml

# Start Apache Zeppelin server
bash ${ZEPPELIN_DIR}/bin/zeppelin-daemon.sh start
CLUSTER_STARTED=`echo $?`

printf "# `date` Started Zeppelin server ${CLUSTER_STARTED}\n" >> status.log

exit ${CLUSTER_STARTED}

