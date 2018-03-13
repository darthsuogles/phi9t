FROM ubuntu:latest
MAINTAINER philip phissenschaft@gmail.com

RUN echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf > /dev/null

RUN apt-get -y update && apt-get install -y \
    autoconf \
    autotools-dev \
    libtool \
    build-essential \
    curl \
    wget \
    git \
    bc \
    ed \
    make \
    ruby \
    unzip \
    libcurl4-openssl-dev \
    software-properties-common \
    python-software-properties \
    sudo

# Add user
RUN useradd -ms /bin/bash drgscl && echo "drgscl:amisabc" | chpasswd && adduser drgscl sudo

# Some locale issues for perl and co.
RUN apt-get update \
    && apt-get install -y locales \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN locale-gen "en_US.UTF-8" && dpkg-reconfigure locales
ENV LANG en_US.utf8
ENV LC_CTYPE en_US.utf8
ENV LC_ALL en_US.utf8

# Please refrain from enabling this
# ENV DEBIAN_FRONTEND noninteractive

# Update toolchain
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get -y update && apt-get install -y gcc-6 g++-6 gfortran-6 \
    && update-alternatives --install \
	                /usr/bin/gcc gcc /usr/bin/gcc-6 90 \
	                --slave /usr/bin/g++ g++ /usr/bin/g++-6 \
	                --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-6 \
                    && [ -e /usr/bin/cc ] || ln -s /usr/bin/gcc /usr/bin/cc

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Entering the user-space
USER drgscl
ENV HOME /home/drgscl

# Build infra bootstrapping
COPY bootstrap.sh /home/drgscl
WORKDIR /home/drgscl
RUN ./bootstrap.sh
RUN echo "source /home/drgscl/.bashrc.lmod" >> /home/drgscl/.bashrc

WORKDIR /home/drgscl/drgscl/build_scripts/linuxbrew
RUN git pull && ./build_linuxbrew.sh
RUN echo "module load linuxbrew" >> /home/drgscl/.bashrc

WORKDIR /home/drgscl
RUN rm -fr /home/drgscl/local/.drgscl/__build

CMD ['/bin/bash']
