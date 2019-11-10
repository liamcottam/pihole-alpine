FROM alpine:3.10 AS builder

RUN apk add --no-cache \
  make \
  gcc \
  musl-dev \
  linux-headers \
  nettle-dev \
  libunwind-dev \
  sqlite-dev \
  sqlite-static

WORKDIR /root
RUN wget https://github.com/pi-hole/FTL/archive/v4.3.1.tar.gz

COPY patches /root/patches

RUN tar xf v4.3.1.tar.gz && \
  cd FTL-4.3.1 && \
  for i in ../patches/*.patch; do patch -p1 -i $i; done && \
  rm -f sqlite3.h sqlite.c && \
  make -j$(nproc)

FROM alpine:3.10

RUN apk add --no-cache \
  lighttpd \
  lighttpd-mod_auth \
  php7-cgi \
  php7-openssl \
  php7-session \
  php7-json \
  php7-sqlite3

RUN wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.7.0/s6-overlay-amd64.tar.gz -O - | \
  tar -xz -C /

RUN wget https://github.com/pi-hole/AdminLTE/archive/v4.3.2.tar.gz -O - | \
  tar -xz --strip 1 -C /var/www/localhost

COPY --from=builder /root/FTL-4.3.1/pihole-FTL /usr/bin/pihole-FTL
RUN mkdir -p /etc/pihole /var/run/pihole /etc/dnsmasq.d /run/lighttpd && \
  chown lighttpd:lighttpd /run/lighttpd

COPY etc /etc

ENV DNSMASQ_USER root
ENV FTL_CMD no-daemon debug

CMD [ "/init" ]
