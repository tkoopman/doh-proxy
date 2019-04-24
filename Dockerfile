FROM alpine:latest as builder
LABEL maintainer "T Koopman"
LABEL description "A DNS-over-HTTP server proxy in Rust. https://github.com/jedisct1/rust-doh"

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN apk add --no-cache libgit2 rust cargo make
RUN cargo install doh-proxy --root /usr/local/

FROM alpine:latest

RUN apk add --no-cache libgcc runit shadow curl su-exec

COPY --from=builder /usr/local/bin/doh-proxy /usr/local/bin/doh-proxy

RUN set -x && \
    groupadd _doh_proxy && \
    useradd -g _doh_proxy -s /dev/null -d /dev/null _doh_proxy && \
    mkdir -p /etc/service/doh-proxy

EXPOSE 3000

ENV ERR_TTL=2
ENV LISTEN_ADDRESS=0.0.0.0:3000
ENV LOCAL_BIND_ADDRESS=0.0.0.0:0
ENV MAX_CLIENTS=512
ENV MAX_TTL=604800
ENV MIN_TTL=10
ENV HTTP_PATH=/dns-query
ENV SERVER_ADDRESS=1.1.1.1:53
ENV TIMEOUT=10

ENTRYPOINT su-exec _doh_proxy:_doh_proxy /usr/local/bin/doh-proxy \
	--err-ttl $ERR_TTL \
	--listen-address $LISTEN_ADDRESS \
	--local-bind-address $LOCAL_BIND_ADDRESS \
	--max-clients $MAX_CLIENTS \
	--max-ttl $MAX_TTL \
	--min-ttl $MIN_TTL \
	--path $HTTP_PATH \
	--server-address $SERVER_ADDRESS \
	--timeout $TIMEOUT
