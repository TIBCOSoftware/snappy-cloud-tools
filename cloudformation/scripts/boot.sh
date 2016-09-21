#!/bin/bash -x

mkdir -p /snappydata/downloads
cd /snappydata/downloads

rm setup.sh

CLOUDFORMATION_URL=`cat cf-script-url.txt`

# wget https://github.com/SnappyDataInc/aws-cloud/raw/master/cloudformation/scripts/cloudformation-setup.sh
wget ${CLOUDFORMATION_URL}
printf "Downloaded cd script $?\n" >> status.log

bash setup.sh
