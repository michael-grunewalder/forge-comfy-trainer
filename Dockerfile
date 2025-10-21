FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_NO_CACHE_DIR=1
ARG JUPYTER_TOKEN=runpod
ENV JUPYTER_TOKEN=${JUPYTER_TOKEN}

# System deps
RUN apt-get update && apt-get install -y \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Python utilities
RUN pip install --upgrade pip wheel setuptools \
    && pip install jupyterlab notebook tensorboard

# Torch + Xformers (CUDA 12.1 wheels that actually exist)
RUN pip install torch==2.3.1+cu121 torchvision==0.18.1+cu121 torchaudio==2.3.1+cu121 \
    --index-url https://download.pytorch.org/whl/cu121 \
    && pip install xformers==0.0.27

# Common AI + web deps (pinned and compatible with Py3.10)
RUN pip install \
    gradio==3.50.2 fastapi==0.103.2 uvicorn==0.23.2 \
    basicsr==1.4.2 gfpgan==1.3.8 realesrgan==0.3.0 \
    numpy==1.26.4 Pillow==10.3.0 accelerate safetensors bitsandbytes==0.41.3 \
    transformers==4.37.2 datasets peft sentencepiece protobuf tqdm

# Forge
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge

# ComfyUI
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui
WORKDIR /workspace/comfyui
RUN pip install -r requirements.txt || true

# Kohya (training)
WORKDIR /workspace
RUN git clone https://github.com/bmaltais/kohya_ss.git train
WORKDIR /workspace/train
# Install only the needed python deps; skip kohya’s broken local path line
RUN pip install accelerate safetensors bitsandbytes==0.41.3 transformers datasets peft tensorboard \
    sentencepiece protobuf tqdm

# Env
ENV COMFYUI_PATH=/workspace/comfyui
ENV FORGE_PATH=/workspace/forge
ENV TRAIN_PATH=/workspace/train
ENV MODEL_DIR=/workspace/models

# Startup
WORKDIR /workspace
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 7860 8188 6006 8888
HEALTHCHECK CMD curl -f http://localhost:7860 || exit 1
ENTRYPOINT ["/bin/bash", "/start.sh"]