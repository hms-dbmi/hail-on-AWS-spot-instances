#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/cloudcreation_log.out 2>&1

export HAIL_HOME="/opt/hail-on-AWS-spot-instances"
export HASH="current"

# Error message
error_msg ()
{
  echo 1>&2 "Error: $1"
  exit 1
}

# Usage
usage()
{
echo "Usage: cloudformation.sh [-v | --version <git hash>] [-h | --help]

Options:
-v | --version <git hash>
    This option takes either the abbreviated (8-12 characters) or the full size hash (40 characters).
    When provided, the command uses a pre-compiled Hail version for the EMR cluster. If the hash (sha1)
    version exists in the pre-compiled list, that specific hash will be used.
    If no version is given or if the hash was not found, Hail will be compiled from scratch using the most
    up to date version available in the repository (https://github.com/hail-is/hail)

-h | --help
	Displays this menu"
    exit 1
}

# Read input parameters
while [ "$1" != "" ]; do
    case $1 in
        -v|--version)	shift
                        HASH="$1"
                        ;;
        -h|--help)      usage
                        ;;
        -*)
      					error_msg "unrecognized option: $1"
      					;;
        *)              usage
    esac
    shift
done

for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
do
   # Distribute keys to slaves for hadoop account
   scp -o "StrictHostKeyChecking no" ~/.ssh/id_rsa ${WORKERIP}:/home/hadoop/.ssh/id_rsa
   scp ~/.ssh/authorized_keys ${WORKERIP}:/home/hadoop/.ssh/authorized_keys
   # Distribute the freshly built Hail files
done

echo 'Keys successfully copied to the worker nodes'

# Add hail to the master node
sudo mkdir -p /opt
sudo chmod 777 /opt/
sudo chown hadoop:hadoop /opt
cd /opt
# sudo yum install -y git  # In case git is not installed
git clone https://github.com/hms-dbmi/hail-on-AWS-spot-instances.git

# Update Python 3.6 in all the nodes in the cluster
# First for the master node
cd $HAIL_HOME/src

./update_hail.sh -v $HASH
# ./install_python36.sh

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
