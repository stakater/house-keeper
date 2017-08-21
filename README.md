# house-keeper
A server that manages house keeping tasks like scheduling start and stop action for servers

For this first of all you need to create a repo where you will keep your schedule. A sample schedule file looks like this:
Note there are 4 parts of each line separated by ';'. 
<ul>
<li>The first part can have either start or stop.</li>
<li>The second part is the instance name on which action is performed. We assume that the ASG uses the same name.</li>
<li>The third part specifies the calendar event when this action is to be performed.</li>
<li>The fourth part is the aws region in which instance is running on. It is optional and should be specified if the specified resource is in a different region than the one house-keeper is running on</li>
</ul>

```
stop;my-stack-dev-worker;*-*-* 19:30:00 UTC;us-west-2
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
start;my-stack-dev-worker;*-*-* 3:55:00 UTC;us-west-2
```

You can learn about calendar events used in this file at https://www.freedesktop.org/software/systemd/man/systemd.time.html#

note that you yourself have to take care of dependencies when starting or stopping a server.
e.g etcd must stop after and start before gocd so we provide the scheduled times accordingly

Apart from this you need to provide your house keeper config repo link in your infrastructure reference repo.
You need to add your house keeper config repository link in house-keeper-user-data.yaml file
