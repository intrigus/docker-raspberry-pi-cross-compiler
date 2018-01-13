#!/bin/bash

: ${RPXC_IMAGE:=intrigus/docker-raspberry-pi-cross-compiler}

docker build -t $RPXC_IMAGE .
