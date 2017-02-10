#!/bin/bash

install_dir="$PWD/distro/install"

which patchelf || brew install patchelf
module load openblas

echo "Performing surgical operations on RPATH"
pkg_libs=($(find "${install_dir}/lib/lua" -name '*.so' -type f))

for libnm in ${pkg_libs[@]}; do
    echo "$libnm"
    patchelf --add-needed "${OPENBLAS_ROOT}/lib/libopenblas.so" "${libnm}"
done


