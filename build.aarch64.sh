#!/bin/bash

L4T_STRING=$(dpkg-query --showformat='${Version}' --show nvidia-l4t-core)
L4T_VERSION="r$(echo $L4T_STRING | cut -f 1 -d '-')"

echo ${L4T_VERSION}
DOCKER_BUILDKIT=0 docker build --network=host -f Dockerfile.aarch64 \
	-t nubificus/jetson-inference:aarch64 \
	--build-arg "L4T_VERSION=${L4T_VERSION}" .
