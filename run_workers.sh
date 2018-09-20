#!/usr/bin/env bash

HOST=`hostname`
CORES=`grep -c ^processor /proc/cpuinfo`

VIDEOS="$HOME/videos/"
TMP="$HOME/tmp/"
IMAGE="fginet/docker-video-encoding:latest"

RESULTS="$HOME/WEBDAV/results/"
JOBS="$HOME/WEBDAV/jobs/"

SFTP_USER=""
SFTP_PASSWORD=""
SFTP_HOST=""
SFTP_PORT=""
SFTP_TARGET_DIR=""

# Overwrite here for testing
CORES=2
RESULTS="$HOME/docker-video-encoding/samples/results/"
JOBS="$HOME/docker-video-encoding/samples/jobs/"

echo Host: $HOST
echo Cores: $CORES

# Update docker image
docker pull $IMAGE

for (( c=1; c<$CORES; c++ ))
do
        WID="${HOST}x${c}"
        WORKER_CMD="python3 worker.py -v \"$VIDEOS\" -t \"$TMP\" -r \"$RESULTS\" -j \"$JOBS\" \
		    -c \"$IMAGE\" -i \"$WID\" -p \"$c\" --log \
		    --sftp-user=\"$SFTP_USER\" --sftp-password=\"$SFTP_PASSWORD\" \
		    --sftp-host=\"$SFTP_HOST\" --sftp-port=\"$SFTP_PORT\" \
		    --sftp-target-dir=\"$SFTP_TARGET_DIR\""

	echo "Running worker $WID"
        echo screen -dm -S "$WID" bash -c "${WORKER_CMD}; exec bash"
done

