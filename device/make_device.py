"""Generate 'Sequencer Analyzer.amxd' (Max for Live audio effect) and a .maxpat copy."""
import json, struct, sys, os

out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
boxes, lines = [], []


def box(id_, maxclass, rect, text=None, ins=1, outs=1, outtype=None, pres=None, **kw):
    b = {"id": id_, "maxclass": maxclass, "numinlets": ins, "numoutlets": outs,
         "patching_rect": rect}
    if outs:
        b["outlettype"] = outtype or [""] * outs
    if text is not None:
        b["text"] = text
    if pres:
        b["presentation"] = 1
        b["presentation_rect"] = pres
    b.update(kw)
    boxes.append({"box": b})


def wire(a, ao, b, bi):
    lines.append({"patchline": {"source": [a, ao], "destination": [b, bi]}})


def button(id_, rect, label, pres, name):
    box(id_, "live.text", rect, ins=1, outs=2, outtype=["", ""], pres=pres,
        mode=0, text=label, texton=label, varname=name, parameter_enable=1,
        saved_attribute_attributes={"valueof": {
            "parameter_longname": name, "parameter_shortname": name, "parameter_type": 2,
            "parameter_mmax": 1, "parameter_enum": ["val1", "val2"], "parameter_invisible": 1}})


# audio passes straight through
box("obj-in", "newobj", [20, 20, 70, 22], "plugin~ 2", ins=2, outs=2, outtype=["signal", "signal"])
box("obj-out", "newobj", [20, 420, 70, 22], "plugout~ 2", ins=2, outs=0)
wire("obj-in", 0, "obj-out", 0)
wire("obj-in", 1, "obj-out", 1)

# title
box("obj-title", "comment", [120, 20, 200, 20], "SEQUENCER ANALYZER", ins=1, outs=0,
    pres=[8, 4, 220, 18], fontface=1, fontsize=12.0)

# buttons
button("obj-cuebtn", [120, 60, 120, 18], "Choose Cue Folder", [8, 26, 128, 20], "CueFolder")
button("obj-buildbtn", [300, 60, 120, 18], "Analyze & Build", [142, 26, 128, 20], "Build")
# Tempo Follow: on/off toggle, saved with the set (default on)
box("obj-tempobtn", "live.text", [460, 60, 120, 18], ins=1, outs=2, outtype=["", ""], pres=[276, 26, 110, 20],
    mode=1, text="Tempo Follow: Off", texton="Tempo Follow: On", varname="TempoFollow", parameter_enable=1,
    activebgoncolor=[1.0, 0.71, 0.2, 1.0], activetextoncolor=[0.1, 0.1, 0.1, 1.0],
    saved_attribute_attributes={"valueof": {
        "parameter_longname": "TempoFollow", "parameter_shortname": "Follow", "parameter_type": 2,
        "parameter_mmax": 1, "parameter_enum": ["off", "on"], "parameter_initial_enable": 1,
        "parameter_initial": [1], "parameter_invisible": 1}})

# tempo range of each song on the track (16 slots x start/end/bpm), stored with the set (hidden)
SLOTS = 16
box("obj-routeslot", "newobj", [620, 200, 60, 22], "route slot", ins=2, outs=2)
box("obj-routeidx", "newobj", [620, 230, 300, 22], "route " + " ".join(str(i) for i in range(SLOTS)), ins=2, outs=SLOTS + 1)
for i in range(SLOTS):
    x = 620 + i * 120
    box("obj-unpack%d" % i, "newobj", [x, 270, 80, 22], "unpack 0. 0. 0.", ins=1, outs=3)
    wire("obj-routeidx", i, "obj-unpack%d" % i, 0)
    for j, key in enumerate(("start", "end", "bpm")):
        name = "Follow%s%d" % (key.capitalize(), i)
        hi = 999.0 if key == "bpm" else 1000000.0
        box("obj-n%d%s" % (i, key), "live.numbox", [x, 300 + j * 30, 60, 15], ins=1, outs=2, outtype=["", "float"],
            varname=name, parameter_enable=1, saved_attribute_attributes={"valueof": {
                "parameter_longname": name, "parameter_shortname": name, "parameter_type": 0,
                "parameter_mmin": 0.0, "parameter_mmax": hi, "parameter_initial_enable": 1,
                "parameter_initial": [0], "parameter_invisible": 1, "parameter_unitstyle": 0}})
        box("obj-p%d%s" % (i, key), "newobj", [x, 400 + j * 30, 110, 22], "prepend fslot %d %s" % (i, key), ins=1, outs=1)
        wire("obj-unpack%d" % i, j, "obj-n%d%s" % (i, key), 0)
        wire("obj-n%d%s" % (i, key), 0, "obj-p%d%s" % (i, key), 0)
        wire("obj-p%d%s" % (i, key), 0, "obj-js", 0)
