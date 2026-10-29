#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/SeqAnalyzer_Remote"
DEST="$HOME/Music/Ableton/User Library/Remote Scripts/SeqAnalyzer_Remote"
for FILE in __init__.py bridge_protocol.py warp_build.py; do
  if [ ! -f "$SOURCE/$FILE" ]; then
    echo "ERROR: Missing $SOURCE/$FILE" >&2
    exit 1
  fi
done
mkdir -p "$DEST"
cp "$SOURCE/__init__.py" "$SOURCE/bridge_protocol.py" "$SOURCE/warp_build.py" "$DEST/"
echo "Installed SeqAnalyzer_Remote in $DEST"
echo "Quit Live completely, relaunch it, and select SeqAnalyzer_Remote in Settings > Link, Tempo & MIDI > Control Surface (Input/Output: None)."
echo "See remote/README.md for ping, build, reopen, and Log.txt checks."
