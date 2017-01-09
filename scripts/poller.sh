#!/bin/bash

#pull repo
cd /house-keeper/house-keeper-config
sudo git fetch
local=$(sudo git rev-parse HEAD)
remote=$(sudo git rev-parse @{u})
if [ "$local" == "$remote" ] ; then
   echo "polled at `date`
  no changes" >> /house-keeper/logs
else
   output=`git pull`
   echo "polled at `date`
  $output" >> /house-keeper/logs
  sudo /house-keeper/house-keeper/scripts/parser.sh
fi
