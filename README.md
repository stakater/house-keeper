# house-keeper
A server that manages house keeping tasks like scheduling start and stop action for servers

For this first of all you need to create a repo where you will keep your schedule. A sample schedule file looks like this:
```
stop;my-stack-dev-worker;*-*-* 19:30:00 UTC
stop;my-stack-dev-admiral;*-*-* 19:33:00 UTC
stop;my-stack-dev-mysql;*-*-* 19:33:00 UTC
stop;my-stack-dev-bastion-host;*-*-* 19:33:00 UTC
stop;my-stack-ga-gocd;*-*-* 19:33:00 UTC
stop;my-stack-dev-consul;*-*-* 19:33:00 UTC
stop;my-stack-ga-etcd;*-*-* 19:35:00 UTC
start;my-stack-ga-etcd;*-*-* 3:47:00 UTC
start;my-stack-dev-consul;*-*-* 3:50:00 UTC
start;my-stack-ga-gocd;*-*-* 3:52:00 UTC
start;my-stack-dev-bastion-host;*-*-* 3:52:00 UTC
start;my-stack-dev-mysql;*-*-* 3:52:00 UTC
start;my-stack-dev-admiral;*-*-* 3:52:00 UTC
start;my-stack-dev-worker;*-*-* 3:55:00 UTC
```
note that you yourself have to take care of dependencies when starting or stopping a server.
e.g etcd must stop after and start before gocd so we provide the scheduled times accordingly

Apart from this you need to provide your house keeper config repo link in your infrastructure reference repo.
You need to add your house keeper config repository link in house-keeper-user-data.yaml file

