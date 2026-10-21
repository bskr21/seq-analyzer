# Sequencer Analyzer for Ableton Live

A Max for Live device that prepares a worship/playback **sequence** in one click. You drop a song
into Live's Arrangement and press **Analyze & Build**. The device then:

1. **Detects the BPM** and bar grid of the song, and locks the clip to that grid with warp markers.
2. **Writes tempo automation** from the first cue to the end of the last section (instant, no playback).
3. **Finds the song structure** (Intro, Verse, Chorus, Bridge, Instrumental, Breakdown, Outro…).
4. Creates a **SECTIONS** MIDI track with one named, colored clip per section.
5. Creates a **GUIDE CUES** audio track with spoken cues from your own cue pack: the section name
   two bars ahead, then "1 2 3 4" in the bar before the section.

> Status: **v0.3.0, prototype.** Tested against a simulated Live API and real song analysis,
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
1. Drag the song onto an **audio track** in Arrangement View, starting on a bar line.
2. Drop **Sequencer Analyzer** (Browser → Max for Live) on that same track.
3. First time: **Choose Cue Folder** → select your cue pack folder.
4. Click **Analyze & Build**. A progress bar shows how far along the analysis is and the time left.
   Repeat for as many songs as you like (one device per song track).
5. **Save the set (⌘S)**, then click **Write Tempo**. Every analyzed song gets its tempo step in the saved file
   (a backup goes to the set's `Backup` folder).
6. **Reopen the set** (File → Open Recent) to see the tempo lane. Live doesn't reload a file it already has open.

Re-running on the same song reuses the SECTIONS / GUIDE CUES tracks and replaces only that song's clips.

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
- **Tempo needs a save and a reopen.** Live's API cannot write arrangement automation, so Write Tempo edits the
  saved set file and you reopen it. `"tempoMode": "record"` records the automation in Live instead (plays the song once).
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
