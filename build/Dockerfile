FROM debian:bullseye-slim

ENV AWS_DEFAULT_REGION=eu-west-1

WORKDIR /tmp
COPY . /tmp

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
        ruby-dev bundler openjdk-17-jre-headless wget tar && \
    bundle install && \
    apt-get --purge remove -y \
        ruby-dev && \
    apt-get --purge autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
