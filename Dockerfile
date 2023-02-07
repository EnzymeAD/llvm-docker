ARG UBUNTU_VERSION=20.04
ARG LLVM_VERSION=14

FROM ubuntu:20.04 AS builder

ARG LLVM_VERSION
ARG BUILD_TYPE

LABEL org.opencontainers.image.source=https://github.com/EnzymeAD/llvm-docker
LABEL org.opencontainers.image.description="LLVM build for use in Enzyme CI"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && apt-get install --no-install-recommends -y ca-certificates software-properties-common gcc g++ cmake ninja-build build-essential python3 python3-distutils git unzip zlib1g-dev \
    && apt-get autoremove -y --purge \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch release/$LLVM_VERSION.x --single-branch --depth 1 https://github.com/llvm/llvm-project.git /tmp/llvm-project/

RUN mkdir /tmp/llvm-project/build && mkdir /tmp/llvm && cd /tmp/llvm-project/build \
    && cmake -G Ninja ../llvm -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_INSTALL_PREFIX=/tmp/llvm \
    -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++" -DLLVM_USE_LINKER="gold" -DLLVM_TARGETS_TO_BUILD="host" \
    -DLLVM_ENABLE_PROJECTS="clang;lld;openmp;polly" -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
    -DLLVM_BUILD_TOOLS=OFF -DLLVM_INSTALL_UTILS=OFF -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF -DCLANG_ENABLE_ARCMT=OFF \
    && cmake --build . && cmake --build . --target install

FROM ubuntu:$UBUNTU_VERSION

COPY --from=builder /tmp/llvm/ /usr/local/

ENV DEBIAN_FRONTEND=
