# GO_VERSION is provided by Cloud Build, and is set to the latest
# version of Go. See the configuration in the deploy directory.

ARG GO_VERSION="1.16-buster"

FROM mcr.microsoft.com/vscode/devcontainers/go:0-${GO_VERSION}

USER vscode

LABEL maintainer="yuebanlaosiji@outlook.com"

ENV GOPROXY=https://goproxy.cn,direct
ENV TZ=Asia/Shanghai

ENV BUILD_DEPS 'curl git gcc patch libc6-dev ca-certificates'

RUN set -eux && \
    sudo apt-get update && apt-get install -y ${BUILD_DEPS} && \
    cd ~ && \
    sudo curl -fsSL https://code-server.dev/install.sh | sh

EXPOSE 8080

ENTRYPOINT ["/usr/bin/code-server","--bind-addr","0.0.0.0:8080"]
