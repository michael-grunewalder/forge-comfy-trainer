#!/bin/bash
set -e

echo "Starting Bearny's AI Lab Container Orchestrator..."

# --- Configuration & Setup ---

# Define directory for large models (often mounted to a persistent volume)
MODEL_DIR="/workspace/models"
REQUIRED_MODEL="stable-diffusion-v1-5.ckpt"

mkdir -p "$MODEL_DIR"

# Check for model download (moved to runtime to prevent Docker build size issues)
if [ ! -f "$MODEL_DIR/$REQUIRED_MODEL" ]; then
    echo "Model $REQUIRED_MODEL not found. Initiating required download..."
    # Placeholder: Replace with actual download command (e.g., curl, huggingface-cli, wget)
    # The actual installation of these models (ComfyUI checkpoints, etc.) would be here.
    echo "Executing model download script..."
    # Example: python3 /workspace/app/scripts/download_models.py
    touch "$MODEL_DIR/$REQUIRED_MODEL" # Creates dummy file for testing flow
    echo "Model readiness check complete."
else
    echo "Required model found: $REQUIRED_MODEL"
fi

# --- Application Service Launcher ---

# The environment variable SERVICE_TO_RUN dictates which application starts.
# This variable is typically set by the user or the hosting platform (e.g., RunPod).
SERVICE_TO_RUN=${SERVICE_TO_RUN:-"JUPYTER"} # Default to Jupyter if not specified

echo "SERVICE_TO_RUN is set to: $SERVICE_TO_RUN"

case "$SERVICE_TO_RUN" in

    # 1. ComfyUI (Node-based workflow UI)
    "COMFYUI")
        echo "Launching ComfyUI..."
        # Assuming ComfyUI is installed and runs via a Python script
        exec python3 /workspace/ComfyUI/main.py --listen 0.0.0.0 --port 3000
        ;;

    # 2. Forge/Stable Diffusion WebUI (General purpose UI)
    "FORGE"|"WEBUI")
        echo "Launching Stable Diffusion WebUI (Forge/A1111/Fooocus)..."
        # Assuming the webui is installed and launched via its standard script
        exec python3 /workspace/webui/launch.py --listen --port 3000 --xformers
        ;;

    # 3. Training Tool (e.g., Kohya-SS or custom script)
    "TRAINING")
        echo "Launching Training Environment (e.g., Kohya-SS or a custom training script)..."
        # This typically launches a specialized Python script or a web UI for training.
        exec python3 /workspace/training/launch_kohya.py --listen 0.0.0.0 --port 3001
        ;;

    # 4. Jupyter Lab (Interactive Notebooks/Development Environment) - Default
    "JUPYTER"|*)
        echo "Launching Jupyter Lab (Interactive Development)..."
        # Assuming Jupyter is installed on the base RunPod image
        # Launches Jupyter with passwordless access on a specified port
        exec jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token=''
        ;;
esac

# If 'exec' fails or the application exits, the container will stop.
# If a restart loop is needed, it would be added here, but 'exec' is preferred.

echo "Service finished execution."
