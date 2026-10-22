// Simulates the parts of Live's API that aicb_live.js uses, then runs a full build.
const fs = require("fs"), path = require("path"), vm = require("vm");
const ROOT = path.resolve(__dirname, "..");
const node = require(path.join(ROOT, "device", "aicb_node.js"));

// ---------------- fake Live set
let nextId = 1;
const objs = {};
function reg(o) { o.id = nextId++; objs[o.id] = o; return o; }
const song = reg({ kind: "song", _tempo: 113, tempo: 113, record_mode: 0, session_automation_record: 0, loop: 0, current_song_time: 0,
  is_playing: 0, tracks: [], tempoLog: [] });
function mkTrack(name, audio) { return reg({ kind: "track", name, has_audio_input: audio ? 1 : 0, can_be_armed: 1, arm: 0, clips: [] }); }
const songTrack = mkTrack("SEQ", true);
song.tracks.push(mkTrack("1-Click", false), songTrack);
song.tracks[0].arm = 1;
const SR = 44100, DUR = 208.192;
// two songs on one track, auto-warped by Live on import at a wrong tempo (147 BPM). Switching Warp on mimics
// Live's "keep the current timing" answer (markers at the set tempo); FAKE_NO=1 mimics answering "No".
function mkSong(file, start, dur) {
  const c = reg({ kind: "clip", audio: 1, name: file.replace(/^.*\//, "").replace(/\.wav$/, ""), file_path: file,
    start_time: start, start_marker: 0, sample_rate: SR, sample_length: Math.round(dur * SR), loop_start: 0, loop_end: dur, dur,
    _warping: 1, markers: [{ sample_time: 0, beat_time: 0 }, { sample_time: dur, beat_time: dur * 147 / 60 },
                            { sample_time: dur + 0.5, beat_time: dur * 147 / 60 + 1, hidden: true }] });
  Object.defineProperty(c, "warping", {
    get() { return this._warping; },
    set(v) {
      if (v && !this._warping) {
        this._old = this.markers;
        // Live keeps timing at the tempo it currently has (song._tempo lags behind sets, see below)
        this.markers = process.env.FAKE_NO ? this._old
          : [{ sample_time: 0, beat_time: 0 }, { sample_time: this.dur, beat_time: this.dur * song._tempo / 60 },
             { sample_time: this.dur + 0.5, beat_time: this.dur * song._tempo / 60 + 1, hidden: true }];
      }
      this._warping = v ? 1 : 0;
    } });
  c.end_time_fn = x => x._warping ? x.start_time + beatAtM(x.markers, x.dur) - x.start_marker : x.start_time + x.dur * song._tempo / 60;
  songTrack.clips.push(c);
  return c;
}
const songClip = mkSong("/Users/x/Gelap Jadi Terang F#150.wav", 64, DUR);
const song2 = mkSong("/Users/x/Kumilikmu.wav", 600, 120);
songTrack.clips.push(reg({ kind: "clip", audio: 1, file_path: "/Users/x/sfx.wav", start_time: 590, sample_rate: SR,
  sample_length: 5 * SR, warping: 0, end_time: 592, name: "sfx" }));   // a short clip: not a song
function beatAtM(M, t) { M = M.slice().sort((a, b) => a.beat_time - b.beat_time); let i = 0; while (i < M.length - 2 && t > M[i + 1].sample_time) i++;
  const a = M[i], b = M[i + 1]; return a.beat_time + (t - a.sample_time) * (b.beat_time - a.beat_time) / (b.sample_time - a.sample_time); }

function resolve(p) {
  p = p.trim();
  let m;
  if ((m = /^id (\d+)$/.exec(p))) return objs[+m[1]];
  if (p === "live_set") return song;
  if (p === "this_device canonical_parent") return songTrack;
  if ((m = /^live_set tracks (\d+)$/.exec(p))) return song.tracks[+m[1]];
  throw new Error("path " + p);
}
function pathOf(o) { const i = song.tracks.indexOf(o); return i >= 0 ? '"live_set tracks ' + i + '"' : '"id ' + o.id + '"'; }

const observers = [];
class LiveAPI {
  constructor(cb, p) { this.o = resolve(p); this.id = this.o.id; this.path = pathOf(this.o); this.cb = cb; }
  set property(name) { observers.push({ api: this, name }); }
  get(prop) {
    const o = this.o;
    const ids = list => list.flatMap(x => ["id", x.id]);
    switch (prop) {
      case "arrangement_clips": return ids(o.clips);
      case "tracks": return ids(o.tracks);
      case "end_time": return [o.end_time_fn ? o.end_time_fn(o) : o.end_time];
      case "tempo": return [o === song ? song._tempo : o.tempo];
      case "is_audio_clip": return [o.audio ? 1 : 0];
      case "warp_markers": return [JSON.stringify({ warp_markers: o.markers })];
      case "file_path": return [o.file_path !== undefined ? o.file_path : (process.env.SET_PATH || "")];
      default: if (!(prop in o)) throw new Error("no prop " + prop + " on " + o.kind); return [o[prop]];
    }
  }
  set(prop, v) {
    if (prop === "tempo") { setTimeout(() => { song._tempo = v; }, 120); this.o.tempo = v; if (song.record_mode && song.is_playing && song.session_automation_record) song.tempoLog.push(["value", song.current_song_time, v]); return; }
    if (prop === "record_mode" && this.o === song && song.is_playing) song.tempoLog.push([v ? "punch-in" : "punch-out", song.current_song_time]);
    if (prop === "is_playing") { song.is_playing = v; return; }
    this.o[prop] = v;
  }
  call(fn, ...a) {
    const o = this.o;
    switch (fn) {
      case "create_midi_track": song.tracks.splice(a[0], 0, mkTrack("MIDI", false)); return;
      case "create_audio_track": song.tracks.splice(a[0], 0, mkTrack("Audio", true)); return;
      case "create_midi_clip": o.clips.push(reg({ kind: "clip", audio: 0, start_time: a[0], end_time: a[0] + a[1], name: "", color: 0 })); return;
      case "create_audio_clip": {
        const f = a[0]; if (!fs.existsSync(f)) throw new Error("missing " + f);
        o.clips.push(reg({ kind: "clip", audio: 1, file: f, start_time: a[1], warping: 1, loop_end: 1, name: "", color: 0,
          end_time_fn: c => c.start_time + (c.warping ? c.loop_end : c.loop_end * song._tempo / 60) })); return;
      }
      case "delete_clip": o.clips = o.clips.filter(c => c.id !== a[1]); return;
      case "add_warp_marker": {
        const d = a[0]; if (typeof d !== "object") throw new Error("dict expected");
        if (!o.warping) throw new Error("not warped");
        o.markers.push({ beat_time: d.beat_time, sample_time: d.sample_time }); o.markers.sort((x, y) => x.beat_time - y.beat_time);
        for (let i = 1; i < o.markers.length; i++) if (o.markers[i].sample_time <= o.markers[i - 1].sample_time) throw new Error("marker order");
        return;
      }
      case "remove_warp_marker": o.markers = o.markers.filter(m => m.hidden || Math.abs(m.beat_time - a[0]) > 1e-9); return;
      case "move_warp_marker": { const m = o.markers.find(m => Math.abs(m.beat_time - a[0]) < 1e-9); if (!m) throw new Error("no marker at " + a[0]); if (!m.hidden) m.beat_time += a[1]; return; }
      case "start_playing": song.is_playing = 1; song.current_song_time = 30; return;   // insert marker somewhere else
      case "stop_playing": song.is_playing = 0; return;
      default: throw new Error("call " + fn);
    }
  }
}
class Task { constructor(fn, ctx) { this.fn = fn; this.interval = 0; this.h = null; }
  schedule(ms) { this.h = setTimeout(() => this.fn(), ms || 0); }
  repeat() { this.h = setInterval(() => { if (song.is_playing) song.current_song_time += 0.25; this.fn(); }, 1); }
  cancel() { clearTimeout(this.h); clearInterval(this.h); } }

const status = [];
const ctx = { LiveAPI, Task, post: s => process.stdout.write("  post: " + s),
  outlet: (n, ...a) => { if (n === 2 || n === 3) return; if (n === 1) status.push(a.slice(1).join(" ")); else if (a[0] === "analyze") onAnalyze(a.slice(1).join(" "));
    else if (a[0] === "queuetempo") { node.queueTempo(JSON.parse(a[1])); console.log("QUEUED", a[1].slice(0, 120)); }
    else if (a[0] === "writetempo") node.writeTempo(a[1]); },
  arrayfromargs: args => Array.prototype.slice.call(args), console };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, "device", "aicb_live.js"), "utf8"), ctx);

