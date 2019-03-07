#!/bin/bash
set -e

if grep isMaster /mnt/var/lib/info/instance.json | grep true; then
  IS_MASTER=true
  echo "Master node!"
fi

sudo yum update -y

if [ "$IS_MASTER" = true ]; then
	sudo yum install -y git  # In case git is not installed
	sudo yum install g++ cmake git -y
	sudo yum -y install gcc72-c++ # Fixes issue with c++14 incompatibility in Amazon Linux
	# Fixes issue of missing lz4
	sudo yum install -y lz4
	sudo yum install -y lz4-devel
fi

wget https://github.com/hms-dbmi/hail-on-AWS-spot-instances/blob/master/src/install_python36.sh
chmod +x install_python36.sh
sh install_python36.sh
rm install_python36.sh
