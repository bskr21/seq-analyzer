# Sequencer Analyzer — migration tracker

Branch: `feature/vst3-ableton-controller` (cut from `feature/separate-analyze-build`).
This is a planning checklist, **not** a statement that work is complete.

## Phase 1 — GitHub foundation

- [x] Create dedicated migration branch without changing `main`.
- [x] Record architecture, existing code ownership, unsupported paths, risks, and acceptance criteria.
- [x] Keep old Max device, Python analysis, Remote Script and legacy installation assets unchanged.
- [ ] Establish CI baseline by running existing JavaScript mock and Python unit tests; record pass/fail.
- [ ] Decide version numbering and contribution/PR policy once the first migration implementation exists.

## Phase 2 — Ableton Controller, no Max for Live

- [ ] Exercise Remote Script `ping` independently of Max.
- [ ] Introduce session-aware bridge protocol and explicit selected clip identity.
- [ ] Validate `build_one` Warp in Live with fresh clip and check markers, boundaries and Save/Reopen.
- [ ] Provide safe failures, preflight checks, logs, and recovery instructions.
- [ ] Migrate MIDI track and SECTIONS clip creation out of `device/aicb_live.js`.
- [ ] Migrate GUIDE CUES audio clip creation; **verify** Python Live API availability and behavior on Live 12.3.2.
- [ ] Implement selected/multi-clip Build with collision and repeat-build protections.

## Phase 3 — tempo and musical alignment

- [ ] Prepare tempo eight bars before song entry (separate from 2-bar section cue and final-bar count).
- [ ] Test Lead **manual** interaction with native Song Tempo Automation; do not claim an API Lead setter.
- [ ] Verify stable BPM, moved/trimmed clips, custom Warp Map and silence-offset cases, rejecting unsupported cases.

## Phase 4 — Max-independent Core

- [ ] Extract Analyze results and section/cue planner from Node for Max.
- [ ] Define versioned Build Plan schema and adapter capability responses.
- [ ] Add unit tests with fixtures from the current implementation.

## Phase 5 — VST3 interface

- [ ] Create JUCE VST3 shell and basic status/Analyze/Review/Build UI.
- [ ] Connect via local bridge off the audio thread; handle disconnected Remote Script safely.
- [ ] Confirm saving/reloading plugin state and no Max for Live dependency.

## Phase 6 — packaging and DAW future

- [ ] Bundle VST3, bridge, Python runtime/models, Remote Script and cue assets in one user-facing installer.
- [ ] Test fresh macOS installation without Max for Live, across DAW restarts.
- [ ] Define adapter capability table for each future DAW before promising automation parity.

## Acceptance for foundation phase

The branch exists, contains this architecture and migration plan, and all legacy code remains at exactly the source branch content. No BUILD feature is considered accepted by this documentation-only phase.

## Safety rules

- Test changes on a **copy** of an Ableton Set; do not use a live performance set.
- Don't rewrite `.als` or automate the macOS UI.
- Avoid destructive changes to custom Warp Maps, overlapping clips, and unverified file paths.
- Stop on mismatch, log the reason, and require user review.