// node side: real plan from the real analysis JSON + real cue folder
const result = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const cueDir = process.argv[3];
function onAnalyze(file) {
  let res = result;
  if (/Kumilikmu/.test(file)) {                     // second song: 74 BPM, 3/4-free simple form
    res = Object.assign({}, result, { tempo_alternatives: process.env.FAKE_ALT ? [98.7] : [], bpm: 74, beat_period: 60 / 74, first_downbeat: 0.0, duration: 120, bars: 37,
      sections: [{ label: "INTRO", start_bar: 1, end_bar: 5 }, { label: "VERSE 1", start_bar: 5, end_bar: 21 },
                 { label: "CHORUS", start_bar: 21, end_bar: 38 }] });
  }
  const plan = node.makePlan(res, { cueDir, leadBars: 2, counts: true, recordTempo: true, tempoMode: process.env.TEMPO_MODE || "follow" });
  setTimeout(() => ctx.plan(JSON.stringify(plan)), 5);
}
ctx.build();
setTimeout(() => {
  console.log("STATUS LOG:\n  " + status.join("\n  "));
  console.log("\nTRACKS:", song.tracks.map(t => t.name).join(" | "));
  const sec = song.tracks.find(t => t.name === "SECTIONS"), cue = song.tracks.find(t => t.name === "GUIDE CUES");
  console.log("\nSECTIONS:"); sec.clips.forEach(c => console.log("  %s %d-%d", c.name.padEnd(13), c.start_time, c.end_time));
  console.log("\nCUES (first 12):"); cue.clips.slice(0, 12).forEach(c => console.log("  %s @%d warp=%d len=%ss %s", c.name.padEnd(13), c.start_time, c.warping, c.loop_end.toFixed(3), path.basename(c.file)));
  console.log("  ... total", cue.clips.length);
  const bpmOf = c => { const v = c.markers.filter(m => !m.hidden); return (60 * (v[v.length - 1].beat_time - v[0].beat_time) / (v[v.length - 1].sample_time - v[0].sample_time)).toFixed(3); };
  console.log("\nSONG CLIPS: warping", songClip.warping, song2.warping, "| warp BPM", bpmOf(songClip), bpmOf(song2),
    "| end beats", songClip.end_time_fn(songClip).toFixed(2), song2.end_time_fn(song2).toFixed(2));
  // re-run to check track reuse
  ctx.build();
  setTimeout(() => {
    console.log("\nRE-RUN tracks:", song.tracks.map(t => t.name).join(" | "), "| sections:", song.tracks.find(t => t.name === "SECTIONS").clips.length, "cues:", song.tracks.find(t => t.name === "GUIDE CUES").clips.length);
    console.log(status[status.length - 1]);
    sweep().then(() => process.exit(0));
  }, 20000);
}, 20000);

