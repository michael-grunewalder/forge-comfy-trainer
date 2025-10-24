FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-runtime-ubuntu22.04

WORKDIR /workspace

# system deps
RUN apt-get update && apt-get install -y \
    git wget unzip ffmpeg libgl1 libglib2.0-0 && \
    pip install --upgrade pip wheel setuptools && \
    pip install \
        accelerate \
        safetensors \
        einops \
        transformers \
        sentencepiece \
        timm \
        triton \
        xformers \
        flash-attn \
        torchsde \
        open-clip-torch \
        opencv-python-headless \
        pillow \
        tqdm && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 7860

ENTRYPOINT ["/start.sh"]
