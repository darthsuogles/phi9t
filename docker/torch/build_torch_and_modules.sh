#!/usr/bin/env bash

set -euo pipefail

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX=${PREFIX:-"${_bsd_}/install"}
TORCH_LUA_VERSION=${TORCH_LUA_VERSION:-"LUAJIT21"}

# The new CUDA 9 won't compile torch without this
# https://github.com/torch/cutorch/issues/797#issuecomment-364602210
export TORCH_NVCC_FLAGS="-D__CUDA_NO_HALF_OPERATORS__"

# Enable environment-modules for spack
source /home/drgscl/spack/share/spack/setup-env.sh

# Load required modules
spack load \
      readline \
      zlib \
      bzip2 \
      snappy \
      libjpeg \
      zeromq \
      openssl \
      openblas \
      opencv \
      cmake

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

echo "Prefix set to $PREFIX"
export CMAKE_PREFIX_PATH=$PREFIX

# Update torch's "distro" repository (cloned from docker proper)
git fetch --all && git rebase origin/master
git submodule update --init --recursive

echo "Installing LuaJIT version: ${TORCH_LUA_VERSION}"
mkdir -p install
mkdir -p build
(cd build
 cmake .. -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
       -DCMAKE_BUILD_TYPE=Release \
       -DWITH_${TORCH_LUA_VERSION}=ON 2>&1 >>$PREFIX/install.log || exit 1
 make 2>&1 | tee $PREFIX/install.log || exit 1
 make install 2>&1 | tee $PREFIX/install.log || exit 1
)

# Get lua paths
setup_lua_env_cmd=$($PREFIX/bin/luarocks path)
eval "$setup_lua_env_cmd"

function build_rock {
    local _rock="$1"
    local _rock_spec="$2"
    set -ex
    [[ -d "${_bsd_}/${_rock}" ]] \
        || quit_with "failed to find rock ${_rock}"

    pushd "${_bsd_}/${_rock}"
    [[ -f "${_rock_spec}" ]] \
        || quit_with "failed to locate rock spec ${_rock_spec}"

    "${PREFIX}"/bin/luarocks make "${_rock_spec}"
    popd
    unset
}

set -ex

echo "Installing common Lua packages"
build_rock extra/luafilesystem \
           rockspecs/luafilesystem-1.6.3-1.rockspec
build_rock extra/penlight \
           penlight-scm-1.rockspec
build_rock extra/lua-cjson \
           lua-cjson-2.1devel-1.rockspec

echo "Installing core Torch packages"
build_rock extra/luaffifb \
           luaffi-scm-1.rockspec
build_rock pkg/sundown \
           rocks/sundown-scm-1.rockspec
build_rock pkg/cwrap \
           rocks/cwrap-scm-1.rockspec
build_rock pkg/paths \
           rocks/paths-scm-1.rockspec
build_rock pkg/torch \
           rocks/torch-scm-1.rockspec
build_rock pkg/dok \
           rocks/dok-scm-1.rockspec
build_rock exe/trepl \
           trepl-scm-1.rockspec
build_rock pkg/sys \
           sys-1.1-0.rockspec
build_rock pkg/xlua \
           xlua-1.0-0.rockspec
build_rock extra/moses \
           rockspec/moses-1.6.1-1.rockspec
build_rock extra/nn \
           rocks/nn-scm-1.rockspec
build_rock extra/graph \
           rocks/graph-scm-1.rockspec
build_rock extra/nngraph \
           nngraph-scm-1.rockspec
build_rock pkg/image \
           image-1.1.alpha-0.rockspec
build_rock pkg/optim \
           optim-1.0.5-0.rockspec

# CUDA
build_rock extra/cutorch \
           rocks/cutorch-scm-1.rockspec
build_rock extra/cunn \
           rocks/cunn-scm-1.rockspec

# # The version provided by `distro` is not up-to-date.
# build_rock extra/cudnn \
#            cudnn-scm-1.rockspec

# Optional packages
echo "Installing optional Torch packages"
build_rock exe/env \
           env-scm-1.rockspec
build_rock extra/threads \
           rocks/threads-scm-1.rockspec
build_rock extra/nnx \
           nnx-0.1-1.rockspec
build_rock extra/argcheck \
           rocks/argcheck-scm-1.rockspec

# In torch `distro`, the cudnn package is not pointing to the latest `R7` branch
echo "Building cudnn.torch for cudnn7 (branch R7)"
git clone https://github.com/soumith/cudnn.torch.git -b R7
build_rock cudnn.torch \
           cudnn-scm-1.rockspec