// ---- tempo follow: move the playhead through the set like Live does and watch the tempo
async function sweep() {
  ctx.init();
  song.is_playing = 1;
  const changes = [];
  for (let pos = 0; pos <= 800; pos += 0.125) {          // ~one notification per 50 ms at 150 BPM
    const before = song._tempo;
    song.current_song_time = pos;
    observers.filter(o => o.name === "current_song_time").forEach(o => o.api.cb(["current_song_time", pos]));
    await new Promise(r => setTimeout(r, 0));
    await new Promise(r => setTimeout(r, 0));
    if (song._tempo !== before) changes.push([pos, before, song._tempo]);
    if (pos === 300) { song.tempo = 120; song._tempo = 120; }                     // someone changes the tempo mid-song (kept)
    if (pos === 650) { song.current_song_time = 100; observers.forEach(o => o.api.cb(["current_song_time", 100]));
                       await new Promise(r => setTimeout(r, 0)); await new Promise(r => setTimeout(r, 150)); changes.push(["jump back to 100 ->", song._tempo]); }
  }
  console.log("\nFOLLOW: tempo changes during playback [beat, from, to]:", JSON.stringify(changes));
  ctx.followon(0); song.tempo = 99; song._tempo = 99; ctx.checkPos(200); ctx.checkPos(700);
  await new Promise(r => setTimeout(r, 5));
  await new Promise(r => setTimeout(r, 200));
  console.log("FOLLOW off -> tempo untouched:", song._tempo === 99);
}
