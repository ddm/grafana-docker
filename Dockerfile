FROM alpine:3.5

ARG GRAFANA_VERSION=4.2.0
ARG GOPATH=/go
ARG GRAFANAPATH=/grafana

COPY http_server.go /tmp/

RUN mkdir -p ${GRAFANAPATH}/public &&\
    mkdir -p ${GRAFANAPATH}/data &&\
    mkdir -p ${GRAFANAPATH}/conf &&\
    mkdir -p ${GRAFANAPATH}/bin &&\
    apk --no-cache add --virtual runtime-dependencies \
      ca-certificates &&\
    apk --no-cache add --virtual build-dependencies \
      curl \
      git \
      go \
      nodejs \
      python \
      musl-dev \
      build-base &&\
    mkdir -p ${GOPATH}/src/github.com/grafana/ &&\
    git clone --depth 1 --branch v${GRAFANA_VERSION} https://github.com/grafana/grafana.git ${GOPATH}/src/github.com/grafana/grafana &&\
    mv /tmp/http_server.go ${GOPATH}/src/github.com/grafana/grafana/pkg/api/http_server.go &&\
    cd ${GOPATH}/src/github.com/grafana/grafana &&\
    go run build.go setup &&\
    go run build.go build &&\
    mv ${GOPATH}/src/github.com/grafana/grafana/bin/grafana-server ${GRAFANAPATH}/bin/grafana-server &&\
    npm install -g yarn &&\
    yarn install --pure-lockfile &&\
    npm run build &&\
    mv ${GOPATH}/src/github.com/grafana/grafana/public_gen/* /grafana/public/ &&\
    rm -rf /usr/lib/node_modules &&\
    rm -rf ${GOPATH} &&\
    rm -rf /root/* &&\
    rm -rf /tmp/* &&\
    apk del --purge build-dependencies &&\
    rm -rf /var/cache/apk/* &&\
    adduser -D -u 1000 grafana &&\
    find /grafana -print | xargs chown grafana:grafana

COPY grafana.ini /grafana/conf/defaults.ini

USER grafana
VOLUME "/grafana/data"
WORKDIR /grafana
EXPOSE 3000

CMD bin/grafana-server
