// Sequencer Analyzer - Live API side (Max [js] object, classic ES5 JavaScript).
// Outlet 0 -> node.script, 1 -> status text, 2 -> progress bar ([jsui], 0..100),
// 3 -> stored parameters: "slot <i> <start> <end> <bpm>" (tempo range of each song, saved with the Live Set).
autowatch = 1;
inlets = 1;
outlets = 6;

var SECTIONS_NAME = "SECTIONS";
var CUES_NAME = "GUIDE CUES";
var COLORS = {
  intro: 0x7FA8C9, verse: 0x5BB55B, "pre chorus": 0xE6B33C, chorus: 0xE5533D, bridge: 0x9B6BD6,
  instrumental: 0x3FB6B2, breakdown: 0x8C8C8C, interlude: 0x6F8FD8, outro: 0x7FA8C9
};
var CUE_COLOR = 0xD08AE0;
var MAX_SONGS = 16;            // songs per track remembered by Tempo Follow (matches the patch)
var MIN_SONG_SECONDS = 30;     // shorter audio clips on the track are not treated as songs
var SNAP_BEATS = 0.25;         // a song whose downbeat is this close to a bar line counts as on the grid

var state = null;              // per-run data
var lastText = "";

function say(msg) { lastText = msg; outlet(1, "set", msg); post("SeqAnalyzer: " + msg + "\n"); }
function bar(pct) { outlet(2, Math.max(0, Math.min(100, Number(pct) || 0))); }
function fmtEta(sec) {
  if (sec < 0) return "";
  if (sec < 50) return " - about " + Math.max(5, Math.round(sec / 5) * 5) + " s left";
  return " - about " + Math.round(sec / 60) + " min left";
}
function songTag() { return state && state.songs && state.songs.length > 1 ? "Song " + (state.idx + 1) + "/" + state.songs.length + ": " : ""; }
// from node.script: progress <percent> <eta seconds> for the current song.
// With several songs, bar and text show the overall percentage and the time left for all of them.
function progress(pct, eta) {
  pct = Number(pct); eta = Number(eta);
  var n = state && state.songs ? state.songs.length : 1, i = state && state.songs ? Math.max(0, state.idx) : 0;
  var overall = (i * 100 + pct) / n;
  if (n > 1 && eta >= 0) {
    var cur = (Date.now() - state.songT0) / 1000;                // this song so far
    var done = state.doneSecs.length ? state.doneSecs.reduce(function (a, b) { return a + b; }, 0) / state.doneSecs.length : cur + eta;
    eta = eta + (n - i - 1) * done;                               // remaining songs at the average speed
  }
  bar(overall);
  var base = lastText.replace(/ \(\d+%.*$/, "");
  lastText = base;
  outlet(1, "set", base + " (" + Math.round(overall) + "%" + fmtEta(eta) + ")");
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
function baseName(p) { return String(p).replace(/^.*[\/\\]/, ""); }

// ------------------------------------------------------------------ entry points
// v0.8.0-alpha: read-only analysis results, kept until the next scan.
var review = null;
var reviewPage = 0;
var REVIEW_PAGE_SIZE = 3;
function analyze() {
  if (state && state.busy) { say("Analysis is running."); return; }
  review = null;
  reviewPage = 0;
  showReviewPage();
  var tr = api("this_device canonical_parent");
  if (trackIndex(tr) < 0 || num(tr, "has_audio_input") !== 1) { fail("put the device on an audio track"); return; }
  var ids = idList(tr, "arrangement_clips"), songs = [];
  for (var i = 0; i < ids.length; i++) {
    var c = byId(ids[i]);
    if (num(c, "is_audio_clip") !== 1) continue;
    var duration = num(c, "sample_length") / Math.max(1, num(c, "sample_rate"));
    if (duration < MIN_SONG_SECONDS) continue;
    songs.push({ id: c.id, file: str(c, "file_path"), clip: str(c, "name"),
      start: num(c, "start_time"), duration: duration, warp: num(c, "warping") });
  }
  songs.sort(function(a,b) { return a.start - b.start; });
  if (!songs.length) { fail("no audio clips over 30 seconds in this track"); return; }
  if (songs.length > MAX_SONGS) { fail("only up to 16 songs are supported"); return; }
  state = { busy: true, mode: "review", track: tr, songs: songs, idx: -1, results: [], doneSecs: [] };
  bar(0);
  nextSong();
}
function analysis() {
  if (!state || state.mode !== "review" || !state.cur) return;
  try {
    var result = JSON.parse(arrayfromargs(arguments).join(" "));
    var s = state.songs[state.idx];
    state.results.push({ id: s.id, file: s.file, clip: s.clip, start: s.start,
      duration: s.duration, warp: s.warp, bpm: Number(result.bpm),
      meter: Number(result.meter), sections: (result.sections || []).length,
      tempo_stable: result.tempo_stable, alternatives: result.tempo_alternatives || [] });
    later(nextSong, 30);
  } catch (e) { fail("could not read analysis JSON: " + e); }
}
function buildreview() {
  say("BUILD is not enabled in v0.8.0-alpha. ANALYZE is read-only; Warp and clips are unchanged.");
}
// The device display has room for three rows. Keep all results and page through them.
function reviewprev() {
  if (reviewPage > 0) reviewPage--;
  showReviewPage();
}
function reviewnext() {
  if (review && (reviewPage + 1) * REVIEW_PAGE_SIZE < review.length) reviewPage++;
  showReviewPage();
}
function cueinfo() {
  var value = arrayfromargs(arguments).join(" ");
  outlet(5, "set", value || "Cue Folder: NOT SELECTED");
}
function showReviewPage() {
  var data = review || [], pages = Math.max(1, Math.ceil(data.length / REVIEW_PAGE_SIZE));
  reviewPage = Math.max(0, Math.min(reviewPage, pages - 1));
  for (var j = 0; j < REVIEW_PAGE_SIZE; j++) {
    var idx = reviewPage * REVIEW_PAGE_SIZE + j;
    var r = data[idx];
    if (!r) { outlet(4, "row", j, "set", ""); continue; }
    var loc = arrangementPosition(r.start);
    var name = String(r.clip || r.name || "?");
    if (name.length > 19) name = name.substring(0, 16) + "...";
    var seconds = Math.floor(r.duration % 60);
    var duration = Math.floor(r.duration / 60) + ":" + (seconds < 10 ? "0" : "") + seconds;
    var row = r.error ? (idx + 1) + ". " + name + " | ERROR" :
      (idx + 1) + ". " + name + " | " + r.bpm.toFixed(1) +
      " BPM | " + duration + " | Bar " + loc + " | Warp " + (r.warp ? "ON" : "OFF");
    outlet(4, "row", j, "set", row);
  }
  outlet(4, "page", "set", "Songs " + (data.length ? reviewPage * REVIEW_PAGE_SIZE + 1 : 0) +
    "-" + Math.min(data.length, (reviewPage + 1) * REVIEW_PAGE_SIZE) +
    " of " + data.length + "  |  Page " + (reviewPage + 1) + "/" + pages);
}
function arrangementPosition(start) {
  var sig = 4;
  try { sig = Math.max(1, num(api("live_set"), "signature_numerator")); } catch (e) {}
  var pos = Number(start) || 0;
  var barNo = Math.floor(pos / sig) + 1;
  var beatNo = Math.floor(pos % sig) + 1;
  return barNo + "." + beatNo + "." + (Math.round((pos - Math.floor(pos)) * 960) + 1);
}
function finishReview() {
  review = state.results.slice();
  reviewPage = 0;
  var ok = review.filter(function(r){ return !r.error; });
  for (var i = 0; i < review.length; i++) {
    var r = review[i];
    post("SeqAnalyzer review " + (i+1) + ": " + (r.clip || r.name) + " | " +
      (r.error || (r.bpm.toFixed(2) + " BPM | " + r.duration.toFixed(1) +
      " sec | start beat " + r.start.toFixed(2) +
      " | Warp " + (r.warp ? "ON" : "OFF"))) + "\\n");
  }
  showReviewPage();
  say("ANALYZE: " + ok.length + "/" + review.length + " songs. Use Previous/Next to see all. BUILD disabled.");
  bar(100);
  state.busy = false;
}
// Legacy v0.7.1 build retained for reference, but not exposed by the alpha device UI.
// Analyze & Build: every song (audio clip >= 30 s) on this track, left to right.
function build() {
  if (state && state.busy) { say("Already working..."); return; }
  var tr = api("this_device canonical_parent");
  if (trackIndex(tr) < 0 || num(tr, "has_audio_input") != 1) { fail("put the device on the audio track that holds the song(s)"); return; }
  var songs = [], ids = idList(tr, "arrangement_clips");
  for (var i = 0; i < ids.length; i++) {
    var c = byId(ids[i]);
    if (num(c, "is_audio_clip") != 1) continue;
    var len = num(c, "sample_length") / Math.max(1, num(c, "sample_rate"));
    if (len >= MIN_SONG_SECONDS) songs.push({ id: c.id, start: num(c, "start_time"), file: str(c, "file_path"), clip: str(c, "name") });
  }
  if (!songs.length) { fail("drag the song(s) into this track's Arrangement first"); return; }
  songs.sort(function (a, b) { return a.start - b.start; });
  if (songs.length > MAX_SONGS) songs = songs.slice(0, MAX_SONGS);
  state = { busy: true, track: tr, songs: songs, idx: -1, results: [], doneSecs: [] };
  bar(0);
  nextSong();
}

function nextSong() {
  if (state.idx >= 0 && state.songT0) state.doneSecs.push((Date.now() - state.songT0) / 1000);
  state.idx++;
  if (state.idx >= state.songs.length) { if (state.mode === "review") finishReview(); else finishAll(); return; }
  var s = state.songs[state.idx];
  state.songT0 = Date.now();
  state.cur = { clipId: s.id, file: s.file, name: baseName(s.file), clip: s.clip };
  say(songTag() + "analyzing " + state.cur.name + " (first run can take a few minutes)");
  outlet(0, state.mode === "review" ? "inspect" : "analyze", JSON.stringify({ file: s.file, clip: s.clip }));
}

function failed() {               // analysis of one song failed: report it and carry on
  if (!state) return;
  state.results.push({ name: state.cur ? state.cur.name : "?", error: lastText });
  if (state.songs && state.idx < state.songs.length - 1) later(nextSong, 50);
  else if (state.mode === "review") finishReview(); else finishAll();
}
// messages coming back from node.script
function status() { say(songTag() + arrayfromargs(arguments).join(" ")); }
function loadbang() { bar(0); }
function options() {}

function plan() {
  if (!state || !state.cur) return;
  var txt = arrayfromargs(arguments).join(" ");
  try { state.cur.plan = JSON.parse(txt); } catch (e) { fail("could not read analysis result"); return; }
  say(songTag() + state.cur.plan.bpm + " BPM - placing sections");
  alignSong();
}

function recordtempo() {   // real-time recording for the last analyzed song (tempoMode "record")
  if (!state || !state.cur || state.cur.songStartBeat === undefined) { say("Run Analyze & Build first"); return; }
  if (state.busy) { say("Already working..."); return; }
  state.busy = true;
  recordTempo(function () {
    state.busy = false;
    say(state.cur.tempoNote ? "Note: " + state.cur.tempoNote : "Tempo automation written: " + state.cur.plan.bpm + " BPM");
  });
}

// ------------------------------------------------------------------ 1. lock the song at its own BPM (warped)
// Each song is warped at exactly its BPM, so its position and length in beats never change with the set tempo
// (unwarped clips grow and shrink with the tempo and run into the next song). Method: set Live's tempo to the
// song's BPM, then switch Warp on with "keep the current timing": the song plays at its original speed at its
// own BPM. Live may show a dialog for this; the device waits for it. The result is checked from the warp markers.
function markers(c) {
  var o = JSON.parse(str(c, "warp_markers"));
  var arr = o.warp_markers || o;
  arr.sort(function (a, b) { return a.beat_time - b.beat_time; });
  return arr;
}
function beatAt(M, t) {
  var i = 0;
  while (i < M.length - 2 && t > M[i + 1].sample_time) i++;
  var a = M[i], b = M[i + 1];
  return a.beat_time + (t - a.sample_time) * (b.beat_time - a.beat_time) / (b.sample_time - a.sample_time);
}
// The warp markers that matter: Live keeps a hidden marker after the last visible one (only used for the BPM of
// the final segment), so with 3 or more markers the last one is ignored.
function visibleMarkers(c) {
  var M = markers(c);
  return M.length >= 3 ? M.slice(0, M.length - 1) : M;
}
function fmtMarkers(c) {
  return JSON.stringify(markers(c).map(function (m) { return [Math.round(m.sample_time * 1000) / 1000, Math.round(m.beat_time * 1000) / 1000]; }));
}
// BPM of the clip's warp map, and whether it is one straight line (no tempo changes inside)
function warpBpm(c) {
  var M = visibleMarkers(c);
  if (M.length < 2) return { bpm: 0, straight: false };
  var a = M[0], z = M[M.length - 1];
  var bpm = 60 * (z.beat_time - a.beat_time) / (z.sample_time - a.sample_time), straight = true;
  for (var i = 1; i < M.length; i++) {
    var seg = 60 * (M[i].beat_time - M[i - 1].beat_time) / Math.max(1e-6, M[i].sample_time - M[i - 1].sample_time);
    if (Math.abs(seg - bpm) / bpm > 0.002) straight = false;
  }
  return { bpm: bpm, straight: straight };
}
function warpOk(c, bpm) {
  if (num(c, "warping") != 1) return false;
  var w = warpBpm(c);
  return w.straight && Math.abs(w.bpm - bpm) / bpm < 0.0005;
}

// Wait until a condition holds (polling every 100 ms), then continue; give up after secs seconds.
function waitFor(cond, secs, then, onTimeout) {
  var t0 = Date.now();
  var task = new Task(function () {
    var ok = false;
    try { ok = cond(); } catch (e) {}
    if (ok) { task.cancel(); later(then, 150); }
    else if (Date.now() - t0 > secs * 1000) { task.cancel(); onTimeout(); }
  }, this);
  task.interval = 100;
  task.repeat(-1);
}

function alignSong() {
  var cur = state.cur, c = byId(cur.clipId), p = cur.plan, song = api("live_set");
  post("SeqAnalyzer: " + cur.name + " warp before: on=" + num(c, "warping") + " " + fmtMarkers(c) + "\n");
  if (warpOk(c, p.bpm)) { alignSong2(); return; }                  // already locked (rebuild)
  say(songTag() + "locking " + cur.name + " at " + p.bpm + " BPM. If Live asks to keep the current timing, click Yes");
  var tempoIs = function () { return Math.abs(num(song, "tempo") - p.bpm) < 0.001; };
  // 1. warp off  2. tempo = song BPM, confirmed by Live  3. warp on ("keep the current timing")  4. check
  var step3 = function () {
    c.set("warping", 1);
    waitFor(function () { return num(c, "warping") == 1 && markers(c).length >= 2; }, 120, step4,
            function () { failSong("Warp did not switch on (no answer to Live's dialog?)"); });
  };
  var step2 = function () {
    song.set("tempo", p.bpm);
    waitFor(tempoIs, 5, step3, function () {
      failSong("Live did not accept tempo " + p.bpm + " (tempo automation in the set? delete it and build again)");
    });
  };
  var step4 = function () {
    post("SeqAnalyzer: " + cur.name + " warp after: " + fmtMarkers(c) + "\n");
    if (!warpOk(c, p.bpm)) {                                        // Live auto-warped, or "No" was clicked
      straightenWarp(c, p);
      post("SeqAnalyzer: " + cur.name + " warp straightened: " + fmtMarkers(c) + "\n");
    }
    if (!warpOk(c, p.bpm)) {
      failSong("could not lock the song at " + p.bpm + " BPM (warp shows " + (Math.round(warpBpm(c).bpm * 100) / 100) +
               "). Details are in the Max console");
      return;
    }
    alignSong2();
  };
  if (num(c, "warping") == 1) {
    c.set("warping", 0);
    waitFor(function () { return num(c, "warping") == 0; }, 5, step2, function () { failSong("could not switch Warp off"); });
  } else step2();
}

// Fallback (Live auto-warped, or "No" was clicked): rebuild the warp map as one straight line at the song's BPM,
// beat(t) = c + k*t, using the first marker and a new one near the end of the file. Live's hidden end marker can't
// be moved, so the line must stay below it; within that limit c is chosen so the first downbeat lands on a bar line.
function straightenWarp(c, p) {
  var k = p.bpm / 60, m = p.meter;
  try {
    var len = num(c, "sample_length") / num(c, "sample_rate");
    var M = markers(c), hidden = M.length >= 3 ? M[M.length - 1] : null;
    var V = visibleMarkers(c), a = V[0];
    for (var i = V.length - 1; i >= 1; i--) { try { c.call("remove_warp_marker", V[i].beat_time); } catch (e) {} }
    var tA = a.sample_time, tB = Math.min(len - 0.05, hidden ? hidden.sample_time - 0.05 : len - 0.05);
    var st = num(c, "start_time"), sm = num(c, "start_marker");
    var cMax = hidden ? hidden.beat_time - k * tB - 0.01 : 1e9;        // keep beat(tB) below the hidden marker
    var cNow = a.beat_time - k * tA;                                      // keeps the audio where it is
    var cBase = Math.min(cNow, cMax);
    // first downbeat on a bar line: st + (c + k*t0 - sm) = multiple of m
    var j = Math.floor((st + cBase + k * p.first_downbeat - sm) / m);
    var cc = m * j - st + sm - k * p.first_downbeat;
    var newA = cc + k * tA, newB = cc + k * tB;
    if (newA < a.beat_time) {                                             // keep markers in order while changing them
      c.call("move_warp_marker", a.beat_time, newA - a.beat_time);
      c.call("add_warp_marker", { beat_time: newB, sample_time: tB });
    } else {
      c.call("add_warp_marker", { beat_time: newB, sample_time: tB });
      c.call("move_warp_marker", a.beat_time, newA - a.beat_time);
    }
  } catch (e) { post("SeqAnalyzer: straighten failed: " + e + "\n"); }
}

function failSong(msg) {
  say(songTag() + "Error: " + msg);
  state.results.push({ name: state.cur.name, error: "Error: " + msg });
  later(nextSong, 1500);
}

function alignSong2() {
  var cur = state.cur, c = byId(cur.clipId), p = cur.plan, m = p.meter;
  var st = num(c, "start_time"), sm = num(c, "start_marker");
  var raw = st + (beatAt(markers(c), p.first_downbeat) - sm);       // arrangement beat of the first downbeat
  var snapped = Math.round(raw / m) * m;
  var off = raw - snapped;
  cur.offGrid = Math.abs(off) > SNAP_BEATS ? off : 0;
  cur.bar0 = cur.offGrid ? raw : snapped;
  cur.songStartBeat = Math.floor(st / m) * m;
  cur.songEndBeat = num(c, "end_time");                              // fixed in beats now that it is warped
  later(makeTracks, 100);
}
function barBeat(n) { return state.cur.bar0 + (n - 1) * state.cur.plan.meter; }

// ------------------------------------------------------------------ 2. tracks (shared by all songs on this track)
function makeTracks() {
  var song = api("live_set"), cur = state.cur, m = cur.plan.meter;
  var idx = trackIndex(byId(state.track.id));
  var midi = idx >= 2 ? api("live_set tracks " + (idx - 2)) : null;
  var aud = idx >= 1 ? api("live_set tracks " + (idx - 1)) : null;
  var reuse = midi && aud && str(midi, "name") == SECTIONS_NAME && str(aud, "name") == CUES_NAME;
  if (reuse) {
    // re-run: clear our old clips in this song's range (cues start up to 4 bars before it)
    [midi, aud].forEach(function (t) {
      idList(t, "arrangement_clips").forEach(function (id) {
        var x = byId(id);
        if (num(x, "end_time") > cur.songStartBeat - 4 * m && num(x, "start_time") < cur.songEndBeat)
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
  var t = byId(state.midiId), cur = state.cur, p = cur.plan, n = 0;
  for (var i = 0; i < p.sections.length; i++) {
    var s = p.sections[i];
    var a = barBeat(s.start_bar), b = Math.min(barBeat(s.end_bar), Math.max(cur.songEndBeat, a + p.meter));
    if (b - a < 0.5) continue;
    t.call("create_midi_clip", a, b - a);
    var c = clipAt(t, a);
    if (c) {
      c.set("name", s.label);
      c.set("color", COLORS[kindOf(s.label)] || 0x6F8FD8);
      n++;
      cur.lastSectionEnd = b;
    }
  }
  cur.nSections = n;
  say(songTag() + "placed " + n + " section clips - adding cues");
  later(makeCues, 100);
}

// ------------------------------------------------------------------ 4. cue clips
function makeCues() {
  var t = byId(state.audId), cur = state.cur, p = cur.plan, beatSec = 60 / p.bpm;
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
    cur.nCues = made.length;
    var first = 1e12;
    for (var q = 0; q < list.length; q++) first = Math.min(first, list[q].pos);
    cur.firstCueBeat = first < 1e12 ? first : cur.songStartBeat;
    if (p.recordTempo && (p.tempoMode == "record" || p.tempoMode == "set")) recordTempo(songDone); else songDone();
  }, 400);
}

function songDone() {
  var cur = state.cur, p = cur.plan, m = p.meter;
  cur.P = Math.floor(Math.min(cur.firstCueBeat, cur.songStartBeat) / m) * m;   // tempo range start
  cur.E = cur.lastSectionEnd || cur.songEndBeat;                               // tempo range end
  state.results.push(cur);
  bar(((state.idx + 1) * 100) / state.songs.length);
  later(nextSong, 50);
}

// ------------------------------------------------------------------ 5. tempo (record / set modes)
// Live's API cannot draw automation; "record" mode records it in real time from the song's first cue to its end.
function recordTempo(done) {
  var song = api("live_set"), cur = state.cur, p = cur.plan, m = p.meter;
  var P = Math.floor(Math.min(cur.firstCueBeat, cur.songStartBeat) / m) * m;
  var E = cur.lastSectionEnd || cur.songEndBeat;
  if (p.tempoMode === "set") {
    song.set("tempo", p.bpm);
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
  say(songTag() + "writing tempo " + p.bpm + " BPM from bar " + (P / m + 1) + ": plays the song once (" +
      Math.floor(secs / 60) + ":" + ("0" + secs % 60).slice(-2) + ")");
  song.set("loop", 0);
  song.set("record_mode", 0);
  song.set("session_automation_record", 1);
  song.call("start_playing");
  var phase = "seek", ticks = 0, stoppedByUser = false;
  var poll = new Task(function () {
    ticks++;
    var playing = num(song, "is_playing") == 1, pos = num(song, "current_song_time");
    if (phase == "seek") {
      if (playing) { song.set("current_song_time", Math.max(0, P - m)); phase = "approach"; }
      else if (ticks > 500) { finishRec(false); }
    } else if (phase == "approach") {
      if (!playing) { stoppedByUser = true; finishRec(false); }
      else if (pos >= P - 0.03 && pos < P + m) { song.set("record_mode", 1); song.set("tempo", p.bpm); phase = "rec"; }
      else if (pos >= P + m) { song.set("current_song_time", Math.max(0, P - m)); }
    } else if (phase == "rec") {
      if (!playing) { stoppedByUser = true; finishRec(true); }
      else if (pos >= E - 0.03) { song.set("record_mode", 0); finishRec(true); }
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
    cur.tempoNote = !wrote ? "tempo not written" : stoppedByUser ? "tempo written only up to where you pressed Stop" : "";
    if (done) done();
  }
}

// ------------------------------------------------------------------ done
function finishAll() {
  var parts = [], notes = [], ok = [], unhinted = [];
  for (var i = 0; i < state.results.length; i++) {
    var r = state.results[i];
    if (r.error) { notes.push(r.name + ": " + r.error.replace(/^.*Error: /, "")); continue; }
    var p = r.plan;
    ok.push(r);
    parts.push(r.name.replace(/\.[^.]*$/, "") + " " + p.bpm + " BPM" + (p.bpm_hint ? "" : " (detected)") + ", " +
               r.nSections + " sections, " + r.nCues + " cues");
    if (!p.bpm_hint) unhinted.push(r.clip || r.name);
    if (p.tempo_alternatives && p.tempo_alternatives.length) {
      var clipName = String(r.clip || r.name).replace(/\.[^.]*$/, "");
      notes.push("CHECK THE TEMPO of " + clipName + ": " + p.bpm + " BPM, or maybe " + p.tempo_alternatives.join(" / ") +
                 "? If it's " + Math.round(p.tempo_alternatives[0]) + ", rename the clip \"" + clipName + " " +
                 Math.round(p.tempo_alternatives[0]) + "BPM\" and build again");
    }
    if (p.note) post("SeqAnalyzer: " + r.name + ": " + p.note + "\n");   // details in the Max console
    if (r.offGrid) notes.push(r.name + ": first downbeat is " + Math.abs(r.offGrid).toFixed(2) +
      " beat " + (r.offGrid > 0 ? "after" : "before") + " a bar line - move the clip to line it up with the grid");
    if (!p.tempo_stable) notes.push(r.name + ": tempo drifts " + p.tempo_range[0] + "-" + p.tempo_range[1] + " BPM, so the grid may wander");
    if (r.tempoNote) notes.push(r.name + ": " + r.tempoNote);
    if (p.missingCues.length) notes.push("no cue file for " + p.missingCues.join(", "));
  }
  var flagged = notes.some(function (n) { return n.indexOf("CHECK THE TEMPO") == 0; });
  if (unhinted.length && !flagged) notes.push("A detected BPM is wrong? Put the tempo in the clip name (e.g. \"My Song 74BPM\") and build again");
  if (ok.length && ok[0].plan.recordTempo && ok[0].plan.tempoMode != "record" && ok[0].plan.tempoMode != "set") storeSlots(ok);
  say("Done: " + (parts.length ? parts.join(" | ") : "nothing built") + (notes.length ? ". " + notes.join(". ") : "") +
      (ok.length && follow.on ? ". Tempo Follow is on" : ""));
  bar(100);
  state.busy = false;
}

// ------------------------------------------------------------------ tempo follow
// While the playhead is inside a song's range (first cue -> end of last section), set Live's tempo to that
// song's BPM. Ranges are kept in hidden stored parameters (MAX_SONGS slots), so they are saved with the set.
var LOOKAHEAD = 0.25;          // beats: switch a little early to cover the notification interval
var follow = { on: 0, slots: [], inside: -1 };
var songObs = null, tempoApi = null, pendingTempo = null;

function storeSlots(list) {
  var slots = [];
  for (var i = 0; i < MAX_SONGS; i++) {
    var r = list[i];
    var s = r ? { start: r.P, end: r.E, bpm: r.plan.bpm } : { start: 0, end: 0, bpm: 0 };
    slots.push(s);
    outlet(3, "slot", i, s.start, s.end, s.bpm);
  }
  follow.slots = slots;
  follow.inside = -1;
  checkPos(num(api("live_set"), "current_song_time"));
}
// restored from the stored parameters when the set loads: fslot <i> start|end|bpm <value>
function fslot(i, key, v) {
  i = Number(i);
  if (!follow.slots[i]) follow.slots[i] = { start: 0, end: 0, bpm: 0 };
  follow.slots[i][key] = Number(v);
}
function followon(v) {
  follow.on = Number(v) ? 1 : 0;
  follow.inside = -1;
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

// the song whose range holds the playhead; when ranges touch or overlap, the one that starts last wins
function slotAt(pos) {
  var best = -1;
  for (var i = 0; i < follow.slots.length; i++) {
    var s = follow.slots[i];
    if (!(s && s.bpm >= 20 && s.end > s.start)) continue;
    if (pos >= s.start - LOOKAHEAD && pos < s.end && (best < 0 || s.start > follow.slots[best].start)) best = i;
  }
  return best;
}

function checkPos(pos) {
  if (!tempoApi) tempoApi = api("live_set");
  if (!follow.on) return;
  var i = slotAt(pos);
  var entering = i >= 0 && i != follow.inside;
  follow.inside = i;
  if (!entering) return;            // only when entering a song, so live tempo changes are left alone
  var bpm = follow.slots[i].bpm;
  if (pendingTempo !== null || Math.abs(num(tempoApi, "tempo") - bpm) < 0.005) return;
  // the Live API does not allow changes from inside a notification: defer
  pendingTempo = bpm;
  later(function () {
    try { tempoApi.set("tempo", pendingTempo); } catch (e) {}
    pendingTempo = null;
  }, 0);
}
