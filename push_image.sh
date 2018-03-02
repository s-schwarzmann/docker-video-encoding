#!/bin/bash
source "$(dirname $0)/config.cfg"

# Build image locally
docker build -t $1 .

# Export image
docker save -o $1.tar $1

# Push image to hosts
for HOST in "${DOCKER_HOST_LIST[@]}"; do
	scp $1.tar ubuntu@$HOST:
	ssh ubuntu@$HOST docker load -i $1.tar
done

rm $1.tar

