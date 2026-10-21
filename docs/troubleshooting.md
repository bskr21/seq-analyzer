# Troubleshooting

| Status line / symptom | Cause | Fix |
|---|---|---|
| `Error: put the device on the audio track that holds the song` | Device on a MIDI/return/main track | Move it to the song's audio track |
| `Error: drag the song into this track's Arrangement first` | No audio clip in the Arrangement on that track | Drop the song in Arrangement View (not Session) |
| `Analysis engine not installed - run Setup first` | venv missing | Run `setup.command` |
| `Choose your cue folder first` | No `cueDir` set | Click **Choose Cue Folder** |
| `… (built-in analysis)` at the end | All-In-One failed (often the first run is offline) | Connect to the internet and run again; check the Max window for the error |
| `No cue file for: …` | No file matching that label | Add a file named `… - <Label>.wav`, see [cue-packs.md](cue-packs.md) |
| `Save the set first (Cmd+S)…` | Set never saved, or saved before the build | Press ⌘S, then **Write Tempo** |
| Tempo lane unchanged after Write Tempo | Live still shows the version in memory | File → Open Recent → your set |
| Lost changes after reopening | Edits made between Write Tempo and reopening | Write Tempo last, then reopen right away. The previous file is in `Backup` |
| `Nothing to write` | No song analyzed since the last write | Run **Analyze & Build** |
| (record mode) `tempo not written` / `only up to where you pressed Stop` | Playback didn't start, or was stopped | Press **Write Tempo** again and let it play |
| Sections are all INTRO / INSTRUMENTAL (v0.1.x) | AI model on an instrumental track | Update to v0.2.0 (vocal check), or set `"structure": "heuristic"` |
| Analysis takes long | Stem separation on CPU | The progress bar shows the time left. For backing tracks, `"structure": "heuristic"` skips stems |
| `Tempo drifts …` | Song isn't steady | Check the grid by ear; manual warp markers may be needed |
| Progress bar stays dark (v0.2.0) | Bar didn't redraw in the device | Update to v0.3.0 |
| Device won't load / shows an empty box | `.amxd` not accepted | Drop an empty Max Audio Effect, open it in Max, open `Sequencer Analyzer.maxpat`, copy everything into it, then save it next to the two `.js` files |
| Buttons do nothing (v0.1.0) | Button clicks were filtered out | Update to v0.1.1 and re-run `setup.command` |
| `setup.command` "can't be opened" | macOS Gatekeeper | Right-click → Open, or run `bash setup.command` in Terminal |

The Max window (Max editor → Window → Max Console) shows every `SeqAnalyzer:` message and any Live API error.
