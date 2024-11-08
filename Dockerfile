FROM registry.suse.com/suse/sle15:15.6 AS base
RUN zypper remove -y container-suseconnect && \
    zypper install -y -t pattern devel_basis && \
    zypper remove -y gcc-7 && \
    zypper install -y \
    bc \
    bzip2 \
    ccache \
    cmake \
    gawk \
    gcc13 \
    gcc13-c++ \
    git \
    gzip \
    hostname \
    lz4 \
    mercurial \
    ninja \
    python3 \
    rpcgen \
    rsync \
    subversion \
    unzip \
    wget \
    zstd && \
    ln -sf /usr/bin/gcc-13 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-13 /usr/bin/g++

ENV SRC_DIR=/source
WORKDIR ${SRC_DIR}/
RUN --mount=type=cache,target=/var/cache/dl

FROM base AS build
ARG BUILDARCH 
ARG BUILDROOT_VERSION
ARG VERBOSE

# Required to build as root, even in Docker
ENV BR2_DL_DIR=/var/cache/dl
ENV FORCE_UNSAFE_CONFIGURE=1
ENV HOME=${SRC_DIR}
COPY . .
RUN ./scripts/entry ci


FROM scratch AS output
ENV SRC_DIR=/source
COPY --from=build ${SRC_DIR}/artifacts /artifacts
COPY --from=build ${SRC_DIR}/dist /dist