"""Protocol v1 dispatcher. Call handle only on Live's main thread."""
import math
import uuid

from .warp_build import BuildRejected, apply_clip, make_plan, validate_clip

PROTOCOL_VERSION = 1
SCRIPT_VERSION = "0.9.0-dev"
CAPABILITIES = ["list_clips", "build_one", "read_clip_state"]


class BridgeError(Exception):
    def __init__(self, code, message, details=None):
        super().__init__(message)
        self.code = code
        self.details = details or {}


def error_response(request_id, code, message, details=None):
    error = {"code": code, "message": message,
             "retryable": code in ("BUSY", "TIMEOUT_MAIN_THREAD", "LIVE_NOT_READY"),
             "details": details or {}}
    return {"v": PROTOCOL_VERSION, "id": request_id, "ok": False, "error": error}


def _number(value, label):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise BridgeError("BAD_PARAMS", label + " must be a finite number")
    return float(value)


def _index(value, label="track_index"):
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise BridgeError("BAD_PARAMS", label + " must be a nonnegative integer")
    return value


def _clip_ref(params):
    ref = params.get("clip_ref")
    if not isinstance(ref, dict):
        raise BridgeError("BAD_PARAMS", "clip_ref must be an object")
    index = _index(ref.get("track_index"))
    start = _number(ref.get("start"), "clip_ref.start")
    name = ref.get("name")
    if not isinstance(name, str) or not name:
        raise BridgeError("BAD_PARAMS", "clip_ref.name must be a nonempty string")
    return {"track_index": index, "start": start, "name": name}


def _optional(clip, name):
    try:
        return getattr(clip, name)
    except (AttributeError, RuntimeError):
        return None


def read_state(clip, ref):
    """Read the current LOM values; never rely on the build's planned end."""
    markers = sorted(
        ({"sample_time": float(m.sample_time), "beat_time": float(m.beat_time)}
         for m in clip.warp_markers), key=lambda m: m["sample_time"])
    segments = []
    for before, after in zip(markers, markers[1:]):
        seconds = after["sample_time"] - before["sample_time"]
        segments.append(round(60.0 * (after["beat_time"] - before["beat_time"]) / seconds, 6)
                        if seconds > 0 else None)
    return {"clip_ref": ref, "warping": bool(clip.warping),
            "looping": bool(clip.looping), "start_time": float(clip.start_time),
            "end_time": float(clip.end_time), "start_marker": float(clip.start_marker),
            "end_marker": float(clip.end_marker), "loop_start": float(clip.loop_start),
            "loop_end": float(clip.loop_end), "warp_markers": markers,
            "implied_bpm_segments": segments}


