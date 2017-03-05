#!/usr/bin/env bash

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX=${PREFIX:-"${_bsd_}/install"}
TORCH_LUA_VERSION=${TORCH_LUA_VERSION:-"LUAJIT21"}

source /home/drgscl/.bashrc.lmod
module load linuxbrew

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

echo "Prefix set to $PREFIX"
export CMAKE_PREFIX_PATH=$PREFIX

git submodule update --init --recursive

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
	    install_name_tool -id ${PREFIX}/lib/libluajit.so ${PREFIX}/lib/libluajit.so
    else
	    install_name_tool -id ${PREFIX}/lib/liblua.so ${PREFIX}/lib/liblua.so
    fi
fi

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

# Optional packages
echo "Installing optional Torch packages"
build_rock exe/env \
           env-scm-1.rockspec
build_rock extra/threads \
           rocks/threads-scm-1.rockspec
build_rock extra/argcheck \
           rocks/argcheck-scm-1.rockspec
