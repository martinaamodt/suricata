FROM alpine:latest AS build_stage
RUN apk update
RUN apk add \
     		 ca-certificates \
		 build-base \
		 py3-yaml \
		 python3 \
		 automake \
		 autoconf \
		 libtool \
		 libcap-ng-dev \
		 lz4-dev \
		 file-dev \
		 geoip-dev \
		 pcre-dev \
		 yaml-dev \
		 libpcap-dev \
		 hiredis-dev \
		 nss-dev \
		 libnet-dev \
		 libnetfilter_queue-dev \
		 libnfnetlink-dev \
		 jansson-dev \
		 nspr-dev \
		 libnetfilter_log-dev \
		 libmaxminddb-dev \
		 rust \
		 luajit-dev \
		 cargo \
		 zlib-dev

RUN cargo install --force cbindgen
ENV PATH="/root/.cargo/bin:${PATH}"
COPY . .
RUN ./autogen.sh \
  && ./configure --disable-gccmarch-native \
  --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
  && make -j${nproc} \
  && make install DESTDIR=/suricata-docker \
  && make install-conf DESTDIR=/suricata-docker


FROM alpine:latest
RUN apk add rsync \
  python3 \
  py-yaml \
  libnet-dev \
  nss-dev \
  lz4-dev \
  pcre-dev \
  file-dev \
  libcap-ng-dev \
  jansson-dev \
  libpcap-dev \
  yaml-dev
RUN pip3 install awscli
WORKDIR /
COPY --from=build_stage suricata-docker/ /suricata-docker/
RUN rsync -rv --copy-links suricata-docker/* /
RUN rm -r suricata-docker/
COPY docker-entrypoint.sh /
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]
