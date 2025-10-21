# ---------- Base ----------
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG JUPYTER_TOKEN=runpod
ENV JUPYTER_TOKEN=${JUPYTER_TOKEN}

# ---------- System dependencies ----------
# - cairo + pkg-config fix pycairo/svglib
# - libgl/libx* fix OpenCV runtime
# - aria2/ffmpeg useful for downloads and media
RUN apt-get update && apt-get install -y \
    git wget curl aria2 ffmpeg \
    ca-certificates pkg-config \
    libcairo2-dev libpango1.0-dev libffi-dev \
    libjpeg-dev libpng-dev \
    libglib2.0-0 libsm6 libxext6 libxrender1 libgl1-mesa-glx \
    python3 python3-venv python3-pip python3-dev \
 && rm -rf /var/lib/apt/lists/*

# ---------- Python (venv) ----------
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN pip install --upgrade pip wheel setuptools \
 && pip install jupyterlab notebook tensorboard

# ---------- PyTorch + Xformers (CUDA 12.1) ----------
RUN pip install torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121 \
 && pip install xformers==0.0.27

# ---------- Common deps used by Forge/Comfy/Trainer ----------
# opencv-python-headless avoids GUI backends (still keep libGL in case)
RUN pip install \
    einops==0.7.0 \
    opencv-python-headless==4.10.0.84 \
    basicsr==1.4.2 gfpgan==1.3.8 realesrgan==0.3.0 \
    numpy==1.26.4 Pillow==10.3.0 \
    accelerate safetensors transformers==4.37.2 \
    datasets peft sentencepiece protobuf tqdm fastapi uvicorn gradio==3.50.2

# ---------- Lay down workspace structure (not required at runtime, helps cache) ----------
WORKDIR /workspace
RUN mkdir -p /workspace/shared/{models,outputs,logs,notebooks}

# (Optional) Clone repos here; at runtime start.sh will re-clone into the mounted volume if missing
RUN git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge || true && \
    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git comfyui || true && \
    git clone --depth=1 https://github.com/bmaltais/kohya_ss.git train || true

# ---------- Start script ----------
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

# ---------- Defaults ----------
ENV FORGE_PORT=7860 COMFY_PORT=8188 JUPYTER_PORT=8888 TB_PORT=6006
EXPOSE 7860 8188 8888 6006

# Important: use /opt (not /workspace) so the script isn't hidden by RunPod's volume mount
CMD ["bash", "/opt/start.sh"]
