FROM phissenschaft/xenial-cuda9-cudnn7-base
MAINTAINER philip phissenschaft@gmail.com

USER root
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends \
    # We need this for `spack` to work
    gfortran \
    # We want to edit stuffs in the container
    emacs-nox \
    sudo \
    && rm -rf /var/lib/apt/lists/*

USER drgscl
WORKDIR /home/drgscl

RUN git clone https://github.com/spack/spack.git

WORKDIR spack/bin
RUN ./spack install \
    zlib \
    bzip2 \
    xz \
    snappy \
    readline \
    cmake

# Install environment-modules
# https://spack.readthedocs.io/en/latest/getting_started.html#environment-modules
RUN ./spack bootstrap

COPY zshrc /home/drgscl/.zshrc

ENTRYPOINT ["/usr/bin/zsh"]
