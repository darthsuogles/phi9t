#!/bin/bash

####################################
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_dir="${script_dir}"/torch-distro/install
lua_ver=5.1
####################################

function quit_with() { printf "Error: %s" "$@"; exit; }

if [ "$(basename ${script_dir})" != "torch-distro" ]; then
    [ -d "${script_dir}/torch-distro" ] || (
	cd ${script_dir}
	git submodule add https://github.com/darthsuogles/torch-distro.git torch-distro --recursive
	cd torch-distro && ./pkg_install.sh
    )
else
    install_dir=$PWD/install
fi
[ -d "${install_dir}" ] || quit_with "cannot find torch install directory"
    
lua_pkg_prefix="${install_dir}/share/lua/${lua_ver}"
export LUA_PATH="${lua_pkg_prefix}/\?.lua;${lua_pkg_prefix}/\?/init.lua;./\?.lua"

lua_dylib_prefix="${install_dir}/lib/lua/${lua_ver}"
export LUA_CPATH="${lua_dylib_dir}/\?.so;./\?.d"

export PATH="${install_dir}/bin:$PATH"
export LD_LIBRARY_PATH="${install_dir}/lib:$LD_LIBRARY_PATH"
export DYLD_LIBRARY_PATH="${install_dir}/lib:$DYLD_LIBRARY_PATH"
