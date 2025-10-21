# Minimal, CUDA 12.1 via PyTorch wheels (no heavy nvidia/cuda base)
FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH \
    HF_HOME=/workspace/shared/huggingface

# System deps: git/LFS, ffmpeg, GL stack, cairo stack, build tools for any wheels that need compiling
RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl wget ca-certificates \
    ffmpeg \
    build-essential pkg-config \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
    libfontconfig1 libfreetype6 libjpeg62-turbo zlib1g \
    libsndfile1 \
 && rm -rf /var/lib/apt/lists/* \
 && git lfs install

# Create workspace/shared structure now (RunPod volume will overlay /workspace; script re-mkdirs on boot)
RUN mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints} \
    /workspace/shared/models/{checkpoints,loras,vae,clip,clip_vision,controlnet,upscale_models,embeddings} \
    /workspace/shared/outputs/{forge,comfyui,kohya} \
    /workspace/shared/logs/{forge,comfyui,jupyter,kohya}

WORKDIR /opt

# Clone apps (shallow)
RUN git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge && \
    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git ComfyUI && \
    git clone --depth=1 https://github.com/bmaltais/kohya_ss.git kohya_ss

# Single venv for all tools
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

# Install CUDA 12.1 PyTorch/XFormers wheels
# (Pinned to recent torch; adjust if RunPod image changes)
RUN pip install --index-url https://download.pytorch.org/whl/cu121 \
    torch==2.4.1+cu121 torchvision==0.19.1+cu121 torchaudio==2.4.1+cu121 && \
    pip install xformers==0.0.27.post2

# Common Python deps (covers Forge/Comfy/kohya needs + Jupyter/TensorBoard)
RUN pip install \
    fastapi uvicorn \
    einops \
    opencv-python \
    safetensors \
    transformers \
    accelerate==0.33.0 \
    bitsandbytes==0.43.3 \
    pycairo \
    pillow==10.2.0 \
    tqdm \
    jupyterlab==4.2.5 \
    tensorboard==2.17.1

# Project requirements (pinned where provided)
# Forge tends to work best with requirements_versions.txt; fall back to requirements.txt if it changes upstream.
RUN if [ -f /opt/forge/requirements_versions.txt ]; then \
        pip install -r /opt/forge/requirements_versions.txt || true ; \
    elif [ -f /opt/forge/requirements.txt ]; then \
        pip install -r /opt/forge/requirements.txt || true ; \
    fi

RUN if [ -f /opt/ComfyUI/requirements.txt ]; then \
        pip install -r /opt/ComfyUI/requirements.txt || true ; \
    fi

RUN if [ -f /opt/kohya_ss/requirements.txt ]; then \
        pip install -r /opt/kohya_ss/requirements.txt || true ; \
    fi

# Make sure the app outputs go to shared paths by default
RUN mkdir -p /opt/forge/models /opt/forge/outputs \
             /opt/ComfyUI/models /opt/ComfyUI/output

# Ports
EXPOSE 7860 8188 8888

# Start script
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

CMD ["/opt/start.sh"]
