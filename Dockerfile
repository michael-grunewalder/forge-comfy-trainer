# Use a currently available base image from RunPod for GPU workloads.
# The previous tags (2.2.0, 2.3.0) were not found. Switching to a stable 1.0.2 tag.
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

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

# --- Installation Step (Combined Layer for Efficiency) ---
# Combine cloning and dependency installation into a single RUN command
# to minimize intermediate layer size and fix "No space left on device" errors.
RUN echo "Cloning repositories..." && \
    # 1. Install ComfyUI
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/ComfyUI/custom_nodes/ComfyUI-Manager && \
    \
    # 2. Install Stable Diffusion WebUI (Forge Edition)
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /workspace/forge-ui && \
    \
    # 3. Install Kohya's LoRA Training Scripts (For Training)
    git clone https://github.com/kohya-ss/sd-scripts.git /workspace/kohya-ss && \
    \
    echo "Installing Python dependencies..." && \
    # Install all requirements and common deep learning packages in one go
    pip install --no-cache-dir \
    -r /workspace/ComfyUI/requirements.txt \
    -r /workspace/forge-ui/requirements.txt \
    -r /workspace/kohya-ss/requirements.txt \
    # Ensure specific packages are installed/upgraded
    diffusers bitsandbytes accelerate torchvision safetensors xformers \
    # Final cleanup of pip cache (optional, but good practice)
    && pip cache purge

# Copy the startup script into the container
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Define the container entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]
