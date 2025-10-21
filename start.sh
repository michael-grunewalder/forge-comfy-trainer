#!/usr/bin/env bash
# Robust multi-service bootstrap for RunPod
# Forge (A1111/Forge), ComfyUI, kohya_ss (trainer), JupyterLab
# Shared data lives in /workspace/shared/*

set -Eeuo pipefail

### ── Config ────────────────────────────────────────────────────────────────
WORKDIR=${WORKDIR:-/workspace}
SHARED_ROOT="$WORKDIR/shared"
FORGE_REPO=${FORGE_REPO:-https://github.com/lllyasviel/stable-diffusion-webui-forge.git}
COMFY_REPO=${COMFY_REPO:-https://github.com/comfyanonymous/ComfyUI.git}
KOHYA_REPO=${KOHYA_REPO:-https://github.com/bmaltais/kohya_ss.git}

FORGE_PATH="$WORKDIR/forge"
COMFY_PATH="$WORKDIR/comfyui"
TRAIN_PATH="$WORKDIR/train"

FORGE_PORT=${FORGE_PORT:-7860}
COMFY_PORT=${COMFY_PORT:-8188}
JUPYTER_PORT=${JUPYTER_PORT:-8888}
JUPYTER_TOKEN=${JUPYTER_TOKEN:-runpod}

SHARED_MODELS="$SHARED_ROOT/models"
SHARED_OUTPUTS="$SHARED_ROOT/outputs"
SHARED_NOTEBOOKS="$SHARED_ROOT/notebooks"
SHARED_LOGS="$SHARED_ROOT/logs"

# Optional non-blocking preload (set SDXL_URL="" to disable)
SDXL_URL=${SDXL_URL:-"https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true"}
SDXL_FILE="$SHARED_MODELS/sd_xl_base_1.0.safetensors"

PY=/venv/bin/python
JUP=/venv/bin/jupyter

### ── Helpers ───────────────────────────────────────────────────────────────
log(){ printf '[%s] %s\n' "$(date +'%F %T')" "$*"; }
ensure_dir(){ mkdir -p "$1"; }
ensure_repo(){
  local path="$1" url="$2"
  if [[ ! -d "$path/.git" ]]; then
    log "Cloning $(basename "$path") → $path"
    git clone --depth 1 "$url" "$path"
  else
    (cd "$path" && git fetch --depth 1 && git reset --hard @{upstream:-HEAD} || true)
  fi
}
safe_link(){ rm -rf "$2"; ln -sfn "$1" "$2"; }
start_bg(){ local name="$1"; shift; nohup "$@" >"$SHARED_LOGS/${name}.log" 2>&1 & echo $! > "$SHARED_LOGS/${name}.pid"; }

### ── Prepare filesystem ────────────────────────────────────────────────────
log "Preparing /workspace/shared structure"
ensure_dir "$SHARED_MODELS"
ensure_dir "$SHARED_OUTPUTS"
ensure_dir "$SHARED_NOTEBOOKS"
ensure_dir "$SHARED_LOGS"

# Ensure repos exist on mounted volume
ensure_repo "$FORGE_PATH" "$FORGE_REPO"
ensure_repo "$COMFY_PATH" "$COMFY_REPO"
ensure_repo "$TRAIN_PATH" "$KOHYA_REPO"

# Link shared dirs into apps
safe_link "$SHARED_MODELS"   "$FORGE_PATH/models"
safe_link "$SHARED_MODELS"   "$COMFY_PATH/models"
safe_link "$SHARED_MODELS"   "$TRAIN_PATH/models"
safe_link "$SHARED_OUTPUTS"  "$FORGE_PATH/outputs"
safe_link "$SHARED_OUTPUTS"  "$COMFY_PATH/output"
safe_link "$SHARED_OUTPUTS"  "$TRAIN_PATH/outputs"
safe_link "$SHARED_NOTEBOOKS" "$TRAIN_PATH/notebooks"

### ── Background model download (non-blocking) ──────────────────────────────
if [[ -n "$SDXL_URL" && ! -f "$SDXL_FILE" ]]; then
  log "SDXL missing; downloading in background → $SDXL_FILE"
  (
    tmp="$SDXL_FILE.part"
    if command -v aria2c >/dev/null 2>&1; then
      aria2c -x8 -s8 -o "$tmp" "$SDXL_URL" && mv -f "$tmp" "$SDXL_FILE"
    else
      wget -q -O "$tmp" "$SDXL_URL" && mv -f "$tmp" "$SDXL_FILE"
    fi
    log "SDXL download complete."
  ) >> "$SHARED_LOGS/model_download.log" 2>&1 &
else
  log "SDXL present or preload disabled."
fi

### ── Launch services ───────────────────────────────────────────────────────
# Forge (use --listen alone; it binds 0.0.0.0)
log "Starting Forge on :$FORGE_PORT"
start_bg forge "$PY" "$FORGE_PATH/launch.py" \
  --listen --port "$FORGE_PORT" --enable-insecure-extension-access

# ComfyUI
log "Starting ComfyUI on :$COMFY_PORT"
start_bg comfyui "$PY" "$COMFY_PATH/main.py" \
  --listen 0.0.0.0 --port "$COMFY_PORT"

# JupyterLab (proxy-friendly flags)
log "Starting JupyterLab on :$JUPYTER_PORT"
ensure_dir "$SHARED_NOTEBOOKS"
start_bg jupyter "$JUP" lab \
  --ip=0.0.0.0 --port="$JUPYTER_PORT" --no-browser --allow-root \
  --NotebookApp.token="$JUPYTER_TOKEN" \
  --NotebookApp.base_url="/" --NotebookApp.default_url="/lab" \
  --NotebookApp.allow_origin="*" --NotebookApp.disable_check_xsrf=True \
  --ServerApp.trust_xheaders=True \
  --notebook-dir="$SHARED_NOTEBOOKS"

### ── Summary + live logs ───────────────────────────────────────────────────
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
log "────────────────────────────────────────────"
log "Forge UI     : http://$IP:$FORGE_PORT"
log "ComfyUI      : http://$IP:$COMFY_PORT"
log "JupyterLab   : http://$IP:$JUPYTER_PORT  (token: $JUPYTER_TOKEN)"
log "Logs in      : $SHARED_LOGS"
log "────────────────────────────────────────────"

touch "$SHARED_LOGS"/{forge,comfyui,jupyter}.log
exec tail -n +1 -F "$SHARED_LOGS"/{forge,comfyui,jupyter}.log
