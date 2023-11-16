ARG UBUNTU_VERSION=22.04
ARG LLVM_URL="https://github.com/llvm/llvm-project"
ARG LLVM_VERSION=17
ARG LLVM_COMMIT=""
ARG BUILD_TYPE=Release
ARG PROJECTS="clang;lld"
ARG TARGETS=X86

FROM ubuntu:22.04 AS builder

ARG UBUNTU_VERSION
ARG LLVM_URL
ARG LLVM_VERSION
ARG LLVM_COMMIT
ARG BUILD_TYPE
ARG PROJECTS
ARG TARGETS

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && apt-get install -y cmake ninja-build build-essential python3 python3-distutils git unzip gcc g++ \
    && apt-get autoremove -y --purge \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
RUN if [ -z "$LLVM_COMMIT" ]; then echo "branch" && git clone --branch release/$LLVM_VERSION.x --single-branch --depth 1 $LLVM_URL /tmp/llvm-project; else echo "commit" && git clone $LLVM_URL /tmp/llvm-project && cd /tmp/llvm-project && git checkout $LLVM_COMMIT; fi

RUN mkdir /tmp/llvm-project/build && mkdir /tmp/llvm && cd /tmp/llvm-project/build \
    && cmake -G Ninja ../llvm -Wno-dev \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_INSTALL_PREFIX=/tmp/llvm \
    -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++" -DLLVM_USE_LINKER="gold" -DLLVM_TARGETS_TO_BUILD="$TARGETS" \
    -DLLVM_ENABLE_PROJECTS=$PROJECTS -DLLVM_ENABLE_RUNTIMES="compiler-rt;openmp" -DLLVM_USE_SPLIT_DWARF=ON \
    -DLLVM_BUILD_TOOLS=OFF -DLLVM_INSTALL_UTILS=OFF -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF -DCLANG_ENABLE_ARCMT=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=2 -DLLVM_ENABLE_ZLIB=OFF \
    && cmake --build . && cmake --build . --target install

FROM ubuntu:$UBUNTU_VERSION

COPY --from=builder /tmp/llvm/ /usr/local/

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && apt-get install -y cmake ninja-build build-essential python3 python3-distutils git unzip gcc g++ libeigen3-dev libboost-dev \
    && apt-get autoremove -y --purge \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
