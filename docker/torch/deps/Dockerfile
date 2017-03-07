from toolchain:gcc-6
MAINTAINER philip phissenschaft@gmail.com

USER drgscl

RUN source /home/drgscl/.bashrc.lmod && module load linuxbrew \
    && (brew update || echo "okay") \
    && (brew upgrade || echo "okay")

RUN source /home/drgscl/.bashrc.lmod && module load linuxbrew \
    && brew install git wget openssl

RUN source /home/drgscl/.bashrc.lmod && module load linuxbrew \
    && brew install libjpeg readline

RUN source /home/drgscl/.bashrc.lmod && module load linuxbrew \
    && brew install python \
    && pip2 install --upgrade pip setuptools wheel \
    && brew install cmake

RUN source /home/drgscl/.bashrc.lmod && module load linuxbrew \
    && brew tap homebrew/science \
    && brew install openblas openmpi \
    && brew install fftw --with-fortran --with-openmp --with-mpi

ENTRYPOINT ["/bin/bash"]
