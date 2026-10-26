#!/usr/bin/env python3
"""Package a Max patch into an AMXD using the checked-in AMXD as a format template.

This does not validate Max compatibility; always test the result in Live.
"""
import json, struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "device" / "Sequencer Analyzer.amxd"
patch = root / "device" / "Sequencer Analyzer.maxpat"
target = root / "dist" / "Sequencer Analyzer v0.8.0-alpha.amxd"
old = source.read_bytes()
new_patch = patch.read_bytes()
json.loads(new_patch.decode("utf-8"))
if old[:4] != b"ampf":
    raise SystemExit("AMXD magic not recognized")
index = old.find(b"ptch")
if index < 0:
    raise SystemExit("ptch chunk not found")
length = struct.unpack_from("<I", old, index + 4)[0]
start = index + 8
end = start + length
if end > len(old):
    raise SystemExit("invalid ptch chunk length")
original = old[start:end]
json.loads(original.decode("utf-8").rstrip("\x00"))
# Preserve the original JSON's trailing NUL convention if it has one.
suffix = b"\x00" if original.endswith(b"\x00") else b""
chunk = new_patch + suffix
built = old[:index + 4] + struct.pack("<I", len(chunk)) + chunk + old[end:]
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(built)
check = target.read_bytes()
assert check[:4] == b"ampf"
assert json.loads(check[start:start+len(chunk)].decode("utf-8").rstrip("\x00"))["patcher"]
print("AMXD packaged:", target, "bytes:", len(built))
