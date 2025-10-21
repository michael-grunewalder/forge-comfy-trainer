# syntax=docker/dockerfile:1
FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# --- System dependencies (includes Cairo & GPU helpers) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl wget ca-certificates \
    ffmpeg \
    build-essential pkg-config \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    libcairo2 libcairo2-dev libpango-1.0-0 libpangocairo-1.0-0 \
    libfontconfig1 libfreetype6 libjpeg62-turbo zlib1g \
    libsndfile1 \
 && rm -rf /var/lib/apt/lists/* \
 && git lfs install

# --- Create workspace dirs ---
RUN mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints}
WORKDIR /opt

# --- Clone repositories (shallow for size) ---
RUN git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git forge && \
    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git ComfyUI && \
    git clone --depth=1 https://github.com/bmaltais/kohya_ss.git kohya_ss

# --- Virtualenv ---
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

# --- Install PyTorch CUDA 12.1 wheels ---
RUN pip install --index-url https://download.pytorch.org/whl/cu121 \
    torch==2.4.1+cu121 torchvision==0.19.1+cu121 torchaudio==2.4.1+cu121 && \
    pip install xformers==0.0.27.post2

# --- Core dependencies ---
# Split bitsandbytes & pycairo into isolated installs so a metadata failure won’t stop the build.
RUN pip install --no-cache-dir \
    fastapi uvicorn \
    einops \
    opencv-python-headless \
    safetensors \
    transformers \
    accelerate==0.33.0 \
    pillow==10.2.0 \
    tqdm \
    jupyterlab==4.2.5 \
    insightface \
    onnxruntime \
    mediapipe \
    fvcore \
    svglib\
    tensorboard==2.17.1 || true

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash libncurses6 libtinfo6 && \
    pip install terminado==0.18.0 && \
    rm -rf /var/lib/apt/lists/*

# --- Handle bitsandbytes separately (binary wheel only) ---
RUN pip install --no-cache-dir --prefer-binary bitsandbytes==0.45.3 || \
    (echo "⚠️ bitsandbytes build failed; falling back to CPU-only mode" && true)

# --- Handle pycairo with headers now available ---
RUN pip install --no-cache-dir pycairo==1.25.1

# --- Forge / ComfyUI / kohya_ss dependencies (graceful fallback) ---
RUN if [ -f /opt/forge/requirements_versions.txt ]; then \
        pip install -r /opt/forge/requirements_versions.txt || true ; \
    elif [ -f /opt/forge/requirements.txt ]; then \
        pip install -r /opt/forge/requirements.txt || true ; \
    fi && \
    pip install -r /opt/ComfyUI/requirements.txt || true && \
    pip install -r /opt/kohya_ss/requirements.txt || true

# --- Ports ---
EXPOSE 7860 8188 8888

# --- Copy startup script ---
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

RUN python - <<'EOF'
import torch, xformers
print("✅ CUDA available:", torch.cuda.is_available())
print("✅ Torch version:", torch.__version__)
print("✅ Xformers version:", xformers.__version__)
EOF

CMD ["/opt/start.sh"]