FROM alpine:3.5

ARG GRAFANA_VERSION=4.2.0
ARG GOPATH=/go

COPY http_server.go /tmp/

RUN apk --no-cache add --virtual build-dependencies \
      curl \
      git \
      go \
      nodejs \
      python \
      musl-dev \
      build-base &&\
    mkdir -p ${GOPATH}/src/github.com/grafana/ &&\
    git clone --depth 1 --branch v${GRAFANA_VERSION} https://github.com/grafana/grafana.git ${GOPATH}/src/github.com/grafana/grafana &&\
    cd ${GOPATH}/src/github.com/grafana/grafana &&\
    mv /tmp/http_server.go ${GOPATH}/src/github.com/grafana/grafana/pkg/api/http_server.go &&\
    go run build.go setup &&\
    go run build.go build &&\
    cd ${GOPATH}/src/github.com/grafana/grafana &&\
    npm install -g yarn &&\
    yarn install --pure-lockfile &&\
    npm run build &&\
    npm uninstall -g yarn &&\
    mkdir -p /grafana/public &&\
    mkdir -p /grafana/data &&\
    mkdir -p /grafana/conf &&\
    mv ${GOPATH}/src/github.com/grafana/grafana/bin/grafana-server /grafana/bin/grafana-server &&\
    mv ${GOPATH}/src/github.com/grafana/grafana/public_gen /grafana/public &&\
    rm -rf ${GOPATH} &&\
    rm -rf /root/* &&\
    rm -rf /tmp/* &&\
    rm -f $(which npm) &&\
    rm -f $(which node) &&\
    apk del --purge build-dependencies &&\
    rm -rf /var/cache/apk/* &&\
    adduser -D -u 1000 grafana &&\
    find /grafana -print | xargs chown grafana:grafana

COPY grafana.ini /grafana/conf/defaults.ini

USER grafana
VOLUME "/grafana/data"
WORKDIR /grafana
EXPOSE 3000

CMD /grafana/bin/grafana-server
