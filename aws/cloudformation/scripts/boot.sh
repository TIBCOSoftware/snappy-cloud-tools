#!/bin/bash -x
# Run as root

export HOMESCREEN=$1
export DOWNLOADS_DIR=/snappydata
export SNAPPYDATA_DIR=/opt/snappydata
export ZEPPELIN_DIR=/opt/zeppelin

mkdir -p ${DOWNLOADS_DIR}
cd ${DOWNLOADS_DIR}

printf "\n# `date` START -------------------------------------------------- #\n" >> status.log

# Install CloudFormation helper scripts
which cfn-signal
if [[ $? -ne 0 ]]; then
  apt-get update
  apt-get -y upgrade
  apt-get -y install python-setuptools
  easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
  printf "# `date` Installed cloudformation helper scripts $?\n" >> status.log
fi

# Update the urls for various artifacts and scripts.
export SNAPPYDATA_URL="https://github.com/SnappyDataInc/snappydata/releases/download/v0.9/snappydata-0.9-bin.tar.gz"
export INTERPRETER_URL="https://github.com/SnappyDataInc/zeppelin-interpreter/releases/download/v0.7.0/snappydata-zeppelin-0.7.0.jar"
export NOTEBOOK_URL="https://github.com/SnappyDataInc/zeppelin-interpreter/raw/notes/examples/notebook/notebook.tar.gz"
export CF_SCRIPT_URL="https://github.com/SnappyDataInc/snappy-cloud-tools/raw/master/aws/cloudformation/scripts/setup.sh"
printf "# `date` Updated urls $?\n" >> status.log

rm setup.sh
wget ${CF_SCRIPT_URL}
printf "# `date` Downloaded cloudformation setup script $?\n" >> status.log

bash setup.sh
SETUP_DONE=`echo $?`

printf "\n# `date` END -------------------------------------------------- #\n" >> status.log

exit ${SETUP_DONE}
