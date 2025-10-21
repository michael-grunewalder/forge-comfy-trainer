FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/venv/bin:$PATH"
ENV JUPYTER_TOKEN=runpod

# ---------- Minimal system layer ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip git wget curl ca-certificates \
    libgl1-mesa-glx libglib2.0-0 ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# ---------- Virtual environment ----------
RUN python3 -m venv /venv && \
    pip install --upgrade pip wheel setuptools

# ---------- Core packages ----------
RUN pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121 && \
    pip install xformers==0.0.27

# ---------- Essential deps ----------
RUN pip install \
    jupyterlab notebook einops==0.7.0 opencv-python-headless==4.10.0.84 \
    numpy Pillow transformers==4.37.2 safetensors tqdm gradio==3.50.2

# ---------- Repo setup ----------
WORKDIR /workspace
RUN mkdir -p /workspace/shared/{models,outputs,logs,notebooks} && \
    git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge && \
    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git comfyui && \
    git clone --depth=1 https://github.com/bmaltais/kohya_ss.git train

# ---------- Start script ----------
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

ENV FORGE_PORT=7860 COMFY_PORT=8188 JUPYTER_PORT=8888
EXPOSE 7860 8188 8888

CMD ["bash", "/opt/start.sh"]
