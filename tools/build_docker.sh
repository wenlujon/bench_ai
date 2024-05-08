#!/bin/bash

DOCKER_NAME=test_22
CONTAINER_NAME=ubuntu_test_22

docker build -t ubuntu:$DOCKER_NAME .

#docker run -itd --name $CONTAINER_NAME ubuntu:$DOCKER_NAME

echo "please attach to container $CONTAINER_NAME with 'docker exec -it $CONTAINER_NAME bash'"

