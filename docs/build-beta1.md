# Sequencer Analyzer — BUILD beta.1 (one-clip Warp test)

This is the first functional BUILD experiment, not the final v0.8.0 release.

## What works in this build

- ANALYZE remains read-only.
- BUILD 1 (beta) selects the FIRST stable-BPM song with Warp ON from the most recent analysis.
- Sends the detected BPM to a separate Python Remote Script running in Ableton.
- Adds Warp Markers using the approach tested in Experiments 10B–14, sets loop_end and end_marker.
- Rejects a target if it was moved/trimmed, looped, has a nonstandard Warp Map, or would overlap another clip.
- Doesn't create native Song Tempo automation. Enable Lead MANUALLY after inspecting BUILD.
- Doesn't create SECTIONS/GUIDE CUES yet. Those come after the one-song Warp build passes in Live.

## Install

1. Make a COPY of your Live Set before attempting any BUILD.
2. Extract the ZIP. Keep the AMXD and three .js files in one folder.
3. Run `install-build-bridge.command` with a Terminal command:
   `bash /path/to/extracted/install-build-bridge.command`
   (Tip: type `bash ` then drag the .command file into Terminal and press Return.)
   The script copies only `remote/SeqAnalyzer_Remote` into the User Library. It doesn't change the existing .als or prior Max devices.
4. Completely quit and restart Ableton.
5. Open Live Settings > Link, Tempo & MIDI. In the Control Surface dropdown, select `SeqAnalyzer_Remote`. Leave Input and Output blank/None.
6. Drag `Sequencer Analyzer v0.8.0-alpha.amxd` from the extracted folder onto your Arrangement audio track. Its name is unchanged for packaging compatibility; the UI says BUILD beta.1.
7. Test with ONE fresh, untrimmed audio clip first, Warp ON, Loop OFF, Lead OFF. Do NOT use a performance/live show Set.

## Test one clip

1. Run ANALYZE and confirm BPM is plausible.
2. If Warp is OFF, turn it ON in the clip and run ANALYZE again.
3. Stop playback and recording. Leave LEAD OFF during BUILD.
4. Click **BUILD 1 (beta)** only once. It applies the FIRST eligible song in the Analyze list.
5. Verify in Live Clip View that segment BPM is near the analyzed BPM, that clip length covers the whole audio, and that no other clip changed.
6. Only after verifying, enable LEAD manually. Check Live's native tempo automation.
7. Save only the COPY when you are satisfied.

The function intentionally refuses a clip when the existing Warp Marker list has more or fewer than two markers. Re-import a clean clip in a fresh test Set if necessary; it will not destroy a custom Warp Map.

If you see BUILD BLOCKED/FAILED, do NOT click repeatedly. Copy the Max Console error and inspect the clip. If BUILD partially modified the clip before an error, press Undo or close the test Set without saving.

## Limitations / next steps

- This is experimental code. GitHub Actions tests the planning logic with fake clips but cannot prove correct behavior in Ableton 12.3.2.
- No built-in rollback on failure. Use a disposable Set.
- No full multi-clip BUILD or overlap rearrangement. No cue or MIDI clip generation in this beta.
- No automatic activation or reading of Lead.
- Only steady-tempo audio starting at file time 0 and Arrangement clip start, no clip trimming, no custom Warp Map, Loop OFF.
- Playback-time Tempo Follow should not be used to judge the new native automation workflow.
- A clip's arrangement end may update on a later Live tick; visually inspect it.

If the remote script is missing from the Control Surface menu, verify the User Library Remote Scripts path and inspect Ableton's Log.txt; remember to restart Live after installing.

## Send back after testing

Please send: detected BPM, Warp Markers before/after (or screenshot of Clip View), arrangement clip length before/after, BUILD status in the device, and whether manually enabling Lead produces the expected tempo envelope.
