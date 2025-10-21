# Use a currently available base image from RunPod for GPU workloads.
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

# --- Cloning Repositories (Only cloning, NO pip install) ---
# By removing the large pip install step from this layer, we prevent the GitHub
# Actions runner from running out of disk space during the build.
RUN echo "Cloning repositories..." && \
    # 1. Install ComfyUI
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/ComfyUI/custom_nodes/ComfyUI-Manager && \
    \
    # 2. Install Stable Diffusion WebUI (Forge Edition)
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git /workspace/forge-ui && \
    \
    # 3. Install Kohya's LoRA Training Scripts (For Training)
    git clone https://github.com/kohya-ss/sd-scripts.git /workspace/kohya-ss

# Copy the startup script (which now handles dependency installation AND model linking)
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Define the container entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]
