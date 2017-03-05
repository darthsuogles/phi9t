#!/bin/bash

USER_ID=${LOCAL_USER_ID:-9001}
container_user=phi9t

echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m "${container_user}"
export HOME=/home/"${container_user}"
chmod a+w /home/"${container_user}"
chown "${container_user}" /home/"${container_user}"

source /home/drgscl/.bashrc.lmod 
module load linuxbrew

exec /usr/local/bin/gosu "${container_user}" /bin/bash "$@"
