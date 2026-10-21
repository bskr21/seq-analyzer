# Cue packs

Point the device at any folder; it is searched recursively for `.wav .aif .aiff .mp3 .flac .m4a`
(hidden files and `__MACOSX` are skipped).

## Name matching
The **cue key** is the part of the file name after the last `" - "`, lower-cased, with `-`/`_` turned into spaces:

| File | Key |
|---|---|
| `English Female - Verse 2.wav` | `verse 2` |
| `English Female - Pre Chorus.wav` | `pre chorus` |
| `Chorus.wav` | `chorus` |
| `English Female - 3.wav` | `3` |

For a section label the device tries, in order: the exact label (`verse 2`), then without its
number (`verse`), then short forms (`inst`, `break`). Counts use keys `1`…`4` (or `1`…`3` in 3/4).
If two files share a key, the one inside a folder whose name contains "section" wins.

Labels with no matching file are listed at the end of the status line ("No cue file for: …").

## Durations
Durations are read from WAV/AIFF headers, so trimming is exact. For other formats the device assumes 1.5 s.
