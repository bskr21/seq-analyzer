# Configuration

Settings live in `~/Library/Application Support/AICueBuilder/config.json`. The file is created when you first choose a cue folder.

```json
{
 "cueDir": "/Users/you/Documents/Music/Click and Guide Samples/English Guides",
 "python": "~/Library/Application Support/AICueBuilder/venv/bin/python",
 "engine": "~/Library/Application Support/AICueBuilder/engine/aicb_analyze.py",
 "leadBars": 2,
 "counts": true,
 "recordTempo": true
}
```

| Key | Default | Meaning |
|---|---|---|
| `cueDir` | none | Cue pack folder (set by **Choose Cue Folder**) |
| `leadBars` | 2 | Bars before a section that its name is spoken |
| `counts` | true | Spoken count in the bar before each section |
| `recordTempo` | true | Record the tempo step at the end of **Analyze & Build** |
| `python`, `engine` | install paths | Change only if you move the install |

Changes take effect on the next run, so there's no need to reload the device.

## Files on disk
| Path | Contents |
|---|---|
| `~/Library/Application Support/AICueBuilder/venv` | Private Python 3.11 + libraries |
| `~/Library/Application Support/AICueBuilder/engine` | Analysis engine |
| `~/Library/Caches/AICueBuilder` | Separated stems and spectrograms (safe to delete) |
| `~/.cache/huggingface`, `~/.cache/torch` | Downloaded AI models |
| `User Library/Presets/Audio Effects/Max Audio Effect/AI Cue Builder` | The device |
