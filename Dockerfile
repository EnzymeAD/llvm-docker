ARG UBUNTU_VERSION=20.04
ARG LLVM_VERSION=14
ARG BUILD_TYPE=RelWithDebInfo

FROM ubuntu:$UBUNTU_VERSION AS builder

ARG LLVM_VERSION
ARG BUILD_TYPE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates gnupg \
    gcc g++ build-essential cmake ninja-build python3 wget git unzip && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --branch release/$LLVM_VERSION.x --single-branch --depth 1 https://github.com/llvm/llvm-project.git /tmp/llvm-project/

RUN mkdir /tmp/llvm-project/build && mkdir /tmp/llvm

WORKDIR /tmp/llvm-project/build

RUN cmake -G Ninja ../llvm \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX=/tmp/llvm -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++" \
    -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_USE_LINKER="gold"  \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;openmp;polly" -DLLVM_ENABLE_RUNTIMES="compiler-rt;libunwind" \
    -DLLVM_TARGETS_TO_BUILD="host" -DLLVM_BUILD_TOOLS=ON -DLLVM_INSTALL_UTILS=ON -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_PARALLEL_LINK_JOBS=2

RUN cmake --build .
RUN cmake --build . --target install
    
FROM ubuntu:$UBUNTU_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends binutils build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/llvm/ /usr/local/

ENV DEBIAN_FRONTEND=
