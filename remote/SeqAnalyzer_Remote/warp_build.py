"""Warp-map builder extracted from Sequencer Analyzer experiments 10B–14.

Runs on Ableton's Python main thread. No UI automation and no ALS file access.
We deliberately support only stable-BPM, untrimmed, Warp-ON audio clips.
"""
import math

TOL = 0.02

class BuildRejected(Exception):
    pass

def _number(v, label):
    try:
        n = float(v)
    except (TypeError, ValueError):
        raise BuildRejected(label + " is not numeric")
    if not math.isfinite(n):
        raise BuildRejected(label + " is not finite")
    return n

def make_plan(duration, bpm, start, next_start=None):
    duration = _number(duration, "duration")
    bpm = _number(bpm, "bpm")
    start = _number(start, "start")
    if not 30 <= duration <= 86400:
        raise BuildRejected("audio must be 30 seconds or longer")
    if not 20 <= bpm <= 999:
        raise BuildRejected("BPM out of range")
    beats = duration * bpm / 60.0
    projected_end = start + beats
    if next_start is not None:
        next_start = _number(next_start, "next clip start")
        if projected_end > next_start + TOL:
            raise BuildRejected("would overlap the next clip (end %.3f > start %.3f)" %
                                (projected_end, next_start))
    # Experiment: GJT 208 sec at 150 BPM => 520 beats.
    # Use intermediate points to keep the final segment at target BPM.
    samples = [min(30.0, duration * .25), duration - min(8.0, duration * .10), duration]
    points = []
    for t in samples:
        if points and abs(t - points[-1][0]) < 0.01:
            continue
        points.append((t, t * bpm / 60.0))
    return {"duration": duration, "bpm": bpm, "length_beats": beats,
            "end": projected_end, "markers": points}

def validate_clip(clip, expected_start, expected_duration):
    if not getattr(clip, "is_audio_clip", False):
        raise BuildRejected("target is not an audio clip")
    if not getattr(clip, "warping", False):
        raise BuildRejected("Warp is OFF; activate Warp manually and re-analyze")
    if getattr(clip, "looping", False):
        raise BuildRejected("Loop is ON; this test supports non-looping clips only")
    if abs(_number(clip.start_time, "start_time") - expected_start) > TOL:
        raise BuildRejected("clip moved since Analyze; analyze again")
    dur = _number(clip.sample_length, "sample_length") / _number(clip.sample_rate, "sample_rate")
    if abs(dur - expected_duration) > 0.06:
        raise BuildRejected("audio changed since Analyze; analyze again")
    if abs(_number(clip.start_marker, "start_marker")) > TOL:
        raise BuildRejected("trimmed clip start is not supported yet")
    if abs(_number(clip.loop_start, "loop_start")) > TOL:
        raise BuildRejected("nonzero loop_start is not supported yet")
    # Do not overwrite existing manually-edited tempo maps.
    markers = list(clip.warp_markers)
    if len(markers) > 3:
        raise BuildRejected("custom Warp Map detected; cannot safely overwrite it")
    return dur

def apply_clip(clip, bpm, expected_start, expected_duration, next_start, marker_factory):
    duration = validate_clip(clip, expected_start, expected_duration)
    plan = make_plan(duration, bpm, expected_start, next_start)
    original_end = _number(clip.end_time, "end_time")
    # No song tempo change. No lead manipulation. No recorder.
    for seconds, beats in plan["markers"]:
        clip.add_warp_marker(marker_factory(seconds, beats))
    # Experiments 13 and 14: loop_end controls arrangement edge, then end_marker.
    clip.loop_end = plan["length_beats"]
    clip.end_marker = plan["length_beats"]
    if abs(_number(clip.end_time, "end_time") - plan["end"]) > 0.06:
        raise BuildRejected("post-build Arrangement end did not match expected %.3f; check clip" %
                            plan["end"])
    plan["original_end"] = original_end
    return plan