box("obj-pfollow", "newobj", [460, 90, 90, 22], "prepend followon", ins=1, outs=1)
box("obj-init", "message", [700, 150, 40, 22], "init", ins=2, outs=1)
# live.text in button mode sends a bang from its left outlet on click
box("obj-dialog", "newobj", [120, 120, 100, 22], "opendialog fold", ins=1, outs=2)
box("obj-prep", "newobj", [120, 150, 120, 22], "prepend setcuedir", ins=1, outs=1)
box("obj-buildmsg", "message", [300, 120, 50, 22], "build", ins=2, outs=1)
wire("obj-cuebtn", 0, "obj-dialog", 0)
wire("obj-dialog", 0, "obj-prep", 0)
wire("obj-buildbtn", 0, "obj-buildmsg", 0)
wire("obj-tempobtn", 0, "obj-pfollow", 0)

# engines
box("obj-node", "newobj", [120, 220, 260, 22], "node.script aicb_node.js @autostart 1 @watch 0", ins=1, outs=2)
box("obj-js", "newobj", [300, 280, 120, 22], "js aicb_live.js", ins=1, outs=4)
wire("obj-prep", 0, "obj-node", 0)
wire("obj-buildmsg", 0, "obj-js", 0)
wire("obj-pfollow", 0, "obj-js", 0)
wire("obj-js", 0, "obj-node", 0)
wire("obj-node", 0, "obj-js", 0)

# say hello once node is up
box("obj-thisdev", "newobj", [600, 150, 90, 22], "live.thisdevice", ins=1, outs=3)
box("obj-delay", "newobj", [600, 180, 70, 22], "delay 2000", ins=2, outs=1)
box("obj-hello", "message", [600, 210, 50, 22], "hello", ins=2, outs=1)
wire("obj-thisdev", 0, "obj-delay", 0); wire("obj-delay", 0, "obj-hello", 0); wire("obj-hello", 0, "obj-node", 0)
# the Live API is ready once live.thisdevice bangs: start following
wire("obj-thisdev", 0, "obj-init", 0); wire("obj-init", 0, "obj-js", 0)
# stored ranges: js writes "slot i start end bpm"; restored values flow back to js when the set loads
wire("obj-js", 3, "obj-routeslot", 0)
wire("obj-routeslot", 0, "obj-routeidx", 0)

# progress bar: custom-drawn [jsui]
box("obj-progress", "jsui", [480, 300, 200, 8], ins=1, outs=1, pres=[8, 54, 378, 8],
    filename="aicb_progress.js", parameter_enable=0, ignoreclick=1)
wire("obj-js", 2, "obj-progress", 0)

# status line
box("obj-status", "comment", [300, 340, 380, 40], "Ready.", ins=1, outs=0,
    pres=[8, 64, 378, 46], linecount=3, fontsize=10.5)
wire("obj-js", 1, "obj-status", 0)

patcher = {"patcher": {
    "fileversion": 1,
    "appversion": {"major": 9, "minor": 0, "revision": 7, "architecture": "x64", "modernui": 1},
    "classnamespace": "box", "rect": [100, 100, 760, 480], "openinpresentation": 1,
    "default_fontsize": 10.0, "default_fontface": 0, "default_fontname": "Arial Bold",
    "gridonopen": 1, "gridsize": [8, 8], "gridsnaponopen": 1, "toolbarvisible": 1,
    "boxanimatetime": 200, "enablehscroll": 1, "enablevscroll": 1, "devicewidth": 396.0,
    "description": "Detects BPM and song sections, adds section clips and guide cues.",
    "digest": "", "tags": "", "style": "", "subpatcher_template": "",
    "boxes": boxes, "lines": lines,
    "dependency_cache": [
        {"name": "aicb_live.js", "bootpath": ".", "type": "TEXT", "implicit": 1},
        {"name": "aicb_node.js", "bootpath": ".", "type": "TEXT", "implicit": 1},
        {"name": "aicb_progress.js", "bootpath": ".", "type": "TEXT", "implicit": 1}],
    "latency": 0, "is_mpe": 0, "external_mpe_tuning_enabled": 0, "minimum_live_version": "",
    "minimum_max_version": "", "platform_compatibility": 0, "autosave": 0}}

js = (json.dumps(patcher, indent=1) + "\n").encode("utf-8") + b"\x00"
amxd = b"ampf" + struct.pack("<I", 4) + b"aaaa" + b"meta" + struct.pack("<I", 4) + b"\x00\x00\x00\x00" + \
       b"ptch" + struct.pack("<I", len(js)) + js
open(os.path.join(out_dir, "Sequencer Analyzer.amxd"), "wb").write(amxd)
open(os.path.join(out_dir, "Sequencer Analyzer.maxpat"), "w").write(json.dumps(patcher, indent=1))
print("ok", len(amxd), "bytes,", len(boxes), "objects,", len(lines), "wires")
