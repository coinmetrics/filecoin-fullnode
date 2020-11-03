FROM ubuntu:18.04 as builder

# dependencies
RUN set -ex; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    build-essential \
    bzr \
    ca-certificates \
    clang \
    curl \
    git \
    jq \
    mesa-opencl-icd \
    ocl-icd-opencl-dev \
    pkg-config \
  ; \
  rm -rf /var/lib/apt/lists/*


# builder user
RUN useradd -m -s /bin/bash builder
USER builder

# rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# go
RUN curl -L https://dl.google.com/go/go1.15.3.linux-amd64.tar.gz | tar -xz -C /home/builder

ENV PATH=$PATH:/home/builder/.cargo/bin:/home/builder/go/bin

ARG VERSION

# source
RUN set -ex; \
  git clone -b v${VERSION} --depth 1 --recursive https://github.com/filecoin-project/lotus.git /home/builder/lotus

# build
RUN set -ex; \
  cd /home/builder/lotus; \
  export CGO_CFLAGS_ALLOW=-D__BLST_PORTABLE__ CGO_CFLAGS=-D__BLST_PORTABLE__; \
  make all -j$(nproc)


FROM ubuntu:18.04

RUN set -ex; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    mesa-opencl-icd \
  ; \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /home/builder/lotus/lotus /usr/bin/

RUN useradd -m -u 1000 -s /bin/bash runner
USER runner

ENTRYPOINT ["lotus"]
