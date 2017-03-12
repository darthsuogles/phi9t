#!/bin/bash

export CUDA_PATH=/usr/local/cuda
export CUDA_SDK_PATH=${CUDA_PATH}/samples

base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -d "${base_dir}/gflags/install_dir/" ]] || (
    cd "${base_dir}"
	[ -d gflags ] || git clone https://github.com/gflags/gflags.git
	cd gflags
	mkdir -p build-tree && cd build-tree
	cmake -DCMAKE_INSTALL_PREFIX=$PWD/../install_dir ..
	make && make install
)

function nvprof() { make && "${CUDA_PATH}"/bin/nvprof "$@"; }

nvprof ./max_poll -kernel_grid_dim 32 -validate -random_init 22321 23321 1 9
