#!/bin/bash
set -e

export PATH=$PATH:/usr/local/bin

cd $HOME
mkdir -p $HOME/.ssh/id_rsa
sudo yum install python36 python36-devel python36-setuptools -y 
sudo easy_install pip
sudo python3 -m pip install --upgrade pip

if grep isMaster /mnt/var/lib/info/instance.json | grep true; then
    sudo yum install g++ cmake git -y
    sudo yum install gcc72-c++ -y # Fixes issue with c++14 incompatibility in Amazon Linux
    sudo yum install lz4 lz4-devel -y # Fixes issue of missing lz4
	# Master node: Install all
	WHEELS="pyserial
	oauth
	argparse
	parsimonious
	wheel
	pandas
	utils
	ipywidgets
	numpy
	scipy
	bokeh
	requests
	boto3
	jupyterlab"
else 
	# Worker node: Install all but jupyter lab
	WHEELS="pyserial
	oauth
	argparse
	parsimonious
	wheel
	pandas
	utils
	ipywidgets
	numpy
	scipy
	bokeh
	requests
	boto3"
fi

for WHEEL_NAME in $WHEELS
do
	sudo python3 -m pip install $WHEEL_NAME
done

sudo yum update -y
