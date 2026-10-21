# Changelog

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
