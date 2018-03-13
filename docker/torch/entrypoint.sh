#!/bin/bash

USER_ID=${LOCAL_USER_ID:-9001}
TORCH_INSTALL_DIR=/home/drgscl/app/torch/distro/install
CONTAINER_DEFAULT_USER=drgscl

function isolate_host_user {
    # Due to some constraints, the new user might not be able to
    # overwrite files in the attached volumes.
    container_user=drgscl

    echo "Starting with UID : $USER_ID"
    useradd --shell /usr/bin/zsh -u $USER_ID -o -c "" -m "${container_user}"
    export HOME=/home/"${container_user}"
    chmod a+w /home/"${container_user}"
    chown "${container_user}" /home/"${container_user}"
}

container_user="${CONTAINER_DEFAULT_USER}"
# Does not seem to be relavent any more.
# isolate_host_user

# Setup environment customization
_zshrc_fname="/home/${container_user}/.zshrc"
touch "${_zshrc_fname}"

cat << _ZSHRC_HEADER_EOF_ >> "${_zshrc_fname}"
TORCH_INSTALL_DIR=${TORCH_INSTALL_DIR}
SPACK_ROOT=/home/drgscl/spack
_ZSHRC_HEADER_EOF_

cat << '_ZSHRC_EOF_' >> "${_zshrc_fname}"
print "[init] zsh ..."

# Load all installed packages
source ${SPACK_ROOT}/share/spack/setup-env.sh
spack load
print "[init] spack packages loaded"

# Customize packages we want to load for downstream images.
[[ -f '/home/drgscl/.zshrc.mod' ]] && source /home/drgscl/.zshrc.mod

# Torch environment
export PATH="${TORCH_INSTALL_DIR}/bin":"${PATH}"
eval "$(luarocks path)"
print "[init] torch installation loaded"

_ZSHRC_EOF_

ln -fn "${_zshrc_fname}" "/home/${container_user}/.bashrc"

# We need this to launch torch directly if the user so choose to.
export PATH="${TORCH_INSTALL_DIR}/bin":"${PATH}"
eval "$(luarocks path)"

if [[ -n "$@" ]]; then
    exec /usr/local/bin/gosu "${container_user}" /usr/bin/zsh -ic $@
else
    exec /usr/local/bin/gosu "${container_user}" /usr/bin/zsh
fi
