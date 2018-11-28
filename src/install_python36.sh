#!/bin/bash

export PATH=$PATH:/usr/local/bin

sudo yum update -y
sudo yum install -y python36
sudo yum install -y python36-devel
sudo yum install -y python36-setuptools
sudo easy_install pip

sudo python -m pip install --upgrade pip
wget https://bootstrap.pypa.io/get-pip.py
# Install latest pip
sudo python3 get-pip.py
sudo python get-pip.py
# Upgrade latest latest pip
sudo python -m pip install --upgrade pip
sudo python3 -m pip install --upgrade pip
rm -f get-pip.py

WHEELS="pyserial
oauth
argparse
wheel
pandas
jupyter
numpy
bokeh"

for WHEEL_NAME in $WHEELS
do
	#sudo python -m pip install $WHEEL_NAME
	sudo python3 -m pip install $WHEEL_NAME
done
