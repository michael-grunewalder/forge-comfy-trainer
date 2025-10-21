#!/bin/bash

# --- 1. Model and Shared Directory Setup ---
echo "Setting up shared model directories..."

# Define the root shared model directory (if not already mounted via volume)
MODEL_ROOT="/workspace/models"
# Define the persistent directory for Python dependencies
PERSISTENT_DEPS_DIR="/workspace/python_deps"

mkdir -p "$MODEL_ROOT"
mkdir -p "$PERSISTENT_DEPS_DIR"

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

# --- 2. Dependency Installation (Executed at Container Runtime) ---
echo "Checking and installing Python dependencies at runtime..."

# Use a marker file to track if installation has been completed successfully
INSTALL_MARKER="$PERSISTENT_DEPS_DIR/.install_complete"

if [ ! -f "$INSTALL_MARKER" ]; then
    echo "Marker file not found. Performing full installation (this will take time)..."

    # Install all dependencies into the persistent directory on the Network Volume.
    # The --target flag ensures persistence across container restarts.
    pip install --target "$PERSISTENT_DEPS_DIR" \
        -r /workspace/ComfyUI/requirements.txt \
        -r /workspace/forge-ui/requirements.txt \
        -r /workspace/kohya-ss/requirements.txt \
        diffusers bitsandbytes accelerate torchvision safetensors xformers
    
    # Create the marker file after successful installation
    touch "$INSTALL_MARKER"
    echo "Installation complete. Marker file created."
else
    echo "Persistent dependencies found. Skipping installation."
fi

# --- 3. Prepare Environment and Startup ---

# Set PYTHONPATH to include the persistent dependency directory
# This ensures Python can find the modules installed via --target.
export PYTHONPATH="$PERSISTENT_DEPS_DIR:$PYTHONPATH"
echo "PYTHONPATH set to include persistent dependencies: $PYTHONPATH"

echo "Startup complete. Starting ComfyUI..."

# Change directory to ComfyUI (default app)
cd /workspace/ComfyUI

# Start ComfyUI, listening on all interfaces (0.0.0.0)
python main.py --listen 0.0.0.0 --port 8888

# Fallback to keep the container running if the main process exits
exec /bin/bash
