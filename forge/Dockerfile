FROM nvidia/cuda:12.1.1-base-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt

RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-pip git wget curl && \
    rm -rf /var/lib/apt/lists/*

ENV APP_NAME=Forge \
    APP_PATH=/workspace/Apps/Forge \
    PYTHON_PATH=/workspace/Python/Forge \
    SHARED_MODELS=/workspace/Shared/models \
    TOOLS_PATH=/workspace/tools \
    START_JUPYTER=true

# Copy shared tools and self-healing launcher
COPY tools /workspace/tools
COPY forge/start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

EXPOSE 7860 8889
CMD ["/bin/bash", "/opt/start.sh"]