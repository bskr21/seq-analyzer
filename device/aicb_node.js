// Sequencer Analyzer - Node for Max side.
// Runs the Python analysis engine, matches cue samples to section labels,
// and hands a finished build plan to aicb_live.js.
const path = require("path");
const fs = require("fs");
const os = require("os");
const { spawn } = require("child_process");

let maxAPI;
try { maxAPI = require("max-api"); } catch (e) { maxAPI = null; } // null when unit-testing outside Max

const SUPPORT = path.join(os.homedir(), "Library", "Application Support", "AICueBuilder");
const CONFIG = path.join(SUPPORT, "config.json");
const DEFAULTS = {
  cueDir: "",
  python: path.join(SUPPORT, "venv", "bin", "python"),
  engine: path.join(SUPPORT, "engine", "aicb_analyze.py"),
  leadBars: 2,          // section-name cue this many bars before the section
  counts: true,         // "1 2 3 4" in the bar before each section
  recordTempo: true,    // tempo automation from the first cue to the end of the last section
  tempoMode: "file",    // "file" = Write Tempo edits the saved set (instant, then reopen) |
                        // "record" = record automation in real time (plays the song) | "set" = just set the tempo
  structure: "auto",    // section engine: "auto" | "allin1" | "heuristic"
  vocalThreshold: 0.12  // below this vocal share a song is treated as instrumental
};

function loadConfig() {
  try { return Object.assign({}, DEFAULTS, JSON.parse(fs.readFileSync(CONFIG, "utf8"))); }
  catch (e) { return Object.assign({}, DEFAULTS); }
}
function saveConfig(cfg) {      // store only what differs from the defaults
  fs.mkdirSync(SUPPORT, { recursive: true });
  const out = { configVersion: 3 };
  for (const k of Object.keys(cfg)) if (k !== "configVersion" && cfg[k] !== DEFAULTS[k]) out[k] = cfg[k];
  fs.writeFileSync(CONFIG, JSON.stringify(out, null, 1));
}
function status(msg) { if (maxAPI) maxAPI.outlet("status", msg); else console.log("STATUS", msg); }

// Max hands folders over as "Macintosh HD:/Users/..." -> POSIX path
function maxToPosix(p) {
  const m = /^([^:/]+):(\/.*)$/.exec(p);
  if (!m) return p;
  if (fs.existsSync(m[2])) return m[2];
  return path.join("/Volumes", m[1], m[2]);
}

// ---------------------------------------------------------------- cue matching
const AUDIO_EXT = new Set([".wav", ".aif", ".aiff", ".mp3", ".flac", ".m4a"]);
function listAudio(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    if (name.startsWith(".") || name === "__MACOSX") continue;
    const full = path.join(dir, name);
    const st = fs.statSync(full);
    if (st.isDirectory()) listAudio(full, out);
    else if (AUDIO_EXT.has(path.extname(name).toLowerCase())) out.push(full);
  }
  return out;
}
const norm = s => s.toLowerCase().replace(/[-_]+/g, " ").replace(/\s+/g, " ").trim();
// "English Female - Pre Chorus 2.wav" -> "pre chorus 2"
function cueKey(file) {
  const base = path.basename(file, path.extname(file));
  const parts = base.split(" - ");
  return norm(parts[parts.length - 1]).replace(/^prechorus/, "pre chorus");
}
function buildCueIndex(dir) {
  const idx = {};
  for (const f of listAudio(dir)) {
    const k = cueKey(f);
    // prefer files from a "Song Sections"-style folder over duplicates elsewhere
    if (!idx[k] || /section/i.test(path.dirname(f))) idx[k] = f;
  }
  return idx;
}
function findCue(idx, label) {
  const l = norm(label);
  const tries = [l, l.replace(/ \d+$/, ""), l.replace("instrumental", "inst"), l.replace("breakdown", "break")];
  for (const t of tries) if (idx[t]) return idx[t];
  return null;
}

