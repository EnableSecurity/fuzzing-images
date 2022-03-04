FROM ghcr.io/enablesecurity/fuzzing-images/clang12:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y build-essential git pkg-config libssl-dev flex bison \
    libsqlite3-dev libsctp-dev libradcli-dev libhiredis-dev unixodbc-dev \
    libconfuse-dev libmysqlclient-dev libexpat1-dev libxml2-dev libpq-dev \
    zlib1g-dev libperl-dev libsnmp-dev libdb-dev libldap2-dev \
    libcurl4-gnutls-dev libgeoip-dev libpcre3-dev libmemcached-dev \
    libmicrohttpd-dev librabbitmq-dev liblua5.1-0-dev libncurses5-dev \
    libjson-c-dev uuid-dev python-dev libmaxminddb-dev \
    vim net-tools psmisc python3

WORKDIR /
RUN git clone https://github.com/google/AFL
WORKDIR /AFL
RUN make clean all
WORKDIR /AFL/llvm_mode
RUN make

WORKDIR /fuzzer

COPY scripts/fuzz.sh fuzz.sh

ENV AFL_PATH="/AFL"
ENV PATH="$PATH:/AFL"

ENTRYPOINT [ "./fuzz.sh" ]