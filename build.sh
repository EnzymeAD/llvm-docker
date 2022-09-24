#!/bin/bash

LLVM_VERSIONS=( 7 8 9 10 11 12 13 14 )
UBUNTU_VERSIONS=( 18.04 20.04 22.04 )

for LLVM_VERSION in "${LLVM_VERSIONS[@]}"
do
    for UBUNTU_VERSION in "${UBUNTU_VERSIONS[@]}"
    do
	    docker buildx build . --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag llvm-docker-$UBUNTU_VERSION-$LLVM_VERSION --build-arg UBUNTU_VERSION=$UBUNTU_VERSION --build-arg LLVM_VERSION=$LLVM_VERSION 
    done
done
