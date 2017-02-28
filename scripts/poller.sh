#!/bin/bash

#pull repo
cd /house-keeper/house-keeper-config
git fetch
local=$(git rev-parse HEAD)
remote=$(git rev-parse @{u})
if [ "$local" == "$remote" ] ; then
   echo "polled at `date`
  no changes" >> /house-keeper/logs
else
   output=`git pull`
   echo "polled at `date`
  $output" >> /house-keeper/logs
  python /house-keeper/house-keeper/scripts/parser.py
fi
