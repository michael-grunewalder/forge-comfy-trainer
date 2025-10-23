# ---------- Base ----------
FROM python:3.10-slim

ARG IMAGE_VERSION="v1.0.0"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ---------- System packages ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ffmpeg libsm6 libxext6 libgl1 build-essential \
    && rm -rf /var/lib/apt/lists/*

# ---------- Virtual environment ----------
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ---------- Python dependencies ----------
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
        torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir \
        xformers==0.0.27.post2 \
        jupyterlab==4.2.5 \
        tqdm pillow==10.2.0 opencv-python \
        fastapi uvicorn aiofiles safetensors einops numpy \
        transformers==4.44.2 accelerate bitsandbytes \
        peft diffusers==0.31.0 && \
    rm -rf /root/.cache/pip

# ---------- Directories ----------
RUN mkdir -p /workspace /opt/scripts
WORKDIR /workspace

# ---------- Copy startup script ----------
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

CMD ["/opt/start.sh"]
