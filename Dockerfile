# ===========================================================
# 🧠 Bearny's AI Lab - Dockerfile (FINAL, with python:3.10-slim base)
# ===========================================================

FROM python:3.10-slim AS base

# --- metadata & version info ---
ARG IMAGE_VERSION="v1.0.0-FUCK_GPT"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# --- system packages ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ffmpeg jq tini \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 python3-venv python3-dev build-essential \
 && rm -rf /var/lib/apt/lists/*

# --- build banner (keep your version echo) ---
RUN echo "🧩 Building SD Dev Image - ${APP_VERSION}"

# ===========================================================
# 🧠 Create venv & install minimal build-safe deps
# (torch, xformers, bitsandbytes installed later in start.sh)
# ===========================================================
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
        jupyterlab==4.2.5 \
        gradio==4.44.0 \
        fastapi \
        uvicorn \
        tqdm \
        pillow==10.2.0 \
        opencv-python \
        safetensors \
        einops \
        pycairo \
        numpy \
 && rm -rf /root/.cache/pip

# ===========================================================
# GPU-dependent libs (torch, torchvision, torchaudio, xformers,
# bitsandbytes, accelerate, tensorboard) are installed at runtime
# inside /workspace/venv in start.sh
# ===========================================================

# --- copy runtime startup script ---
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# --- working directory ---
WORKDIR /workspace

# --- metadata labels ---
LABEL org.opencontainers.image.title="Bearny's AI Lab" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.description="RunPod Forge + ComfyUI + JupyterLab unified environment" \
      org.opencontainers.image.created="${IMAGE_VERSION}"

# --- entrypoint & default command ---
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/start.sh"]
