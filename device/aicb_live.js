// AI Cue Builder - Live API side (Max [js] object, classic ES5 JavaScript).
// Outlet 0 -> node.script (analyze requests), outlet 1 -> status text.
autowatch = 1;
inlets = 1;
outlets = 2;

var SECTIONS_NAME = "SECTIONS";
var CUES_NAME = "GUIDE CUES";
var COLORS = {
  intro: 0x7FA8C9, verse: 0x5BB55B, "pre chorus": 0xE6B33C, chorus: 0xE5533D, bridge: 0x9B6BD6,
  instrumental: 0x3FB6B2, breakdown: 0x8C8C8C, interlude: 0x6F8FD8, outro: 0x7FA8C9
};
var CUE_COLOR = 0xD08AE0;

var state = null;   // per-run data

function say(msg) { outlet(1, "set", msg); post("AICB: " + msg + "\n"); }
function fail(msg) { say("Error: " + msg); state = null; }

// ------------------------------------------------------------------ LiveAPI helpers
function api(path) { return new LiveAPI(null, path); }
function byId(id) { return new LiveAPI(null, "id " + id); }
function num(o, prop) { return Number(o.get(prop)[0]); }
function str(o, prop) { var v = o.get(prop); return (v instanceof Array) ? v.join(" ") : String(v); }
function idList(o, prop) {
  var r = o.get(prop), out = [];
  for (var i = 0; i + 1 < r.length; i += 2) if (r[i] == "id" && Number(r[i + 1]) > 0) out.push(Number(r[i + 1]));
  return out;
}
function later(fn, ms) { var t = new Task(fn, this); t.schedule(ms || 0); return t; }
function trackIndex(o) { var m = /tracks (\d+)/.exec(String(o.path)); return m ? Number(m[1]) : -1; }
function clipAt(track, start) {
  var ids = idList(track, "arrangement_clips");
  for (var i = 0; i < ids.length; i++) {
    var c = byId(ids[i]);
    if (Math.abs(num(c, "start_time") - start) < 0.01) return c;
  }
  return null;
}

// ------------------------------------------------------------------ entry points
function build() {
  if (state && state.busy) { say("Already working..."); return; }
  var tr = api("this_device canonical_parent");
  var tIdx = trackIndex(tr);
  if (tIdx < 0 || num(tr, "has_audio_input") != 1) { fail("put the device on the audio track that holds the song"); return; }
  var best = null, bestLen = 0, ids = idList(tr, "arrangement_clips");
  for (var i = 0; i < ids.length; i++) {
    var c = byId(ids[i]);
    if (num(c, "is_audio_clip") != 1) continue;
    var len = num(c, "end_time") - num(c, "start_time");
    if (len > bestLen) { best = c; bestLen = len; }
  }
  if (!best) { fail("drag the song into this track's Arrangement first"); return; }
  state = { busy: true, track: tr, clip: best, clipId: best.id, file: str(best, "file_path") };
  say("Analyzing... (first run can take a few minutes)");
  outlet(0, "analyze", state.file);
}

function failed() { if (state) state.busy = false; }
// messages coming back from node.script
function status() { say(arrayfromargs(arguments).join(" ")); }
function options() {}

function plan() {
  if (!state) return;
  var txt = arrayfromargs(arguments).join(" ");
  try { state.plan = JSON.parse(txt); } catch (e) { fail("could not read analysis result"); return; }
  say("Tempo " + state.plan.bpm + " BPM - locking song to the grid");
  warpSong();
}

function recordtempo() {   // re-run only the tempo step for the last analyzed song
  if (!state || !state.plan || state.songStartBeat === undefined) { say("Run Analyze & Build first"); return; }
  recordTempo(function () { say("Tempo automation written"); });
}

// ------------------------------------------------------------------ 1. warp song clip to the detected grid
function markers(c) {
  var raw = str(c, "warp_markers"), o = JSON.parse(raw);
  var arr = o.warp_markers || o;
  arr.sort(function (a, b) { return a.beat_time - b.beat_time; });
  return arr;
}
function beatAt(M, t, bpm) {
  if (M.length < 2) return (M.length ? M[0].beat_time + (t - M[0].sample_time) * bpm / 60 : t * bpm / 60);
  var i = 0;
  while (i < M.length - 2 && t > M[i + 1].sample_time) i++;
  var a = M[i], b = M[i + 1];
  return a.beat_time + (t - a.sample_time) * (b.beat_time - a.beat_time) / (b.sample_time - a.sample_time);
}

