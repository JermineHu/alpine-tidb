FROM golang:alpine
RUN  apk --no-cache --no-progress add git make && \
      rm -rf /var/cache/apk/*

RUN git clone https://github.com/pingcap/tidb.git /go/src/github.com/pingcap/tidb && \
    cd /go/src/github.com/pingcap/tidb && \
    make && \
    mv bin/tidb-server /tidb-server && \
    make clean && \
    apk del git make && rm -rf /go /usr/local/go

EXPOSE 4000

ENTRYPOINT ["/tidb-server"]
