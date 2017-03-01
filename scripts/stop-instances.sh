#!/bin/bash

###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

# This script stops Instances based on name provided and suspends auto scaling processes for those instances
#----------------------------------------------
# Argument1: INSTANCE_NAME
# Argument2: CONTAINER_NAME
# Argument3: REGION
#----------------------------------------------

#Input Parameters
INSTANCE_NAME=$1
CONTAINER_NAME=$2
REGION=$3

# Check number of parameters equals 2 OR 3
if [[ "$#" -ne 2 && "$#" -ne 3 ]]; then
    echo "ERROR: Illegal number of parameters"
    exit 1
fi

if [ "$REGION" != "" ]
then
    #use provided region
    region=$REGION
else
    #find region
    region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    region=${region::-1}
fi

#log running
echo "Stopping $INSTANCE_NAME on `date`"

shopt -s lastpipe
docker exec $CONTAINER_NAME aws ec2 describe-instances --region $region --query "Reservations[].Instances[?Tags[?Key=='Name'&&Value=='$INSTANCE_NAME']].{id:InstanceId,asgName:Tags[?Key=='aws:autoscaling:groupName'].Value|[0]}" --output text | readarray -t instances
echo "${instances[@]}"
for k in "${instances[@]}"; do
  data=($k)

  echo "suspending processes for ${data[0]} in region $region"
  docker exec $CONTAINER_NAME aws autoscaling suspend-processes --region $region --auto-scaling-group-name ${data[0]} --scaling-processes Launch HealthCheck

  suspended_processes=""
  while [[ $count -lt 6 && $suspended_processes == *"Launch"* && $suspended_processes == *"HealthCheck"* ]]
  do
    suspended_processes=`docker exec $CONTAINER_NAME aws autoscaling describe-auto-scaling-groups --region $region --auto-scaling-group-name ${data[0]} --query "AutoScalingGroups[0].SuspendedProcesses[].ProcessName" --output text`
    ((count=count+1))
  done

  echo "stopping instance ${data[1]} in region $region"
  docker exec $CONTAINER_NAME aws ec2 stop-instances --instance-ids ${data[1]} --region $region
done
