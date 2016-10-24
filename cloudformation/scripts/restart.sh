#!/bin/bash -x

cd /snappydata/downloads

printf "\n# `date` RESTART -------------------------------------------------- #\n" >> status.log

ZEPPELIN_DIR=zeppelin-0.6.1-bin-netinst

SNAPPYDATA_URL=`cat snappydata-url.txt`
SNAPPYDATA_TAR_NAME=`echo ${SNAPPYDATA_URL} | cut -d'/' -f 9`
SNAPPYDATA_DIR=`echo ${SNAPPYDATA_TAR_NAME%.tar.gz}`

NOTEBOOK_URL=`cat notebook-url.txt`
PUBLIC_HOSTNAME=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname`

# Download and extract the notebook
rm -rf notebook.tar.gz notebook/
wget ${NOTEBOOK_URL}
tar -xf notebook.tar.gz
printf "# `date` Extracted notebook $?\n" >> status.log

# Copy the notebook to Zeppelin and update the local hostname.
cp -R notebook/* ${ZEPPELIN_DIR}/notebook/
find ${ZEPPELIN_DIR}/notebook -type f -print0 | xargs -0 sed -i "s/localhost/${PUBLIC_HOSTNAME}/g"

# Start the SnappyData cluster
bash ${SNAPPYDATA_DIR}/sbin/snappy-start-all.sh > cluster-status.log
RUNNING=`grep -ic running cluster-status.log`

printf "# `date` Started SnappyData cluster, running ${RUNNING}\n" >> status.log

if [[ ${RUNNING} -ne 3 ]]; then
  printf "\n# `date` FAILED -------------------------------------------------- #\n" >> status.log
  exit 1
fi

# Start Apache Zeppelin server
bash ${ZEPPELIN_DIR}/bin/zeppelin-daemon.sh start
CLUSTER_STARTED=`echo $?`

printf "# `date` Started Zeppelin server ${CLUSTER_STARTED}\n" >> status.log

printf "\n# `date` END -------------------------------------------------- #\n" >> status.log


