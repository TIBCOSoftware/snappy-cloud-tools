#!/bin/bash -x
# Run as root

printf "\n# `date` START -------------------------------------------------- #\n" >> status.log

mkdir -p /snappydata/downloads
cd /snappydata/downloads

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
printf "https://github.com/SnappyDataInc/snappydata/releases/download/v0.7/snappydata-0.7-bin.tar.gz" > snappydata-url.txt
printf "https://github.com/SnappyDataInc/zeppelin-interpreter/releases/download/v0.6.1/snappydata-zeppelin-0.6.1.jar" > interpreter-url.txt
printf "https://s3-us-west-2.amazonaws.com/zeppelindemo/quickstart/notebook.tar.gz" > notebook-url.txt
printf "https://github.com/SnappyDataInc/snappy-cloud-tools/raw/master/aws/cloudformation/scripts/quickstart/setup.sh" > cf-script-url.txt
printf "# `date` Updated urls $?\n" >> status.log

rm setup.sh
CF_SCRIPT_URL=`cat cf-script-url.txt`
wget ${CF_SCRIPT_URL}
printf "# `date` Downloaded cloudformation setup script $?\n" >> status.log

bash setup.sh
SETUP_DONE=`echo $?`

printf "\n# `date` END -------------------------------------------------- #\n" >> status.log

exit ${SETUP_DONE}
