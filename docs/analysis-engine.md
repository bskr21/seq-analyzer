# Analysis engine (`aicb_analyze.py`)

```
aicb_analyze.py <audio> [--out result.json] [--engine auto|allin1|heuristic]
```
Progress goes to stderr as `PROGRESS <text>`. The result goes to `--out`, or to stdout if `--out` is not given.
Compressed formats (MP3, M4A…) are decoded to a temporary WAV first, so ffmpeg isn't needed on `PATH`.

## 1. Beats, downbeats and tempo
- **madmom** `RNNDownBeatProcessor` + `DBNDownBeatTrackingProcessor` (3/4 or 4/4, 55–215 BPM).
  With `--bpm-hint X`, only tempi within ±6% of X are considered, which rules out 2×, ½× and 4/3× errors.
  The device takes the hint from the clip name, the file name or a parent folder (see the README).
- **Ambiguity check** (no hint): the tracker's best-path log-probability per frame at the detected tempo is compared
  with 3/4, 4/3, 2/3 and 3/2 of it. Alternatives within 0.12 are reported in `tempo_alternatives`. On GJT the true
  tempo wins by 0.18 or more; halving is always close (0.06), so ×½ and ×2 aren't checked.
  Falls back to librosa's beat tracker if madmom is missing.
- **Grid fit:** a robust linear fit `t = a + b·k` over all beat times (iteratively drops outliers).
  `bpm = 60 / b`. The downbeat phase is the `k mod meter` that madmom marks as beat 1 most often.
- **Stability:** local tempo over 8-beat windows (ignoring the last 4 bars, where endings slow down).
  `tempo_stable = false` if the 90th-percentile deviation is more than 2% of the BPM.

Bar *n* starts at `first_downbeat + (n−1) · meter · beat_period`.

## 2. Sections

### Choosing the engine (`--engine auto`)
1. **Vocal check on an excerpt:** three 20-second pieces (at 25%, 50% and 75% of the song) go through HTDemucs in
   two-stem mode (vocals / no vocals). It's fast and light on memory.
2. The **vocal share** is the vocal stem's energy as a fraction of the total.
3. If it's below `--vocal-threshold` (default 0.12), the song is an **instrumental backing track**, so use Engine B.
   The AI model is trained on full songs and labels nearly everything `inst` when there's no singing.
4. Otherwise separate the full song into four stems (`--segment 7 -j 1` to limit memory) and run Engine A.
   If its result has neither a verse nor a chorus, fall back to Engine B.

The `note` field in the output says which path was taken.

### Engine A: All-In-One
The [All-In-One Music Structure Analyzer](https://github.com/mir-aidj/all-in-one) separates the song with Demucs and
predicts labeled segments (`intro, verse, chorus, bridge, inst, outro, break`). Segment edges are snapped
to the bar grid above. The 8-model `harmonix-all` ensemble runs on CPU.

### Engine B: built-in heuristic (fallback)
Used automatically if All-In-One fails (the status line then says "built-in analysis").
1. **Per-bar features:** four band energies (20–200 Hz, 0.2–2 kHz, 2–5 kHz, 5–11 kHz), percussive RMS,
   and harmonic chroma.
2. **Ending:** trailing bars more than 15 dB below the song level are folded into the last section.
3. **Stop bars:** a single bar more than 6 dB quieter than both neighbours (a band break) is ignored for statistics.
4. **Boundaries:** candidate lines every 4 bars. A boundary is accepted when the band-energy profile of
   the 4 bars before vs. after differs by more than 3 dB (norm), with a bonus after a stop bar.
5. **Clustering:** sections are "the same" when their energy profile is within 2.5 dB and the first
   8 bars of chroma match (cosine > 0.75).
6. **Labels:**
   - repeating clusters inside the song body: the most repeated (latest on ties) → **CHORUS**;
     the other one that appears first → **VERSE**; one that always comes right before the chorus → **PRE CHORUS**
   - one-off sections before the first repeat → **INTRO**; after the last repeat → **OUTRO**
   - other one-offs: ≤ 4 bars → **INTERLUDE**; quiet (> 3 dB below median, adjacent quiet pieces merged)
     → **BREAKDOWN**; sounding like the intro (ignoring bass level) → **INSTRUMENTAL**; otherwise → **BRIDGE**
   - a quiet opening of ≤ 4 bars (count-in/pad) is left unlabeled

These rules were tuned on one song (*Gelap Jadi Terang*), where they reproduce the hand-checked labels.

### Numbering
Consecutive segments of the same kind are merged. Verses, bridges and pre-choruses get numbers
when they occur more than once (`VERSE 1`, `VERSE 2`); choruses stay `CHORUS`.

## Progress protocol
stderr lines:
- `PROGRESS <text>`: the current stage
- `PERCENT <0-100> <eta seconds>`: overall progress

Each stage (decode, beats, demix, model, features) is weighted by its expected time:
`rate × song length`. The stem stage reports its own percentage, and the other stages are estimated from
elapsed time. Measured rates are saved to `~/Library/Caches/AICueBuilder/timing.json`, so estimates improve
after the first run.

## Output
```json
{
  "file": "/path/song.mp3", "duration": 208.19,
  "bpm": 150.0, "beat_period": 0.4, "meter": 4, "first_downbeat": 0.043,
  "tempo_stable": true, "tempo_range": [149.1, 150.5],
  "beat_engine": "madmom", "engine": "heuristic", "bars": 130,
  "vocal_share": 0.03, "note": "instrumental track (vocals 3%): using repetition analysis",
  "sections": [
    {"kind": "intro", "label": "INTRO", "start_bar": 5, "end_bar": 13, "start": 6.44, "end": 19.24},
    {"kind": "verse", "label": "VERSE 1", "start_bar": 13, "end_bar": 33, "start": 19.24, "end": 51.24}
  ]
}
```
`end_bar` is exclusive.
