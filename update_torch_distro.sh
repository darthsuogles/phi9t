#!/bin/bash

####################################
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_dir="${script_dir}"/torch-distro/install
lua_ver=5.1
####################################

function _log_msg() {
    [[ $# -ge 2 ]] || return
    local log_type="$1"; shift    
    >&2 echo "[${log_type}]: $@"
}
function log_info() { _log_msg "INFO" $@; }
function log_warn() { _log_msg "WARNING" $@; }
function log_error() { _log_msg "ERROR" $@; exit; }
function quit_with() { _log_msg "QUIT" $@; exit; }


[ "${NO_INSTALL}" == "yes" ] || (
    if [ "$(basename ${script_dir})" != "torch-distro" ]; then
	[ -d "${script_dir}/torch-distro" ] || \
	    git submodule add https://github.com/darthsuogles/torch-distro.git torch-distro --recursive
	cd "${script_dir}/torch-distro"	
    else
	log_warn "(deprecated) running inside the torch-distro directory"
	install_dir=$PWD/install
    fi

    log_info "updating packages"
    git remote remove forigink
    git remote add forigink https://github.com/torch/distro.git
    git pull forigink --rebase
    git submodule update
    git submodule foreach git pull origin master
    ./pkg_install.sh
)
[ -d "${install_dir}" ] || quit_with "cannot find torch install directory"

cat <<EOF
>> Done!
Exporting data to external environment variable file
--------------------------------------------
source ${script_dir}/envar_torch.sh"
--------------------------------------------
EOF

lua_pkg_prefix="${install_dir}/share/lua/${lua_ver}"
lua_dylib_prefix="${install_dir}/lib/lua/${lua_ver}"

cat <<EOF > ${script_dir}/envar_torch.sh
# Automatically generated 
export LUA_PATH="${lua_pkg_prefix}/\?.lua;${lua_pkg_prefix}/\?/init.lua;./\?.lua"
export LUA_CPATH="${lua_dylib_dir}/\?.so;./\?.d"
export PATH="${install_dir}/bin:$PATH"
export LD_LIBRARY_PATH="${install_dir}/lib:$LD_LIBRARY_PATH"
export DYLD_LIBRARY_PATH="${install_dir}/lib:$DYLD_LIBRARY_PATH"
EOF
