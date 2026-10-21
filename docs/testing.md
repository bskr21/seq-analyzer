# Testing

## What was validated (v0.1)
| Check | Result |
|---|---|
| Tempo on *Gelap Jadi Terang* (live-recording backing track) | 150.00 BPM, 4/4. Downbeats match the bar grid already set by hand in Live |
| Heuristic sections on the same song | INTRO 5 · VERSE 1 13 · CHORUS 33 · INTERLUDE 49 · VERSE 2 53 · CHORUS 73 · INSTRUMENTAL 89 · BREAKDOWN 97 · CHORUS 105 · OUTRO 117. Matches the hand-checked labels |
| Installer self-test signal (synthetic 120 BPM click) | 120.0 BPM |
| NATTEN stand-in vs brute-force neighborhood attention (1D and 2D, with dilation) | max error < 1e-6 |
| All-In-One network forward pass (random weights) | runs; output shapes correct |
| Engine stages with a stand-in Demucs (v0.2.0) | stem progress parsed; instrumental track (vocal share 0.1%) → repetition analysis, same labels; vocal track (75%) → AI-model path reuses the stems and extracts spectrograms (model download blocked in the test sandbox) |
| Tempo recording (v0.2.0, simulated) | playback started elsewhere, then jumped; punch-in at the song start (beat 64), value 150, punch-out at the song end |
| `aicb_live.js` against a **simulated LOM** fed with the real analysis | section clips and 50 cues land on exactly the beats of a hand-built reference set; tempo step written at the song start; armed tracks restored; a second run reuses the tracks |

## Not yet validated
- Running inside Live 12.3.2 (device loading, LOM timing, the real transport during tempo recording)
- All-In-One with its real weights on macOS
- Songs in 3/4, songs with tempo drift, very short sections

## Running the tests
```bash
# engine
python engine/aicb_analyze.py song.mp3 --out result.json            # auto (AI model, then fallback)
python engine/aicb_analyze.py song.mp3 --out result.json --engine heuristic

# device logic against the simulated Live API
node test/mock_live_test.js result.json "/path/to/English Guides"
```
`test/mock_live_test.js` loads `aicb_live.js` into a Node VM with a fake `LiveAPI` and `Task`. It models tracks,
clips, warp markers (with Live's ordering rule), clip creation and the transport, then prints the resulting
tracks, clips and tempo writes.
