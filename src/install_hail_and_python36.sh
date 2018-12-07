#!/bin/bash
# Dependencies: install_python36.sh, setup.sh, jupyter_build.sh, jupyter_run.sh
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/cloudcreation_log.out 2>&1

export HAIL_HOME="/opt/hail-on-AWS-spot-instances"
# Download Hail builds to use a specific relase
# curl --output hail-all-spark.jar https://s3.amazonaws.com/avl-hail-73/hail_0.2_emr_5.10_spark_2.2.0/hail-all-spark.jar
# curl --output hail-python.zip https://s3.amazonaws.com/avl-hail-73/hail_0.2_emr_5.10_spark_2.2.0/hail-python.zip
for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
do
   # Distribute keys to slaves for hadoop account
   scp -o "StrictHostKeyChecking no" ~/.ssh/id_rsa ${WORKERIP}:/home/hadoop/.ssh/id_rsa
   scp ~/.ssh/authorized_keys ${WORKERIP}:/home/hadoop/.ssh/authorized_keys
   # Distribute the freshly built Hail files
done

echo 'Keys successfully copied to NODES'

# Add hail to the master node
sudo mkdir -p /opt
sudo chmod 777 /opt/
sudo chown hadoop:hadoop /opt
cd /opt
sudo yum install -y git  # In case git is not installed
git clone https://github.com/hms-dbmi/hail-on-AWS-spot-instances.git


# Update Python 3.6 in all the nodes in the cluster
# First for the master node
cd $HAIL_HOME/src

./update_hail.sh
./install_python36.sh

# cd $HOME
# wget -O hail-all-spark.jar https://storage.googleapis.com/hail-common/builds/devel/jars/hail-devel-ae9e34fb3cbf-Spark-2.2.0.jar
# wget -O hail-python.zip https://storage.googleapis.com/hail-common/builds/devel/python/hail-devel-ae9e34fb3cbf.zip
# cd $HAIL_HOME/src
# Then for the worker nodes
for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
do
   scp /home/hadoop/hail-* $WORKERIP:/home/hadoop/
   scp install_python36.sh hadoop@${WORKERIP}:/tmp/install_python36.sh
   ssh hadoop@${WORKERIP} "sudo ls -al /tmp/install_python36.sh"
   ssh hadoop@${WORKERIP} "sudo /tmp/install_python36.sh"
   ssh hadoop@${WORKERIP} "python3 --version"
done

# Set the time zone for cronupdates
sudo cp /usr/share/zoneinfo/America/New_York /etc/localtime

sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2 > /tmp/t1.txt
aws emr list-instances --cluster-id ${CLUSTERID} | jq -r .Instances[].Ec2InstanceId > /tmp/ec2list1.txt

# setup crontab to check dropped instances every minute
sudo echo "* * * * * /opt/hail-on-AWS-spot-instances/src/run_when_new_instance_added.sh >> /tmp/cloudcreation_log.out 2>&1 # min hr dom month dow" | crontab -

./jupyter_build.sh
./jupyter_run.sh
