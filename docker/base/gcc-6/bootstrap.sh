#!/bin/bash

drgscl_base=${HOME}/local/.drgscl
drgscl_install_dir=${drgscl_base}/cellar
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
#INSTALLER_PERL_VERSION=5.24.0

# Helper functions
function _lpp() {
    severity="$1"; shift 
    message="$@"
    timestamp="$(date -u "+%F %H:%M:%S %a (UTC)")"
    printf "${timestamp} [drgscl] @ ${severity}: ${message}\n"
}
function log_info() { _lpp "INFO" "$@"; }
function log_warn() { _lpp "WARNING" "$@"; }
function log_errs() { _lpp "ERROR" "$@"; exit; }
function quit_with() { log_info "$@"; exit; }

# Mimicking a human user
function _wisper_fetch() {
    local user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/601.5.17 (KHTML, like Gecko) Version/9.1 Safari/601.5.17"
    local header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    [[ $# -ge 1 ]] || quit_with "usage: _wisper_fetch <wget|curl> ..."
    local cmd=$1; shift
    
    case "${cmd}" in
        curl) 
            if ! which curl &>/dev/null; then
                curl -A "${user_agent}" "$@"
                return 0
            fi
            log_warn "cannot find curl, default to wget"
            ;;
        wget) 
            log_info "using wget"
            ;;
        \?) log_errs "do not recognize download command "
            return 1
            ;;
    esac
    
    wget --header="${header}" --user-agent="${user_agent}" "$@"
}

set -ex

# Bootstrap the whole building process
log_info "Prepareing local install directories under ${drgscl_base}"
mkdir -p "${drgscl_base}"
mkdir -p "${drgscl_install_dir}"

# First install linuxbrew and a few important packages
(mkdir -p ~/drgscl && cd $_
 [ -d build_scripts/ ] || git clone https://github.com/darthsuogles/build_scripts.git
)

export LINUXBREW_ROOT="${drgscl_install_dir}/linuxbrew/dev"
export PATH="${LINUXBREW_ROOT}/bin:${PATH}"
export CPATH="${LINUXBREW_ROOT}/include:${CPATH}"
export LD_LIBRARY_PATH="${LINUXBREW_ROOT}/lib:${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${LINUXBREW_ROOT}/lib/pkgconfig/${PKG_CONFIG_PATH}"

(mkdir -p "${drgscl_install_dir}/linuxbrew" && cd $_
 log_info "Building linuxbrew as a precursor to build"    
 [ -d dev/ ] || git clone https://github.com/Linuxbrew/linuxbrew.git dev
 cd dev && git pull && git submodule update --init --recursive
    
 export HOMEBREW_BUILD_FROM_SOURCE=yes 
 
 brew tap homebrew/dupes
 brew install zlib bzip2 xz snappy
 brew install readline
)

# Installing lua
lua_install_dir="${drgscl_install_dir}/lua/latest"
lua_version="NONE"
[ -d "${lua_install_dir}/" ] || (
    log_warn "Must install lua"
    mkdir -p "${drgscl_base}/pkg/lua" && cd "$_"
    
    lua_version=$(_wisper_fetch wget -O- http://www.lua.org/download.html 2>&1 | \
		              perl -ne 'print "$1\n" if /ftp\/lua-(\d+(\.\d+)+?)\.tar\.gz/' | \
                      sort -nr | uniq | head -n1)
    [[ -n "${lua_version}" ]] || log_errs "cannot find valid LUA version"
    lua_tarball="lua-${lua_version}.tar.gz"
    [[ -n "${lua_tarball}" ]] || log_errs "failed to parse lua downloading address"
    _wisper_fetch wget "http://www.lua.org/ftp/${lua_tarball}"
    [[ -f "${lua_tarball}" ]] || log_errs "failed to download lua ${lua_tarball}"

    log_info "Installing Lua"
    if [ ! -d "${lua_version}" ]; then
	    lua_extract_dir=$(tar -zxvf "${lua_tarball}" 2>&1 | sed 's@/.*@@' | uniq | perl -pe 's/^\s*x\s+//')
	    mv "${lua_extract_dir}" "${lua_version}"
	    [ -d "${lua_version}" ] || log_errs "cannot create extracted lua files"
    fi
    cd "${lua_version}"
    
	CPATH="${LINUXBREW_ROOT}/include:${CPATH}" LIBRARY_PATH="${LINUXBREW_ROOT}/lib:${LIBRARY_PATH}" make linux
    make install INSTALL_TOP="${drgscl_install_dir}/lua/${lua_version}"	
    ln -s "${drgscl_install_dir}/lua/${lua_version}" "${lua_install_dir}"
)
[ -d "${lua_install_dir}/" ] || log_errs "failed to install lua"
export PATH="${lua_install_dir}/bin:$PATH"

