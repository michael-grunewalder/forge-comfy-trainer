FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 PYTHONUNBUFFERED=1
WORKDIR /opt

# OS deps (cv2 runtime, video, git, shell utils, tini for PID1)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    git curl wget unzip ca-certificates \
    ffmpeg libgl1 libglib2.0-0 \
    net-tools iproute2 procps tini \
 && rm -rf /var/lib/apt/lists/*

# Env layout (persistent volumes live under /workspace)
ENV APP_NAME=ComfyUI \
    APP_PATH=/workspace/Apps/ComfyUI \
    PY_PATH=/workspace/Python/ComfyUI \
    SHARED_MODELS=/workspace/Shared/models \
    TOOLS_PATH=/workspace/tools \
    START_JUPYTER=true

# Shared tools + fixed entrypoint script (kept outside /workspace to avoid masking)
COPY tools /workspace/tools
COPY comfyui/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 8188 8888

ENTRYPOINT ["/usr/bin/tini","-g","--"]
CMD ["/bin/bash","/opt/start.sh"]