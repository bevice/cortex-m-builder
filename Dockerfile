FROM ubuntu:24.04

LABEL maintainer="bevice" \
      org.opencontainers.image.description="Cortex-M firmware builder with ARM GNU Toolchain, CMake and Ninja"

ARG DEBIAN_FRONTEND=noninteractive
ARG CMAKE_VERSION=4.4.5
ARG CMAKE_SHA256=ed85135c5a5135b45e50423cb406dea04ca3338da0b8ef3c9ede963559680be0
ARG NINJA_VERSION=1.13.2
ARG NINJA_SHA256=5749cbc4e668273514150a80e387a957f933c6ed3f5f11e03fb30955e2bbead6
ARG ARM_TOOLCHAIN_VERSION=15.3.rel2
ARG ARM_TOOLCHAIN_SHA256=463df9665c246fa13bab2102115bbf83440661b6eb70b44f3dfd4712ca30037a

# Official toolchain binaries require glibc and a Linux amd64 host.
RUN test "$(dpkg --print-architecture)" = amd64 \
    && apt-get update && apt-get install --yes --no-install-recommends \
        bash build-essential ca-certificates curl git make openssh-client \
        python3 python3-venv xz-utils unzip \
        libncursesw6 libtinfo6 libpython3.12 libexpat1 \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl --fail --location --retry 3 \
      "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" \
      --output /tmp/cmake.tar.gz; \
    echo "${CMAKE_SHA256}  /tmp/cmake.tar.gz" | sha256sum --check -; \
    tar -xzf /tmp/cmake.tar.gz --directory /usr/local --strip-components=1; \
    rm /tmp/cmake.tar.gz

RUN set -eux; \
    curl --fail --location --retry 3 \
      "https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip" \
      --output /tmp/ninja.zip; \
    echo "${NINJA_SHA256}  /tmp/ninja.zip" | sha256sum --check -; \
    unzip /tmp/ninja.zip -d /usr/local/bin; \
    chmod +x /usr/local/bin/ninja; \
    rm /tmp/ninja.zip

RUN set -eux; \
    curl --fail --location --retry 3 \
      "https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages/generic/gnu-toolchain/${ARM_TOOLCHAIN_VERSION}/arm-gnu-toolchain-${ARM_TOOLCHAIN_VERSION}-x86_64-arm-none-eabi.tar.xz" \
      --output /tmp/arm-toolchain.tar.xz; \
    echo "${ARM_TOOLCHAIN_SHA256}  /tmp/arm-toolchain.tar.xz" | sha256sum --check -; \
    mkdir --parents /opt/arm-gnu-toolchain; \
    tar -xJf /tmp/arm-toolchain.tar.xz --directory /opt/arm-gnu-toolchain --strip-components=1; \
    rm /tmp/arm-toolchain.tar.xz

ENV ARM_TOOLCHAIN_PATH=/opt/arm-gnu-toolchain
ENV PATH="/opt/arm-gnu-toolchain/bin:${PATH}"
ENV CMAKE_GENERATOR=Ninja

COPY --chmod=755 builder.sh /builder.sh

RUN cmake --version && ninja --version && arm-none-eabi-gcc --version \
    && arm-none-eabi-gdb --version && gcc --version && bash -n /builder.sh

ENTRYPOINT ["/builder.sh"]
