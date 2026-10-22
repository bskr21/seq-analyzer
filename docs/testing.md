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
| Warping (v0.7.1, simulated with Live's behavior from the field test: tempo applies ~120 ms late, hidden end marker that can't be removed or moved) | the v0.7.0 script reproduces the field error ("warp shows" the previous tempo). v0.7.1: both songs locked at 150.000 / 74.000 BPM, and a second run reuses everything. Answering "No": the fallback rebuilds a straight line under the hidden marker, first downbeat on a bar line |
| Warping (v0.7.0, simulated) | clips auto-warped at a wrong 147 BPM. "Yes" answer: locked at exactly 150.000 and 74.000 BPM, song ends fixed at 584.48 and 748.00 beats. "No" answer: the fallback straightens the markers, same result |
| Tempo ambiguity check (v0.7.0) | GJT: no alternative flagged (best 150 BPM at −2.649/frame; 3/4 −3.005, 4/3 −2.965, 2/3 −2.827). Not yet checked on a song that is truly ambiguous |
| Vocal check on excerpt (v0.7.0, stand-in Demucs) | only a 60 s excerpt is separated (two stems); instrumental → no full separation; stems cleaned up |
| BPM hint (v0.6.0) | name parsing: `F#150`, `150BPM`, `E113`, `74BPM`, `bpm 72`, `Bbm 72`, `(A 98)` found; `Track 2024`, `Psalm 23`, `GJT.mp3` ignored. On GJT: hint 150 → same result as without; a wrong hint of 112.5 forces 109 BPM, which shows the hint truly constrains the tracker |
| Two songs on one track (v0.5.0, simulated) | both auto-warped clips set to unwarped; song 1 (150 BPM) sections unchanged; song 2 (74 BPM at beat 600) gets its sections and cues on the same tracks; a 5 s clip is skipped. Tempo Follow: 150 at 63.75, 74 at 591.75 (first cue of song 2), jumping back restores the song's tempo |
| Tempo Follow (v0.4.0, simulated playhead sweep) | tempo switches 113 → 150 at beat 63.75 (song starts at 64). A manual tempo change mid-song is kept. Jumping back into the song from outside sets 150 again. With Tempo Follow off, the tempo isn't touched |
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
