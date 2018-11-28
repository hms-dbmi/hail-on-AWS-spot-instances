#!/bin/bash -x -e

# Install brew
OS=$(uname)
if [ "$OS" == "Darwin" ]; then
	echo "Installing brew for Mac"
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
elif [ "$OS" == "Linux" ]; then
	echo "Installing brew for Linux"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
		if [ ! -f ~/.bashrc ]; then # Fedora, Red Hat, CentOS, etc.
			sudo yum -y groupinstall 'Development Tools'
		elif [ ! -f ~/.bashrc ]; then # Debian, Ubuntu, etc.
			sudo apt-get -y install build-essential curl file git
		fi
	echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc
	source ~/.bashrc
fi

# Check if python3 is installed
PYTH=$(which python3)
if [ -z "$PYTH" ]; then
	echo "\n\nInstalling Python3..."
	brew install python3
fi

echo "\n\nInstalling pip"
pip install --upgrade pip

# Install the AWS command tool
echo "\n\nInstalling aws CLI tool"
brew install awscli

echo "\n\nInstalling additional python libraries"
pip3 install boto3 pandas botocore paramiko pyyaml -q #parallel-ssh
