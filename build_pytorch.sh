#!/bin/bash

pushd pytorch

git fetch --all && git rebase origin/master
MACOSX_DEPLOYMENT_TARGET=10.12 NO_CUDA=1 python3 setup.py install

popd

