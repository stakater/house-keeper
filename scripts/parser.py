#!/usr/bin/env python3
import yaml,os,subprocess,shlex
class ScheduleBuilder(object):

    #----------------------------------------------------------------------
    def __init__(self):
        """Constructor"""
    #---------------------------------------------------------------------

    def buildSchedule(self,dictionary):
        if "name" in dictionary and "asg" in dictionary and "startTime" in dictionary and "stopTime" in dictionary:
            return dictionary

if __name__ == "__main__":
    #stop and delete old timers
    for file in os.listdir("/etc/systemd/system"):
        if "house-keeper-s" in file:
            if "timer" in file:
                command = "systemctl stop %s"%file
                print("executing %s"%command)
                subprocess.call(shlex.split(command))
            os.remove(os.path.join("/etc/systemd/system",file))
    f = open('/house-keeper/house-keeper-config/config.yml')
    #use safe_load instead load
    dataMap = yaml.safe_load(f)
    f.close()
    scheduleBuilder = ScheduleBuilder()
    scheduleCount=0
    for input_schedule in dataMap["housekeeper"]["nodes"]:
        schedule = scheduleBuilder.buildSchedule(input_schedule)
        if schedule:
            scheduleCount = scheduleCount+1
            instanceName=schedule["name"]
            asg=schedule["asg"]
            if "region" in schedule:
                region = schedule["region"]
                serviceName = instanceName + "-" + region + "-%d" %(scheduleCount) + ".service"
                timerName = instanceName + "-" + region + "-%d"%(scheduleCount) + ".timer"
            else:
                region = ""
                serviceName = instanceName + "-%d"%(scheduleCount) + ".service"
                timerName = instanceName + "-%d"%(scheduleCount) + ".timer"
            startTime = schedule["startTime"]
            startServiceFile = open("/etc/systemd/system/house-keeper-start-%s"%serviceName, 'w')
            startServiceFile.write("[Unit]\n"+
                                   "Description=Start %s on %s in %s\n\n" %(instanceName,startTime,region)+
                                   "[Service]\n"+
                                   "Type=oneshot\n"+
                                   "ExecStartPre=/usr/bin/docker run -d --name %n stakater/aws-cli\n"+
                                   "ExecStart=/usr/bin/sh -c '/house-keeper/house-keeper/scripts/start-instances.sh \"%s\" \"%%n\" \"%s\" \"%s\" >> /house-keeper/logs'\n" %(instanceName,region,asg)+
                                   "ExecStop=-/usr/bin/docker rm -vf %n")
            startServiceFile.close()
            startTimerFile = open("/etc/systemd/system/house-keeper-start-%s"%timerName, 'w')
            startTimerFile.write("[Unit]\n"+
                                 "Description=Run house-keeper-start-%s on %s\n\n" %(serviceName, startTime)+
                                 "[Timer]\n"+
                                 "OnCalendar=%s\n" %startTime)
            startTimerFile.close()

            command="sudo systemctl daemon-reload"
            command1="sudo systemctl start house-keeper-start-%s"%timerName
            print("executing %s ; %s"%(command,command1))
            subprocess.call(shlex.split(command))
            subprocess.call(shlex.split(command1))

            stopTime = schedule["stopTime"]
            stopServiceFile = open("/etc/systemd/system/house-keeper-stop-%s"%serviceName, 'w')
            stopServiceFile.write("[Unit]\n"+
                                  "Description=Stop %s on %s in %s\n\n" %(instanceName,stopTime,region)+
                                  "[Service]\n"+
                                  "Type=oneshot\n"+
                                  "ExecStartPre=/usr/bin/docker run -d --name %n stakater/aws-cli\n"+
                                  "ExecStart=/usr/bin/sh -c '/house-keeper/house-keeper/scripts/stop-instances.sh \"%s\" \"%%n\" \"%s\" \"%s\" >> /house-keeper/logs'\n" %(instanceName,region,asg)+
                                  "ExecStop=-/usr/bin/docker rm -vf %n")
            stopServiceFile.close()
            stopTimerFile = open("/etc/systemd/system/house-keeper-stop-%s"%timerName, 'w')
            stopTimerFile.write("[Unit]\n"+
                                "Description=Run house-keeper-stop-%s on %s\n\n" %(serviceName, stopTime)+
                                "[Timer]\n"+
                                "OnCalendar=%s\n" %stopTime)
            stopTimerFile.close()

            command="sudo systemctl daemon-reload"
            command1="sudo systemctl start house-keeper-stop-%s"%timerName
            print("executing %s ; %s"%(command,command1))
            subprocess.call(shlex.split(command))
            subprocess.call(shlex.split(command1))
        else:
            print("Invalid input schedule:\n%s"+input_schedule)