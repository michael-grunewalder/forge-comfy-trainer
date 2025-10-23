# ===============================================================
# 🧠 Bearny's AI Lab – Persistent RunPod Environment
# With version tagging and runtime installer on /workspace
# ===============================================================

FROM python:3.10-slim

ARG IMAGE_VERSION="v1.0.2"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    VENV_PATH=/workspace/venv \
    PATH="/workspace/venv/bin:$PATH"

RUN echo "==============================================================" && \
    echo " 🧩 Building SD Dev Image - ${APP_VERSION}" && \
    echo " Base Image: python:3.10-slim" && \
    echo "=============================================================="

# --- Core system dependencies ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates ffmpeg \
    libgl1 libglib2.0-0 libsm6 libxext6 python3-venv procps \
    && rm -rf /var/lib/apt/lists/*

# --- Workspace setup ---
WORKDIR /workspace
RUN mkdir -p /workspace/shared/logs /workspace/shared/models /workspace/shared/configs

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

CMD ["/opt/start.sh"]