#!/bin/bash -x

mkdir -p /snappydata/downloads
cd /snappydata/downloads


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
