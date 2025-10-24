FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

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
        open-clip-torch \
        opencv-python-headless \
        pillow \
        tqdm && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 7860

ENTRYPOINT ["/start.sh"]
