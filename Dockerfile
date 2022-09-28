ARG UBUNTU_VERSION=20.04
ARG LLVM_VERSION=14

FROM ubuntu:$UBUNTU_VERSION AS builder

ARG LLVM_VERSION
ARG BUILD_TYPE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && apt-get install -y ca-certificates software-properties-common gnupg2 wget \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - \
    && apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
    && apt-get update -q && apt-get install -y gcc-11 g++-11 cmake ninja-build build-essential libssl-dev python3 python3-distutils git unzip zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# RUN git clone --branch v3.24.2 --single-branch --depth 1 https://github.com/Kitware/CMake.git /tmp/cmake

# WORKDIR /tmp/cmake

# RUN ./bootstrap && make -j && make -j install

RUN git clone --branch release/$LLVM_VERSION.x --single-branch --depth 1 https://github.com/llvm/llvm-project.git /tmp/llvm-project/

RUN mkdir /tmp/llvm-project/build && mkdir /tmp/llvm

WORKDIR /tmp/llvm-project/build

RUN cmake -G Ninja ../llvm \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_INSTALL_PREFIX=/tmp/llvm \
    -DCMAKE_C_COMPILER="gcc-11" -DCMAKE_CXX_COMPILER="g++-11" -DLLVM_USE_LINKER="gold" -DLLVM_TARGETS_TO_BUILD="host" \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;openmp;polly" \
    -DLLVM_BUILD_TOOLS=ON -DLLVM_INSTALL_UTILS=ON -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF 

RUN cmake --build .
RUN cmake --build . --target install

FROM ubuntu:$UBUNTU_VERSION

COPY --from=builder /tmp/llvm/ /usr/local/

ENV DEBIAN_FRONTEND=
