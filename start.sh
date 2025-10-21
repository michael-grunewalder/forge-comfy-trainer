#!/bin/bash

# --- 1. Model and Shared Directory Setup ---
echo "Setting up shared model directories..."

# Define the root shared model directory (if not already mounted via volume)
MODEL_ROOT="/workspace/models"
mkdir -p "$MODEL_ROOT"

# Create standard subdirectories within the shared root
mkdir -p "$MODEL_ROOT/checkpoints"
mkdir -p "$MODEL_ROOT/loras"
mkdir -p "$MODEL_ROOT/vae"
mkdir -p "$MODEL_ROOT/embeddings"
mkdir -p "$MODEL_ROOT/upscalers"
mkdir -p "$MODEL_ROOT/controlnet"

# Create shared symbolic links for ComfyUI to use the shared structure
echo "Linking ComfyUI paths to shared directories..."
mkdir -p /workspace/ComfyUI/models
ln -sf "$MODEL_ROOT/checkpoints" /workspace/ComfyUI/models/checkpoints
ln -sf "$MODEL_ROOT/loras" /workspace/ComfyUI/models/loras
ln -sf "$MODEL_ROOT/vae" /workspace/ComfyUI/models/vae
ln -sf "$MODEL_ROOT/embeddings" /workspace/ComfyUI/models/embeddings
ln -sf "$MODEL_ROOT/upscalers" /workspace/ComfyUI/models/upscale_models
ln -sf "$MODEL_ROOT/controlnet" /workspace/ComfyUI/models/controlnet

# Create shared symbolic links for Forge to use the shared structure
echo "Linking Forge paths to shared directories..."
mkdir -p /workspace/forge-ui/models
ln -sf "$MODEL_ROOT/checkpoints" /workspace/forge-ui/models/Stable-diffusion
ln -sf "$MODEL_ROOT/loras" /workspace/forge-ui/models/Lora
ln -sf "$MODEL_ROOT/vae" /workspace/forge-ui/models/VAE
ln -sf "$MODEL_ROOT/embeddings" /workspace/forge-ui/embeddings
ln -sf "$MODEL_ROOT/upscalers" /workspace/forge-ui/models/ESRGAN

# Kohya's scripts typically take a path as an argument, so no symlink is strictly needed
# but having the shared structure is beneficial for organization.

# --- 2. Dependency Installation (Executed at Container Runtime) ---
echo "Installing Python dependencies at runtime..."
pip install --no-cache-dir \
    -r /workspace/ComfyUI/requirements.txt \
    -r /workspace/forge-ui/requirements.txt \
    -r /workspace/kohya-ss/requirements.txt \
    diffusers bitsandbytes accelerate torchvision safetensors xformers

# --- 3. Application Startup ---
echo "Startup complete. Starting ComfyUI..."

# Change directory to ComfyUI (default app)
cd /workspace/ComfyUI

# Start ComfyUI, listening on all interfaces (0.0.0.0)
python main.py --listen 0.0.0.0 --port 8888

# Fallback to keep the container running if the main process exits
exec /bin/bash
