# Changelog

## v0.4.0 (2026-10-21)
- **Tempo Follow** replaces Write Tempo. After a build, the device stores its song's range and BPM (saved with
  the set). Whenever playback enters that song, from the first cue to the end of the last section, it switches
  Live's tempo to the song's BPM. No saving, reopening or playthrough is needed, and it works for any number of songs.
  It acts only on entering a song, so live tempo changes are kept.
- The third button is now a **Tempo Follow: On/Off** switch, saved with the set.
- Removed the saved-file writer (`aicb_tempo.py`). `tempoMode: "record"` and `"set"` are still available.

## v0.3.0 (2026-10-21)
- **Write Tempo** (new default): after building, save the set and press Write Tempo. Every analyzed song gets a
  tempo step from its first cue to the end of its last section, written straight into the saved set in about a second.
  The device checks that the set was saved after the build and keeps a backup. Reopen the set afterwards.
  Real-time recording is still available (`"tempoMode": "record"`).
- **Progress bar** redrawn with `[jsui]`. It stayed dark inside the device in v0.2.0.
- The **Re-record Tempo** button is now **Write Tempo**.

## v0.2.0 (2026-10-21)
- **Progress bar** with percentage and time left. Stem separation reports real progress, the other stages
  are estimated, and estimates learn the machine's speed after the first run. The bar also follows the tempo pass.
- **Sections on instrumental tracks:** stems are separated first and the vocal share is measured. Backing tracks
  without singing use the repetition analysis (the AI model labelled everything INTRO/INSTRUMENTAL). The AI result is
  also rejected if it has no verse or chorus.
- **Tempo:** automation now runs from the first cue (or song start) to the end of the song, recorded in one real-time
  pass. It previously covered only one bar and started at the insert marker.
- New settings: `tempoMode`, `structure`, `vocalThreshold`.

## v0.1.1 (2026-10-21)
- **Fix:** the three buttons did nothing. `live.text` in button mode sends a bang, which a `sel 1` filter blocked;
  buttons are now wired straight to their actions.
- Renamed the tool to **Sequencer Analyzer** (device, title, installer, docs). The installer removes the old
  `AI Cue Builder` device folder; the engine's support folder is unchanged, so models are not re-downloaded.
- Installer now points to **Browser → Max for Live**.

## v0.1.0 (2026-10-21)
First prototype.
- Max for Live device with Choose Cue Folder / Analyze & Build / Re-record Tempo
- Analysis engine: madmom beat/downbeat grid, All-In-One sections, built-in fallback rules
- Song clip locked to the grid with two warp markers and aligned to a bar line
- SECTIONS MIDI track with named, colored clips; GUIDE CUES track with name + count cues
- Tempo step recorded in about one bar of real-time automation recording
- One-time macOS installer with self-test
