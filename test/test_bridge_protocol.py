"""Offline bridge contract tests; run with unittest discovery from the repo root."""
import importlib
import importlib.util
import json
from pathlib import Path
import queue
import socket
from types import ModuleType, SimpleNamespace
import sys
import threading
import unittest

PACKAGE = "SeqAnalyzer_Remote"
PACKAGE_PATH = Path(__file__).resolve().parents[1] / "remote" / PACKAGE
if PACKAGE not in sys.modules:
    package = ModuleType(PACKAGE)
    package.__path__ = [str(PACKAGE_PATH)]
    sys.modules[PACKAGE] = package
protocol = importlib.import_module(PACKAGE + ".bridge_protocol")


class FakeClip:
    def __init__(self):
        self.is_audio_clip = True
        self.warping = True
        self.looping = False
        self.name = "GJT"
        self.start_time = 64.0
        self.end_time = 480.0
        self.start_marker = self.loop_start = 0.0
        self.end_marker = self.loop_end = 416.0
        self.sample_rate = 44100
        self.sample_length = 208 * self.sample_rate
        self.file_path = "/fake/GJT.wav"
        self.warp_markers = [SimpleNamespace(sample_time=0, beat_time=0),
                             SimpleNamespace(sample_time=0.015625, beat_time=0.03125)]

    def add_warp_marker(self, marker):
        self.warp_markers.append(marker)


class FakeSong:
    def __init__(self):
        self.is_playing = False
        self.record_mode = False
        self.clip = FakeClip()
        self.tracks = [SimpleNamespace(name="Songs", arrangement_clips=[self.clip])]
        self.undo_steps = []

    def begin_undo_step(self):
        self.undo_steps.append("begin")

    def end_undo_step(self):
        self.undo_steps.append("end")


