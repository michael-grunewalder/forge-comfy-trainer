FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime
#FROM nvidia/cuda:12.1.1-base-ubuntu22.04

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

ENV APP_NAME=Trainer \
    APP_PATH=/workspace/Apps/Trainer \
    PY_PATH=/workspace/Python/Trainer \
    SHARED_MODELS=/workspace/Shared/models \
    TOOLS_PATH=/workspace/tools \
    START_JUPYTER=true

COPY tools /workspace/tools
COPY trainer/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 7861 8890

ENTRYPOINT ["/usr/bin/tini","-g","--"]
CMD ["/bin/bash","/opt/start.sh"]