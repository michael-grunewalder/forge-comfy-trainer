# Use a currently available base image from RunPod for GPU workloads
# Changed tag from 2.2.0 to a more stable/available 2.3.0 tag to fix 'not found' error.
FROM runpod/pytorch:2.3.0-py3.10-cuda12.1.2-devel

# --- Environment Setup ---
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/workspace
WORKDIR /workspace

# Install common utilities
RUN echo "Installing OS dependencies..." && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    unzip \
    nano \
    # Clean up to reduce image size
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- 1. Install ComfyUI ---
RUN echo "Installing ComfyUI..." && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
# Install ComfyUI Manager (highly recommended)
RUN echo "Installing ComfyUI Manager..." && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/ComfyUI/custom_nodes/ComfyUI-Manager

# --- 2. Install Stable Diffusion WebUI (Forge Edition) ---
RUN echo "Installing SD WebUI Forge..." && \
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /workspace/forge-ui

# --- 3. Install Kohya's LoRA Training Scripts (For Training) ---
RUN echo "Installing Kohya's SS..." && \
    git clone https://github.com/kohya-ss/sd-scripts.git /workspace/kohya-ss

# --- Install Python Dependencies (Combined) ---
# Install all requirements and common deep learning packages
RUN echo "Installing Python dependencies..." && \
    pip install --no-cache-dir \
    -r /workspace/ComfyUI/requirements.txt \
    -r /workspace/forge-ui/requirements.txt \
    -r /workspace/kohya-ss/requirements.txt \
    # Ensure specific packages are installed/upgraded
    diffusers bitsandbytes accelerate torchvision safetensors xformers \
    # Match torch version to the base image environment
    && pip install --no-cache-dir torch==2.3.0+cu121 --extra-index-url https://download.pytorch.org/whl/cu121

# Copy the startup script into the container
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Define the container entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]
