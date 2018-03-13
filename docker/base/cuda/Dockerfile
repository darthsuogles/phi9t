FROM nvidia/cuda:9.0-base-ubuntu16.04
MAINTAINER philip phissenschaft@gmail.com

RUN echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf > /dev/null

# Copied from TensorFlow's cuda development docker
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-9-0 \
        cuda-cublas-dev-9-0 \
        cuda-cudart-dev-9-0 \
        cuda-cufft-dev-9-0 \
        cuda-curand-dev-9-0 \
        cuda-cusolver-dev-9-0 \
        cuda-cusparse-dev-9-0 \
        curl \
        git \
        libcudnn7=7.0.5.15-1+cuda9.0 \
        libcudnn7-dev=7.0.5.15-1+cuda9.0 \
        libcurl3-dev \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        zsh \
        && \
    rm -rf /var/lib/apt/lists/* && \
    find /usr/local/cuda-9.0/lib64/ -type f -name 'lib*_static.a' -not -name 'libcudart_static.a' -delete && \
    rm /usr/lib/x86_64-linux-gnu/libcudnn_static_v7.a

# Add user
RUN useradd -ms /usr/bin/zsh drgscl && echo "drgscl:amisabc" | chpasswd && adduser drgscl sudo

# Please refrain from enabling this
# ENV DEBIAN_FRONTEND noninteractive

# Entering the user-space
USER drgscl
ENV HOME /home/drgscl
RUN touch ${HOME}/.zshrc

CMD [ '/usr/bin/zsh' ]