// ---------------------------------------------------------------- audio file length (header only)
function audioDuration(file) {
  try {
    const fd = fs.openSync(file, "r");
    const buf = Buffer.alloc(65536);
    const n = fs.readSync(fd, buf, 0, buf.length, 0);
    const size = fs.fstatSync(fd).size;
    fs.closeSync(fd);
    const id = buf.toString("ascii", 0, 4);
    if (id === "RIFF" || id === "RF64") {
      let p = 12, byteRate = 0;
      while (p + 8 <= n) {
        const cid = buf.toString("ascii", p, p + 4);
        let len = buf.readUInt32LE(p + 4);
        if (cid === "fmt ") byteRate = buf.readUInt32LE(p + 16);
        if (cid === "data") {
          if (len === 0xffffffff || p + 8 + len > size) len = size - p - 8;
          return byteRate ? len / byteRate : null;
        }
        p += 8 + len + (len % 2);
      }
    } else if (id === "FORM") {
      let p = 12;
      while (p + 8 <= n) {
        const cid = buf.toString("ascii", p, p + 4);
        const len = buf.readUInt32BE(p + 4);
        if (cid === "COMM") {
          const frames = buf.readUInt32BE(p + 10);
          // 80-bit IEEE extended sample rate
          const exp = buf.readUInt16BE(p + 16) & 0x7fff;
          const mant = buf.readUInt32BE(p + 18);
          const rate = mant * Math.pow(2, exp - 16383 - 31);
          return frames / rate;
        }
        p += 8 + len + (len % 2);
      }
    }
  } catch (e) { /* fall through */ }
  return null;
}

// ---------------------------------------------------------------- plan
function makePlan(result, cfg) {
  if (!cfg.cueDir || !fs.existsSync(cfg.cueDir)) throw new Error("Choose your cue folder first");
  const idx = buildCueIndex(cfg.cueDir);
  const missing = new Set();
  const cueFor = label => {
    const f = findCue(idx, label);
    if (!f) { missing.add(label); return null; }
    return { path: f, dur: audioDuration(f) || 1.5 };
  };
  const sections = result.sections.map(s => Object.assign({}, s, { cue: cueFor(s.label) }));
  const counts = [];
  for (let i = 1; i <= result.meter; i++) {
    const c = cfg.counts ? cueFor(String(i)) : null;
    counts.push(c);
  }
  return {
    bpm: result.bpm, meter: result.meter, beat_period: result.beat_period,
    first_downbeat: result.first_downbeat, bars: result.bars, duration: result.duration,
    tempo_stable: result.tempo_stable, tempo_range: result.tempo_range, engine: result.engine,
    sections, counts, leadBars: cfg.leadBars, recordTempo: !!cfg.recordTempo, tempoMode: cfg.tempoMode || "record",
    note: result.note || "",
    missingCues: Array.from(missing)
  };
}

// ---------------------------------------------------------------- analysis
let busy = false;
function analyze(file) {
  return new Promise((resolve, reject) => {
    const cfg = loadConfig();
    if (!fs.existsSync(cfg.python)) return reject(new Error("Analysis engine not installed - run Setup first"));
    const out = path.join(os.tmpdir(), "aicb_" + Date.now() + ".json");
    const args = [cfg.engine, file, "--out", out, "--engine", ["auto", "allin1", "heuristic"].includes(cfg.structure) ? cfg.structure : "auto",
                  "--vocal-threshold", String(cfg.vocalThreshold)];
    const p = spawn(cfg.python, args, { env: Object.assign({}, process.env, { PYTHONWARNINGS: "ignore" }) });
    let err = "";
    p.stdout.on("data", () => {});
    p.stderr.on("data", d => {
      err += d.toString();
      for (const line of d.toString().split("\n")) {
        if (line.startsWith("PROGRESS ")) status(line.slice(9));
        else if (line.startsWith("PERCENT ")) {
          const [pct, eta] = line.slice(8).trim().split(/\s+/).map(Number);
          if (maxAPI && !isNaN(pct)) maxAPI.outlet("progress", pct, isNaN(eta) ? -1 : eta);
        }
      }
    });
    p.on("error", reject);
    p.on("close", code => {
      if (code !== 0 || !fs.existsSync(out)) return reject(new Error("Analysis failed: " + err.trim().split("\n").slice(-1)[0]));
      const res = JSON.parse(fs.readFileSync(out, "utf8"));
      fs.unlinkSync(out);
      resolve(res);
    });
  });
}

