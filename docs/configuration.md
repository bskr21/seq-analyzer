# Configuration

Settings live in `~/Library/Application Support/AICueBuilder/config.json`.
(The support folder keeps the tool's first name, AI Cue Builder, so existing installs keep their models.) The file is created when you first choose a cue folder.

```json
{
 "cueDir": "/Users/you/Documents/Music/Click and Guide Samples/English Guides",
 "python": "~/Library/Application Support/AICueBuilder/venv/bin/python",
 "engine": "~/Library/Application Support/AICueBuilder/engine/aicb_analyze.py",
 "leadBars": 2,
 "counts": true,
 "recordTempo": true,
 "tempoMode": "file",
 "structure": "auto",
 "vocalThreshold": 0.12
}
```

| Key | Default | Meaning |
|---|---|---|
| `cueDir` | none | Cue pack folder (set by **Choose Cue Folder**) |
| `leadBars` | 2 | Bars before a section that its name is spoken |
| `counts` | true | Spoken count in the bar before each section |
| `recordTempo` | true | Write tempo at the end of **Analyze & Build** |
| `tempoMode` | `file` | `file`: **Write Tempo** writes the steps into the saved set (save first, reopen after). `record`: records the automation in Live (plays the song once). `set`: just sets the tempo, no automation |
| `structure` | `auto` | Section engine: `auto` (vocal check), `allin1` (always AI model), `heuristic` (always repetition analysis, fastest: skips stem separation) |
| `vocalThreshold` | 0.12 | Vocal share below which a song counts as instrumental |
| `python`, `engine` | install paths | Change only if you move the install |

Changes take effect on the next run, so there's no need to reload the device.

## Files on disk
| Path | Contents |
|---|---|
| `~/Library/Application Support/AICueBuilder/venv` | Private Python 3.11 + libraries |
| `~/Library/Application Support/AICueBuilder/engine` | Analysis engine |
| `~/Library/Application Support/AICueBuilder/tempo_queue.json` | Songs analyzed but not yet written by Write Tempo |
| `<set folder>/Backup` | Copy of the set made before each Write Tempo |
| `~/Library/Caches/AICueBuilder` | Separated stems and spectrograms (safe to delete) |
| `~/.cache/huggingface`, `~/.cache/torch` | Downloaded AI models |
| `User Library/Presets/Audio Effects/Max Audio Effect/Sequencer Analyzer` | The device (Browser → Max for Live) |
