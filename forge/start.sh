#!/bin/bash
set -euo pipefail

log() { printf "\033[1;33m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

APP_NAME="${APP_NAME:-Forge}"
APP_PATH="${APP_PATH:-/workspace/Apps/Forge}"
PY_PATH="${PY_PATH:-/workspace/Python/Forge}"
TOOLS_PATH="${TOOLS_PATH:-/workspace/tools}"
JUPYTER_PORT="${JUPYTER_PORT:-8889}"
START_JUPYTER="${START_JUPYTER:-true}"
# NEU: Argumente für SDXL-Optimierung (aus Dockerfile)
FORGE_ARGS="${FORGE_ARGS:-}" 
# NEU: Steuerung der Neuinstallation (Standard: 0)
FORCE_INSTALL="${FORCE_INSTALL:-0}" 
# Basisordner für Modelle (Forge sucht models/Stable-diffusion etc. relativ dazu)
DATA_ROOT="/workspace/Shared" 

# Ordnerstruktur sicherstellen
mkdir -p "$TOOLS_PATH" "$APP_PATH" "$PY_PATH" "$DATA_ROOT/models/Stable-diffusion" "$DATA_ROOT/models/VAE" "$DATA_ROOT/models/Lora"

# 1) Python venv
if [[ ! -x "$PY_PATH/bin/python3" ]]; then
  log "Creating Python venv at $PY_PATH…"
  python3 -m venv "$PY_PATH"
  source "$PY_PATH/bin/activate"
  pip install --upgrade pip wheel jupyterlab
  ok "Venv ready."
else
  source "$PY_PATH/bin/activate"
  ok "Using existing venv."
fi

# 2) App code (Handling Force Install)
if [[ "$FORCE_INSTALL" == "1" ]]; then
  log "FORCE_INSTALL ist auf 1 gesetzt. Lösche und klone Forge neu…"
  rm -rf "$APP_PATH"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  ok "Forge repo bereit (Erzwungener Klon)."
elif [[ ! -d "$APP_PATH/.git" ]]; then
  log "Klone Forge in $APP_PATH (Erste Installation)…"
  rm -rf "$APP_PATH"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  ok "Forge repo bereit (Initialer Klon)."
else
  log "Wiederverwende und aktualisiere Forge repo…"
  cd "$APP_PATH"
  git pull
  ok "Forge repo aktualisiert."
fi

# 3) Optional Jupyter
if [[ "$START_JUPYTER" == "true" ]]; then
  log "Starte JupyterLab auf ${JUPYTER_PORT}…"
  nohup jupyter lab --ip=0.0.0.0 --port="${JUPYTER_PORT}" \
        --NotebookApp.token='' --NotebookApp.password='' --no-browser \
        > "$TOOLS_PATH/jupyter.log" 2>&1 &
  ok "JupyterLab läuft."
fi

# 4) Launch (CD und Installation/Start durch launch.py)
log "Starte Forge auf 7860…"
cd "$APP_PATH" # <--- WICHTIG: Wechsel in das Forge-Verzeichnis
# Die Forge-Abhängigkeiten werden beim ersten Aufruf von launch.py in das VENV installiert
exec python launch.py --listen --port 7860 \
     --data-dir "$DATA_ROOT" \
     $FORGE_ARGS \
     --skip-version-check
     