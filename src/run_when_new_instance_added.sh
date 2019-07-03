#!/bin/bash

# Grabs the list of EC2s
sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2 > /tmp/t2.txt
# Queries for the EC2 IDs
CLUSTERID="$(jq -r .jobFlowId /mnt/var/lib/info/job-flow.json)"
REGION="$(jq -r .region /mnt/var/lib/info/extraInstanceData.json)"
aws emr list-instances --cluster-id ${CLUSTERID} --region ${REGION} | jq -r .Instances[].Ec2InstanceId > /tmp/ec2list2.txt
KEY=$(ls ~/.ssh/id_rsa/)
# Check if there was an EC2 addition
if [ -z "`diff /tmp/ec2list2.txt /tmp/ec2list1.txt`" ]; then
  echo "No new instances detected/added"
else
  for WORKERIP in `diff /tmp/t1.txt /tmp/t2.txt | grep "> " | sed 's/> //'`
  do
     # Distribute keys to workers for account hadoop
     echo "Updating cluster"
     # scp -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa/${KEY} ~/.ssh/id_rsa/${KEY} ${WORKERIP}:/home/hadoop/.ssh/id_rsa
     scp -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa/${KEY} ~/.ssh/authorized_keys ${WORKERIP}:/home/hadoop/.ssh/authorized_keys
     # Install Python 3 - Bootstrap takes care of Python 3 install
     # scp /opt/hail-on-AWS-spot-instances/src/install_python36.sh hadoop@${WORKERIP}:/tmp/install_python36.sh
     # ssh hadoop@${WORKERIP} "sudo ls -al /tmp/install_python36.sh"
     # ssh hadoop@${WORKERIP} "sudo /tmp/install_python36.sh &" 
     # ssh hadoop@${WORKERIP} "python3 --version"
     # Distribute Hail files
     scp -i $HOME/.ssh/id_rsa/${KEY} $HOME/hail-* $WORKERIP:/home/hadoop/
     sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2 > /tmp/t1.txt
     aws emr list-instances --cluster-id ${CLUSTERID} --region ${REGION} | jq -r .Instances[].Ec2InstanceId > /tmp/ec2list1.txt
     sudo stop hadoop-yarn-resourcemanager; sleep 1; sudo start hadoop-yarn-resourcemanager
  done
fi
