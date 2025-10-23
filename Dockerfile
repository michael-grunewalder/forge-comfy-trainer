# ===========================================================
# 🧠  Bearny's AI Lab - RunPod Image
# Slim base, installs Python + CUDA via PyTorch wheels
# ===========================================================
ARG IMAGE_VERSION="v1.1.0"
FROM python:3.10-slim AS base

LABEL maintainer="Michael Grunewalder"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PATH="/opt/venv/bin:$PATH"

# -----------------------------------------------------------
# 🔧 Base OS setup
# -----------------------------------------------------------
RUN echo "🧩 Building SD Dev Image - ${APP_VERSION}" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git wget curl ca-certificates \
        ffmpeg libsm6 libxext6 libgl1 \
        tini bash jq git-lfs vim \
        build-essential pkg-config && \
    git lfs install && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------
# 🧱 Create basic structure
# -----------------------------------------------------------
WORKDIR /opt
RUN mkdir -p /workspace/shared /workspace/tools /workspace/apps /workspace/venv

# -----------------------------------------------------------
# 🐍 Install minimal Python deps
# -----------------------------------------------------------
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir xformers==0.0.27.post2 \
        jupyterlab==4.2.5 gradio==4.44.0 fastapi uvicorn \
        opencv-python pillow==10.2.0 tqdm safetensors accelerate==0.34.2 \
        bitsandbytes==0.45.3 einops pycairo tensorboard==2.17.1 && \
    rm -rf /root/.cache/pip

# -----------------------------------------------------------
# 🧩 Copy startup script
# -----------------------------------------------------------
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# -----------------------------------------------------------
# 🧩 Environment defaults
# -----------------------------------------------------------
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV FORCE_CUDA=1
ENV TORCH_CUDA_ARCH_LIST="8.6 8.9"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# -----------------------------------------------------------
# 🧩 Volume Mounts
# -----------------------------------------------------------
VOLUME ["/workspace"]

# -----------------------------------------------------------
# 🧩 Entrypoint
# -----------------------------------------------------------
ENTRYPOINT ["/usr/bin/tini", "--", "/opt/start.sh"]

# -----------------------------------------------------------
# 🧠 Final info
# -----------------------------------------------------------
RUN echo "✅ Bearny's AI Lab Docker image ready (v${APP_VERSION})"
