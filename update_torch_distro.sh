#!/bin/bash

####################################
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_dir="${script_dir}"/distro/install
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

cd "${script_dir}"

[ -d distro ] || git clone https://github.com/torch/distro.git

# (cd distro
#  log_info "updating packages"
#  module load linuxbrew
#  ./install.sh <<EOF
# no
# EOF
# )

cat <<EOF
>> Done!
Exporting data to external environment variable file
--------------------------------------------
source ${script_dir}/envar_torch.sh"
--------------------------------------------
EOF

lua_pkg_prefix="${install_dir}/share/lua/${lua_ver}"
lua_lib_prefix="${install_dir}/lib/lua/${lua_ver}"

source ~/drgscl/build_scripts/gen_modules.sh 
export LUA_MODFILE_PKG_INSTALL_DIR="${install_dir}"
guess_print_lua_modfile torch distro https://github.com/torch/distro.git

cat <<EOF > ${script_dir}/envar_torch.sh
# Automatically generated 
export LUA_PATH="${lua_pkg_prefix}/\?.lua;${lua_pkg_prefix}/\?/init.lua;./\?.lua"
export LUA_CPATH="${lua_lib_prefix}/\?.so;./\?.d"
export PATH="${install_dir}/bin:$PATH"
export LD_LIBRARY_PATH="${install_dir}/lib:$LD_LIBRARY_PATH"
EOF
