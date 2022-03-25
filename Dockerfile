# GO_VERSION is provided by Cloud Build, and is set to the latest
# version of Go. See the configuration in the deploy directory.

# docker pull golang:1.18.0-buster
ARG GO_VERSION="1.18.0"

FROM golang:${GO_VERSION}-buster

LABEL maintainer="yuebanlaosiji@outlook.com"

ENV BUILD_DEPS 'curl git gcc patch libc6-dev ca-certificates'

RUN set -eux && \
    apt-get update && apt-get install -y ${BUILD_DEPS} && \
    cd ~ && \
    curl -fsSL https://code-server.dev/install.sh | sh

EXPOSE 8080

ENTRYPOINT ["/usr/bin/code-server","--bind-addr","0.0.0.0:8080"]
