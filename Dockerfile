# ===============================================================
# 🧠 Bearny's AI Lab – Custom RunPod Image
# Slim, version-tagged build; installs nothing heavy in image layer
# ===============================================================

FROM python:3.10-slim

# --- Version and environment metadata ---
ARG IMAGE_VERSION="v1.0.1"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    VENV_PATH=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

# --- Pretty banner at build time ---
RUN echo "==============================================================" && \
    echo " 🧩 Building SD Dev Image - ${APP_VERSION}" && \
    echo " Base Image: python:3.10-slim" && \
    echo "=============================================================="

WORKDIR /opt

# --- Minimal system dependencies ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates \
    ffmpeg libgl1 libglib2.0-0 libsm6 libxext6 python3-venv procps \
  && rm -rf /var/lib/apt/lists/*

# --- Workspace prep ---
WORKDIR /workspace
RUN mkdir -p /workspace/shared/logs /workspace/shared/models /workspace/shared/configs

# --- Copy startup script (runtime installer/launcher) ---
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# --- Banner at the end of image build ---
RUN echo "✅ Image Build Completed: ${APP_VERSION} ready for launch"

# --- Default entrypoint ---
CMD ["/opt/start.sh"]