# Installing luarocks
luarocks_install_dir="${drgscl_install_dir}/luarocks/latest"
luarocks_version="NONE"
[ -d "${luarocks_install_dir}/" ] || (
    luarocks_dir="${drgscl_install_dir}/luarocks"
    mkdir "${drgscl_install_dir}/luarocks" && cd "$_"
    log_info "Installing Luarocks"
    
    luarocks_version=2.3.0
    luarocks_tarball=luarocks-${luarocks_version}.tar.gz
    [ -f "${luarocks_tarball}" ] || _wisper_fetch wget "http://luarocks.org/releases/${luarocks_tarball}"
    luarocks_extract_dir=$(
	    tar -zxvf "${luarocks_tarball}" 2>&1 | sed 's@/.*@@' | uniq | perl -pe 's/^\s*x\s+//')
    mv ${luarocks_extract_dir} ${luarocks_version}-src

    cd ${luarocks_version}-src
    ./configure --prefix="${luarocks_dir}/${luarocks_version}" \
		        --sysconfdir="${luarocks_dir}/${luarocks_version}/luarocks" \
		        --with-lua="${lua_install_dir}" \
		        --force-config
    make build && make install
    ln -s "${luarocks_dir}/${luarocks_version}" "${luarocks_install_dir}"        
)
[ -d "${luarocks_install_dir}/" ] || log_errs "failed to install luarocks"

# Configure luarocks so that lua can find it
export PATH="${luarocks_install_dir}/bin:${PATH}"
lua_version="$(basename "$(readlink "${lua_install_dir}")")"
lua_version_major="${lua_version%.*}"
export LUA_PATH="${luarocks_install_dir}/share/lua/${lua_version_major}/?.lua;${luarocks_install_dir}/share/lua/${lua_version_major}/?/init.lua;;"
export LUA_CPATH="${luarocks_install_dir}/lib/lua/${lua_version_major}/?.so;;"

# Installing required luarocks
for rock in "luasocket" "luaposix" "luafilesystem"; do
    [ -d "${luarocks_install_dir}/lib/luarocks/rocks/${rock}" ] && continue
    luarocks install "${rock}"
done

# Finally, installing the module file
log_info "Installing Lmod"
lmod_install_dir="${drgscl_install_dir}/Lmod/dev"

[ -d "${lmod_install_dir}/" ] || (cd ~/drgscl
    log_info "building Lmod from https://github.com/TACC/Lmod"
    [ -d Lmod/ ] || git clone https://github.com/TACC/Lmod.git
    cd Lmod
     
    ./configure --prefix="${lmod_install_dir}" \
	            --with-module-root-path="${script_dir}/modules" \
	            --with-spiderCacheDir="${drgscl_base}/modules/data/cacheDir" \
	            --with-updateSystemFn="${drgscl_base}/modules/data/system.txt" \
	            --with-tcl=no
    
    make && make install
)
[ -d "${lmod_install_dir}/" ] || log_errs "failed to install Lmod"

cat <<__EOF_ZSH__ > ${HOME}/.zshrc.lmod
export PATH=${lua_install_dir}/bin:${luarocks_install_dir}/bin:\$PATH
export LD_LIBRARY_PATH="${LINUXBREW_ROOT}/lib:${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${LINUXBREW_ROOT}/lib/pkgconfig/${PKG_CONFIG_PATH}"
export LUA_PATH="$LUA_PATH"
export LUA_CPATH="$LUA_CPATH"

export MODULEPATH=${HOME}/local/.drgscl/modulefiles
export LMOD_COLORIZE="YES"

source ${lmod_install_dir}/lmod/lmod/init/zsh
__EOF_ZSH__

cat <<__EOF_BASH__ > ${HOME}/.bashrc.lmod
export PATH=${lua_install_dir}/bin:${luarocks_install_dir}/bin:\$PATH
export LD_LIBRARY_PATH="${LINUXBREW_ROOT}/lib:${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${LINUXBREW_ROOT}/lib/pkgconfig/${PKG_CONFIG_PATH}"
export LUA_PATH="$LUA_PATH"
export LUA_CPATH="$LUA_CPATH"

export MODULEPATH=${HOME}/local/.drgscl/modulefiles
export LMOD_COLORIZE="YES"

source ${lmod_install_dir}/lmod/lmod/init/bash
__EOF_BASH__

if [ -f ${script_dir}/drgscl.sh ]; then (
    cd ${script_dir}
    chmod a+x ./drgscl.sh
    mkdir -p ./bin
    cp ./drgscl.sh ./bin/drgscl
    echo "export PATH=\${PATH}:${script_dir}/bin" >> ${HOME}/.zshrc.lmod
    echo "export PATH=\${PATH}:${script_dir}/bin" >> ${HOME}/.bashrc.lmod
) fi

