#!/bin/bash

#pull repo
cd /house-keeper/house-keeper-config
git fetch
if $(git rev-parse HEAD) == $(git rev-parse @{u}) ; then
   echo "polled at `date`
  no changes" >> logs
else
   output=`cd dummy-repo;git pull`
   echo "polled at `date`
  $output" >> logs
  sudo ./house-keeper/house-keeper/scripts/parser.sh
fi
