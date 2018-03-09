FROM phissenschaft/xenial-cuda9-cudnn7-base
MAINTAINER philip phissenschaft@gmail.com

USER root
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     python-dev

USER drgscl
WORKDIR /home/drgscl

RUN git clone https://github.com/spack/spack.git

WORKDIR spack/bin
RUN ./spack install zlib bzip2 xz snappy readline
RUN ./spack install lua-jit

# Install environment-modules
# https://spack.readthedocs.io/en/latest/getting_started.html#environment-modules
RUN ./spack bootstrap

COPY zshrc /home/drgscl/.zshrc

ENTRYPOINT ["/usr/bin/zsh"]