// add a marker unless one already sits there (re-runs); replace a mismatched one
function ensureMarker(c, beat, t) {
  var M = markers(c);
  for (var i = 0; i < M.length; i++) {
    if (Math.abs(M[i].sample_time - t) < 0.0005) return;
    if (Math.abs(M[i].beat_time - beat) < 0.001) c.call("remove_warp_marker", M[i].beat_time);
  }
  c.call("add_warp_marker", { beat_time: beat, sample_time: t });
}

function warpSong() {
  var c = byId(state.clipId), p = state.plan;
  if (num(c, "warping") != 1) { c.set("warping", 1); later(warpSong2, 500); } else warpSong2();
}
function warpSong2() {
  var c = byId(state.clipId), p = state.plan;
  var barSec = p.beat_period * p.meter, k = p.bpm / 60;
  var sampleLen = num(c, "sample_length") / num(c, "sample_rate");
  // reference downbeats inside the file
  var refBar = 1, tA = p.first_downbeat;
  while (tA < 0.005) { tA += barSec; refBar++; }
  var lastBar = refBar + Math.floor((Math.min(sampleLen, p.duration) - 0.05 - tA) / barSec);
  var tB = tA + (lastBar - refBar) * barSec;
  if (tB <= tA + barSec) { fail("song is too short"); return; }
  var M = markers(c);
  var bA = beatAt(M, tA, p.bpm), bB = beatAt(M, tB, p.bpm);
  try {
    ensureMarker(c, bA, tA);
    ensureMarker(c, bB, tB);
  } catch (e) { fail("could not add warp markers (" + e + ")"); return; }
  later(function () {
    // keep only our two markers
    var M2 = markers(c);
    for (var i = 0; i < M2.length; i++) {
      var b = M2[i].beat_time;
      if (Math.abs(b - bA) > 0.001 && Math.abs(b - bB) > 0.001) { try { c.call("remove_warp_marker", b); } catch (e) {} }
    }
    // exact tempo between the markers
    var bB2 = bA + (tB - tA) * k;
    c.call("move_warp_marker", bB, bB2 - bB);
    // put the reference downbeat on a bar line
    var st = num(c, "start_time"), sm = num(c, "start_marker");
    var barBeats = p.meter;
    var arrA = st + (bA - sm);
    var delta = Math.round(arrA / barBeats) * barBeats - arrA;
    if (Math.abs(delta) > 1e-6) {
      if (delta > 0) { c.call("move_warp_marker", bB2, delta); c.call("move_warp_marker", bA, delta); }
      else { c.call("move_warp_marker", bA, delta); c.call("move_warp_marker", bB2, delta); }
    }
    state.bar0 = st + (bA + delta - sm) - (refBar - 1) * barBeats;   // arrangement beat of bar 1
    state.songStartBeat = Math.floor(st / barBeats) * barBeats;
    state.songEndBeat = num(c, "end_time");
    later(makeTracks, 100);
  }, 300);
}
function barBeat(n) { return state.bar0 + (n - 1) * state.plan.meter; }

// ------------------------------------------------------------------ 2. tracks
function makeTracks() {
  var song = api("live_set");
  var idx = trackIndex(byId(state.track.id));
  var midi = idx >= 2 ? api("live_set tracks " + (idx - 2)) : null;
  var aud = idx >= 1 ? api("live_set tracks " + (idx - 1)) : null;
  var reuse = midi && aud && str(midi, "name") == SECTIONS_NAME && str(aud, "name") == CUES_NAME;
  if (reuse) {
    // re-run: clear our old clips in this song's range
    [midi, aud].forEach(function (t) {
      idList(t, "arrangement_clips").forEach(function (id) {
        var c = byId(id);
        if (num(c, "end_time") > state.songStartBeat - 4 * state.plan.meter && num(c, "start_time") < state.songEndBeat)
          t.call("delete_clip", "id", id);
      });
    });
  } else {
    song.call("create_midi_track", idx);
    song.call("create_audio_track", idx + 1);
    midi = api("live_set tracks " + idx);
    aud = api("live_set tracks " + (idx + 1));
    midi.set("name", SECTIONS_NAME);
    aud.set("name", CUES_NAME);
  }
  state.midiId = midi.id; state.audId = aud.id;
  later(makeSections, 100);
}

// ------------------------------------------------------------------ 3. section clips
function kindOf(label) { return label.toLowerCase().replace(/ \d+$/, ""); }
function makeSections() {
  var t = byId(state.midiId), p = state.plan, n = 0;
  for (var i = 0; i < p.sections.length; i++) {
    var s = p.sections[i];
    var a = barBeat(s.start_bar), b = Math.min(barBeat(s.end_bar), Math.max(state.songEndBeat, a + p.meter));
    if (b - a < 0.5) continue;
    t.call("create_midi_clip", a, b - a);
    var c = clipAt(t, a);
    if (c) {
      c.set("name", s.label);
      c.set("color", COLORS[kindOf(s.label)] || 0x6F8FD8);
      n++;
    }
  }
  state.nSections = n;
  say("Placed " + n + " section clips - adding cues");
  later(makeCues, 100);
}

