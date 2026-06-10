# syntax=docker/dockerfile:1
FROM registry.suse.com/bci/bci-base:16.0 AS bci
RUN zypper remove -y container-suseconnect && \
    zypper install -y -t pattern devel_basis && \
    zypper install -y \
    bc \
    bzip2 \
    ccache \
    cmake \
    cpio \
    file \
    gawk \
    gcc15 \
    gcc15-c++ \
    git \
    gzip \
    hostname \
    lz4 \
    mercurial \
    ninja \
    python3 \
    rpcgen \
    rsync \
    unzip \
    wget \
    which \
    zstd && \
    ln -sf /usr/bin/gcc-15 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-15 /usr/bin/g++

FROM bci AS build
ARG BUILDARCH
ARG BUILDROOT_VERSION
ARG VERBOSE
ENV BUILDARCH=${BUILDARCH} BUILDROOT_VERSION=${BUILDROOT_VERSION} VERBOSE=${VERBOSE}
ENV BR2_DL_DIR=/var/cache/dl 
# Required to build as root, even in Docker
ENV FORCE_UNSAFE_CONFIGURE=1
WORKDIR /usr/src/k3s-root
COPY --parents buildroot/ iptables-detect/ package/ patches/ scripts/ /usr/src/k3s-root/

FROM build AS download
RUN ./scripts/download

FROM build AS ci
RUN ./scripts/ci

FROM scratch AS result
COPY --from=ci /usr/src/k3s-root/dist/ /dist/
COPY --from=ci /usr/src/k3s-root/artifacts/ /artifacts/
