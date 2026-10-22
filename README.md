# Sequencer Analyzer for Ableton Live

A Max for Live device that prepares a worship/playback **sequence** in one click. You drop a song
into Live's Arrangement and press **Analyze & Build**. The device then:

1. **Detects the BPM** and bar grid of every song on the track, and warps each song at exactly its own BPM
   (original speed, fixed length in beats, so songs never run into each other).
2. **Follows the song's tempo:** whenever the playhead enters the song (from its first cue to the end of its last
   section), Live's tempo switches to the song's BPM. No automation, no saving, no extra playback.
3. **Finds the song structure** (Intro, Verse, Chorus, Bridge, Instrumental, Breakdown, Outro…).
4. Creates a **SECTIONS** MIDI track with one named, colored clip per section.
5. Creates a **GUIDE CUES** audio track with spoken cues from your own cue pack: the section name
   two bars ahead, then "1 2 3 4" in the bar before the section.

> Status: **v0.7.0, prototype.** Tested against a simulated Live API and real song analysis,
> but not yet run inside Live itself. See [Known limitations](#known-limitations).

## Requirements
- macOS (Apple Silicon or Intel)
- Ableton Live 12 **Suite** (Max for Live), tested target 12.3.2
- Internet for the one-time setup (~2 GB of Python packages and AI models)
- A guide-cue sample pack whose file names end with the cue name, e.g. `English Female - Chorus.wav`

## Install
1. Download/unzip the release folder.
2. Right-click **`setup.command`** → **Open**. It:
   - installs [uv](https://github.com/astral-sh/uv) and a private Python 3.11 in
     `~/Library/Application Support/AICueBuilder/venv`
   - installs the analysis engine and downloads the AI models
   - copies the device to `User Library/Presets/Audio Effects/Max Audio Effect/Sequencer Analyzer/`,
     which Live lists under **Browser → Max for Live**
   - runs a self-test (a synthetic 120 BPM click should read as 120 BPM)

## Use
1. Drag your song(s) onto an **audio track** in Arrangement View, each starting on a bar line. Several songs can
   sit one after another on the same track (audio clips shorter than 30 s, like sound effects, are skipped).
2. Drop **Sequencer Analyzer** (Browser → Max for Live) on that same track.
3. First time: **Choose Cue Folder** → select your cue pack folder.
   While building, Live may ask *"Would you like to keep the current timing of the clip(s)?"*: click **Yes**.
4. Click **Analyze & Build**. A progress bar shows how far along the analysis is and the time left.
   All songs on the track are processed in order into the same SECTIONS / GUIDE CUES tracks.
5. Keep the device on the track: with **Tempo Follow: On** it switches the tempo whenever playback enters a song
   (up to 16 per track), including when you jump into the middle. Changes you make to the tempo mid-song are left alone.

Re-building is quick: each song's analysis is cached, so only new or changed files are analyzed again.

### Getting the tempo right
Beat trackers can lock onto 2×, ½× or 4/3× the real tempo (for example, 99 instead of 74 BPM on a ballad with a
syncopated feel). Songs whose tempo looks ambiguous are named in the final status ("CHECK THE TEMPO of …").
If a tempo appears in the **clip name**, the **file name** or a **parent folder**
(`74BPM`, `74 bpm`, or key+tempo like `F#150`, `E113`), the device searches only within 6% of it. To fix a wrong BPM,
rename the clip in Live, for example `KUMILIKMU BRIDGE 2X 74BPM`, and press Analyze & Build again. The clip name wins.
Section detection depends on the bar grid, so a corrected tempo also fixes the sections.

Re-running reuses the SECTIONS / GUIDE CUES tracks and replaces only the analyzed songs' clips.

## Documentation
| Doc | What's in it |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Components, data flow, why it's built this way |
| [docs/analysis-engine.md](docs/analysis-engine.md) | Beat/tempo detection, structure detection, output JSON |
| [docs/live-integration.md](docs/live-integration.md) | Live Object Model calls, warping math, tempo recording |
| [docs/cue-packs.md](docs/cue-packs.md) | How cue files are matched to sections |
| [docs/configuration.md](docs/configuration.md) | Settings file and options |
| [docs/testing.md](docs/testing.md) | How it was validated and how to test changes |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common problems and fixes |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## Known limitations
- **Tempo Follow is not automation.** Live's API can't write arrangement automation, so the device sets the tempo
  live. It switches about a quarter beat early to cover its reaction time. It overrides any tempo automation in the
  set, and an offline audio export may not follow it. `"tempoMode": "record"` records real automation instead (plays the song once).
- **One steady tempo per song.** Fine for click-based backing tracks. Songs that drift get a warning.
- **Section labels need a listen.** Songs with vocals use the AI model (All-In-One). Instrumental backing tracks
  use the repetition analysis, because the AI model labels almost everything "instrumental" when there's no singing.
  The repetition rules were tuned on a single song.
- **macOS only** for now (the installer and paths are Mac-specific).

## Credits
- [All-In-One Music Structure Analyzer](https://github.com/mir-aidj/all-in-one) (Taejun Kim & Juhan Nam): sections, beats
- [madmom](https://github.com/CPJKU/madmom): beat and downbeat tracking
- [Demucs](https://github.com/facebookresearch/demucs): source separation used by All-In-One
- [librosa](https://librosa.org): audio features
