"""Offline tests for the non-destructive build planning and validation."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest

PATH = Path(__file__).resolve().parents[1] / "remote" / "SeqAnalyzer_Remote" / "warp_build.py"
spec = importlib.util.spec_from_file_location("warp_build", PATH)
wb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wb)

class Clip:
    def __init__(self):
        self.is_audio_clip = True
        self.warping = True
        self.looping = False
        self.start_time = 64.0
        self.end_time = 480.0
        self.start_marker = 0.0
        self.loop_start = 0.0
        self.loop_end = 416.0
        self.end_marker = 416.0
        self.sample_length = 208 * 44100
        self.sample_rate = 44100
        self.warp_markers = [SimpleNamespace(sample_time=0, beat_time=0),
                             SimpleNamespace(sample_time=0.015625, beat_time=0.03125)]
        self.added = []
    def add_warp_marker(self, marker):
        self.added.append(marker)

class BuildTests(unittest.TestCase):
    def test_150_bpm_mapping(self):
        plan = wb.make_plan(208, 150, 64, 700)
        self.assertEqual(plan["length_beats"], 520)
        self.assertEqual(plan["markers"], [(30,75),(200,500),(208,520)])
        self.assertEqual(plan["end"], 584)
    def test_reject_overlap(self):
        with self.assertRaisesRegex(wb.BuildRejected, "overlap"):
            wb.make_plan(208, 150, 64, 500)
    def test_reject_warp_off(self):
        clip = Clip()
        clip.warping = False
        with self.assertRaisesRegex(wb.BuildRejected, "Warp is OFF"):
            wb.validate_clip(clip, 64, 208)
    def test_reject_existing_map(self):
        clip = Clip()
        clip.warp_markers.append(object())
        with self.assertRaisesRegex(wb.BuildRejected, "two original"):
            wb.validate_clip(clip, 64, 208)
    def test_reject_nonzero_anchor(self):
        clip = Clip()
        clip.warp_markers[0].sample_time = 2.0
        with self.assertRaisesRegex(wb.BuildRejected, "first Warp Marker"):
            wb.validate_clip(clip, 64, 208)
    def test_reject_moved_clip(self):
        clip = Clip()
        with self.assertRaisesRegex(wb.BuildRejected, "moved"):
            wb.validate_clip(clip, 128, 208)
    def test_apply_single_clip(self):
        clip = Clip()
        result = wb.apply_clip(clip, 150, 64, 208, 700, lambda a,b:(a,b))
        self.assertEqual(clip.added, [(30,75),(200,500),(208,520)])
        self.assertEqual(clip.loop_end, 520)
        self.assertEqual(clip.end_marker, 520)
        self.assertEqual(result["end"], 584)
    def test_reject_second_build(self):
        clip = Clip()
        wb.apply_clip(clip,150,64,208,700,lambda a,b:(a,b))
        clip.warp_markers += clip.added
        with self.assertRaises(wb.BuildRejected):
            wb.apply_clip(clip,150,64,208,700,lambda a,b:(a,b))

if __name__ == "__main__":
    unittest.main()
