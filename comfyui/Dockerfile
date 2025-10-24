FROM nvidia/cuda:12.1.1-base-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-pip git wget curl unzip && \
    rm -rf /var/lib/apt/lists/*

ENV APP_NAME=ComfyUI \
    APP_PATH=/workspace/Apps/ComfyUI \
    PYTHON_PATH=/workspace/Python/ComfyUI \
    SHARED_MODELS=/workspace/Shared/models \
    TOOLS_PATH=/workspace/tools \
    START_JUPYTER=true

# Shared tools and boot script
COPY tools /workspace/tools
COPY comfyui/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 8188 8888
CMD ["/bin/bash", "/opt/start.sh"]