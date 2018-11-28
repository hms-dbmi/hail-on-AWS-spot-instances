#!/bin/bash

# export HAIL_HOME=/opt/hail-on-AWS-spot-instances
cd $HAIL_HOME/src

sudo rm -r hail
sudo rm /etc/alternatives/jre/include/include
./hail_build.sh

for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
do
	scp /home/hadoop/hail-* $WORKERIP:/home/hadoop/
done

sudo stop hadoop-yarn-resourcemanager; sleep 3; sudo start hadoop-yarn-resourcemanager
