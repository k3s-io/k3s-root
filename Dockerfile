FROM ubuntu:18.04 AS ubuntu
RUN yes | unminimize

# setup prereqs
RUN apt-get update
RUN apt-get install -y \
    build-essential \
    ccache \
    gcc \
    git \
    g++ \
    rsync \
    bc \
    wget \
    curl \
    ca-certificates \
    ncurses-dev \
    python \
    unzip

# download buildroot
ARG BUILDROOT_VERSION=2020.02.2
RUN mkdir /usr/src/buildroot
RUN curl -fL https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.bz2 | tar xvjf - -C /usr/src/buildroot --strip-components=1

# build
ARG ARCH=amd64
WORKDIR /usr/src/buildroot
COPY ./package/. ./package/
COPY buildroot/config /usr/src/buildroot/.config
COPY buildroot/${ARCH}config /usr/src/buildroot/.config-arch
RUN cat .config-arch >> .config

COPY patches patches
RUN set -e -x; for p in patches/*.patch; do patch -p1 -i $p; done

RUN make oldconfig
RUN make

# save build
WORKDIR /usr/src

# copy binaries
RUN mkdir bin && \
    cp -d buildroot/output/target/usr/sbin/*tables* bin/ && \
    cp buildroot/output/target/usr/sbin/conntrack bin/ && \
    cp buildroot/output/target/usr/sbin/ethtool bin/ && \
    cp buildroot/output/target/usr/sbin/ipset bin/ && \
    cp buildroot/output/target/usr/bin/find bin/ && \
    cp buildroot/output/target/usr/bin/nsenter bin/ && \
    cp buildroot/output/target/usr/bin/pigz bin/ && \
    cp buildroot/output/target/usr/bin/slirp4netns bin/ && \
    cp buildroot/output/target/usr/bin/socat bin/ && \
    cp buildroot/output/target/usr/bin/coreutils bin/ && \
    cp buildroot/output/target/sbin/ip bin/ && \
    cp buildroot/output/target/sbin/blkid bin/ && \
    cp buildroot/output/target/sbin/losetup bin/ && \
    cp buildroot/output/target/bin/busybox bin/ && \
    cp buildroot/output/target/usr/sbin/swanctl bin/ && \
    cp buildroot/output/target/usr/libexec/ipsec/charon bin/

# save etc
RUN mkdir etc && \
    cp -rp buildroot/output/target/var/lib/rancher/k3s/agent/* etc/

# setup links
RUN set -e -x; \
    link() { \
        for l in $(find -L buildroot/output/target/ -samefile buildroot/output/target/$1/$2 | xargs -n 1 basename | sort -u | grep -v "^$2\$"); do \
            ln -s $2 bin/$l; \
        done; \
    }; \
    link bin busybox; \
    link usr/bin coreutils;
