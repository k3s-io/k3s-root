#!/bin/bash
set -x -e

for ARCH in amd64 arm arm64; do
    docker build --build-arg ARCH=${ARCH} -t k3s-root .
    docker run -i --rm k3s-root tar cf - -C /usr/src ./bin > dist/k3s-root-${ARCH}.tar
done
