#!/bin/bash
set -e

# Shared folders
SHARED="/workspace/shared"
FORGE_PATH="/workspace/forge"
COMFY_PATH="/workspace/comfyui"
TRAIN_PATH="/workspace/train"
JUPYTER_PORT=8888
FORGE_PORT=7860
COMFY_PORT=8188

# Prepare workspace
mkdir -p "$SHARED"/{models,outputs,logs,notebooks}
ln -sf "$SHARED/models" "$FORGE_PATH/models"
ln -sf "$SHARED/models" "$COMFY_PATH/models"
ln -sf "$SHARED/models" "$TRAIN_PATH/models"

# Download SDXL if missing
if [ ! -f "$SHARED/models/sd_xl_base_1.0.safetensors" ]; then
  echo "Downloading SDXL base model..."
  wget -q -O "$SHARED/models/sd_xl_base_1.0.safetensors" \
    "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true"
fi

# Launch Forge
cd "$FORGE_PATH"
nohup /venv/bin/python launch.py \
  --listen --port "$FORGE_PORT" --enable-insecure-extension-access \
  > "$SHARED/logs/forge.log" 2>&1 &

# Launch ComfyUI
cd "$COMFY_PATH"
nohup /venv/bin/python main.py \
  --listen 0.0.0.0 --port "$COMFY_PORT" \
  > "$SHARED/logs/comfyui.log" 2>&1 &

# Launch JupyterLab
cd "$SHARED/notebooks"
nohup /venv/bin/jupyter lab \
  --ip=0.0.0.0 \
  --port="$JUPYTER_PORT" \
  --no-browser \
  --allow-root \
  --NotebookApp.token="$JUPYTER_TOKEN" \
  --notebook-dir="$SHARED/notebooks" \
  > "$SHARED/logs/jupyter.log" 2>&1 &

echo "────────────────────────────────────────────"
echo "Forge UI     : http://\$HOSTNAME:$FORGE_PORT"
echo "ComfyUI      : http://\$HOSTNAME:$COMFY_PORT"
echo "JupyterLab   : http://\$HOSTNAME:$JUPYTER_PORT"
echo "Logs in      : $SHARED/logs"
echo "────────────────────────────────────────────"

tail -f /dev/null
