# syntax=docker/dockerfile:1
FROM python:3.10-slim

ARG IMAGE_VERSION="v1.0.5"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH \
    HF_HOME=/workspace/shared/huggingface

# OS deps (GL, Cairo, codecs, bash, terminal libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl wget ca-certificates \
    ffmpeg build-essential pkg-config \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    libcairo2 libcairo2-dev libpango-1.0-0 libpangocairo-1.0-0 \
    libfontconfig1 libfreetype6 libjpeg62-turbo zlib1g \
    libsndfile1 bash libncurses6 libtinfo6 \
 && rm -rf /var/lib/apt/lists/* && git lfs install

# Shared dirs
RUN mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints} && \
    mkdir -p /workspace/shared/models/{checkpoints,loras,vae,clip,clip_vision,controlnet,upscale_models,embeddings} && \
    mkdir -p /workspace/shared/outputs/{forge,comfyui,kohya} && \
    mkdir -p /workspace/shared/logs/{forge,comfyui,jupyter,kohya} && \
    mkdir -p /workspace/notebooks

WORKDIR /opt

# Apps (shallow)
RUN git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge && \
    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git ComfyUI && \
    git clone --depth=1 https://github.com/bmaltais/kohya_ss.git kohya_ss

# Python env
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --upgrade pip setuptools wheel

# PyTorch CUDA 12.1 + xformers (works per your log: torch 2.4.1+cu121, xformers 0.0.27.post2)
RUN pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch==2.4.1+cu121 torchvision==0.19.1+cu121 torchaudio==2.4.1+cu121 && \
    pip install xformers==0.0.27.post2

# Core deps (headless OpenCV to stay <3GB)
RUN pip install --no-cache-dir \
      fastapi uvicorn einops opencv-python-headless safetensors transformers \
      accelerate==0.33.0 pillow==10.2.0 tqdm jupyterlab==4.2.5 tensorboard==2.17.1 terminado==0.18.0

# bnb prebuilt wheel (aligns with your log; if no wheel, continue build)
RUN pip install --no-cache-dir --prefer-binary bitsandbytes==0.45.3 || true

# Quiet Forge warnings
RUN pip install insightface onnxruntime mediapipe fvcore svglib || true

# App reqs (best-effort; upstream changes shouldn’t break image)
RUN if [ -f /opt/forge/requirements_versions.txt ]; then \
      pip install -r /opt/forge/requirements_versions.txt || true ; \
    elif [ -f /opt/forge/requirements.txt ]; then \
      pip install -r /opt/forge/requirements.txt || true ; \
    fi \
 && pip install -r /opt/ComfyUI/requirements.txt || true \
 && pip install -r /opt/kohya_ss/requirements.txt || true

EXPOSE 7860 8188 8888

# Build banner
RUN echo "🧩 Building SD Dev Image - ${APP_VERSION}"

# Start script
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

CMD ["/opt/start.sh"]