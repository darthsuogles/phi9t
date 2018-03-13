#!/bin/bash

# Enable environment-modules for spack
source /home/drgscl/spack/share/spack/setup-env.sh

# Load required modules
spack install \
      readline \
      zlib \
      bzip2 \
      snappy \
      libjpeg \
      zeromq \
      openssl \
      opencv \
      openblas \
      cmake
