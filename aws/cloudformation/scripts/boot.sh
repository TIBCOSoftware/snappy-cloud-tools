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
# Commit SHA eeaf8df94a4056a1037ba693e30d52ad997035e5
printf "https://github.com/SnappyDataInc/snappy-poc/releases/download/0.6-cf/snappydata-0.6.1-SNAPSHOT-bin.tar.gz" > snappydata-url.txt
# Commit SHA ab1d1365e7920267a4957e8c8b6f7084bee71b98
printf "https://github.com/SnappyDataInc/snappy-poc/releases/download/0.6-cf/snappydata-zeppelin-0.6.1-SNAPSHOT.jar" > interpreter-url.txt
printf "https://github.com/SnappyDataInc/zeppelin-interpreter/raw/notes/examples/notebook/notebook.tar.gz" > notebook-url.txt
printf "https://github.com/SnappyDataInc/aws-cloud/raw/master/cloudformation/scripts/setup.sh" > cf-script-url.txt
printf "# `date` Updated urls $?\n" >> status.log

rm setup.sh
CF_SCRIPT_URL=`cat cf-script-url.txt`
wget ${CF_SCRIPT_URL}
printf "# `date` Downloaded cloudformation setup script $?\n" >> status.log

bash setup.sh
SETUP_DONE=`echo $?`

printf "\n# `date` END -------------------------------------------------- #\n" >> status.log

exit ${SETUP_DONE}
