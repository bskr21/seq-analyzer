# Troubleshooting

| Status line / symptom | Cause | Fix |
|---|---|---|
| `Error: put the device on the audio track that holds the song` | Device on a MIDI/return/main track | Move it to the song's audio track |
| `Error: drag the song into this track's Arrangement first` | No audio clip in the Arrangement on that track | Drop the song in Arrangement View (not Session) |
| `Analysis engine not installed - run Setup first` | venv missing | Run `setup.command` |
| `Choose your cue folder first` | No `cueDir` set | Click **Choose Cue Folder** |
| `… (built-in analysis)` at the end | All-In-One failed (often the first run is offline) | Connect to the internet and run again; check the Max window for the error |
| `No cue file for: …` | No file matching that label | Add a file named `… - <Label>.wav`, see [cue-packs.md](cue-packs.md) |
| `Tempo not recorded (transport did not start)` | Playback didn't start within 10 s | Turn off Count-In and click **Re-record Tempo**, or draw the step by hand |
| `Tempo drifts …` | Song isn't steady | Check the grid by ear; manual warp markers may be needed |
| Device won't load / shows an empty box | `.amxd` not accepted | Drop an empty Max Audio Effect, open it in Max, open `AI Cue Builder.maxpat`, copy everything into it, then save it next to the two `.js` files |
| `setup.command` "can't be opened" | macOS Gatekeeper | Right-click → Open, or run `bash setup.command` in Terminal |

The Max window (Max editor → Window → Max Console) shows every `AICB:` message and any Live API error.
