#!/usr/bin/env python3

import boto3 #sudo python3 -m pip install boto3
import pandas as pd
import time
import sys
import botocore
import paramiko
import re
import os
import yaml

PATH=os.path.dirname(os.path.abspath(__file__))

c=yaml.load(open(PATH+"/config_EMR_spot.yaml"))

# Spot instances and different CORE/MASTER instances
command='aws emr create-cluster --applications Name=Hadoop Name=Spark --tags \'project='+c['config']['PROJECT_TAG']+'\' \'Owner='+c['config']['OWNER_TAG']+'\' \'Name='+c['config']['EC2_NAME_TAG']+'\' --ec2-attributes \'{"KeyName":"'+c['config']['KEY_NAME']+'","InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"'+c['config']['SUBNET_ID']+'","EmrManagedSlaveSecurityGroup":"'+c['config']['WORKER_SECURITY_GROUP']+'","EmrManagedMasterSecurityGroup":"'+c['config']['MASTER_SECURITY_GROUP']+'"}\' --service-role EMR_DefaultRole --release-label emr-5.13.0 --log-uri \''+c['config']['S3_BUCKET']+'\' --name \''+c['config']['EMR_CLUSTER_NAME']+'\' --instance-groups \'[{"InstanceCount":1,"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":1}]},"InstanceGroupType":"MASTER","InstanceType":"'+c['config']['MASTER_INSTANCE_TYPE']+'","Name":"Master-Instance"},{"InstanceCount":'+c['config']['CORE_COUNT']+',"BidPrice":"'+c['config']['CORE_BID_PRICE']+'","EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":1}]},"InstanceGroupType":"CORE","InstanceType":"'+c['config']['CORE_INSTANCE_TYPE']+'","Name":"Core-Group"}]\' --configurations \'[{"Classification":"spark","Properties":{"maximizeResourceAllocation":"true"},"Configurations":[]}]\' --auto-scaling-role EMR_AutoScaling_DefaultRole --ebs-root-volume-size 10 --scale-down-behavior TERMINATE_AT_TASK_COMPLETION --region '+c['config']['REGION']


print("\n\nYour AWS CLI export command:\n")
print(command)

cluster_id_json=os.popen(command).read()
cluster_id=cluster_id_json.split(": \"",1)[1].split("\"\n")[0]
print('\nClusterId: '+cluster_id+'\n')

# Gives EMR cluster information
client_EMR = boto3.client('emr')

# Cluster state update
status_EMR='STARTING'
time.sleep(3)
# Wait until the cluster is created
while (status_EMR!='EMPTY'):
	print('Creating EMR...')
	details_EMR=client_EMR.describe_cluster(ClusterId=cluster_id)
	status_EMR=details_EMR.get('Cluster').get('Status').get('State')
	print('Cluster status: '+status_EMR)
	time.sleep(5)
	if (status_EMR=='WAITING'):
		print('Cluster successfully created! Starting HAIL installation...')
		break
	if (status_EMR=='TERMINATED_WITH_ERRORS'):
		sys.exit("Cluster un-successfully created. Ending installation...")


# Get public DNS from master node
master_dns=details_EMR.get('Cluster').get('MasterPublicDnsName')
master_IP=re.sub("-",".",master_dns.split(".compute")[0].split("ec2-")[1])

print('\nMaster DNS: '+ master_dns)
# print('Master IP: '+ master_IP+'\n')


# Copy the key into the master
command='scp -o \'StrictHostKeyChecking no\' -i '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem hadoop@'+master_dns+':/home/hadoop/.ssh/id_rsa'
os.system(command)
print('Copying keys...')
# Copy the installation script into the master
command='scp -o \'StrictHostKeyChecking no\' -i '+c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem '+PATH+'/install_hail_python36.sh hadoop@'+master_dns+':/home/hadoop'
os.system(command)

print('Installing software...')
print('Allow 20-25 minutes for full installation')
print('\n This is your JupyterNotebook link: '+ master_IP+':8192\n')
key = paramiko.RSAKey.from_private_key_file(c['config']['PATH_TO_KEY']+c['config']['KEY_NAME']+'.pem')
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(hostname=master_IP, username="hadoop", pkey=key)
# Execute a command(cmd) after connecting/ssh to an instance
stdin, stdout, stderr = client.exec_command('cd /home/hadoop/')
stdin, stdout, stderr = client.exec_command('./install_hail_and_python36.sh')
# close the client connection
client.close()
