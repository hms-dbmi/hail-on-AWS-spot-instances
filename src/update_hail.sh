#!/bin/bash

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

echo "Running Hail installation with option: $HASH"
sudo rm -r hail
sudo rm /etc/alternatives/jre/include/include
# Build Hail
./hail_build.sh -v $HASH

# KEY=$(ls ~/.ssh/id_rsa/)
# for WORKERIP in `sudo grep -i privateip /mnt/var/lib/info/*.txt | sort -u | cut -d "\"" -f 2`
# do
# 	scp -i $HOME/.ssh/id_rsa/$KEY $HOME/hail-* $WORKERIP:/home/hadoop/
# done

sudo stop hadoop-yarn-resourcemanager; sleep 1; sudo start hadoop-yarn-resourcemanager
