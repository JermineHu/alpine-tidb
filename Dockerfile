FROM alpine:3.6
MAINTAINER Jermine <Jermine.hu@qq.com>
ENV GOLANG_VERSION 1.9
# https://golang.org/issue/14851 (Go 1.8 & 1.7)
# https://golang.org/issue/17847 (Go 1.7)
COPY *.patch /go-alpine-patches/
COPY go-wrapper /usr/local/bin/

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
	   ca-certificates \
	    git \
		make \
		bash \
		gcc \
		musl-dev \
		openssl \
		go ; \
	    export \
# set GOROOT_BOOTSTRAP such that we can actually build Go
		GOROOT_BOOTSTRAP="$(go env GOROOT)" \
# ... and set "cross-building" related vars to the installed system's values so that we create a build targeting the proper arch
# (for example, if our build host is GOARCH=amd64, but our build env/image is GOARCH=386, our build needs GOARCH=386)
		GOOS="$(go env GOOS)" \
		GOARCH="$(go env GOARCH)" \
		GO386="$(go env GO386)" \
		GOARM="$(go env GOARM)" \
		GOHOSTOS="$(go env GOHOSTOS)" \
		GOHOSTARCH="$(go env GOHOSTARCH)" ; \
	wget -O go.tgz "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz"; \
	echo 'a4ab229028ed167ba1986825751463605264e44868362ca8e7accc8be057e993 *go.tgz' | sha256sum -c -; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	cd /usr/local/go/src; \
	for p in /go-alpine-patches/*.patch; do \
		[ -f "$p" ] || continue; \
		patch -p2 -i "$p"; \
	done; \
	./make.bash; \
	rm -rf /go-alpine-patches; \
	export PATH="/usr/local/go/bin:$PATH"; \
	go version ;\
    git clone https://github.com/pingcap/tidb.git /go/src/github.com/pingcap/tidb ; \
    cd /go/src/github.com/pingcap/tidb ; \
    make ; \
    mv bin/tidb-server /tidb-server ; \
    make clean ; \
	rm -r /var/cache/apk ; \
	rm -r /usr/share/man ; \
	rm -rf /go /usr/local/go ;\
    apk del .build-deps

EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
