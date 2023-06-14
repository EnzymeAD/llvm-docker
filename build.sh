#!/bin/bash

LLVM_VERSIONS=( 9 10 11 12 13 14 15 )
UBUNTU_VERSIONS=( 20 )

for LLVM_VERSION in "${LLVM_VERSIONS[@]}"
do
    for UBUNTU_VERSION in "${UBUNTU_VERSIONS[@]}"
    do
        echo "Building LLVM $LLVM_VERSION on Ubuntu $UBUNTU_VERSION"
	    docker buildx build . --push --platform linux/arm64,linux/amd64 --tag ghcr.io/enzymead/llvm-docker/ubuntu-$UBUNTU_VERSION-llvm-$LLVM_VERSION:latest --build-arg UBUNTU_VERSION=$UBUNTU_VERSION.04 --build-arg LLVM_VERSION=$LLVM_VERSION 
    done
done
