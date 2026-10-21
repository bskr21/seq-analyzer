#!/usr/bin/env python3
"""Sequencer Analyzer - write tempo steps into a saved Live Set (.als).

Usage: aicb_tempo.py <set.als> <entries.json>
entries.json: [{"start": beat, "end": beat, "bpm": 150.0, "song": "GJT.mp3", "sections": ["INTRO", ...]}]

For each entry the main-track tempo envelope gets a step up to `bpm` at `start` and a step back to
the previous value at `end`; points in between are replaced. A backup of the set is written to
<set folder>/Backup first. Prints a JSON report on stdout.
"""
import copy, datetime, gzip, json, os, shutil, sys
import xml.etree.ElementTree as ET

FAR_PAST = -63072000.0


def value_at(events, t):
    """Envelope value at beat t (linear between points, steps where two points share a time)."""
    pts = sorted(((float(e.get("Time")), float(e.get("Value"))) for e in events), key=lambda p: p[0])
    if not pts:
        return None
    before = [p for p in pts if p[0] <= t]
    after = [p for p in pts if p[0] > t]
    if not before:
        return pts[0][1]
    if not after:
        return before[-1][1]
    (t0, v0), (t1, v1) = before[-1], after[0]
    return v0 + (v1 - v0) * (t - t0) / (t1 - t0)


def main():
    als, entries_path = sys.argv[1], sys.argv[2]
    entries = json.load(open(entries_path))
    raw = gzip.open(als).read()
    root = ET.fromstring(raw)
    ls = root.find("LiveSet")
    report = {"ok": True, "written": [], "skipped": []}

    # every entry must be backed by what was saved: the song clip and the section clips
    paths = [n.get("Value") or "" for tag in ("Path", "RelativePath") for n in ls.iter(tag)]
    clip_names = {n.get("Value") for n in ls.iter("Name")}
    usable = []
    for e in entries:
        if e.get("song") and not any(p.endswith("/" + e["song"]) or p == e["song"] for p in paths):
            report["skipped"].append({"song": e.get("song"), "why": "song not in the saved set"})
        elif e.get("sections") and not set(e["sections"]) <= clip_names:
            report["skipped"].append({"song": e.get("song"), "why": "section clips not saved yet"})
        else:
            usable.append(e)
    if not usable:
        report["ok"] = False
        print(json.dumps(report))
        return

    mt = ls.find("MainTrack")
    tempo = mt.find("DeviceChain/Mixer/Tempo")
    target = tempo.find("AutomationTarget").get("Id")
    manual = float(tempo.find("Manual").get("Value"))
    envs = mt.find("AutomationEnvelopes/Envelopes")
    env = None
    for x in envs.findall("AutomationEnvelope"):
        if x.find("EnvelopeTarget/PointeeId").get("Value") == target:
            env = x
    if env is None:  # first tempo automation in this set
        ids = [int(x.get("Id")) for x in envs.findall("AutomationEnvelope")]
        env = ET.SubElement(envs, "AutomationEnvelope", {"Id": str(max(ids) + 1 if ids else 0)})
        ET.SubElement(ET.SubElement(env, "EnvelopeTarget"), "PointeeId", {"Value": target})
        auto = ET.SubElement(env, "Automation")
        evs = ET.SubElement(auto, "Events")
        ET.SubElement(evs, "FloatEvent", {"Id": "0", "Time": str(FAR_PAST), "Value": repr(manual)})
        tv = ET.SubElement(auto, "AutomationTransformViewState")
        ET.SubElement(tv, "IsTransformPending", {"Value": "false"})
        ET.SubElement(tv, "TimeAndValueTransforms")
    evs = env.find("Automation/Events")
    next_id = max([int(e.get("Id")) for e in evs] + [0]) + 1

    lo = float(tempo.find("MidiControllerRange/Min").get("Value"))
    hi = float(tempo.find("MidiControllerRange/Max").get("Value"))
    for e in sorted(usable, key=lambda x: x["start"]):
        a, b, bpm = float(e["start"]), float(e["end"]), float(e["bpm"])
        if not lo <= bpm <= hi:
            report["skipped"].append({"song": e.get("song"), "why": "bpm outside %g-%g" % (lo, hi)})
            continue
        events = list(evs)
        # tempo just before the step, and just after the song (a point pair at b = step; the last one wins)
        v_before = value_at([x for x in events if float(x.get("Time")) < a], a)
        v_after = value_at(events, b)
        v_before = manual if v_before is None else v_before
        v_after = manual if v_after is None else v_after
        for x in events:
            if a <= float(x.get("Time")) <= b:
                evs.remove(x)
        new = [(a, v_before), (a, bpm), (b, bpm), (b, v_after)]
        for t, v in new:
            el = ET.Element("FloatEvent", {"Id": str(next_id), "Time": repr(float(t)), "Value": repr(float(v))})
            next_id += 1
            evs.append(el)
        report["written"].append({"song": e.get("song"), "start": a, "end": b, "bpm": bpm,
                                  "before": v_before, "after": v_after})
    # Live expects events in time order
    items = sorted(list(evs), key=lambda x: float(x.get("Time")))
    for x in list(evs):
        evs.remove(x)
    for x in items:
        evs.append(x)

    folder = os.path.join(os.path.dirname(als), "Backup")
    os.makedirs(folder, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H%M%S")
    backup = os.path.join(folder, "%s [%s].als" % (os.path.splitext(os.path.basename(als))[0], stamp))
    shutil.copy2(als, backup)
    data = b'<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="utf-8")
    tmp = als + ".tmp"
    with gzip.open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, als)
    report["backup"] = backup
    print(json.dumps(report))


if __name__ == "__main__":
    main()
