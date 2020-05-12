#!/bin/bash
set -x -e

mkdir -p dist
for ARCH in amd64 arm arm64; do
    docker build --build-arg ARCH=${ARCH} --tag k3s-root .
    docker run --rm k3s-root \
        tar cf - -C /usr/src ./bin ./etc > dist/k3s-root-${ARCH}.tar
done
