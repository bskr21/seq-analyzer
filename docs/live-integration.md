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

## Tempo
The LOM has no function to write arrangement automation. Three modes (`tempoMode`):

### `file` (default): Write Tempo edits the saved set
1. After each build the device queues `{start, end, bpm, song, sections}` in `tempo_queue.json`.
   `start` is the bar line of the first cue or the song start, whichever is earlier; `end` is the end of the last section clip.
2. **Write Tempo** reads `song.file_path`. An unsaved set is refused.
3. `aicb_tempo.py` checks that the saved file contains the song file and all its section clips.
   If not, you saved before building, so it asks you to save first.
4. It copies the set to `Backup/<name> [date time].als`, then writes into the main track's tempo envelope
   (creating it if needed). For each song it replaces any points between `start` and `end` with four points:
   `(start, tempo before)`, `(start, bpm)`, `(end, bpm)`, `(end, tempo after)`. Songs before and after keep theirs.
   Writing again for the same song gives the same result.
5. The user reopens the set (File → Open Recent).

### `record`: real-time recording in Live
Playback runs from one bar before `start`. At `start` the device punches in (Automation Arm + Arrangement Record)
and sets `song.tempo`; at the song end it punches out. All armed tracks are disarmed during the take and restored afterwards.
Live returns to the previous tempo after punch-out. This plays the song once, and pressing Stop cancels.

### `set`
Just sets `song.tempo`, with no automation.

## Progress bar
A `[jsui]` (`aicb_progress.js`) draws the bar; `aicb_live.js` sends it 0–100 from the `PERCENT` lines relayed
by Node (and from the playhead position in `record` mode).