// ------------------------------------------------------------------ 4. cue clips
function makeCues() {
  var t = byId(state.audId), p = state.plan, beatSec = 60 / p.bpm;
  var lead = p.leadBars * p.meter, hasCounts = false, list = [];
  for (var j = 0; j < p.counts.length; j++) if (p.counts[j]) hasCounts = true;
  var lastEnd = -1e9;
  for (var i = 0; i < p.sections.length; i++) {
    var s = p.sections[i], S = barBeat(s.start_bar);
    var room = (hasCounts ? lead - p.meter : lead) * beatSec;          // seconds before the count starts
    if (s.cue && S - lead >= 0 && S - lead >= lastEnd - 1e-6)
      list.push({ path: s.cue.path, pos: S - lead, sec: Math.min(s.cue.dur, room), name: s.label });
    for (var j2 = 0; j2 < p.counts.length; j2++) {
      var cc = p.counts[j2], pos = S - p.meter + j2;
      if (cc && pos >= 0) list.push({ path: cc.path, pos: pos, sec: Math.min(cc.dur, beatSec), name: String(j2 + 1) });
    }
    lastEnd = S;
  }
  var made = [];
  for (var k = 0; k < list.length; k++) {
    try {
      t.call("create_audio_clip", list[k].path, list[k].pos);
      var c = clipAt(t, list[k].pos);
      if (c) { made.push({ id: c.id, item: list[k] }); c.set("warping", 0); }
    } catch (e) { post("AICB: cue failed " + list[k].path + " " + e + "\n"); }
  }
  later(function () {           // warping change is deferred by Live - trim afterwards
    for (var m = 0; m < made.length; m++) {
      var c = byId(made[m].id);
      try {
        c.set("loop_end", made[m].item.sec);
        c.set("name", made[m].item.name);
        c.set("color", CUE_COLOR);
      } catch (e) {}
    }
    state.nCues = made.length;
    if (p.recordTempo) recordTempo(finish); else finish();
  }, 400);
}

// ------------------------------------------------------------------ 5. tempo automation (short real-time recording)
function recordTempo(done) {
  var song = api("live_set"), p = state.plan;
  var X = state.songStartBeat;
  var saved = {
    rec: num(song, "record_mode"), autoArm: num(song, "session_automation_record"),
    loop: num(song, "loop"), pos: num(song, "current_song_time"), arms: []
  };
  idList(song, "tracks").forEach(function (id) {
    var tr = byId(id);
    if (num(tr, "can_be_armed") == 1 && num(tr, "arm") == 1) { saved.arms.push(id); tr.set("arm", 0); }
  });
  say("Recording tempo step (" + p.bpm + " BPM) at the song start...");
  song.set("loop", 0);
  song.set("current_song_time", X);
  song.set("session_automation_record", 1);
  song.set("record_mode", 1);
  song.call("start_playing");
  var tries = 0, wrote = false;
  var poll = new Task(function () {
    tries++;
    var playing = num(song, "is_playing") == 1, pos = num(song, "current_song_time");
    if (!wrote && playing && pos >= X - 0.01) {
      song.set("tempo", p.bpm);
      wrote = true;
      later(stopRec, Math.round(p.meter * 60000 / p.bpm) + 250);   // hold for one bar
      poll.cancel();
    } else if (tries > 500) { poll.cancel(); stopRec(); }
  }, this);
  poll.interval = 20;
  poll.repeat(-1);
  function stopRec() {
    song.call("stop_playing");
    song.set("record_mode", saved.rec);
    song.set("session_automation_record", saved.autoArm);
    song.set("loop", saved.loop);
    saved.arms.forEach(function (id) { byId(id).set("arm", 1); });
    song.set("current_song_time", X);
    if (!wrote) say("Tempo not recorded (transport did not start) - set it by hand to " + p.bpm);
    if (done) done();
  }
}

// ------------------------------------------------------------------ done
function finish() {
  var p = state.plan;
  var msg = "Done: " + p.bpm + " BPM, " + state.nSections + " sections, " + state.nCues + " cues";
  if (p.engine !== "allin1") msg += " (built-in analysis)";
  if (!p.tempo_stable) msg += ". Tempo drifts " + p.tempo_range[0] + "-" + p.tempo_range[1] + " BPM: check the grid";
  if (p.missingCues.length) msg += ". No cue file for: " + p.missingCues.join(", ");
  say(msg);
  state.busy = false;
}
