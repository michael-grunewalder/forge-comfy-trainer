FROM nvidia/cuda:12.1.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 PYTHONUNBUFFERED=1
WORKDIR /opt

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    git curl wget ca-certificates \
    ffmpeg libgl1 libglib2.0-0 \
    build-essential pkg-config \
    net-tools iproute2 procps tini \
 && rm -rf /var/lib/apt/lists/*

# WICHTIGE ANPASSUNGEN (SDXL-Optimierungen in FORGE_ARGS)
ENV APP_NAME=Forge \
    APP_PATH=/workspace/Apps/Forge \
    PY_PATH=/workspace/Python/Forge \
    SHARED_MODELS=/workspace/Shared/modules \
    TOOLS_PATH=/workspace/tools \
    START_JUPYTER=true \
    # SDXL-Optimierte Argumente für Stabilität (gegen NaN- und OOM-Fehler):
    FORGE_ARGS="--medvram --no-half-vae --upcast-sampling --opt-sdp-attention --disable-nan-check"

COPY tools /workspace/tools
COPY forge/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 7860 8889

ENTRYPOINT ["/usr/bin/tini","-g","--"]
CMD ["/bin/bash","/opt/start.sh"]