from toolchain:gcc-6
MAINTAINER philip phissenschaft@gmail.com

USER drgscl
RUN mkdir -p app/torch
WORKDIR app/torch

RUN git clone https://github.com/torch/distro.git --recursive
WORKDIR distro

COPY build_deps.sh .
RUN ./build_deps.sh

COPY pkg_install.sh .
RUN ./pkg_install.sh

# Install file access
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

WORKDIR /home/phi9t
COPY entrypoint.sh /home/phi9t/.

WORKDIR /home/drgscl/app/torch/distro/install
ENTRYPOINT ["/home/phi9t/entrypoint.sh", "bin/th"]
