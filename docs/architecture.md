# Architecture

```
┌──────────────────── Ableton Live 12 ────────────────────┐
│  Sequencer Analyzer.amxd (Max Audio Effect, song track) │
│                                                         │
│  [buttons] ──► aicb_live.js  ◄──────► aicb_node.js      │
│                (Max [js], Live API)    (Node for Max)   │
│                     │                        │          │
│     tracks, clips,  │                        │ spawns   │
│     warp markers,   ▼                        ▼          │
│     tempo record   Live Object Model    Python engine ──┼──► result JSON
└─────────────────────────────────────────────────────────┘
                                   aicb_analyze.py (private venv)
```

## Components

| File | Runs in | Job |
|---|---|---|
| `device/Sequencer Analyzer.amxd` | Live (Max for Live) | UI: Choose Cue Folder, Analyze & Build, Re-record Tempo, status line. Audio passes through untouched (`plugin~` → `plugout~`). |
| `device/aicb_live.js` | Max `[js]` (classic ES5) | Everything that touches the Live Set through the Live Object Model (LOM). |
| `device/aicb_node.js` | Node for Max | Runs the Python engine, reads progress, matches cue files to section labels, builds the **plan**. |
| `engine/aicb_analyze.py` | Python 3.11 venv | Beat/tempo grid and section detection → JSON. |
| `device/aicb_progress.js` | Max `[jsui]` | Draws the progress bar. |
| `engine/natten_shim/` | Python | Pure-PyTorch stand-in for the NATTEN attention ops All-In-One needs (verified against a brute-force reference). |
| `setup.command` | Terminal | One-time installer. |

## Data flow

1. **Analyze & Build** → `aicb_live.js` lists every audio clip of 30 s or more on the device's track (up to 16),
   left to right, and processes them one at a time (steps 2–4).
2. It sends `analyze <path>` to `aicb_node.js`. A cached result is used if the file (path, size, date) and the
   analysis settings haven't changed; otherwise Node runs
   `venv/bin/python aicb_analyze.py <file> --out <tmp.json>` and forwards `PROGRESS` lines to the status line.
3. Node turns the analysis into a **plan**: tempo, grid, sections and resolved cue file paths with durations.
4. `aicb_live.js` then runs these steps, with short delays between them because Live applies some property changes later:
   1. **Place**: turn the song clip's warping off if Live auto-warped it, then compute where its downbeats fall:
      `start_time + (seconds − clip start offset) × bpm/60`. If that's within 0.25 beat of a bar line, it snaps to the line.
   2. **Tracks**: create or reuse `SECTIONS` (MIDI) and `GUIDE CUES` (audio) directly above the song track.
   3. **Section clips**: one empty MIDI clip per section, named and colored by section type.
   4. **Cue clips**: unwarped audio clips, the section name `leadBars` ahead and counts in the bar before.
   5. **Tempo**: after the last song, store each song's tempo range (start beat, end beat, BPM) in hidden device
      parameters (16 slots), which are saved with the set.
5. **Tempo Follow** (while the set is open): the device observes `current_song_time`. When the playhead enters its
   range, it sets `song.tempo` to the stored BPM.

## Design decisions

- **Why a Python engine instead of pure Max?** The structure model (All-In-One) and the beat tracker
  (madmom) are PyTorch/NumPy projects; Max can't run them. Node for Max is the bridge, because it can launch processes.
- **Why `[js]` and not Node for the Live side?** Only Max's `js`/`v8` objects can access `LiveAPI`.
- **Why unwarped?** Tempo Follow plays each song at its own BPM, so the audio doesn't need stretching. Changing warp
  markers through the API also made Live ask "keep the current timing?", and it misaligned the audio.
- **Why Tempo Follow instead of automation?** The LOM can set `song.tempo` but can't write arrangement automation,
  and clip envelopes in the Arrangement can only modulate, not set absolute values. Recording automation means
  playing every song in real time, and editing the saved file means saving and reopening. Following the playhead needs
  neither, and works for any number of songs. See [live-integration.md](live-integration.md).
- **Why unwarped cue clips?** Spoken cues should never be time-stretched.
