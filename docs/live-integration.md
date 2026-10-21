# Live integration (`aicb_live.js`)

Written in classic ES5 for Max's `[js]` object. All Live access goes through `LiveAPI`.
Reference: [Live Object Model](https://docs.cycling74.com/apiref/lom/).

## LOM calls used

| Purpose | Object | Call / property |
|---|---|---|
| Find the song | `this_device canonical_parent` | `has_audio_input`, `arrangement_clips`, clip `is_audio_clip`, `file_path`, `start_time`, `end_time` |
| Warp | Clip | `warping`, `warp_markers`, `add_warp_marker {beat_time, sample_time}`, `remove_warp_marker`, `move_warp_marker`, `start_marker`, `sample_length`, `sample_rate` |
| Tracks | Song | `create_midi_track(index)`, `create_audio_track(index)`; Track `name` |
| Section clips | Track | `create_midi_clip(start, length)`; Clip `name`, `color` |
| Cue clips | Track | `create_audio_clip(path, position)`; Clip `warping = 0`, `loop_end` (seconds when unwarped) |
| Re-run cleanup | Track | `delete_clip` |
| Tempo | Song | `tempo`, `record_mode`, `session_automation_record` (Automation Arm), `loop`, `current_song_time`, `start_playing`, `stop_playing`, `is_playing`; Track `arm`, `can_be_armed` |

Live applies some property changes (notably `warping`) later rather than immediately, so steps are spaced
with `Task` timers (100–500 ms).

## Warping the song onto the grid
Given the plan's `bpm`, `first_downbeat` (t₀) and bar length:
1. Turn warping on and read the existing markers.
2. Choose a reference downbeat `tA` (the first one at or after 5 ms) and the last full downbeat `tB`.
3. Add markers at `tA` and `tB` using the beat values the current markers already give them, so timing doesn't change yet.
   Existing markers at the same spot are reused (this makes re-runs safe).
4. Remove every other marker, then move B so that `bB = bA + (tB − tA) · bpm/60`. This gives an exact constant tempo.
5. Shift both markers by `δ` so that `start_time + (bA − start_marker)` lands on the nearest bar line.
6. Bar *n* in the arrangement is `bar0 + (n − 1) · meter`, where `bar0` is derived from step 5.

## Cue placement
For a section starting at arrangement beat `S`:
- name cue at `S − leadBars·meter`, trimmed so it ends before the count starts
- count cues "1…meter" at `S − meter + i`, each trimmed to one beat
- a name cue is skipped if it would start before the previous section starts (very short sections)

## Tempo recording
The LOM has no function to write arrangement automation, so the device records it in real time.
Step position `P` is the bar line of the first cue or the song start, whichever is earlier. The end `E` is the end of the song clip.
1. Save the record and Automation Arm states, the loop setting, and which tracks are armed. Disarm all tracks, so no audio or MIDI is recorded.
2. Turn on Automation Arm with Arrangement Record off, then start playback. `start_playing` starts at the
   insert marker, so the device then jumps the playhead to one bar before `P`.
3. Poll every 20 ms. When the playhead reaches `P`, punch in (`record_mode = 1`) and set `song.tempo = bpm`.
4. At `E`, punch out and stop, then restore everything. The progress bar follows the playhead in the meantime.

Live writes the new value only between punch-in and punch-out, then returns to the previous tempo or envelope.
So in a medley, the songs before and after keep their tempo. Pressing Stop cancels the recording; the tempo is then written only up to that point.

`"tempoMode": "set"` skips the recording and just sets `song.tempo` (no automation). `recordTempo: false` leaves tempo alone.

## Progress bar
`aicb_live.js` resizes a panel (`progfill`) through `thispatcher` (`script sendbox progfill presentation_rect …`)
from the `PERCENT` lines relayed by Node, and from the playhead position during tempo recording.
