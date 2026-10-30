# SeqAnalyzer_Remote: G0 installation and verification

This is an Ableton Live 12 Remote Script. Use a **copy** of a Live Set containing one audio Arrangement clip. Live testing is performed by the owner; offline mock tests do not prove Live behavior.

## Install

1. Quit Ableton Live completely.
2. From the repository root, run `bash remote/install-build-bridge.command`. It copies `__init__.py`, `bridge_protocol.py`, and `warp_build.py` into `~/Music/Ableton/User Library/Remote Scripts/SeqAnalyzer_Remote/`. If your User Library is elsewhere, copy those three files to its `Remote Scripts/SeqAnalyzer_Remote/` directory instead.
3. Relaunch Live. Open **Settings > Link, Tempo & MIDI** and select **SeqAnalyzer_Remote** as a Control Surface. Set Input and Output to **None**.
4. Check for `SeqAnalyzer Remote listening on 127.0.0.1:9128` in Live's `Log.txt`. On macOS, find the current version's log under `~/Library/Preferences/Ableton/Live 12*/Log.txt`; run `find "$HOME/Library/Preferences/Ableton" -name Log.txt -print` if unsure. If the port is unavailable, Log.txt reports it. Check with `lsof -nP -iTCP:9128`.

The older repository-root `install-build-bridge.command` installs only two files and is not suitable for protocol v1. Use the command under `remote/` above.

## Check the bridge

With Live running and the Control Surface selected:

```sh
printf '{"v":1,"id":"ping-1","action":"ping","params":{"protocol_min":1,"protocol_max":1}}\n' | nc -w 5 127.0.0.1 9128
```

Expect `ok:true`, the same `id`, `protocol_version:1`, a `session_id`, and `capabilities` containing `list_clips`, `build_one`, and `read_clip_state`. `ECONNREFUSED` means the script is not listening; check the Control Surface choice and Log.txt. The `session_id` changes when the Remote Script reloads.

## Build one song and verify after reopen

1. Stop playback and recording. Choose an untrimmed, non-looping audio Arrangement clip with Warp ON and exactly two original warp markers. Note its track index (zero-based), name, Arrangement start in beats, original audio duration in seconds, and analyzed BPM. Ensure the planned end (`start + duration × BPM / 60`) does not overlap the next clip.
2. Run `list_clips` and copy its exact `clip_ref` into the next requests. The example below uses track 0, start 64 beats, name `GJT`, duration 208 seconds, BPM 150. Replace all values with those of your clip.

```sh
printf '{"v":1,"id":"list-1","action":"list_clips","params":{"track_index":0}}\n' | nc -w 5 127.0.0.1 9128
printf '{"v":1,"id":"dry-1","action":"build_one","params":{"clip_ref":{"track_index":0,"start":64,"name":"GJT"},"duration":208,"bpm":150,"dry_run":true}}\n' | nc -w 5 127.0.0.1 9128
printf '{"v":1,"id":"build-1","action":"build_one","params":{"clip_ref":{"track_index":0,"start":64,"name":"GJT"},"duration":208,"bpm":150}}\n' | nc -w 5 127.0.0.1 9128
printf '{"v":1,"id":"read-1","action":"read_clip_state","params":{"clip_ref":{"track_index":0,"start":64,"name":"GJT"}}}\n' | nc -w 5 127.0.0.1 9128
```

3. Record the `build_one` response and the separate `read_clip_state` response. The last is authoritative: check marker positions, implied BPM segments, `end_time`, and the clip in Live. Never automatically retry `build_one` after a timeout; read state first.
4. Save the Set, quit Live, reopen it, select the Control Surface if needed, and run `ping` and `read_clip_state` again. Compare the marker list, implied BPM, and end time before and after reopen. The new `session_id` is expected; the clip's state should persist.
5. Enable **Lead** manually after BUILD. Its status cannot be read or set through this API. Capture the before and after JSON, a screenshot of the clip warp markers, and relevant Log.txt lines for G0 evidence. Do not include private audio paths in a public report.

The Remote Script does not create SECTIONS or GUIDE CUES in M0. Live 12 behavior, including hidden end markers and delayed end-time changes, remains to be verified on the owner's installation.
