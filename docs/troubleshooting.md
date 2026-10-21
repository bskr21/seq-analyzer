# Troubleshooting

| Status line / symptom | Cause | Fix |
|---|---|---|
| `Error: put the device on the audio track that holds the song` | Device on a MIDI/return/main track | Move it to the song's audio track |
| `Error: drag the song into this track's Arrangement first` | No audio clip in the Arrangement on that track | Drop the song in Arrangement View (not Session) |
| `Analysis engine not installed - run Setup first` | venv missing | Run `setup.command` |
| `Choose your cue folder first` | No `cueDir` set | Click **Choose Cue Folder** |
| `… (built-in analysis)` at the end | All-In-One failed (often the first run is offline) | Connect to the internet and run again; check the Max window for the error |
| `No cue file for: …` | No file matching that label | Add a file named `… - <Label>.wav`, see [cue-packs.md](cue-packs.md) |
| Tempo doesn't change when the song plays | Tempo Follow off, device removed, or the song wasn't built in this version | Turn **Tempo Follow: On**, keep the device on the track, run **Analyze & Build** again |
| "Re-Enable Automation" lights up | The set has tempo automation, and Tempo Follow overrode it | Delete the tempo automation, or turn Tempo Follow off for that song |
| Tempo change lands slightly early | 0.25-beat lookahead | Intended: it covers the device's reaction time |
| (record mode) `tempo not written` / `only up to where you pressed Stop` | Playback didn't start, or was stopped | Run **Analyze & Build** again and let the pass finish |
| Sections are all INTRO / INSTRUMENTAL (v0.1.x) | AI model on an instrumental track | Update to v0.2.0 (vocal check), or set `"structure": "heuristic"` |
| Analysis takes long | Stem separation on CPU | The progress bar shows the time left. For backing tracks, `"structure": "heuristic"` skips stems |
| `Tempo drifts …` | Song isn't steady | Check the grid by ear; manual warp markers may be needed |
| Progress bar stays dark (v0.2.0) | Bar didn't redraw in the device | Update to v0.3.0 |
| Device won't load / shows an empty box | `.amxd` not accepted | Drop an empty Max Audio Effect, open it in Max, open `Sequencer Analyzer.maxpat`, copy everything into it, then save it next to the two `.js` files |
| Buttons do nothing (v0.1.0) | Button clicks were filtered out | Update to v0.1.1 and re-run `setup.command` |
| `setup.command` "can't be opened" | macOS Gatekeeper | Right-click → Open, or run `bash setup.command` in Terminal |

The Max window (Max editor → Window → Max Console) shows every `SeqAnalyzer:` message and any Live API error.
