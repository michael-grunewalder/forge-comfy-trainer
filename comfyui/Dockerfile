FROM pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime

WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    git wget unzip ffmpeg libgl1 libglib2.0-0 && \
    RUN python -m pip debug --verbose && \
    pip install --upgrade pip wheel setuptools && \
    pip install \
        numpy \
        pillow \
        tqdm \
        opencv-python-headless \
        safetensors \
        accelerate==0.33.0 \
        xformers==0.0.27 \
        triton==3.0.0 \
        torchsde==0.2.6 && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8188 8888
ENTRYPOINT ["/start.sh"]