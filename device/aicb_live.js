// Sequencer Analyzer - Live API side (Max [js] object, classic ES5 JavaScript).
// Outlet 0 -> node.script, 1 -> status text, 2 -> progress bar ([jsui], 0..100),
// 3 -> stored parameters (start/end/bpm of this song's tempo range, saved with the Live Set).
autowatch = 1;
inlets = 1;
outlets = 4;

var SECTIONS_NAME = "SECTIONS";
var CUES_NAME = "GUIDE CUES";
var COLORS = {
  intro: 0x7FA8C9, verse: 0x5BB55B, "pre chorus": 0xE6B33C, chorus: 0xE5533D, bridge: 0x9B6BD6,
  instrumental: 0x3FB6B2, breakdown: 0x8C8C8C, interlude: 0x6F8FD8, outro: 0x7FA8C9
};
var CUE_COLOR = 0xD08AE0;

var state = null;   // per-run data

var lastText = "";

function say(msg) { lastText = msg; outlet(1, "set", msg); post("SeqAnalyzer: " + msg + "\n"); }
function bar(pct) { outlet(2, Math.max(0, Math.min(100, Number(pct) || 0))); }
function fmtEta(sec) {
  if (sec < 0) return "";
  if (sec < 50) return " - about " + Math.max(5, Math.round(sec / 5) * 5) + " s left";
  return " - about " + Math.round(sec / 60) + " min left";
}
// from node.script: progress <percent> <eta seconds>
function progress(pct, eta) {
  bar(pct);
  var base = lastText.replace(/ \(\d+%.*$/, "");
  lastText = base;
  outlet(1, "set", base + " (" + Math.round(pct) + "%" + fmtEta(eta) + ")");
}
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
  bar(0);
  say("Analyzing... (first run can take a few minutes)");
  outlet(0, "analyze", state.file);
}

function failed() { if (state) state.busy = false; }
// messages coming back from node.script
function status() { say(arrayfromargs(arguments).join(" ")); }
function loadbang() { bar(0); }
function options() {}

function plan() {
  if (!state) return;
  var txt = arrayfromargs(arguments).join(" ");
  try { state.plan = JSON.parse(txt); } catch (e) { fail("could not read analysis result"); return; }
  say("Tempo " + state.plan.bpm + " BPM - locking song to the grid");
  warpSong();
}

function recordtempo() {   // real-time recording for the last analyzed song (tempoMode "record", not on a button)
  if (!state || !state.plan || state.songStartBeat === undefined) { say("Run Analyze & Build first"); return; }
  if (state.busy) { say("Already working..."); return; }
  state.busy = true;
  recordTempo(function () {
    state.busy = false;
    say(state.tempoNote ? "Note: " + state.tempoNote : "Tempo automation written: " + state.plan.bpm + " BPM");
  });
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
      state.lastSectionEnd = b;
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
    } catch (e) { post("SeqAnalyzer: cue failed " + list[k].path + " " + e + "\n"); }
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
    var first = 1e12;
    for (var q = 0; q < list.length; q++) first = Math.min(first, list[q].pos);
    state.firstCueBeat = first < 1e12 ? first : state.songStartBeat;
    if (p.recordTempo && (p.tempoMode == "record" || p.tempoMode == "set")) recordTempo(finish); else finish();
  }, 400);
}

// ------------------------------------------------------------------ 5. tempo
// Live's API cannot draw automation, so the tempo is recorded in real time: playback runs from just
// before the first cue to the end of the song with Automation Arm on. When recording stops, Live
// returns to whatever tempo was there before, so earlier/later songs in a medley keep theirs.
function recordTempo(done) {
  var song = api("live_set"), p = state.plan, m = p.meter;
  var P = Math.floor(Math.min(state.firstCueBeat, state.songStartBeat) / m) * m;   // step position
  var E = state.songEndBeat;
  if (p.tempoMode === "set") {             // no automation: just set the tempo
    song.set("tempo", p.bpm);
    say("Tempo set to " + p.bpm + " BPM (no automation)");
    if (done) done();
    return;
  }
  var saved = {
    rec: num(song, "record_mode"), autoArm: num(song, "session_automation_record"),
    loop: num(song, "loop"), arms: []
  };
  idList(song, "tracks").forEach(function (id) {
    var tr = byId(id);
    if (num(tr, "can_be_armed") == 1 && num(tr, "arm") == 1) { saved.arms.push(id); tr.set("arm", 0); }
  });
  var secs = Math.round((E - P) * 60 / p.bpm);
  say("Writing tempo " + p.bpm + " BPM from bar " + (P / m + 1) + ": plays the song once (" +
      Math.floor(secs / 60) + ":" + ("0" + secs % 60).slice(-2) + ")");
  song.set("loop", 0);
  song.set("record_mode", 0);
  song.set("session_automation_record", 1);
  song.call("start_playing");               // starts at the insert marker...
  var phase = "seek", ticks = 0, stoppedByUser = false;
  var poll = new Task(function () {
    ticks++;
    var playing = num(song, "is_playing") == 1, pos = num(song, "current_song_time");
    if (phase == "seek") {
      if (playing) { song.set("current_song_time", Math.max(0, P - m)); phase = "approach"; }   // ...so jump one bar before P
      else if (ticks > 500) { finishRec(false); }
    } else if (phase == "approach") {
      if (!playing) { stoppedByUser = true; finishRec(false); }
      else if (pos >= P - 0.03 && pos < P + m) {            // punch in right at the step
        song.set("record_mode", 1);
        song.set("tempo", p.bpm);
        phase = "rec";
      } else if (pos >= P + m) { song.set("current_song_time", Math.max(0, P - m)); }
    } else if (phase == "rec") {
      if (!playing) { stoppedByUser = true; finishRec(true); }
      else if (pos >= E - 0.03) { song.set("record_mode", 0); finishRec(true); }   // punch out at the song end
      else if (ticks % 10 == 0) progress(100 * (pos - P) / Math.max(1, E - P), (E - pos) * 60 / p.bpm);
    }
  }, this);
  poll.interval = 20;
  poll.repeat(-1);
  function finishRec(wrote) {
    poll.cancel();
    song.call("stop_playing");
    song.set("record_mode", saved.rec);
    song.set("session_automation_record", saved.autoArm);
    song.set("loop", saved.loop);
    saved.arms.forEach(function (id) { byId(id).set("arm", 1); });
    song.set("current_song_time", P);
    bar(wrote && !stoppedByUser ? 100 : 0);
    state.tempoNote = !wrote ? "tempo not written - use Re-record Tempo" :
      stoppedByUser ? "tempo written only up to where you pressed Stop" : "";
    if (done) done();
  }
}

