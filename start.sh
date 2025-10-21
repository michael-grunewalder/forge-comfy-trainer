#!/bin/bash

# This script sets up persistence and launches all AI services.

# --- Configuration & Logging ---
LOG_FILE="/workspace/startup_log.txt"
SHARED_MODELS_DIR="/workspace/shared/models"
echo "Starting multi-tool AI environment at $(date)" | tee $LOG_FILE
echo "--- Initializing Shared Storage and Symlinks ---" | tee -a $LOG_FILE

# Set up Environment Variables
export PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
export TRANSFORMERS_CACHE="/workspace/data/hf-cache"
export HF_HOME="/workspace/data/hf-cache"

# --- 1. Create Shared Model Directories (Persistent on Network Volume) ---
# Create the root shared directory
mkdir -p "$SHARED_MODELS_DIR"

# Define and create all necessary subdirectories for model types
declare -a MODEL_FOLDERS=(
    "checkpoints"  # SDXL/1.5 models (CKPT/SAFETENSORS)
    "loras"        # LoRA/LyCORIS models
    "vaes"         # VAE files
    "embeddings"   # Textual Inversion embeddings
    "upscalers"    # ESRGAN, SwinIR, etc.
    "controlnet"   # ControlNet models
)

for folder in "${MODEL_FOLDERS[@]}"; do
    if [ ! -d "$SHARED_MODELS_DIR/$folder" ]; then
        mkdir -p "$SHARED_MODELS_DIR/$folder"
        echo "Created shared directory: $SHARED_MODELS_DIR/$folder" | tee -a $LOG_FILE
    fi
done

# --- 2. Create Symbolic Links for Model Sharing ---
# Function to create a symlink if the target directory doesn't exist or is empty
create_symlink() {
    local target_path=$1
    local link_path=$2
    local link_name=$(basename "$link_path")
    local app_dir=$(dirname "$link_path")

    # Ensure the parent app directory exists
    if [ ! -d "$app_dir" ]; then
        echo "Error: Application directory $app_dir not found. Cannot create link for $link_name." | tee -a $LOG_FILE
        return
    fi

    # Remove the existing directory/file if it's not already a symlink
    if [ -d "$link_path" ] && [ ! -L "$link_path" ]; then
        rm -rf "$link_path"
    fi

    # Create the symlink
    if [ ! -L "$link_path" ]; then
        ln -s "$target_path" "$link_path"
        echo "Successfully linked $link_name to shared storage." | tee -a $LOG_FILE
    else
        echo "Symlink for $link_name already exists." | tee -a $LOG_FILE
    fi
}

# Symlinks for ComfyUI
create_symlink "$SHARED_MODELS_DIR/checkpoints" "/workspace/ComfyUI/models/checkpoints"
create_symlink "$SHARED_MODELS_DIR/loras" "/workspace/ComfyUI/models/loras"
create_symlink "$SHARED_MODELS_DIR/vaes" "/workspace/ComfyUI/models/vae"
create_symlink "$SHARED_MODELS_DIR/embeddings" "/workspace/ComfyUI/models/embeddings"
create_symlink "$SHARED_MODELS_DIR/controlnet" "/workspace/ComfyUI/models/controlnet"

# Symlinks for Forge UI (SD WebUI)
create_symlink "$SHARED_MODELS_DIR/checkpoints" "/workspace/forge-ui/models/Stable-diffusion"
create_symlink "$SHARED_MODELS_DIR/loras" "/workspace/forge-ui/models/Lora"
create_symlink "$SHARED_MODELS_DIR/vaes" "/workspace/forge-ui/models/VAE"
create_symlink "$SHARED_MODELS_DIR/embeddings" "/workspace/forge-ui/embeddings"
create_symlink "$SHARED_MODELS_DIR/upscalers" "/workspace/forge-ui/models/ESRGAN"

# Kohya-SS does not typically require symlinks as model paths are provided at runtime,
# but the shared directory is now available for easy selection.

echo "--- Launching Services ---" | tee -a $LOG_FILE

# --- 3. Launch JupyterLab (Port 8888) ---
echo "3. Starting JupyterLab on port 8888..." | tee -a $LOG_FILE
JUPYTER_TOKEN=$(uuidgen)
echo "JUPYTER_TOKEN=$JUPYTER_TOKEN" >> $LOG_FILE
echo "JupyterLab Token: $JUPYTER_TOKEN"
nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token="$JUPYTER_TOKEN" &> /workspace/jupyter.log &

# --- 4. Launch ComfyUI (Port 8188) ---
echo "4. Starting ComfyUI on port 8188..." | tee -a $LOG_FILE
nohup python3 /workspace/ComfyUI/main.py --listen 0.0.0.0 --port 8188 --gpu-id 0 --disable-hashing --cuda-device 0 &> /workspace/comfyui.log &

# --- 5. Launch Forge UI (Port 7860) ---
echo "5. Starting SD WebUI Forge on port 7860..." | tee -a $LOG_FILE
# Performance flags: --xformers and --opt-sdp-attention are key
nohup python3 /workspace/forge-ui/launch.py --listen --port 7860 --no-half --no-half-vae --xformers --opt-sdp-attention --skip-version-check --exit &> /workspace/forgeui.log &

# --- 6. Launch Training Interface (Kohya's SS GUI - Port 7861) ---
echo "6. Starting Kohya's SS WebUI (Port 7861)..." | tee -a $LOG_FILE
nohup /usr/bin/python3 /workspace/kohya-ss/train_gui.py --listen 0.0.0.0 &> /workspace/kohya_gui.log &

# --- Keep the container running ---
echo "All services launched. Monitoring logs..." | tee -a $LOG_FILE
# Display the combined log for the user to see the Jupyter token and service status
tail -f $LOG_FILE
