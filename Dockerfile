FROM debian:jessie-slim

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r memcache && useradd -r -g memcache memcache

ENV MEMCACHED_VERSION 1.4.13
# ENV MEMCACHED_SHA1 519b417515206b0b95ff9bf14106a891f6a2252e

RUN set -x \
	&& buildDeps=' \
		ca-certificates \
		dpkg-dev \
		gcc \
		libc6-dev \
		libevent-dev \
		libsasl2-dev \
		make \
		perl \
		wget \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& wget -O memcached.tar.gz "https://memcached.org/files/old/memcached-$MEMCACHED_VERSION.tar.gz" \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	&& cd /usr/src/memcached \
	&& ./configure \
		--build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
		--enable-sasl \
	&& make -j "$(nproc)" \
	&& make install \
	&& cd / && rm -rf /usr/src/memcached \
	&& apt-mark manual \
		libevent-2.0-5 \
		libsasl2-2 \
	&& apt-get purge -y --auto-remove $buildDeps
#	&& memcached -V

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
