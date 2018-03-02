#!/bin/bash

source "$(dirname $0)/config.cfg"

>&2 echo "Running $IMAGE_NAME on [${DOCKER_HOST_LIST[@]}]."
>&2 echo "Maximum of $MAX_RUNNING_CONTAINERS in parallel per host."

while read line; do
    ENV_STRING=$(get_env_string "$line")
    scheduled=0
    while [[ $scheduled -eq 0 ]]; do
        HOST=${DOCKER_HOST_LIST[0]}
	RD="docker -H ${HOST}:${DOCKER_PORT}"  
	RUNNING_CONTAINERS=$($RD ps -q | wc -l)
	if [[ $RUNNING_CONTAINERS -lt $MAX_RUNNING_CONTAINERS ]]; then
	    >&2 echo "Task '$line' scheduled to $HOST ($(($RUNNING_CONTAINERS+1))/$MAX_RUNNING_CONTAINERS)"
	    #echo "$RD run --rm ${DOCKER_OPTS} ${ENV_STRING} ${IMAGE_NAME}"
	    bash -c "$RD run --rm ${DOCKER_OPTS} ${ENV_STRING} ${IMAGE_NAME}" &
	    scheduled=1
	    sleep ${SLEEP_BETWEEN_JOBS}
	else
	    #>&2 echo "$HOST has $RUNNING_CONTAINERS/$MAX_RUNNING_CONTAINERS containers running. Skip."
	    sleep ${SLEEP_BETWEEN_JOBS}
	fi
	DOCKER_HOST_LIST=("${DOCKER_HOST_LIST[@]:1}" "$HOST")
    done
done<$1

>&2 echo "Scheduled all tasks. Waiting for last task to finish."

sleep 5

for HOST in ${DOCKER_HOST_LIST[@]}; do
    RD="docker -H ${HOST}:${DOCKER_PORT}"
    while [[ $($RD info 2>/dev/null| grep Running | grep -o -E [0-9]*) -gt 0 ]]; do
	sleep 5
    done
    >&2 echo "$HOST has finished all tasks."
done

>&2 echo "All tasks finished."
