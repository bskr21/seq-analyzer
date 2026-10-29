"""Offline checks for build_one's transport-independent preflight."""
import importlib.util
from pathlib import Path
import sys
from types import ModuleType, SimpleNamespace
import unittest

from test_warp_build import Clip


def load_remote_script():
    framework = ModuleType("_Framework")
    control_surface = ModuleType("_Framework.ControlSurface")

    class ControlSurface:
        def song(self):
            return self.fake_song

    control_surface.ControlSurface = ControlSurface
    old_framework = sys.modules.get("_Framework")
    old_control_surface = sys.modules.get("_Framework.ControlSurface")
    sys.modules["_Framework"] = framework
    sys.modules["_Framework.ControlSurface"] = control_surface
    package_path = Path(__file__).resolve().parents[1] / "remote" / "SeqAnalyzer_Remote" / "__init__.py"
    spec = importlib.util.spec_from_file_location(
        "qa_build_one_remote", package_path,
        submodule_search_locations=[str(package_path.parent)],
    )
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    try:
        spec.loader.exec_module(module)
    finally:
        for name, old in (("_Framework", old_framework),
                          ("_Framework.ControlSurface", old_control_surface)):
            if old is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = old
    return module


remote = load_remote_script()


class BuildOnePreflightTests(unittest.TestCase):
    def setUp(self):
        self.clip = Clip()
        self.clip.name = "GJT"
        self.song = SimpleNamespace(
            is_playing=False, record_mode=False,
            tracks=[SimpleNamespace(arrangement_clips=[self.clip])],
        )
        self.controller = remote.SeqAnalyzerRemote.__new__(remote.SeqAnalyzerRemote)
        self.controller.fake_song = self.song
        self.request = {
            "v": 1, "id": "qa-build-one", "action": "build_one",
            "params": {
                "clip_ref": {"track_index": 0, "start": 64, "name": "GJT"},
                "duration": 208, "bpm": 150,
            },
        }
        self.controller._dispatcher = remote.Dispatcher(lambda: self.song)

    def assert_rejected_without_changes(self, code, message):
        response = self.controller._dispatcher.handle(self.request)
        self.assertFalse(response["ok"])
        self.assertEqual(response["id"], "qa-build-one")
        self.assertEqual(response["error"]["code"], code)
        self.assertRegex(response["error"]["message"], message)
        self.assertEqual(self.clip.added, [])
        self.assertEqual(self.clip.loop_end, 416.0)
        self.assertEqual(self.clip.end_marker, 416.0)

    def test_reject_playback_active(self):
        self.song.is_playing = True
        self.assert_rejected_without_changes("PLAYBACK_ACTIVE", "stop playback and recording")

    def test_reject_recording_active(self):
        self.song.record_mode = True
        self.assert_rejected_without_changes("PLAYBACK_ACTIVE", "stop playback and recording")

    def test_reject_moved_clip(self):
        # Simulate a clip moving between identity lookup and preflight validation.
        original = self.clip

        class MovingClip:
            def __init__(self, clip):
                self.clip = clip
                self.start_reads = 0

            def __getattr__(self, name):
                if name == "start_time":
                    self.start_reads += 1
                    return 64.03 if self.start_reads >= 3 else 64.0
                return getattr(self.clip, name)

        self.song.tracks[0].arrangement_clips[0] = MovingClip(original)
        self.assert_rejected_without_changes("CLIP_MOVED", "clip moved since Analyze")

    def test_reject_trimmed_clip(self):
        self.clip.start_marker = 4.0
        self.assert_rejected_without_changes("CLIP_TRIMMED", "trimmed")

    def test_reject_loop_on(self):
        self.clip.looping = True
        self.assert_rejected_without_changes("LOOP_ON", "Loop is ON")

    def test_reject_non_pristine_marker_count(self):
        self.clip.warp_markers.append(SimpleNamespace(sample_time=100, beat_time=250))
        self.assert_rejected_without_changes("WARP_MAP_NOT_PRISTINE", "exactly two original Warp Markers")

    def test_reject_overlap_with_next_clip(self):
        next_clip = Clip()
        next_clip.name = "next"
        next_clip.start_time = 500.0
        self.song.tracks[0].arrangement_clips.append(next_clip)
        self.assert_rejected_without_changes("OVERLAPS_NEXT_CLIP", "overlap")
        self.assertEqual(next_clip.added, [])


if __name__ == "__main__":
    unittest.main()
