FROM alpine:3.20
ARG KIND_VERSION=v0.27.0
ARG KUBECTL_VERSION=v1.32.3
ARG HELM_VERSION=v3.17.2
RUN apk add --no-cache bash curl openssl git coreutils jq docker-cli python3 \
 && curl -fsSLo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64 \
 && curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
 && curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xz -C /tmp \
 && mv /tmp/linux-amd64/helm /usr/local/bin/helm && rm -rf /tmp/linux-amd64 \
 && chmod +x /usr/local/bin/kind /usr/local/bin/kubectl
WORKDIR /work
