# Live integration (`aicb_live.js`)

Written in classic ES5 for Max's `[js]` object. All Live access goes through `LiveAPI`.
Reference: [Live Object Model](https://docs.cycling74.com/apiref/lom/).

## LOM calls used

| Purpose | Object | Call / property |
|---|---|---|
| Find the song | `this_device canonical_parent` | `has_audio_input`, `arrangement_clips`, clip `is_audio_clip`, `file_path`, `start_time`, `end_time` |
| Place song | Clip | `warping` (set to 0), `loop_start`, `loop_end`, `sample_length`, `sample_rate` |
| Tracks | Song | `create_midi_track(index)`, `create_audio_track(index)`; Track `name` |
| Section clips | Track | `create_midi_clip(start, length)`; Clip `name`, `color` |
| Cue clips | Track | `create_audio_clip(path, position)`; Clip `warping = 0`, `loop_end` (seconds when unwarped) |
| Re-run cleanup | Track | `delete_clip` |
| Tempo | Song | `tempo`, `record_mode`, `session_automation_record` (Automation Arm), `loop`, `current_song_time`, `start_playing`, `stop_playing`, `is_playing`; Track `arm`, `can_be_armed` |

Live applies some property changes (notably `warping`) later rather than immediately, so steps are spaced
with `Task` timers (100–500 ms).

## Placing a song on the grid (unwarped)
1. If Live auto-warped the clip on import, set `warping = 0` and wait 500 ms (Live applies it later).
2. Read `start_time` (beats) and `loop_start` / `loop_end`, which are seconds for unwarped clips.
3. Arrangement beat of file time *t*, while the song plays at its BPM: `start_time + (t − loop_start) · bpm/60`.
4. The first downbeat's beat is snapped to the nearest bar line when it's within 0.25 beat (decoder delay and
   detection jitter). Otherwise sections follow the audio exactly, and the status line suggests moving the clip.
5. Song end = `start_time + (loop_end − loop_start) · bpm/60`. `end_time` isn't used, because for unwarped clips it
   depends on the current set tempo.

## Cue placement
For a section starting at arrangement beat `S`:
- name cue at `S − leadBars·meter`, trimmed so it ends before the count starts
- count cues "1…meter" at `S − meter + i`, each trimmed to one beat
- a name cue is skipped if it would start before the previous section starts (very short sections)

## Tempo
The LOM has no function to write arrangement automation, and arrangement clip envelopes can only modulate.
Three modes (`tempoMode`):

### `follow` (default): Tempo Follow
- After a build, the device stores each song's range and BPM in hidden parameters: 16 slots of
  `FollowStart<i>`, `FollowEnd<i>`, `FollowBpm<i>` ("stored only"). They're saved with the set and restored when it loads.
  `start` is the bar line of the first cue or the song start, whichever is earlier; `end` is the end of the last section clip.
- An observer on `live_set current_song_time` checks every playhead update. When the playhead **enters** a song's
  range (`start − 0.25 beat` up to `end`, from outside it, including jumps), the device sets `song.tempo` to that song's
  BPM. When songs are back to back, the upcoming song wins inside the 0.25-beat lookahead.
  The Live API doesn't allow changes inside a notification, so the change is deferred with a `Task`.
- It acts only on entering, so a tempo change made mid-song is kept. The **Tempo Follow** switch (saved with the set) turns it off.
- The 0.25-beat lookahead covers the notification interval (roughly 50 ms).
- Limits: it overrides any tempo automation in the set (Live shows Re-Enable Automation), and an offline export may not follow it.

### `record`: real-time recording in Live
At the end of a build, playback runs from one bar before `start`. At `start` the device punches in (Automation Arm +
Arrangement Record) and sets `song.tempo`; at the song end it punches out. Armed tracks are disarmed during the take and
restored afterwards. This plays the song once, and pressing Stop cancels.

### `set`
Just sets `song.tempo` once, with no automation.

## Progress bar
A `[jsui]` (`aicb_progress.js`) draws the bar; `aicb_live.js` sends it 0–100 from the `PERCENT` lines relayed
by Node (and from the playhead position in `record` mode).
