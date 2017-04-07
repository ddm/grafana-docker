FROM alpine:3.5

ARG GRAFANA_VERSION=4.2.0
ARG NODE_VERSION=7.8.0
ARG YARN_VERSION=0.21.3
ARG GOPATH=/go
ARG NODE_BUILD_PATH=/tmp/node

COPY http_server.go /tmp/
COPY grafana.ini /tmp/

RUN apk --no-cache add --virtual build-dependencies \
      go \
      curl \
      git \
      musl-dev \
      build-base \
      python \
      linux-headers \
      binutils-gold \
      libstdc++ \
      gnupg &&\
    mkdir -p ${GOPATH}/src/github.com/grafana/ &&\
    git clone https://github.com/grafana/grafana.git ${GOPATH}/src/github.com/grafana/grafana &&\
    cd ${GOPATH}/src/github.com/grafana/grafana &&\
    git checkout v${GRAFANA_VERSION} &&\
    cp /tmp/http_server.go ${GOPATH}/src/github.com/grafana/grafana/pkg/api/http_server.go &&\
    go run build.go setup &&\
    go run build.go build &&\
    git clone --depth 1 --branch v${NODE_VERSION} https://github.com/nodejs/node.git ${NODE_BUILD_PATH} &&\
    cd ${NODE_BUILD_PATH} &&\
    ./configure --prefix=${NODE_BUILD_PATH} && \
    make -j$(getconf _NPROCESSORS_ONLN) &&\
    cd ${NODE_BUILD_PATH} &&\
    for key in \
      6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done &&\
    curl -fSL -o yarn.js "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-legacy-${YARN_VERSION}.js" &&\
    curl -fSL -o yarn.js.asc "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-legacy-${YARN_VERSION}.js.asc" &&\
    gpg --batch --verify yarn.js.asc yarn.js &&\
    cd ${GOPATH}/src/github.com/grafana/grafana &&\
    cp ${NODE_BUILD_PATH}/yarn.js . &&\
    PATH=$PATH:${NODE_BUILD_PATH}/bin node yarn install --pure-lockfile &&\
    PATH=$PATH:${NODE_BUILD_PATH}/bin npm run build &&\
    mkdir -p /grafana/public &&\
    mkdir -p /grafana/data &&\
    mkdir -p /grafana/conf &&\
    cp /tmp/grafana.ini /grafana/conf/defaults.ini &&\
    cp ${GOPATH}/src/github.com/grafana/grafana/bin/grafana-server /grafana/ &&\
    cp -R ${GOPATH}/src/github.com/grafana/grafana/public_gen/* /grafana/public/ &&\
    rm -rf ${GOPATH} &&\
    rm -rf ${NODE_BUILD_PATH} &&\
    rm -rf /root/* &&\
    rm -rf /tmp/* &&\
    apk del --purge build-dependencies &&\
    rm -rf /var/cache/apk/* &&\
    adduser -D -u 1000 grafana &&\
    find /grafana -print | xargs chown grafana:grafana

USER grafana
VOLUME "/grafana/data"
WORKDIR /grafana
EXPOSE 3000

CMD /grafana/grafana-server
