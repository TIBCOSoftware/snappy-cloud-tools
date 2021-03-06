#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

pushd /home/ec2-user/snappydata > /dev/null

source ec2-variables.sh

if [[ ! -d ${SNAPPY_HOME_DIR} ]]; then
  echo "The SnappyData cluster may not have been started using the snappy-ec2 script."
  echo "Could not shutdown the cluster as its product directory not found."
  exit 2
else
  # Shutdown the SnappyData cluster
  sh "${SNAPPY_HOME_DIR}/sbin/snappy-stop-all.sh"
fi

popd > /dev/null

