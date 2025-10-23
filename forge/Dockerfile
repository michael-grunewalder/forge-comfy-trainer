FROM nvidia/cuda:12.1.1-base-ubuntu22.04
WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-pip git wget curl && \
    rm -rf /var/lib/apt/lists/*

ENV APP_PATH=/workspace/Apps/Forge \
    PYTHON_PATH=/workspace/Python/Forge \
    SHARED_MODELS=/workspace/Shared/models

RUN mkdir -p $APP_PATH $PYTHON_PATH $SHARED_MODELS

COPY start.sh /workspace/Apps/Forge/start.sh
RUN chmod +x /workspace/Apps/Forge/start.sh

EXPOSE 7860 8889
CMD ["/workspace/Apps/Forge/start.sh"]