class Dispatcher:
    def __init__(self, song_getter, marker_factory=None, live_version_getter=None):
        self.song_getter = song_getter
        self.marker_factory = marker_factory
        self.live_version_getter = live_version_getter or (lambda: "unknown")
        self.session_id = str(uuid.uuid4())

    def handle(self, request):
        request_id = request.get("id") if isinstance(request, dict) else None
        if not isinstance(request_id, str) or not request_id or len(request_id) > 64:
            request_id = None
        try:
            if not isinstance(request, dict) or request_id is None:
                raise BridgeError("BAD_REQUEST", "request must be an object with a nonempty id (max 64 characters)")
            if type(request.get("v")) is not int or request.get("v") != PROTOCOL_VERSION:
                raise BridgeError("PROTOCOL_MISMATCH", "protocol version 1 is required",
                                  {"server_min": 1, "server_max": 1})
            action = request.get("action")
            if not isinstance(action, str) or not action:
                raise BridgeError("BAD_REQUEST", "action must be a nonempty string")
            params = request.get("params", {})
            if not isinstance(params, dict):
                raise BridgeError("BAD_REQUEST", "params must be an object")
            if action == "ping":
                result = self._ping(params)
            elif action == "list_clips":
                result = self._list_clips(params)
            elif action == "read_clip_state":
                ref = _clip_ref(params)
                result = read_state(self._find_clip(ref)[1], ref)
            elif action == "build_one":
                result = self._build_one(params)
            else:
                raise BridgeError("UNKNOWN_ACTION", "unrecognized action")
            if action != "ping":
                result["_session"] = self.session_id
            return {"v": PROTOCOL_VERSION, "id": request_id, "ok": True, "result": result}
        except BridgeError as exc:
            return error_response(request_id, exc.code, str(exc), exc.details)
        except BuildRejected as exc:
            return error_response(request_id, exc.code, str(exc))
        except Exception as exc:
            return error_response(request_id, "LIVE_API_ERROR", "Live API operation failed",
                                  {"exception": type(exc).__name__})

    def _song(self):
        try:
            song = self.song_getter()
        except Exception as exc:
            raise BridgeError("LIVE_NOT_READY", "Live Set is not ready",
                              {"exception": type(exc).__name__})
        if song is None:
            raise BridgeError("LIVE_NOT_READY", "Live Set is not ready")
        return song

    def _ping(self, params):
        low = _index(params.get("protocol_min", 1), "protocol_min")
        high = _index(params.get("protocol_max", 1), "protocol_max")
        if low > 1 or high < 1 or low > high:
            raise BridgeError("PROTOCOL_MISMATCH", "no shared protocol version",
                              {"server_min": 1, "server_max": 1})
        song = self._song()
        try:
            live_version = self.live_version_getter()
        except Exception:
            live_version = "unknown"
        return {"service": "SeqAnalyzer_Remote", "script_version": SCRIPT_VERSION,
                "protocol_version": 1, "live_version": live_version,
                "session_id": self.session_id,
                "song_id_hint": {"track_count": len(song.tracks),
                                 "is_playing": bool(song.is_playing)},
                "capabilities": list(CAPABILITIES)}

    def _track(self, song, index):
        if index >= len(song.tracks):
            raise BridgeError("TRACK_NOT_FOUND", "source track no longer exists")
        return song.tracks[index]

    def _find_clip(self, ref):
        track = self._track(self._song(), ref["track_index"])
        clips = sorted(track.arrangement_clips, key=lambda c: c.start_time)
        matches = [c for c in clips if abs(float(c.start_time) - ref["start"]) < 0.02
                   and str(c.name) == ref["name"]]
        if not matches:
            raise BridgeError("CLIP_NOT_FOUND", "analyzed clip was not found; analyze again")
        if len(matches) > 1:
            raise BridgeError("CLIP_AMBIGUOUS", "multiple clips match clip_ref")
        return clips, matches[0]

    def _list_clips(self, params):
        song = self._song()
        selected = params.get("track_index")
        indices = range(len(song.tracks)) if selected is None else [_index(selected)]
        tracks = []
        for index in indices:
            track = self._track(song, index)
            clips = []
            for clip in track.arrangement_clips:
                if not bool(clip.is_audio_clip):
                    continue
                ref = {"track_index": index, "start": float(clip.start_time),
                       "name": str(clip.name)}
                sample_rate = _optional(clip, "sample_rate")
                sample_length = _optional(clip, "sample_length")
                duration = (float(sample_length) / float(sample_rate)
                            if sample_rate and sample_length is not None else None)
                clips.append({"clip_ref": ref, "is_audio": True,
                              "warping": bool(clip.warping), "looping": bool(clip.looping),
                              "start_time": float(clip.start_time), "end_time": float(clip.end_time),
                              "start_marker": float(clip.start_marker), "end_marker": float(clip.end_marker),
                              "loop_start": float(clip.loop_start), "loop_end": float(clip.loop_end),
                              "file_path": _optional(clip, "file_path"),
                              "sample_rate": sample_rate, "duration_s": duration,
                              "warp_marker_count": len(list(clip.warp_markers))})
            tracks.append({"track_index": index, "track_name": str(track.name), "clips": clips})
        return {"tracks": tracks}

    def _build_one(self, params):
        ref = _clip_ref(params)
        bpm = _number(params.get("bpm"), "bpm")
        duration = _number(params.get("duration"), "duration")
        if not 20 <= bpm <= 999 or not 30 <= duration <= 86400:
            raise BridgeError("BAD_PARAMS", "bpm or duration out of range")
        dry_run = params.get("dry_run", False)
        if not isinstance(dry_run, bool):
            raise BridgeError("BAD_PARAMS", "dry_run must be a boolean")
        song = self._song()
        if song.is_playing or song.record_mode:
            raise BridgeError("PLAYBACK_ACTIVE", "stop playback and recording before BUILD")
        clips, clip = self._find_clip(ref)
        next_starts = [float(c.start_time) for c in clips if c is not clip and
                       float(c.start_time) >= ref["start"] - 0.02]
        next_start = min(next_starts) if next_starts else None
        validate_clip(clip, ref["start"], duration)
        plan = make_plan(duration, bpm, ref["start"], next_start)
        result = {"clip_ref": ref, "bpm": bpm, "start": ref["start"],
                  "end": plan["end"], "length_beats": plan["length_beats"],
                  "markers_added": len(plan["markers"]), "dry_run": dry_run,
                  "reminder": "Enable Lead manually AFTER BUILD."}
        if dry_run:
            result["planned_markers"] = [
                {"sample_time": seconds, "beat_time": beats}
                for seconds, beats in plan["markers"]]
            return result
        if self.marker_factory is None:
            raise BridgeError("LIVE_NOT_READY", "WarpMarker API is unavailable")
        song.begin_undo_step()
        try:
            apply_clip(clip, bpm, ref["start"], duration, next_start, self.marker_factory)
        finally:
            song.end_undo_step()
        result["state_after"] = read_state(clip, ref)
        return result
