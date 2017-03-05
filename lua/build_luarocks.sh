#!/bin/bash

ver=2.4.1
tarball="luarocks-${ver}.tar.gz"
install_dir="${PWD}/install"

lua_root="$(brew --prefix luajit)"
lua_bin=luajit
lua_ver=2.1.0-beta2

ln -sfn "${lua_root}/bin/${lua_bin}" "${lua_root}/bin/lua"

[[ -d build-tree ]] || (
    mkdir -p build-tree && cd $_
    [[ -f "${tarball}" ]] || \
        wget "https://luarocks.org/releases/${tarball}"
    mkdir -p "luarocks-${ver}" && \
        tar -C "$_" --strip-components 1 -zxf "${tarball}"
)

(cd "build-tree/luarocks-${ver}"
 ./configure --prefix="${install_dir}/${lua_bin}/${lua_ver}" \
		     --sysconfdir="${install_dir}/${lua_bin}/${lua_ver}/luarocks" \
		     --with-lua-bin="${lua_root}/bin" \
             --with-lua-include="${lua_root}/include/luajit-2.1" \
		     --force-config
 make build && make install
)
