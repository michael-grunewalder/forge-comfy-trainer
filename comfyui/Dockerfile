FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-runtime-ubuntu22.04

WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    git wget unzip ffmpeg libgl1 libglib2.0-0 && \
    pip install --upgrade pip wheel setuptools && \
    pip install \
        numpy \
        pillow \
        tqdm \
        opencv-python-headless \
        xformers \
        triton \
        torchsde \
        safetensors \
        accelerate && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8188 8888
ENTRYPOINT ["/start.sh"]