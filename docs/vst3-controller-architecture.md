# Sequencer Analyzer — VST3 + Ableton Controller architecture

Status: **proposal / migration foundation**, not a working VST3 implementation.
Base branch: `feature/separate-analyze-build` at `445eeb9d752bd072029f96f4e05330965980ba41`.
New work branch: `feature/vst3-ableton-controller`.

## Product goal

A user installs and interacts with one Sequencer Analyzer VST3 plugin, without requiring Max for Live. Background components can be installed by the same installer. On Ableton Live, a dedicated Python Remote Script edits Arrangement clips; future DAWs require separate adapters and capability validation.

The plugin UI is **not** the same as a VST3 having direct access to Arrangement editing.

## Layers and responsibility

1. **VST3 UI (future, JUCE)**: song list, Analyze/Review/Build controls, progress, errors, host-connection status. Never run heavyweight Python inference or blocking socket operations on the real-time audio callback.
2. **Sequencer Core (existing, to be decoupled)**: `engine/aicb_analyze.py` detects BPM, beats/downbeats and song sections. Move cue/section planning out of `device/aicb_node.js` into a Max-independent module. Produce an explicit, validated Build Plan describing proposed changes.
3. **Local bridge (existing prototype, to be revised)**: authenticated or otherwise access-controlled localhost communication; request IDs, timeouts, version negotiation, session/DAW identity, error reporting, progress, and explicit confirmation before modifying clips. Current beta uses localhost port 9128; treat this as an implementation detail, not a public protocol.
4. **Ableton adapter (existing prototype, incomplete)**: `remote/SeqAnalyzer_Remote/__init__.py` receives `ping` and `build_one`; `warp_build.py` contains single-clip Warp build logic. Add clip discovery, chosen-target validation, MIDI sections, audio cues, multi-clip build, and persistent-result verification. Observe Live main-thread requirements.
5. **Future DAW adapters**: implement only functions exposed by each DAW; communicate unsupported features explicitly.

## Reuse policy

- **Preserve** `engine/`, `remote/`, and current tests until refactor replacements are proven.
- **Preserve** `device/` (Max .amxd, .maxpat and JS) as reference and comparison fixture throughout migration. Do not delete or move it in this foundation phase.
- **Preserve** `setup.command`, `install-build-bridge.command` and current packaging scripts for legacy reproducibility. The new installer is a separate deliverable.
- **Do not merge to main** until acceptance tests demonstrate functional parity and independent install.
- Use `main` as legacy baseline; `experiment/analyze-build-v08` is currently the same commit as main.

## Existing vs not yet proven

**In source:** Python analysis; Max JS cue/sections logic; localhost bridge; Remote Script `ping` and `build_one`; one-clip Warp plan and unit tests. `docs/build-beta1.md` explicitly says beta.1 does **not** create MIDI sections or audio cues and does **not** write native tempo automation.

**Experimentally observed outside the full product:** Ableton Live 12.3.2 on macOS; creating Warp markers with `Live.Clip.WarpMarker`, adjusting `loop_end` and `end_marker`, checking playback and reopening; manually enabling Lead to produce native Song Tempo Automation. These experiments are evidence, not production integration.

**Not yet established:** a Max-free end-to-end Analyze→Build sequence; audio-cue clip creation from Python in target Live version; full Warp-map persistence after reopen; complete multi-song control; eight-bar tempo lead-in; automatic Lead API setter; VST3 build, installer, clean-device test, and other DAW adapters.

## Functional contract for Build Plan (proposal)

The core generates a reviewable plan containing source clip identity, file identity/position, proposed target BPM, Warp map assumptions, clip boundaries, computed sections and positions, cue file references, intended cue offsets, optional tempo preparation points, and warnings.

The adapter must verify song/clip identity and preconditions immediately before writing. If the user moved, trimmed or changed the clip, refuse to proceed rather than silently touching another clip. The first version should require playback stopped and use a disposable Live Set.

A Build operation is complete only after verifying expected clips and positions. No claim of atomic rollback until implemented and tested.

## Tempo strategy

Do not substitute playback-time Tempo Follow or temporary global BPM changes for native Song Tempo Automation. Target tempo preparation **eight bars before each song**, with **Lead enabled manually** until a verified API path exists. Section-name cue lead time (currently two bars) and count-in are **separate** settings from tempo preparation.

## Compatibility and validation

First development target: Ableton Live 12.3.2 on macOS. Test fresh untrimmed, steady-BPM, Warp ON/Loop OFF clips before introducing custom Warp maps, silence offsets, tempo changes, multiple clips or overlapping items. Save/reopen checks are required. No UI automation or direct editing of .als.

## Next milestone

Controller v0.1: Max-free remote `ping`, list/resolve chosen target, then safe one-clip Warp build and post-build verification in Live. Only then implement MIDI SECTIONS and audio GUIDE CUES and move to a multi-song Build and VST3 UI.
