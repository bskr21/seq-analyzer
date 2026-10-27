"""Sequencer Analyzer dedicated Remote Script bridge (Ableton Live 12 / Python 3).

Localhost-only TCP. All Live API accesses execute inside update_display, on Live's main thread.
One request at a time, no arbitrary-code execution, no UI automation.
"""
from _Framework.ControlSurface import ControlSurface
import json
import queue
import socket
import threading
import traceback

from .warp_build import BuildRejected, apply_clip, validate_clip, make_plan

HOST = "127.0.0.1"
PORT = 9128
MAX_REQUEST = 16384

class SeqAnalyzerRemote(ControlSurface):
    def __init__(self, c_instance):
        super(SeqAnalyzerRemote, self).__init__(c_instance)
        self._closed = threading.Event()
        self._requests = queue.Queue(maxsize=8)
        self._server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._server.bind((HOST, PORT))
        self._server.listen(2)
        self._server.settimeout(0.5)
        self._thread = threading.Thread(target=self._accept_loop, name="SeqAnalyzerBridge", daemon=True)
        self._thread.start()
        self.log_message("SeqAnalyzer Remote listening on %s:%d" % (HOST, PORT))

    def _accept_loop(self):
        while not self._closed.is_set():
            try:
                conn, _ = self._server.accept()
            except socket.timeout:
                continue
            except OSError:
                break
            with conn:
                conn.settimeout(20)
                try:
                    data = bytearray()
                    while b"\n" not in data and len(data) <= MAX_REQUEST:
                        part = conn.recv(4096)
                        if not part:
                            break
                        data.extend(part)
                    if len(data) > MAX_REQUEST:
                        raise BuildRejected("request too large")
                    request = json.loads(bytes(data).split(b"\n", 1)[0].decode("utf-8"))
                    response_queue = queue.Queue(maxsize=1)
                    self._requests.put((request, response_queue), timeout=2)
                    response = response_queue.get(timeout=15)
                except Exception as e:
                    response = {"ok": False, "error": str(e)}
                try:
                    conn.sendall((json.dumps(response) + "\n").encode("utf-8"))
                except OSError:
                    pass

    def update_display(self):
        super(SeqAnalyzerRemote, self).update_display()
        # Main thread only: never access the Live Object Model in the socket worker.
        for _ in range(2):
            try:
                request, reply = self._requests.get_nowait()
            except queue.Empty:
                return
            try:
                result = self._execute(request)
                reply.put_nowait({"ok": True, "result": result})
            except Exception as e:
                self.log_message("SeqAnalyzer BUILD error: %s" % e)
                reply.put_nowait({"ok": False, "error": str(e)})

    def _execute(self, req):
        if req.get("action") == "ping":
            return {"service": "SeqAnalyzer_Remote", "version": "0.8.0-beta.1"}
        if req.get("action") != "build_one":
            raise BuildRejected("unrecognized command")
        song = self.song()
        if song.is_playing or song.record_mode:
            raise BuildRejected("stop playback/recording before BUILD")
        track_index = int(req["track_index"])
        if track_index < 0 or track_index >= len(song.tracks):
            raise BuildRejected("source track no longer exists")
        track = song.tracks[track_index]
        clips = sorted(track.arrangement_clips, key=lambda c: c.start_time)
        expected_start = float(req["start"])
        # Index by position and title; refuse ambiguity.
        matches = [c for c in clips if abs(float(c.start_time)-expected_start)<0.02
                   and str(c.name)==str(req["clip_name"])]
        if len(matches) != 1:
            raise BuildRejected("could not uniquely find analyzed clip; ANALYZE again")
        clip = matches[0]
        if str(clip.name) != str(req["clip_name"]):
            raise BuildRejected("clip changed since Analyze")
        next_starts = [float(c.start_time) for c in clips if c is not clip and
                       float(c.start_time) >= expected_start-0.02]
        # All arrangement clips count, including short effects.
        next_start = min(next_starts) if next_starts else None
        validate_clip(clip, expected_start, float(req["duration"]))
        planned = make_plan(req["duration"], req["bpm"], expected_start, next_start)
        # The user should enable Lead AFTER the warp map is finished.
        import Live
        song.begin_undo_step()
        try:
            result = apply_clip(clip, float(req["bpm"]), expected_start,
                                float(req["duration"]), next_start, Live.Clip.WarpMarker)
        finally:
            song.end_undo_step()
        return {"name": str(clip.name), "bpm": result["bpm"],
                "start": expected_start, "end": result["end"],
                "length_beats": result["length_beats"],
                "markers_added": len(result["markers"]),
                "reminder": "Enable Lead manually AFTER BUILD."}

    def disconnect(self):
        self._closed.set()
        try:
            self._server.close()
        except Exception:
            pass
        super(SeqAnalyzerRemote, self).disconnect()

def create_instance(c_instance):
    return SeqAnalyzerRemote(c_instance)
