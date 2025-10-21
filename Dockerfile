# ---------- Base ----------
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG JUPYTER_TOKEN=runpod
ENV JUPYTER_TOKEN=${JUPYTER_TOKEN}

# ---------- System deps ----------
RUN apt-get update && apt-get install -y \
    git wget curl vim nano htop unzip \
    pkg-config libcairo2-dev libpango1.0-dev libffi-dev \
    libjpeg-dev libpng-dev libglib2.0-dev libsm6 libxext6 libxrender1 \
    python3 python3-venv python3-pip python3-dev \
    && rm -rf /var/lib/apt/lists/*

# ---------- Python env ----------
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN pip install --upgrade pip wheel setuptools \
    && pip install jupyterlab notebook tensorboard

# ---------- PyTorch + Xformers ----------
RUN pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121 \
    && pip install xformers==0.0.27

# ---------- Common AI deps ----------
RUN pip install \
    gradio==3.50.2 fastapi==0.103.2 uvicorn==0.23.2 \
    basicsr==1.4.2 gfpgan==1.3.8 realesrgan==0.3.0 \
    numpy==1.26.4 Pillow==10.3.0 accelerate safetensors bitsandbytes==0.45.3 \
    transformers==4.37.2 datasets peft sentencepiece protobuf tqdm

# ---------- Forge ----------
WORKDIR /workspace
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge

# ---------- ComfyUI ----------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git comfyui

# ---------- kohya_ss trainer ----------
RUN git clone https://github.com/bmaltais/kohya_ss.git train

# ---------- Cleanup & defaults ----------
RUN mkdir -p /workspace/shared/{models,outputs,logs,notebooks}

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh
WORKDIR /workspace
ENTRYPOINT ["/opt/start.sh"]
