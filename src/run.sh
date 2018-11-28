#!/bin/bash -x -e

echo "Generating the EMR cluster. See log details at /tmp/cloudcreation_log.out"

# Save the AWS Keys to the default folder
CREDENTIALS=$(ls  ~/.aws)
if [ -z "$CREDENTIALS" ]; then
	echo "Your AWS configuration file is required!"
	echo "For help visit:"
	echo "https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html"
	echo "See your accessKeys.csv file to find the Access Keys"
	echo "\n\n Your inputs should look like this:\n\n"
	echo "AWS Access Key ID [None]: ANEXAMPLEKEYID"
	echo "AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
	echo "Default region name [None]: us-east-1"
	echo "Default output format [None]: json"
	echo "\n\n"
	aws configure
else
	echo "Using existing AWS credentials..."
	echo "To reconfigure run: aws configure"
	echo "For help visit: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html"
	echo "\n\n"
fi


echo "Starting EMR cluster. This operation takes 5-7 minutes..."
python3 EMR_deploy_and_install_spot.py
