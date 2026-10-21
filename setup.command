#!/bin/bash
# AI Cue Builder - one-time setup for macOS (Apple Silicon or Intel).
# Installs the analysis engine into ~/Library/Application Support/AICueBuilder
# and the Max for Live device into your Ableton User Library.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Library/Application Support/AICueBuilder"
DEVICE_DIR="$HOME/Music/Ableton/User Library/Presets/Audio Effects/Max Audio Effect/AI Cue Builder"
echo "== AI Cue Builder setup =="

mkdir -p "$APP/engine"
cp "$HERE/engine/aicb_analyze.py" "$APP/engine/"

# 1. uv gives us a known-good Python 3.11 without touching your system Python
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv >/dev/null 2>&1; then
  echo "-- installing uv (Python manager)"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "-- creating Python environment"
uv venv --python 3.11 --allow-existing "$APP/venv"
PY="$APP/venv/bin/python"

echo "-- installing analysis libraries (a few minutes, ~2 GB)"
uv pip install --python "$PY" setuptools wheel cython "numpy<2.3"
uv pip install --python "$PY" torch==2.5.1 torchaudio==2.5.1 "librosa>=0.10" soundfile
uv pip install --python "$PY" --no-build-isolation "git+https://github.com/CPJKU/madmom"
uv pip install --python "$PY" allin1

# All-In-One needs NATTEN's attention ops; use the bundled pure-PyTorch version
if ! "$PY" -c "from natten.functional import natten1dqkrpb" >/dev/null 2>&1; then
  SITE="$("$PY" -c 'import site; print(site.getsitepackages()[0])')"
  cp -R "$HERE/engine/natten_shim/natten" "$SITE/"
fi

echo "-- downloading AI models"
"$PY" -c "from demucs.pretrained import get_model; get_model('htdemucs')" || echo "   (demucs model will download on first use)"
"$PY" -c "from allin1.models import load_pretrained_model; load_pretrained_model('harmonix-all')" || echo "   (structure model will download on first use)"

echo "-- self-test"
"$PY" - <<'EOF'
import numpy as np, soundfile as sf, tempfile, subprocess, sys, os, json
sr = 44100; t = np.arange(int(sr * 24)) / sr
y = np.zeros_like(t)
for b in np.arange(0, 24, 0.5):           # 120 BPM clicks, accent on beat 1
    i = int(b * sr); n = int(0.03 * sr)
    y[i:i + n] += (1.0 if int(b * 2) % 4 == 0 else 0.5) * np.sin(2 * np.pi * (1500 if int(b * 2) % 4 == 0 else 1000) * t[:n])
f = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name; sf.write(f, y, sr)
eng = os.path.expanduser("~/Library/Application Support/AICueBuilder/engine/aicb_analyze.py")
out = f + ".json"
subprocess.run([sys.executable, eng, f, "--out", out, "--engine", "heuristic"], check=True, stderr=subprocess.DEVNULL)
r = json.load(open(out)); print("   self-test tempo:", r["bpm"], "BPM (expected 120)")
EOF

echo "-- installing the device"
mkdir -p "$DEVICE_DIR"
cp "$HERE/device/AI Cue Builder.amxd" "$HERE/device/aicb_live.js" "$HERE/device/aicb_node.js" "$DEVICE_DIR/"

echo
echo "Done. In Live: Browser > Audio Effects > Max Audio Effect > AI Cue Builder"
echo "(or Places > User Library > Presets > Audio Effects > Max Audio Effect)."
read -n 1 -s -r -p "Press any key to close."