class BridgeTests(unittest.TestCase):
    def setUp(self):
        self.song = FakeSong()
        self.bridge = protocol.Dispatcher(lambda: self.song,
                                          lambda seconds, beats: SimpleNamespace(
                                              sample_time=seconds, beat_time=beats),
                                          lambda: "12.3.2")
        self.ref = {"track_index": 0, "start": 64, "name": "GJT"}

    def call(self, action, params=None, request_id="test-1"):
        return self.bridge.handle({"v": 1, "id": request_id, "action": action,
                                   "params": params or {}})

    def test_ping_and_envelope(self):
        response = self.call("ping", {"protocol_min": 1, "protocol_max": 1})
        self.assertEqual(response["id"], "test-1")
        self.assertEqual(response["v"], 1)
        self.assertTrue(response["ok"])
        self.assertEqual(response["result"]["protocol_version"], 1)
        self.assertEqual(response["result"]["live_version"], "12.3.2")
        self.assertEqual(response["result"]["session_id"], self.bridge.session_id)

    def test_errors_are_structured_and_echo_id(self):
        cases = [
            ({"v": 2, "id": "x", "action": "ping"}, "PROTOCOL_MISMATCH"),
            ({"v": 1, "id": "x", "action": "missing"}, "UNKNOWN_ACTION"),
            ({"v": 1, "id": "x", "action": "ping", "params": []}, "BAD_REQUEST"),
            ({"v": 1, "action": "ping"}, "BAD_REQUEST"),
        ]
        for request, code in cases:
            with self.subTest(code=code):
                response = self.bridge.handle(request)
                self.assertFalse(response["ok"])
                self.assertEqual(response["error"]["code"], code)
                self.assertEqual(response["id"], request.get("id"))
                self.assertIn("retryable", response["error"])

    def test_ping_range_mismatch(self):
        response = self.call("ping", {"protocol_min": 2, "protocol_max": 2})
        self.assertEqual(response["error"]["code"], "PROTOCOL_MISMATCH")
        self.assertEqual(response["error"]["details"], {"server_min": 1, "server_max": 1})

    def test_read_state_is_sorted_and_read_only(self):
        clip = self.song.clip
        clip.warp_markers = [SimpleNamespace(sample_time=208, beat_time=520),
                             SimpleNamespace(sample_time=0, beat_time=0),
                             SimpleNamespace(sample_time=30, beat_time=75)]
        response = self.call("read_clip_state", {"clip_ref": self.ref})
        self.assertTrue(response["ok"])
        state = response["result"]
        self.assertEqual(state["clip_ref"], self.ref)
        self.assertEqual([m["sample_time"] for m in state["warp_markers"]], [0, 30, 208])
        self.assertEqual(state["implied_bpm_segments"], [150, 150])
        self.assertEqual(state["_session"], self.bridge.session_id)
        self.assertEqual(self.song.undo_steps, [])

    def test_read_state_while_playing(self):
        self.song.is_playing = True
        self.assertTrue(self.call("read_clip_state", {"clip_ref": self.ref})["ok"])

    def test_list_and_clip_not_found(self):
        listed = self.call("list_clips")["result"]["tracks"][0]["clips"][0]
        self.assertEqual(listed["clip_ref"], self.ref)
        self.assertEqual(listed["duration_s"], 208)
        missing = self.call("read_clip_state", {"clip_ref": dict(self.ref, start=65)})
        self.assertEqual(missing["error"]["code"], "CLIP_NOT_FOUND")

    def test_dry_run_does_not_write(self):
        response = self.call("build_one", {"clip_ref": self.ref, "duration": 208,
                                            "bpm": 150, "dry_run": True})
        self.assertTrue(response["ok"])
        self.assertEqual(response["result"]["planned_markers"][-1],
                         {"sample_time": 208, "beat_time": 520})
        self.assertEqual(len(self.song.clip.warp_markers), 2)
        self.assertEqual(self.song.undo_steps, [])

    def test_build_then_read_state(self):
        response = self.call("build_one", {"clip_ref": self.ref, "duration": 208,
                                            "bpm": 150})
        self.assertTrue(response["ok"])
        self.assertEqual(self.song.undo_steps, ["begin", "end"])
        self.assertEqual(response["result"]["markers_added"], 3)
        state = self.call("read_clip_state", {"clip_ref": self.ref})["result"]
        self.assertEqual(len(state["warp_markers"]), 5)
        self.assertEqual(self.song.clip.loop_end, 520)

    def test_build_preconditions_and_error_codes(self):
        self.song.is_playing = True
        params = {"clip_ref": self.ref, "duration": 208, "bpm": 150}
        self.assertEqual(self.call("build_one", params)["error"]["code"], "PLAYBACK_ACTIVE")
        self.song.is_playing = False
        self.song.clip.warping = False
        self.assertEqual(self.call("build_one", params)["error"]["code"], "WARP_OFF")
        self.song.clip.warping = True
        self.assertEqual(self.call("build_one", dict(params, bpm=0))["error"]["code"],
                         "BAD_PARAMS")

    def test_socket_accepts_two_requests_on_one_connection(self):
        framework = ModuleType("_Framework")
        controls = ModuleType("_Framework.ControlSurface")
        controls.ControlSurface = type("ControlSurface", (), {})
        sys.modules["_Framework"] = framework
        sys.modules["_Framework.ControlSurface"] = controls
        spec = importlib.util.spec_from_file_location(
            PACKAGE + ".socket_script", PACKAGE_PATH / "__init__.py")
        spec.submodule_search_locations = None
        script = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(script)
        worker = SimpleNamespace(_closed=threading.Event(), _requests=queue.Queue(),
                                 _send=script.SeqAnalyzerRemote._send)
        server, client = socket.socketpair()
        client.settimeout(2)
        thread = threading.Thread(target=script.SeqAnalyzerRemote._serve_connection,
                                  args=(worker, server))
        thread.start()
        try:
            requests = [
                {"v": 1, "id": "first", "action": "ping"},
                {"v": 1, "id": "second", "action": "read_clip_state",
                 "params": {"clip_ref": self.ref}},
            ]
            client.sendall("".join(json.dumps(req) + "\n" for req in requests).encode())
            responses = []
            with client.makefile("rb") as stream:
                for _ in requests:
                    request, reply = worker._requests.get(timeout=2)
                    reply.put(self.bridge.handle(request))
                    responses.append(json.loads(stream.readline()))
            self.assertEqual([r["id"] for r in responses], ["first", "second"])
            self.assertTrue(all(r["ok"] for r in responses))
        finally:
            worker._closed.set()
            client.shutdown(socket.SHUT_WR)
            client.close()
            server.close()
            thread.join(timeout=2)
            self.assertFalse(thread.is_alive())


if __name__ == "__main__":
    unittest.main()
