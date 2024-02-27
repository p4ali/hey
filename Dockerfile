ARG DOCKER_HUB_REMOTE=hub.docker.prod.walmart.com/hub-docker-release-remote
FROM $DOCKER_HUB_REMOTE/library/golang:1.21-alpine as builder

RUN version=$(grep '^VERSION' /etc/os-release | awk -F= '{ print $2 }' | awk -F. '{ print($1"."$2) }') && \
    echo "Setup Alpine ${version} package repositories" && \
    echo "http://ark-repos.wal-mart.com/ark/apk/published/alpine/$version/direct/soe/noenv/community" > /etc/apk/repositories && \
    echo "http://ark-repos.wal-mart.com/ark/apk/published/alpine/$version/direct/soe/noenv/main" >> /etc/apk/repositories && \
    rm -f /etc/ssl/cert.pem && ln -s /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem && \
    apk add --update --no-cache curl

# Build
WORKDIR /go/src/github.com/rakyll/hey
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o hey hey.go

ARG CRED_USERNAME
ARG CRED_PASSWORD
ARG GENERIC_REPO
ARG TIMESTAMP
RUN tar cvfz hey-${TIMESTAMP}.tar.gz hey
# https://ci.artifacts.prod.walmart.com/ui/repos/tree/General/platform-generic/microservices/servicemesh/tools
RUN curl -X PUT -u ${CRED_USERNAME}:${CRED_PASSWORD} ${GENERIC_REPO}/microservices/servicemesh/tools/hey-${TIMESTAMP}-linux-amd64.tgz -T hey-${TIMESTAMP}.tar.gz -v --fail

