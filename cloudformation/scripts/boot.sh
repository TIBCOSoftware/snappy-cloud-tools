#!/bin/bash -x
# Run as root

printf "\n# `date` START -------------------------------------------------- #\n" >> status.log

mkdir -p /snappydata/downloads
cd /snappydata/downloads

# Install CloudFormation helper scripts
apt-get update
apt-get -y upgrade
apt-get -y install python-setuptools  
easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz

# Update the urls for various artifacts and scripts.
printf "https://github.com/SnappyDataInc/snappydata/releases/download/v0.6/snappydata-0.6-bin.tar.gz" > snappydata-url.txt
printf "https://github.com/SnappyDataInc/zeppelin-interpreter/releases/download/v0.6/snappydata-zeppelin-0.6.jar" > interpreter-url.txt
printf "https://github.com/SnappyDataInc/zeppelin-interpreter/raw/notes/examples/notebook/notebook.tar.gz" > notebook-url.txt
printf "https://github.com/SnappyDataInc/aws-cloud/raw/master/cloudformation/scripts/setup.sh" > cf-script-url.txt
printf "Updated urls $?\n" >> status.log

rm setup.sh
CF_SCRIPT_URL=`cat cf-script-url.txt`
wget ${CF_SCRIPT_URL}
printf "Downloaded cloudformation script $?\n" >> status.log

bash setup.sh
SETUP_DONE=`echo $?`

printf "\n# `date` END -------------------------------------------------- #\n" >> status.log

exit ${SETUP_DONE}
