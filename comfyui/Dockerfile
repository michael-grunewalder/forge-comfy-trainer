FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

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