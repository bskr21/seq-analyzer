# Live integration (`aicb_live.js`)

Written in classic ES5 for Max's `[js]` object. All Live access goes through `LiveAPI`.
Reference: [Live Object Model](https://docs.cycling74.com/apiref/lom/).

## LOM calls used

| Purpose | Object | Call / property |
|---|---|---|
| Find the song | `this_device canonical_parent` | `has_audio_input`, `arrangement_clips`, clip `is_audio_clip`, `file_path`, `start_time`, `end_time` |
| Lock song | Clip + Song | `song.tempo`, `warping`, `warp_markers`, `remove_warp_marker`, `move_warp_marker`, `start_marker`, `end_time` |
| Tracks | Song | `create_midi_track(index)`, `create_audio_track(index)`; Track `name` |
| Section clips | Track | `create_midi_clip(start, length)`; Clip `name`, `color` |
| Cue clips | Track | `create_audio_clip(path, position)`; Clip `warping = 0`, `loop_end` (seconds when unwarped) |
| Re-run cleanup | Track | `delete_clip` |
| Tempo | Song | `tempo`, `record_mode`, `session_automation_record` (Automation Arm), `loop`, `current_song_time`, `start_playing`, `stop_playing`, `is_playing`; Track `arm`, `can_be_armed` |

Live applies some property changes (notably `warping`) later rather than immediately, so steps are spaced
with `Task` timers (100–500 ms).

## Locking a song at its BPM (warped)
1. If the clip is already warped as one straight line at exactly the song's BPM (a rebuild), nothing changes.
2. Otherwise: set `song.tempo` to the song's BPM; if the clip is warped, switch Warp off; then switch Warp **on**.
   Live keeps the current timing, so the song is warped at exactly the BPM. Live may ask about this; the device
   polls every 200 ms (up to 2 minutes) until Warp is on.
3. Check: the warp markers must form one straight line at the BPM (±0.05%). If Live auto-warped instead, or "No" was
   clicked, the device keeps the first and last markers, removes the rest, and moves the last one to the exact BPM.
   If that still fails, the song is reported and skipped.
4. Position: the arrangement beat of the first downbeat is `start_time + (beat_at(first_downbeat) − start_marker)`,
   snapped to the bar line when within 0.25 beat. The song end is the clip's `end_time` (fixed in beats now).

Why not unwarped (v0.5.0)? An unwarped clip's length in beats follows the current set tempo, so at another song's tempo
it grows into the next song and its Tempo Follow range overlaps the next one's.

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
  BPM. When ranges touch or overlap, the song that starts last wins.
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
