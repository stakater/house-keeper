#!/bin/bash

readarray commands < /house-keeper/house-keeper-config/config
counter=0
for command in "${commands[@]}"; do
	((counter++))
	echo "command is $command"
	IFS=';' read -ra data <<< "$command"
	echo "data is $data and first index is ${data[0]}"
	sudo sh -c "{
		echo '[Unit]'
                echo \"Description=${data[0]} ${data[1]} on ${data[2]}\"
		echo ''
		echo '[Service]'
                echo 'Type=oneshot'
                echo \"ExecStart=/usr/bin/sh -c '/usr/bin/date >> /tmp/date'\"
       	} > /etc/systemd/system/house-keeper-${data[0]}-${data[1]}-$counter.service"
	sudo sh -c "{
		echo '[Unit]'
		echo \"Description=Run test-${data[0]}-${data[1]}-$counter.service on ${data[2]}\"
		echo ''
		echo '[Timer]'
		echo \"OnCalendar=${data[2]}\"
	} > /etc/systemd/system/house-keeper-${data[0]}-${data[1]}-$counter.timer"
	sudo systemctl start house-keeper-${data[0]}-${data[1]}-$counter.timer
done
