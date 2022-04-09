FROM ubuntu:20.04
LABEL description="Base docker image with CUDA 10.0 and cuDNN 7.6 for developing and performing compute in containers on NVIDIA GPU."
LABEL maintainer="Vlad Klim, vladsklim@gmail.com"

USER root

# Packages versions
ENV CUDA_VERSION=10.0.130 \ 
    CUDA_PKG_VERSION=10-0=10.0.130-1 \
    NCCL_VERSION=2.4.8 \
    CUDNN_VERSION=7.6.5.32

# BASE
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*

# RUNTIME AND DEVEL CUDA
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends cuda-cudart-$CUDA_PKG_VERSION cuda-compat-10-0 \
                                               cuda-libraries-$CUDA_PKG_VERSION cuda-nvtx-$CUDA_PKG_VERSION libnccl2=$NCCL_VERSION-1+cuda10.0 \
                                               cuda-nvml-dev-$CUDA_PKG_VERSION cuda-command-line-tools-$CUDA_PKG_VERSION \
                                               cuda-libraries-dev-$CUDA_PKG_VERSION cuda-minimal-build-$CUDA_PKG_VERSION \
                                               libnccl-dev=$NCCL_VERSION-1+cuda10.0 && \
    ln -s cuda-10.0 /usr/local/cuda && \
    apt-mark hold libnccl2 && \
    rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs

# RUNTIME AND DEVEL CUDNN7
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libcudnn7=$CUDNN_VERSION-1+cuda10.0 libcudnn7-dev=$CUDNN_VERSION-1+cuda10.0 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    NVIDIA_REQUIRE_CUDA="cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=439,driver<441"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y git curl wget make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

RUN git clone https://github.com/pyenv/pyenv.git /root/.pyenv \
    && /root/.pyenv/bin/pyenv install 3.6.9 \
    && /root/.pyenv/bin/pyenv global 3.6.9

RUN git clone https://github.com/Tubaher/grapes_project.git /root/grapes_project \
    && cd /root/grapes_project \
    && /root/.pyenv/versions/3.6.9/bin/pip install -r requirements.txt \
    && rm -rf /root/grapes_project

ENV PATH /root/.pyenv/versions/3.6.9/bin:$PATH

CMD ["bash"]