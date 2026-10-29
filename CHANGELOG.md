# Changelog

## Unreleased
- Add GitHub Actions CI for pull requests and pushes to `feature/vst3-ableton-controller`; it runs the Python unit suite and compiles the Remote Script modules.
- **Bridge v1 (M0, SeqAnalyzer_Remote, `remote/`) — not yet tested in a real Live 12.** Line-delimited JSON protocol on
  `127.0.0.1:9128` with envelope `{v, id, action, params}`; `id` is echoed, `v` must be 1 (otherwise `PROTOCOL_MISMATCH`).
  - `ping`: handshake (`protocol_min`/`protocol_max` range); returns `session_id`, `live_version`, `capabilities`.
  - `list_clips`: read-only list of Arrangement audio clips with `clip_ref`, warp marker count, `file_path`/`duration_s`.
  - `build_one`: builds one clip's warp map, with `dry_run` (validation + `planned_markers` without changing Live); wrapped in an undo step; returns `state_after`.
  - `read_clip_state`: re-reads warp markers and `implied_bpm_segments` for G0 verification (including after the Set is reopened).
  - Structured errors `{code, message, retryable, details}` (e.g. `CLIP_MOVED`, `WARP_MAP_NOT_PRISTINE`, `PLAYBACK_ACTIVE`, `BUSY`).
  - Limits: 16 KiB per request (`REQUEST_TOO_LARGE`), connection closed after 20 s without a complete line, 15 s wait for the main thread (`TIMEOUT_MAIN_THREAD`), queue of 8 requests (`BUSY`).
  - Install and verification guide in `remote/README.md`; contract tests in `test/test_bridge_protocol.py`.
  - **Not yet proven:** the TCP bridge in a real Live (beta.1 only got `ECONNREFUSED`), `add_warp_marker`/`loop_end`/`end_marker` through the product integration, warp map persistence after reopen (the core of G0), availability of `live_version`/`file_path`/`warp_markers` in 12.3.2, whether the hidden end marker appears in `warp_markers`. Lead status cannot be read via the API: enable it manually after BUILD. Existing tests use fake clips.
  - **ADR 0001 vs implementation differences (code unchanged):** (1) beta.1 protocol 0 is not supported, v1 only (answers T3); (2) `result._session` is sent on every response except `ping`, while the ADR makes it optional in M0; (3) `duration` is capped at 30–86400 s, the upper bound is not in the ADR; (4) `INTERNAL` is in the ADR but unused, unexpected exceptions become `LIVE_API_ERROR`; (5) `BuildRejected` carries no `details` (the ADR example for `CLIP_MOVED` has `expected_start`/`actual_start`); (6) the server serves one connection at a time, so an idle connection blocks other clients for up to 20 s; (7) `PROTOCOL_MISMATCH` on `ping` is range-based, on other requests it is `v` != 1.
- docs: tambah `docs/vst/roadmap.md` (M0-M4, gate G0-G4).

## v0.7.1 (2026-10-22)
- **Fix: "could not lock the song".** Live applies a tempo change after a short delay, so Warp was switched on at
  the previous tempo. The device now waits until Live reports the song's BPM before switching Warp on.
- **Fix: rebuilds re-warped correct songs.** Live's hidden end marker made a correctly warped song look wrong.
  It's now ignored in the check.
- **Fallback rebuilt:** if Live auto-warps or "No" is clicked, the warp map is rebuilt as one straight line under the
  hidden end marker (which can't be moved), with the first downbeat on a bar line.
- Warp markers before/after are logged to the Max console; tempo automation that blocks the tempo is reported.

## v0.7.0 (2026-10-22)
- **Songs are warped again, at exactly their own BPM** (set the tempo, then Warp on with "keep the current timing";
  verified from the warp markers, with a fallback that straightens them). v0.5.0's unwarped songs changed length with
  the set tempo, ran into the next song, and made Tempo Follow flip tempos mid-song.
- **Tempo Follow:** when ranges touch or overlap, the song that starts last wins.
- **Much less memory and disk:** the vocal check uses a 60-second excerpt (two stems), so instrumental tracks never get a
  full stem separation; full separation (vocal songs only) runs with smaller segments.
- **Tempo ambiguity check:** songs whose tempo could be 4/3, 3/4, 2/3 or 3/2 of the detected one are named in the
  final status with the likely alternative.

## v0.6.0 (2026-10-21)
- **BPM hint:** a tempo in the clip name, file name or folder (`74BPM`, `F#150`, `E113`…) limits beat tracking to ±6%
  of it. Fixes 4/3× and 2× errors (a 74 BPM song was detected as 99.44). Renaming the clip is the per-song override;
  the analysis cache respects it.
- Progress text and bar now both show the overall percentage across all songs, and the time left for all of them.
- Final status marks detected tempos and explains how to correct one. Engine notes go to the Max console.

## v0.5.0 (2026-10-21)
- **Songs stay unwarped.** The device no longer touches warp markers (Live asked "keep the current timing?" and the
  audio ended up faster). If Live auto-warped a clip, the device turns warping off. Tempo Follow plays each song at
  its own BPM, and section positions are computed from the original audio.
- **Several songs per track:** every audio clip of 30 s or more on the track is analyzed and built in order, into the
  same SECTIONS / GUIDE CUES tracks. Tempo Follow remembers up to 16 songs per track, each with its own BPM.
- **Analysis cache:** rebuilding a song that's already analyzed is instant.
- The progress bar covers all songs, and the status line shows "Song 1/2: …".

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
