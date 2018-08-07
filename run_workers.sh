#!/usr/bin/env bash

HOST=`hostname`
CORES=`grep -c ^processor /proc/cpuinfo`

VIDEOS="$HOME/videos/"
TMP="$HOME/tmp/"
IMAGE="ls3info/encoding:latest"

RESULTS="$HOME/WEBDAV/results/"
JOBS="$HOME/WEBDAV/jobs/"

# Overwrite here for testing
CORES=2
RESULTS="$HOME/docker-video-encoding/samples/results/"
JOBS="$HOME/docker-video-encoding/samples/jobs/"

echo Host: $HOST
echo Cores: $CORES

for (( c=1; c<$CORES; c++ ))
do
        WID="${HOST}x${c}"
        WORKER_CMD="python3 worker.py -v \"$VIDEOS\" -t \"$TMP\" -r \"$RESULTS\" -j \"$JOBS\" -c "$IMAGE" -i "$WID" -p $c"

	echo "Running worker $WID"
        echo screen -dm -S "$WID" bash -c "${WORKER_CMD}; exec bash"
done

