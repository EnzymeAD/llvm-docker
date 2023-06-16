ARG UBUNTU_VERSION=20.04
ARG LLVM_VERSION=14

FROM ubuntu:20.04 AS builder

ARG LLVM_VERSION
ARG BUILD_TYPE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && apt-get install -y cmake ninja-build build-essential python3 python3-distutils git unzip zlib1g-dev gcc g++ \
    && apt-get autoremove -y --purge \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch release/$LLVM_VERSION.x --single-branch --depth 1 https://github.com/llvm/llvm-project.git /tmp/llvm-project/

RUN mkdir /tmp/llvm-project/build && mkdir /tmp/llvm && cd /tmp/llvm-project/build \
    && cmake -G Ninja ../llvm -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_INSTALL_PREFIX=/tmp/llvm \
    -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++" -DLLVM_USE_LINKER="gold" -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_ENABLE_RUNTIMES="compiler-rt;openmp" \
    -DLLVM_BUILD_TOOLS=OFF -DLLVM_INSTALL_UTILS=OFF -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DCLANG_ENABLE_STATIC_ANALYZER=OFF -DCLANG_ENABLE_ARCMT=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    && cmake --build . && cmake --build . --target install

FROM ubuntu:$UBUNTU_VERSION

COPY --from=builder /tmp/llvm/ /usr/local/

ENV DEBIAN_FRONTEND=
