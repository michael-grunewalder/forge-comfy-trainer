# ---------- Base ----------
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------- System deps ----------
RUN apt-get update && apt-get install -y \
    git wget curl python3 python3-pip python3-venv ffmpeg libgl1 libglib2.0-0 libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# ---------- Python environment ----------
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip install --upgrade pip wheel setuptools

# ---------- Core tools ----------
RUN pip install jupyterlab notebook tensorboard

# ---------- Clone Forge ----------
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge
WORKDIR /workspace/forge
RUN pip install -r requirements.txt && pip install xformers==0.0.27 triton==2.3.0

# ---------- Clone ComfyUI ----------
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui
WORKDIR /workspace/comfyui
RUN pip install -r requirements.txt || true

# ---------- Clone kohya_ss ----------
WORKDIR /workspace
RUN git clone https://github.com/bmaltais/kohya_ss.git train
WORKDIR /workspace/train
RUN pip install -r requirements.txt
RUN pip install accelerate safetensors bitsandbytes==0.43.1

# ---------- Environment vars ----------
ENV COMFYUI_PATH=/workspace/comfyui
ENV FORGE_PATH=/workspace/forge
ENV TRAIN_PATH=/workspace/train
ENV MODEL_DIR=/workspace/models
ENV JUPYTER_TOKEN="runpod"

# ---------- Copy startup script ----------
WORKDIR /workspace
COPY start.sh /start.sh
RUN chmod +x /start.sh

# ---------- Expose ports ----------
EXPOSE 7860 8188 6006 8888

ENTRYPOINT ["/bin/bash", "/start.sh"]
