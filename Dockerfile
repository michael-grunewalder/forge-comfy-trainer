# ===========================================================
# 🧠 Bearny's AI Lab - Dockerfile (fixed version)
# ===========================================================

FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

# --- metadata & build variables ---
ARG IMAGE_VERSION="v1.1.0-cuda"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# --- basic system setup ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip python3-dev git wget curl ffmpeg jq \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 tini \
 && rm -rf /var/lib/apt/lists/*

# --- print version info during build ---
RUN echo "🧩 Building SD Dev Image - ${APP_VERSION}"

# --- create venv ---
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# ===========================================================
# IMPORTANT:
# Do NOT install torch/xformers/bitsandbytes here.
# These depend on runtime CUDA libraries which are only
# available inside the RunPod container environment.
# ===========================================================

# --- lightweight base Python deps ---
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
        jupyterlab==4.2.5 \
        gradio==4.44.0 \
        fastapi uvicorn tqdm pillow==10.2.0 \
        opencv-python safetensors pycairo \
        tensorboard==2.17.1 einops && \
    rm -rf /root/.cache/pip

# --- copy runtime scripts ---
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# --- working directory ---
WORKDIR /workspace

# --- labels for traceability ---
LABEL org.opencontainers.image.title="Bearny's AI Lab" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.description="RunPod template for Forge UI + ComfyUI + JupyterLab" \
      org.opencontainers.image.created="${IMAGE_VERSION}"

# --- entrypoint ---
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/start.sh"]