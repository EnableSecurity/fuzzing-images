FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y subversion git wget build-essential g++ autoconf libtool bison flex gdb screen inotify-tools gnuplot subversion python python3 software-properties-common

WORKDIR /usr/local/src
RUN git clone -b llvmorg-12.0.1 --depth 1 https://github.com/llvm/llvm-project

WORKDIR /usr/local/src
RUN wget https://cmake.org/files/v3.13/cmake-3.13.4.tar.gz
RUN tar xzvf cmake-3.13.4.tar.gz
WORKDIR /usr/local/src/cmake-3.13.4
RUN ./bootstrap
RUN make -j8
RUN make install

RUN mkdir -p /usr/local/src/llvm-project/llvm-build
WORKDIR /usr/local/src/llvm-project/llvm-build
RUN cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=/usr/local/clang \
 -DLLVM_ENABLE_PROJECTS="clang;compiler-rt" \
 -DLLVM_INCLUDE_EXAMPLES="off" \
 -DLLVM_INCLUDE_TESTS="off" \
 -DLLVM_INCLUDE_BENCHMARKS="off" \
 ../llvm
RUN make -j8
RUN make install

FROM ubuntu:20.04
COPY --from=0 /usr/local/clang/bin /usr/bin
COPY --from=0 /usr/local/clang/include /usr/include
COPY --from=0 /usr/local/clang/lib /usr/lib
COPY --from=0 /usr/local/clang/libexec /usr/libexec
COPY --from=0 /usr/local/clang/share /usr/share

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y build-essential git pkg-config flex bison \
    libssl-dev libsqlite3-dev libmysqlclient-dev \
    vim net-tools psmisc python3 gdb tcpdump
