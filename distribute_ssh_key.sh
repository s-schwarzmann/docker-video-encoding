#!/bin/bash

source "config.cfg"

for HOST in "${DOCKER_HOST_LIST[@]}"; do
	ssh-copy-id $SSH_USER@$HOST
done
