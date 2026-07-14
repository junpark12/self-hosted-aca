FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    ca-certificates \
    unzip \
    zip \
    wget \
    apt-transport-https \
    software-properties-common \
    lsb-release \
    gnupg \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI - Container App Job의 system-assigned Managed Identity로
# 'az login --identity' 후 'az webapp deploy'를 실행하기 위해 필요
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN useradd -m runner
WORKDIR /home/runner/actions-runner

ARG RUNNER_VERSION=2.335.1
RUN curl -L -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz

RUN ./bin/installdependencies.sh

COPY start.sh .
RUN chmod +x start.sh \
    && chown -R runner:runner /home/runner

USER runner
ENTRYPOINT ["./start.sh"]
