FROM alpine:3.5

ARG GRAFANA_VERSION=4.2.0
ARG NODE_VERSION=7.8.0
ARG YARN_VERSION=0.21.3
ARG GOPATH=/go

COPY http_server.go /tmp/

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
    mkdir -p /node &&\
    cd /node &&\
    for key in \
      9554F04D7259F04124DE6B476D5A82AC7E37093B \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      56730D5401028683275BD23C23EFEFE93C4CFFFE \
    ; do \
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done &&\
    curl -sSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.xz && \
    curl -sSL https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc | \
      gpg --batch --decrypt | \
      grep " node-v${NODE_VERSION}.tar.xz\$" | \
      sha256sum -c | \
      grep . && \
    tar -xf node-v${NODE_VERSION}.tar.xz && \
    cd node-v${NODE_VERSION} && \
    ./configure --prefix=/node && \
    make -j$(getconf _NPROCESSORS_ONLN) &&\
    make install &&\
    cd /node &&\
    for key in \
      6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done &&\
    curl -fSL -o yarn.js "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-legacy-${YARN_VERSION}.js" &&\
    curl -fSL -o yarn.js.asc "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-legacy-${YARN_VERSION}.js.asc" &&\
    gpg --batch --verify yarn.js.asc yarn.js &&\
    cd ${GOPATH}/src/github.com/grafana/grafana &&\
    mv /node/yarn.js . &&\
    PATH=$PATH:/node/bin node yarn install --pure-lockfile &&\
    PATH=$PATH:/node/bin npm run build &&\
    mkdir -p /grafana/public &&\
    mkdir -p /grafana/conf &&\
    mkdir -p /grafana/data &&\
    cp ${GOPATH}/src/github.com/grafana/grafana/bin/* /grafana/ &&\
    cp -R ${GOPATH}/src/github.com/grafana/grafana/public_gen/* /grafana/public/ &&\
    rm -rf /go &&\
    rm -rf /node &&\
    rm -rf /root/.gnupg &&\
    rm /tmp/http_server.go &&\
    apk del --purge build-dependencies

COPY grafana.ini /grafana/conf/defaults.ini
RUN adduser -D -u 1000 grafana &&\
    find /grafana -print | xargs chown -R grafana:grafana

USER grafana
VOLUME ["/grafana/data", "/grafana/conf"]
WORKDIR /grafana
EXPOSE 3000

ENTRYPOINT /grafana/grafana-server
