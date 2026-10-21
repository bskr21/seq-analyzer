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
| `engine/aicb_tempo.py` | Python 3.11 venv | Writes queued tempo steps into the saved `.als` (Write Tempo). |
| `device/aicb_progress.js` | Max `[jsui]` | Draws the progress bar. |
| `engine/natten_shim/` | Python | Pure-PyTorch stand-in for the NATTEN attention ops All-In-One needs (verified against a brute-force reference). |
| `setup.command` | Terminal | One-time installer. |

## Data flow

1. **Analyze & Build** → `aicb_live.js` finds the longest audio clip on the device's track and reads its `file_path`.
2. It sends `analyze <path>` to `aicb_node.js`, which runs
   `venv/bin/python aicb_analyze.py <file> --out <tmp.json>` and forwards `PROGRESS` lines to the status line.
3. Node turns the analysis into a **plan**: tempo, grid, sections and resolved cue file paths with durations.
4. `aicb_live.js` then runs these steps, with short delays between them because Live applies some property changes later:
   1. **Warp**: lock the song clip to the detected grid and put bar 1 on a bar line.
   2. **Tracks**: create or reuse `SECTIONS` (MIDI) and `GUIDE CUES` (audio) directly above the song track.
   3. **Section clips**: one empty MIDI clip per section, named and colored by section type.
   4. **Cue clips**: unwarped audio clips, the section name `leadBars` ahead and counts in the bar before.
   5. **Tempo**: queue the song's tempo step: start bar, end bar and BPM, in `tempo_queue.json`.
5. **Write Tempo** (after ⌘S): Node runs `aicb_tempo.py <set.als> <queue>`, which backs up the set and writes every
   queued step into the main track's tempo envelope. You then reopen the set.

## Design decisions

- **Why a Python engine instead of pure Max?** The structure model (All-In-One) and the beat tracker
  (madmom) are PyTorch/NumPy projects; Max can't run them. Node for Max is the bridge, because it can launch processes.
- **Why `[js]` and not Node for the Live side?** Only Max's `js`/`v8` objects can access `LiveAPI`.
- **Why warp the song?** Warp markers make the grid exact and keep the song locked to bars even if the
  set tempo changes later. Two markers (first and last downbeat) give a constant tempo.
- **Why edit the saved file for tempo?** The LOM can set `song.tempo` but has no function to write arrangement
  automation. Recording it in Live works, but it means playing every song once in real time. Editing the saved set is
  instant and handles many songs at once. See [live-integration.md](live-integration.md).
- **Why unwarped cue clips?** Spoken cues should never be time-stretched.
