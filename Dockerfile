FROM nginx:1.14.1
LABEL maintainer="Jason Wilder mail@jasonwilder.com"

# Set container parameters
ENV DOCKER_GEN_VERSION 0.7.4
ENV DHPARAM_GENERATION 0
ENV PROXY_SSL_CONTACT ""
ENV PROXY_SSL_ROOT_DOMAINS in.macdata.io,svc.in.macdata.io
ENV PROXY_SSL_CERTS_DIR /root/ssl.d

# Install wget and install/updates certificates
RUN apt-get -qq update \
 && apt-get -qq install -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    wget \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    curl \
    cron \
    jq \
 && pip3 install -q shinto-cli \
 && apt-get -qq clean \
 && rm -r /var/lib/apt/lists/*

# Install Forego
RUN wget --quiet -O /usr/local/bin/forego https://github.com/jwilder/forego/releases/download/v0.16.1/forego \
    && chmod +x /usr/local/bin/forego

RUN wget --quiet https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

# Get cli53
RUN wget --quiet -O /usr/local/bin/cli53 https://github.com/barnybug/cli53/releases/download/0.8.15/cli53-linux-amd64 \
    && chmod +x /usr/local/bin/cli53

# Get dehydrated
RUN wget --quiet -O /tmp/dehydrated-0.6.2.tar.gz https://github.com/lukas2511/dehydrated/releases/download/v0.6.2/dehydrated-0.6.2.tar.gz \
 && tar -C /tmp -xzf /tmp/dehydrated-0.6.2.tar.gz \
 && mv /tmp/dehydrated-0.6.2/dehydrated /usr/local/bin/dehydrated \
 && chmod +x /usr/local/bin/dehydrated \
 && rm -rf /tmp/dehydrated-0.6.2.tar.gz /tmp/dehydrated-0.6.2

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf

# Add networks list
COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/

# Add a weeky cron job
RUN chmod +x /app/certs.sh \
    && (crontab -l ; echo "0 0 * * 1 /app/certs.sh")| crontab -

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["$PROXY_SSL_CERTS_DIR", "/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