// ------------------------------------------------------------------ done
function finish() {
  var p = state.plan;
  var msg = "Done: " + p.bpm + " BPM, " + state.nSections + " sections, " + state.nCues + " cues";
  if (p.recordTempo && p.tempoMode != "record" && p.tempoMode != "set") {
    var m = p.meter, P = Math.floor(Math.min(state.firstCueBeat, state.songStartBeat) / m) * m;
    var E = state.lastSectionEnd || state.songEndBeat;
    setFollow(P, E, p.bpm);
    msg += ". Tempo follows this song: " + p.bpm + " BPM, bars " + (P / m + 1) + "-" + Math.round(E / m);
  }
  if (p.note) msg += ". " + p.note.charAt(0).toUpperCase() + p.note.slice(1);
  if (state.tempoNote) msg += ". Note: " + state.tempoNote;
  if (!p.tempo_stable) msg += ". Tempo drifts " + p.tempo_range[0] + "-" + p.tempo_range[1] + " BPM: check the grid";
  if (p.missingCues.length) msg += ". No cue file for: " + p.missingCues.join(", ");
  say(msg);
  bar(100);
  state.busy = false;
}

// ------------------------------------------------------------------ tempo follow
// While the playhead is inside this song's range (first cue -> end of last section), set Live's tempo to
// the song's BPM. The range and BPM live in three hidden stored parameters, so they are saved with the set.
var LOOKAHEAD = 0.25;          // beats: switch a little early to cover the notification interval
var follow = { on: 1, start: 0, end: 0, bpm: 0, inside: false };
var songObs = null, tempoApi = null, pendingTempo = null;

function setFollow(start, end, bpm) {
  follow.start = start; follow.end = end; follow.bpm = bpm; follow.inside = false;
  outlet(3, "start", start);
  outlet(3, "end", end);
  outlet(3, "bpm", bpm);
  checkPos(num(api("live_set"), "current_song_time"));
}
// values restored from the stored parameters when the set loads
function fstart(v) { follow.start = Number(v); }
function fend(v) { follow.end = Number(v); }
function fbpm(v) { follow.bpm = Number(v); }
function followon(v) {
  follow.on = Number(v) ? 1 : 0;
  follow.inside = false;
  if (follow.on && songObs) checkPos(num(api("live_set"), "current_song_time"));
}

function init() {                // from live.thisdevice: the Live API is ready
  if (songObs) return;
  tempoApi = api("live_set");
  songObs = new LiveAPI(function (args) {
    if (args && args[0] == "current_song_time") checkPos(Number(args[1]));
  }, "live_set");
  songObs.property = "current_song_time";
}

function checkPos(pos) {
  if (!tempoApi) tempoApi = api("live_set");
  if (!follow.on || !(follow.bpm >= 20) || !(follow.end > follow.start)) return;
  var inside = pos >= follow.start - LOOKAHEAD && pos < follow.end;
  var entering = inside && !follow.inside;
  follow.inside = inside;
  if (!entering) return;            // only on entering the song, so live tempo changes are left alone
  if (pendingTempo !== null) return;
  if (Math.abs(num(tempoApi, "tempo") - follow.bpm) < 0.005) return;
  // the Live API does not allow changes from inside a notification: defer
  pendingTempo = follow.bpm;
  later(function () {
    try { tempoApi.set("tempo", pendingTempo); } catch (e) {}
    pendingTempo = null;
  }, 0);
}
