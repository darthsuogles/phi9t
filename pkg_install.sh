#!/usr/bin/env bash

THIS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PREFIX=${PREFIX:-"${THIS_DIR}/install"}
BATCH_INSTALL=1
SKIP_RC=1
TORCH_LUA_VERSION=${TORCH_LUA_VERSION:-"LUAJIT21"}

function help {
    cat << _HELP_EOF_
usage: $0
This script will install Torch and related, useful packages into $PREFIX.

  -b      Run without requesting any user input (will automatically add PATH to shell profile)


_HELP_EOF_
}

while getopts 'bshc' cmd_args; do
    case "${cmd_args}" in
        h) help; exit 2
           ;;
        b) BATCH_INSTALL=1
           ;;
	    c) USE_LLVM38=1
	       ;;
        s) SKIP_RC=1
           ;;
    esac
done

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "${OS}" == "darwin" ]; then
    echo "OSX detected, using llvm/clang"
fi
echo "Prefix set to $PREFIX"
git submodule update --init --recursive

if [ "${OS}" == "darwin" ]; then
    echo "Using homebrew to install dependencies"

    brew install git readline cmake wget
    brew link readline --force
    brew install libjpeg zeromq openssl
    brew tap homebrew/science
    brew install openblas
    brew install fftw --with-fortran --with-openmp --with-mpi
    brew install sox
fi

echo "Installing LuaJIT version: ${TORCH_LUA_VERSION}"
mkdir -p install
mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_${TORCH_LUA_VERSION}=ON 2>&1 >>$PREFIX/install.log || exit 1
make 2>&1 | tee $PREFIX/install.log || exit 1
make install 2>&1 | tee $PREFIX/install.log || exit 1
cd ..

# check if we are on mac and fix RPATH for local install
path_to_install_name_tool=$(which install_name_tool 2>/dev/null)
if [ -x "$path_to_install_name_tool" ]; then
    if [ ${TORCH_LUA_VERSION} == "LUAJIT21" ] || [ ${TORCH_LUA_VERSION} == "LUAJIT20" ]; then
	    install_name_tool -id ${PREFIX}/lib/libluajit.dylib ${PREFIX}/lib/libluajit.dylib
    else
	install_name_tool -id ${PREFIX}/lib/liblua.dylib ${PREFIX}/lib/liblua.dylib
    fi
fi

setup_lua_env_cmd=$($PREFIX/bin/luarocks path)
eval "$setup_lua_env_cmd"

set -ex

echo "Installing common Lua packages"
cd ${THIS_DIR}/extra/luafilesystem \
    && $PREFIX/bin/luarocks make rockspecs/luafilesystem-1.6.3-1.rockspec || exit 1
cd ${THIS_DIR}/extra/penlight \
    && $PREFIX/bin/luarocks make penlight-scm-1.rockspec || exit 1
cd ${THIS_DIR}/extra/lua-cjson \
    && $PREFIX/bin/luarocks make lua-cjson-2.1devel-1.rockspec || exit 1

echo "Installing core Torch packages"
cd ${THIS_DIR}/extra/luaffifb && $PREFIX/bin/luarocks make luaffi-scm-1.rockspec       || exit 1
cd ${THIS_DIR}/pkg/sundown   && $PREFIX/bin/luarocks make rocks/sundown-scm-1.rockspec || exit 1
cd ${THIS_DIR}/pkg/cwrap     && $PREFIX/bin/luarocks make rocks/cwrap-scm-1.rockspec   || exit 1
cd ${THIS_DIR}/pkg/paths     && $PREFIX/bin/luarocks make rocks/paths-scm-1.rockspec   || exit 1
cd ${THIS_DIR}/pkg/torch     && $PREFIX/bin/luarocks make rocks/torch-scm-1.rockspec   || exit 1
cd ${THIS_DIR}/pkg/dok       && $PREFIX/bin/luarocks make rocks/dok-scm-1.rockspec     || exit 1
cd ${THIS_DIR}/exe/trepl     && $PREFIX/bin/luarocks make trepl-scm-1.rockspec         || exit 1
cd ${THIS_DIR}/pkg/sys       && $PREFIX/bin/luarocks make sys-1.1-0.rockspec           || exit 1
cd ${THIS_DIR}/pkg/xlua      && $PREFIX/bin/luarocks make xlua-1.0-0.rockspec          || exit 1
cd ${THIS_DIR}/extra/nn      && $PREFIX/bin/luarocks make rocks/nn-scm-1.rockspec      || exit 1
cd ${THIS_DIR}/extra/graph   && $PREFIX/bin/luarocks make rocks/graph-scm-1.rockspec   || exit 1
cd ${THIS_DIR}/extra/nngraph && $PREFIX/bin/luarocks make nngraph-scm-1.rockspec       || exit 1
cd ${THIS_DIR}/pkg/image     && $PREFIX/bin/luarocks make image-1.1.alpha-0.rockspec   || exit 1
cd ${THIS_DIR}/pkg/optim     && $PREFIX/bin/luarocks make optim-1.0.5-0.rockspec       || exit 1

# Optional packages
echo "Installing optional Torch packages"
cd ${THIS_DIR}/exe/env              && $PREFIX/bin/luarocks make env-scm-1.rockspec
cd ${THIS_DIR}/extra/threads        && $PREFIX/bin/luarocks make rocks/threads-scm-1.rockspec
cd ${THIS_DIR}/extra/argcheck       && $PREFIX/bin/luarocks make rocks/argcheck-scm-1.rockspec
