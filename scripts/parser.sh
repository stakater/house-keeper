#!/bin/bash

readarray commands < /house-keeper/house-keeper-config/config
counter=0

#remove old timers
shopt -s lastpipe
sudo systemctl list-timers --all | grep "house-keeper.*timer" -o | readarray -t timers
for t in ${timers[@]}; do
	echo "stoping timer $t"
	sudo systemctl stop $t
	sudo rm house-keeper-s*
done

#add new timers
for command in "${commands[@]}"; do
	((counter++))
	echo "command is $command"
	IFS=';' read -ra data <<< "$command"
	sudo sh -c "{
		echo '[Unit]'
                echo \"Description=${data[0]} ${data[1]} on ${data[2]}\"
		echo ''
		echo '[Service]'
                echo 'Type=oneshot'
                echo \"ExecStartPre=/usr/bin/docker run -d --name %n stakater/aws-cli\"
                echo \"ExecStart=/usr/bin/sh -c '/house-keeper/house-keeper/scripts/${data[0]}-instances.sh ${data[1]} %n >> /house-keeper/logs'\"
       	        echo \"ExecStop=-/usr/bin/docker rm -vf %n\"
        } > /etc/systemd/system/house-keeper-${data[0]}-${data[1]}-$counter.service"
	sudo sh -c "{
		echo '[Unit]'
		echo \"Description=Run test-${data[0]}-${data[1]}-$counter.service on ${data[2]}\"
		echo ''
		echo '[Timer]'
		echo \"OnCalendar=${data[2]}\"
	} > /etc/systemd/system/house-keeper-${data[0]}-${data[1]}-$counter.timer"
	sudo systemctl daemon-reload
	sudo systemctl start house-keeper-${data[0]}-${data[1]}-$counter.timer
done
