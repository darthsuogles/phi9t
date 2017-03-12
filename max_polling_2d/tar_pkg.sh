#!/bin/bash

script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
(
    pkg=$(basename ${script_dir})
    cd "${script_dir}"
    fnm_list=($(for fnm in $(git ls-tree -r master --name-only); do echo "${pkg}/${fnm}"; done | tr '\n' ' '))
    cd ..
    tar -Jcvf "${pkg}.tbz2" ${fnm_list[@]}
)