async function run(file) {
  if (busy) return status("Already working...");
  busy = true;
  try {
    status("Analyzing " + path.basename(file) + " ...");
    const res = await analyze(file);
    const plan = makePlan(res, loadConfig());
    if (maxAPI) await maxAPI.outlet("plan", JSON.stringify(plan));
    else console.log(JSON.stringify(plan, null, 1));
  } catch (e) {
    status("Error: " + e.message);
    if (maxAPI) maxAPI.outlet("failed");
  } finally { busy = false; }
}

// ---------------------------------------------------------------- tempo written into the saved set
const QUEUE = path.join(SUPPORT, "tempo_queue.json");
function loadQueue() { try { return JSON.parse(fs.readFileSync(QUEUE, "utf8")); } catch (e) { return []; } }
function saveQueue(q) { fs.mkdirSync(SUPPORT, { recursive: true }); fs.writeFileSync(QUEUE, JSON.stringify(q, null, 1)); }
function queueTempo(entry) {
  const q = loadQueue().filter(e => !(e.song === entry.song && Math.abs(e.start - entry.start) < 4));
  q.push(entry);
  saveQueue(q);
}
function writeTempo(alsPath) {
  const cfg = loadConfig();
  if (cfg.tempoMode === "record" || cfg.tempoMode === "set") { if (maxAPI) maxAPI.outlet("recordtempo"); return; }
  const q = loadQueue();
  if (!q.length) return status("Nothing to write: run Analyze & Build first");
  const tmp = path.join(os.tmpdir(), "seqan_tempo_" + Date.now() + ".json");
  fs.writeFileSync(tmp, JSON.stringify(q));
  const script = path.join(path.dirname(cfg.engine), "aicb_tempo.py");
  const p = spawn(cfg.python, [script, alsPath, tmp]);
  let out = "", err = "";
  p.stdout.on("data", d => out += d);
  p.stderr.on("data", d => err += d);
  p.on("close", code => {
    try { fs.unlinkSync(tmp); } catch (e) {}
    let r;
    try { r = JSON.parse(out); } catch (e) { return status("Error writing tempo: " + (err.trim().split("\n").pop() || "unknown")); }
    if (!r.written.length) {
      const why = r.skipped.length ? r.skipped[0].why : "nothing to write";
      return status(why.indexOf("not saved") >= 0 || why.indexOf("not in the saved") >= 0
        ? "Save the set first (Cmd+S) so the new clips are in the file, then press Write Tempo"
        : "Tempo not written: " + why);
    }
    saveQueue(q.filter(e => !r.written.some(w => w.song === e.song && Math.abs(w.start - e.start) < 1e-6)));
    const songs = r.written.map(w => w.bpm + " BPM").join(", ");
    status("Tempo written (" + songs + "). Now reopen the set: File > Open Recent > " + path.basename(alsPath, ".als"));
  });
}

if (maxAPI) {
  maxAPI.addHandler("queuetempo", (...parts) => { try { queueTempo(JSON.parse(parts.join(" "))); } catch (e) { status("Error: " + e.message); } });
  maxAPI.addHandler("writetempo", (...parts) => writeTempo(parts.join(" ")));
  maxAPI.addHandler("analyze", (...parts) => run(parts.join(" ")));
  maxAPI.addHandler("setcuedir", (...parts) => {
    const cfg = loadConfig();
    cfg.cueDir = maxToPosix(parts.join(" "));
    saveConfig(cfg);
    const n = Object.keys(buildCueIndex(cfg.cueDir)).length;
    status("Cue folder set: " + path.basename(cfg.cueDir) + " (" + n + " cues)");
  });
  maxAPI.addHandler("option", (key, val) => {
    const cfg = loadConfig();
    cfg[key] = typeof DEFAULTS[key] === "boolean" ? !!val : typeof DEFAULTS[key] === "string" ? String(val) : Number(val);
    saveConfig(cfg);
  });
  maxAPI.addHandler("hello", () => {
    const cfg = loadConfig();
    maxAPI.outlet("options", cfg.leadBars, cfg.counts ? 1 : 0, cfg.recordTempo ? 1 : 0);
    status(cfg.cueDir ? "Ready. Cues: " + path.basename(cfg.cueDir) : "Ready. Choose your cue folder.");
  });
}

module.exports = { queueTempo, loadQueue, writeTempo, makePlan, buildCueIndex, findCue, cueKey, audioDuration, maxToPosix };
