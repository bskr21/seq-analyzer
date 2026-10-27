#!/bin/bash
# Install only the beta BUILD bridge, without changing the user's existing AMXD or Python engine.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$HERE/remote/SeqAnalyzer_Remote"
DEST="$HOME/Music/Ableton/User Library/Remote Scripts/SeqAnalyzer_Remote"
if [ ! -f "$SOURCE/__init__.py" ] || [ ! -f "$SOURCE/warp_build.py" ]; then
  echo "ERROR: Extract the entire alpha/beta package before installing." >&2
  exit 1
fi
mkdir -p "$DEST"
cp "$SOURCE/__init__.py" "$SOURCE/warp_build.py" "$DEST/"
echo "Installed Remote Script to:"
echo "$DEST"
echo
echo "Quit and relaunch Ableton Live 12."
echo "Settings > Link, Tempo & MIDI > Control Surface: SeqAnalyzer_Remote"
echo "Input/Output: None. Test with a COPY of your Live Set."
read -r -p "Press Return to close..." _
