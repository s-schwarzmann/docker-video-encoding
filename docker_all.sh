#!/bin/bash

source config.cfg

for node in ${DOCKER_HOST_LIST[@]}; do
        ssh $node $@
done
