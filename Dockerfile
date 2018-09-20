FROM alpine:latest as builder

ENV  STELLAR_CORE_VERSION=v10.0.0

# Remove docs' block to get rid off pandoc problems
ADD Makefile.am.patch /

RUN mkdir -p /go/src/github.com/stellar/ \
    && apk add --no-cache git make g++ postgresql-dev autoconf automake libtool bison flex musl-dev linux-headers \
    && git clone https://github.com/stellar/stellar-core.git \
    && cd stellar-core \
    && git checkout $STELLAR_CORE_VERSION \
    && git submodule update --init --recursive \
    && git apply /Makefile.am.patch \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install

FROM google/cloud-sdk:alpine

RUN apk add --no-cache libpq libstdc++ libgcc
COPY --from=builder /usr/local/bin/stellar-core /usr/local/bin/stellar-core

EXPOSE 11625
EXPOSE 11626


RUN mkdir /data
VOLUME /data
RUN mkdir -p /secrets/gcloud/storage
VOLUME /secrets/gcloud/storage

ADD gsutil /gsutil

ADD configs /configs
VOLUME /configs

ADD start /

ENV \
    STELLAR_CORE_CFG="/configs/stellar-core.cfg" \
    GCLOUD_STORAGE_CREDENTIALS="/secrets/gcloud/storage/credentials.json"\
    NONEWDB=\
    NONEWHIST=\
    ARCHIVE_NAME=\
    BUCKET_DIR_PATH=\
    STELLAR_CORE_CFG_URL=

ENTRYPOINT ["/bin/bash", "/start"]
