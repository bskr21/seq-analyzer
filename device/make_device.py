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
button("obj-tempobtn", [460, 60, 120, 18], "Re-record Tempo", [276, 26, 110, 20], "Tempo")
# live.text in button mode sends a bang from its left outlet on click
box("obj-dialog", "newobj", [120, 120, 100, 22], "opendialog fold", ins=1, outs=2)
box("obj-prep", "newobj", [120, 150, 120, 22], "prepend setcuedir", ins=1, outs=1)
box("obj-buildmsg", "message", [300, 120, 50, 22], "build", ins=2, outs=1)
box("obj-tempomsg", "message", [460, 120, 90, 22], "recordtempo", ins=2, outs=1)
wire("obj-cuebtn", 0, "obj-dialog", 0)
wire("obj-dialog", 0, "obj-prep", 0)
wire("obj-buildbtn", 0, "obj-buildmsg", 0)
wire("obj-tempobtn", 0, "obj-tempomsg", 0)

# engines
box("obj-node", "newobj", [120, 220, 260, 22], "node.script aicb_node.js @autostart 1 @watch 0", ins=1, outs=2)
box("obj-js", "newobj", [300, 280, 120, 22], "js aicb_live.js", ins=1, outs=3)
wire("obj-prep", 0, "obj-node", 0)
wire("obj-buildmsg", 0, "obj-js", 0)
wire("obj-tempomsg", 0, "obj-js", 0)
wire("obj-js", 0, "obj-node", 0)
wire("obj-node", 0, "obj-js", 0)

# say hello once node is up
box("obj-thisdev", "newobj", [600, 150, 90, 22], "live.thisdevice", ins=1, outs=3)
box("obj-delay", "newobj", [600, 180, 70, 22], "delay 2000", ins=2, outs=1)
box("obj-hello", "message", [600, 210, 50, 22], "hello", ins=2, outs=1)
wire("obj-thisdev", 0, "obj-delay", 0); wire("obj-delay", 0, "obj-hello", 0); wire("obj-hello", 0, "obj-node", 0)

# progress bar: a track panel and a fill panel resized by aicb_live.js via thispatcher
box("obj-progbg", "panel", [480, 300, 200, 6], ins=1, outs=0, pres=[8, 54, 378, 6],
    varname="progbg", bgcolor=[0.16, 0.16, 0.16, 1.0], bgfillcolor_type="color", bgfillcolor_color=[0.16, 0.16, 0.16, 1.0], border=0, rounded=3, mode=0, ignoreclick=1)
box("obj-progfill", "panel", [480, 310, 1, 6], ins=1, outs=0, pres=[8, 54, 1, 6],
    varname="progfill", bgcolor=[1.0, 0.71, 0.2, 1.0], bgfillcolor_type="color", bgfillcolor_color=[1.0, 0.71, 0.2, 1.0], border=0, rounded=3, mode=0, ignoreclick=1)
box("obj-thispatcher", "newobj", [480, 320, 80, 22], "thispatcher", ins=1, outs=2)
wire("obj-js", 2, "obj-thispatcher", 0)

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
        {"name": "aicb_node.js", "bootpath": ".", "type": "TEXT", "implicit": 1}],
    "latency": 0, "is_mpe": 0, "external_mpe_tuning_enabled": 0, "minimum_live_version": "",
    "minimum_max_version": "", "platform_compatibility": 0, "autosave": 0}}

js = (json.dumps(patcher, indent=1) + "\n").encode("utf-8") + b"\x00"
amxd = b"ampf" + struct.pack("<I", 4) + b"aaaa" + b"meta" + struct.pack("<I", 4) + b"\x00\x00\x00\x00" + \
       b"ptch" + struct.pack("<I", len(js)) + js
open(os.path.join(out_dir, "Sequencer Analyzer.amxd"), "wb").write(amxd)
open(os.path.join(out_dir, "Sequencer Analyzer.maxpat"), "w").write(json.dumps(patcher, indent=1))
print("ok", len(amxd), "bytes,", len(boxes), "objects,", len(lines), "wires")
