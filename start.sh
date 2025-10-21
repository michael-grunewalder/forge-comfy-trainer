#!/usr/bin/env bash
# Unified startup script for Forge, ComfyUI, Kohya (training), Jupyter, TensorBoard
# Cleaned up to keep all shared data under /workspace/shared/*
# Robust for RunPod volume mounts, idempotent, non-blocking, no recursion links

set -Eeuo pipefail

### ─── Config ────────────────────────────────────────────────────────────────
WORKDIR="${WORKDIR:-/workspace}"
SHARED_ROOT="$WORKDIR/shared"

FORGE_REPO="${FORGE_REPO:-https://github.com/lllyasviel/stable-diffusion-webui-forge.git}"
COMFY_REPO="${COMFY_REPO:-https://github.com/comfyanonymous/ComfyUI.git}"
KOHYA_REPO="${KOHYA_REPO:-https://github.com/bmaltais/kohya_ss.git}"

FORGE_PORT="${FORGE_PORT:-7860}"
COMFY_PORT="${COMFY_PORT:-8188}"
TB_PORT="${TB_PORT:-6006}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
JUPYTER_TOKEN="${JUPYTER_TOKEN:-runpod}"

FORGE_PATH="$WORKDIR/forge"
COMFY_PATH="$WORKDIR/comfyui"
TRAIN_PATH="$WORKDIR/train"

SHARED_MODELS="$SHARED_ROOT/models"
SHARED_OUTPUTS="$SHARED_ROOT/outputs"
SHARED_NOTEBOOKS="$SHARED_ROOT/notebooks"
SHARED_LOGS="$SHARED_ROOT/logs"

SDXL_URL="${SDXL_URL:-https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true}"
SDXL_FILE="$SHARED_MODELS/sd_xl_base_1.0.safetensors"

PYTHON="${PYTHON:-python}"
TB_BIN="${TB_BIN:-tensorboard}"
JUP_BIN="${JUP_BIN:-jupyter}"

### ─── Helpers ───────────────────────────────────────────────────────────────
log() { printf '[%s] %s\n' "$(date +'%F %T')" "$*"; }
fail() { printf '[%s] ERROR: %s\n' "$(date +'%F %T')" "$*" >&2; exit 1; }

ensure_dir() { mkdir -p "$1" || fail "mkdir -p $1"; }

ensure_repo() {
  local path="$1" url="$2"
  if [[ ! -d "$path/.git" ]]; then
    log "Cloning $(basename "$path") → $path"
    git clone --depth 1 "$url" "$path" || fail "git clone $url"
  else
    (cd "$path" && git fetch --depth 1 && git reset --hard @{upstream:-HEAD} || true)
  fi
}

safe_link() {
  local target="$1" linkpath="$2"
  rm -rf "$linkpath"
  ln -sfn "$target" "$linkpath"
}

start_bg() {
  local name="$1"; shift
  local logf="$SHARED_LOGS/${name}.log"
  log "Starting $name → $logf"
  ( "$@" >"$logf" 2>&1 & echo $! > "$SHARED_LOGS/${name}.pid" )
}

### ─── Prepare folders ───────────────────────────────────────────────────────
log "Preparing workspace structure"
ensure_dir "$SHARED_MODELS"
ensure_dir "$SHARED_OUTPUTS"
ensure_dir "$SHARED_NOTEBOOKS"
ensure_dir "$SHARED_LOGS"

# Clone or update repos if not present
ensure_repo "$FORGE_PATH" "$FORGE_REPO"
ensure_repo "$COMFY_PATH" "$COMFY_REPO"
ensure_repo "$TRAIN_PATH" "$KOHYA_REPO"

# Create symlinks to shared dirs
safe_link "$SHARED_MODELS" "$FORGE_PATH/models"
safe_link "$SHARED_MODELS" "$COMFY_PATH/models"
safe_link "$SHARED_MODELS" "$TRAIN_PATH/models"

safe_link "$SHARED_OUTPUTS" "$FORGE_PATH/outputs"
safe_link "$SHARED_OUTPUTS" "$COMFY_PATH/output"
safe_link "$SHARED_OUTPUTS" "$TRAIN_PATH/outputs"

safe_link "$SHARED_NOTEBOOKS" "$TRAIN_PATH/notebooks"

### ─── Background model download ─────────────────────────────────────────────
if [[ -n "$SDXL_URL" && ! -f "$SDXL_FILE" ]]; then
  log "SDXL model not found; downloading in background → $SDXL_FILE"
  (
    tmp="$SDXL_FILE.part"
    if command -v aria2c >/dev/null 2>&1; then
      aria2c -x8 -s8 -o "$tmp" "$SDXL_URL" && mv -f "$tmp" "$SDXL_FILE"
    else
      wget -q -O "$tmp" "$SDXL_URL" && mv -f "$tmp" "$SDXL_FILE"
    fi
    log "SDXL download completed."
  ) >> "$SHARED_LOGS/model_download.log" 2>&1 &
else
  log "SDXL model already present or download disabled."
fi

### ─── Sanity checks ─────────────────────────────────────────────────────────
if ! command -v nvidia-smi >/dev/null 2>&1; then
  log "nvidia-smi not found (OK on CPU-only systems)."
else
  nvidia-smi || true
fi

### ─── Launch services ───────────────────────────────────────────────────────
start_bg forge "$PYTHON" "$FORGE_PATH/launch.py" \
  --listen 0.0.0.0 --port "$FORGE_PORT" --enable-insecure-extension-access

start_bg comfyui "$PYTHON" "$COMFY_PATH/main.py" \
  --listen 0.0.0.0 --port "$COMFY_PORT"

###ensure_dir "$TRAIN_PATH/logs"
###start_bg tensorboard "$TB_BIN" \
###  --logdir "$TRAIN_PATH/logs" --host 0.0.0.0 --port "$TB_PORT"

start_bg jupyter "$JUP_BIN" lab \
  --ip=0.0.0.0 \
  --port="$JUPYTER_PORT" \
  --no-browser \
  --allow-root \
  --NotebookApp.token="$JUPYTER_TOKEN" \
  --notebook-dir="$SHARED_NOTEBOOKS" \
  --ServerApp.base_url="/" \
  --ServerApp.allow_origin="*"

### ─── Status summary ────────────────────────────────────────────────────────
log "────────────────────────────────────────────"
log "Forge UI     : http://\$HOSTNAME:$FORGE_PORT"
log "ComfyUI      : http://\$HOSTNAME:$COMFY_PORT"
log "TensorBoard  : http://\$HOSTNAME:$TB_PORT"
log "JupyterLab   : http://\$HOSTNAME:$JUPYTER_PORT  (token: $JUPYTER_TOKEN)"
log "Logs in      : $SHARED_LOGS"
log "────────────────────────────────────────────"

touch "$SHARED_LOGS"/{forge,comfyui,tensorboard,jupyter}.log
exec tail -n +1 -F "$SHARED_LOGS"/{forge,comfyui,tensorboard,jupyter}.log
