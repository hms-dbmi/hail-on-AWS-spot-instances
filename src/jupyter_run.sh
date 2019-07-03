#!/bin/bash

export SPARK_HOME=/usr/lib/spark
export PYSPARK_PYTHON=python3
export HAIL_HOME=/opt/hail-on-AWS-spot-instances

export PYTHONPATH="/home/hadoop/hail-python.zip:$SPARK_HOME/python:${SPARK_HOME}/python/lib/py4j-src.zip"
echo "PYTHONPATH: ${PYTHONPATH}"

export PYSPARK_PYTHON=python3
echo "PYSPARK_PYTHON: ${PYSPARK_PYTHON}"

# Needed for HDFS
JAR_PATH="/home/hadoop/hail-all-spark.jar:/usr/share/aws/emr/emrfs/lib/emrfs-hadoop-assembly-2.32.0.jar"
export PYSPARK_SUBMIT_ARGS="--conf spark.driver.extraClassPath='$JAR_PATH' --conf spark.executor.extraClassPath='$JAR_PATH' pyspark-shell"
echo "PYSPARK_SUBMIT_ARGS: ${PYSPARK_SUBMIT_ARGS}"

# Configure Jupyter Lab
mkdir -p $HOME/.jupyter
cp /opt/hail-on-AWS-spot-instances/src/jupyter_notebook_config.py $HOME/.jupyter/

mkdir -p $HAIL_HOME/notebook/
chmod -R 777 $HAIL_HOME/notebook
cd $HAIL_HOME/notebook/

JUPYTERPID=`cat /tmp/jupyter_notebook.pid` # Kill an existing Jupyter Lab if any running 
kill $JUPYTERPID
nohup jupyter lab >/tmp/jupyter_notebook.log 2>&1 &
echo $! > /tmp/jupyter_notebook.pid
echo "Started Jupyter Lab in the background."
