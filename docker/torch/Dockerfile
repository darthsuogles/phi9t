FROM phissenschaft/torch-deps:xenial-cuda9-cudnn7
MAINTAINER philip phissenschaft@gmail.com

USER drgscl
WORKDIR /home/drgscl

RUN mkdir -p app/torch
WORKDIR app/torch

RUN git clone https://github.com/torch/distro.git --recursive
WORKDIR distro

# Build the package
COPY pkg_install.sh .
RUN ./pkg_install.sh
RUN chmod -R a+w /home/drgscl/app/torch/distro/install/

# Install host user file access settings
USER root
ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu \
       "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc \
       "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y

WORKDIR /home/drgscl/app
COPY entrypoint.sh .

WORKDIR /tmp/host
ENTRYPOINT ["/home/drgscl/app/entrypoint.sh"]
