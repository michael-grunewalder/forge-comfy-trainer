FROM nvidia/cuda:12.1.1-base-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-pip git wget curl unzip && \
    rm -rf /var/lib/apt/lists/*

ENV APP_PATH=/workspace/Apps/ComfyUI \
    PYTHON_PATH=/workspace/Python/ComfyUI \
    SHARED_MODELS=/workspace/Shared/models \
    TOOLS_PATH=/workspace/tools

RUN mkdir -p $APP_PATH $PYTHON_PATH $SHARED_MODELS $TOOLS_PATH

# copy shared tools (context is repo root via workflow)
COPY tools /workspace/tools

# copy module launcher from its folder (explicit path required)
COPY comfyui/start.sh /workspace/Apps/ComfyUI/start.sh
RUN chmod +x /workspace/Apps/ComfyUI/start.sh

EXPOSE 8188 8888
CMD ["/workspace/Apps/ComfyUI/start.sh"]