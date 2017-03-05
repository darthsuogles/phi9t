#!/bin/bash

source /home/drgscl/.bashrc.lmod
module load linuxbrew

brew update
brew upgrade

echo "Using homebrew to install dependencies"
brew install git perl wget
brew install readline && brew link readline --force
brew install libjpeg zeromq openssl

brew install python 
pip2 install --upgrade pip setuptools wheel
brew install python3
pip3 install --upgrade pip setuptools wheel
brew install cmake

brew tap homebrew/science
brew install openblas
brew install fftw --with-fortran --with-openmp --with-mpi
brew install sox
