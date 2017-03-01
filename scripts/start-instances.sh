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

# This script starts Instances based on name provided and resumes auto scaling processes for those instances
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
echo "Starting $INSTANCE_NAME on `date`"

shopt -s lastpipe
docker exec $CONTAINER_NAME aws ec2 describe-instances --region $region --query "Reservations[].Instances[?Tags[?Key=='Name'&&Value=='$INSTANCE_NAME']].{id:InstanceId,asgName:Tags[?Key=='aws:autoscaling:groupName'].Value|[0]}" --output text | readarray -t instances
echo "${instances[@]}"
asg_name="";
instanceIds="";
#start instances
for instance in "${instances[@]}"; do
  data=($instance)
  asg_name=${data[0]}
  instanceIds="$instanceIds ${data[1]}"
  echo "starting instance ${data[1]} in region $region"
  docker exec $CONTAINER_NAME aws ec2 start-instances --instance-ids ${data[1]} --region $region
done

#wait for instances to start before resuming processes
instances=($instanceIds)
count=1
while [[ $count -lt 120 && ${#instances[@]} != 0 ]]
do
  echo "Waiting for ${instances[@]} to start"
  sleep 5
  for instance in "${instances[@]}"; do
    state=`docker exec $CONTAINER_NAME aws ec2 describe-instances --region $region --query "Reservations[].Instances[?InstanceId=='$instance'].State.Name" --output text`
    echo "$instance is $state"
    if [ "$state" == "running" ]
    then
      instances=(`echo "${instances[@]/$instance}"`)
    fi
  done
  ((count=count+1))
done

#Resuming Processses
echo "resuming processes for $asg_name  in region $region"
docker exec $CONTAINER_NAME aws autoscaling resume-processes --region $region --auto-scaling-group-name $asg_name --scaling-processes Launch HealthCheck
