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
  tempoMode: "follow",  // "follow" = the device switches Live's tempo while its song plays (no automation) |
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
    sections, counts, leadBars: cfg.leadBars, recordTempo: !!cfg.recordTempo, tempoMode: cfg.tempoMode || "follow",
    note: result.note || "", bpm_hint: result.bpm_hint || null, tempo_alternatives: result.tempo_alternatives || [],
    missingCues: Array.from(missing)
  };
}

// ---------------------------------------------------------------- analysis
let busy = false;
// ---------------------------------------------------------------- tempo hint from names
// "74BPM", "74 bpm", "bpm 74" anywhere; or the key+tempo style "F#150", "E113", "Bbm 72" at the end of a name.
function bpmFromName(name) {
  if (!name) return null;
  const s = String(name).replace(/\.[a-z0-9]{2,4}$/i, "");
  let m = /(\d{2,3}(?:[.,]\d+)?)\s*-?\s*bpm\b/i.exec(s) || /\bbpm\s*-?\s*(\d{2,3}(?:[.,]\d+)?)/i.exec(s);
  if (!m) m = /(?:^|[\s_\-(\[])[A-G](?:#|b)?m?\s?(\d{2,3})\s*[)\]]?\s*$/.exec(s);
  if (!m) return null;
  const v = parseFloat(m[1].replace(",", "."));
  return v >= 40 && v <= 250 ? v : null;
}
// clip name (the user's override) > file name > parent folders
function bpmHint(file, clipName) {
  const parts = [clipName, path.basename(file), path.basename(path.dirname(file)), path.basename(path.dirname(path.dirname(file)))];
  for (const p of parts) { const v = bpmFromName(p); if (v) return { bpm: v, from: p === clipName ? "clip name" : "\"" + p + "\"" }; }
  return null;
}

function analyze(file, hint) {
  return new Promise((resolve, reject) => {
    const cfg = loadConfig();
    if (!fs.existsSync(cfg.python)) return reject(new Error("Analysis engine not installed - run Setup first"));
    const out = path.join(os.tmpdir(), "aicb_" + Date.now() + ".json");
    const args = [cfg.engine, file, "--out", out, "--engine", ["auto", "allin1", "heuristic"].includes(cfg.structure) ? cfg.structure : "auto",
                  "--vocal-threshold", String(cfg.vocalThreshold)];
    if (hint) args.push("--bpm-hint", String(hint.bpm));
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

// analysis results are cached per file (path, size, date) and per analysis settings
const ENGINE_VERSION = "0.7";
function cacheFile(file, hint) {
  const cfg = loadConfig(), st = fs.statSync(file);
  const key = [ENGINE_VERSION, file, st.size, st.mtimeMs, cfg.structure, cfg.vocalThreshold, hint ? hint.bpm : ""].join("|");
  return path.join(os.homedir(), "Library", "Caches", "AICueBuilder", "results",
    require("crypto").createHash("sha1").update(key).digest("hex") + ".json");
}

async function run(file, clipName) {
  if (busy) return status("Already working...");
  busy = true;
  try {
    const hint = bpmHint(file, clipName);
    status("analyzing " + path.basename(file) + (hint ? " (tempo hint " + hint.bpm + " BPM from " + hint.from + ")" : "") + " ...");
    const cached = cacheFile(file, hint);
    let res;
    if (fs.existsSync(cached)) {
      res = JSON.parse(fs.readFileSync(cached, "utf8"));
      if (maxAPI) maxAPI.outlet("progress", 100, 0);
    } else {
      res = await analyze(file, hint);
      fs.mkdirSync(path.dirname(cached), { recursive: true });
      fs.writeFileSync(cached, JSON.stringify(res));
    }
    const plan = makePlan(res, loadConfig());
    if (maxAPI) await maxAPI.outlet("plan", JSON.stringify(plan));
    else console.log(JSON.stringify(plan, null, 1));
  } catch (e) {
    status("Error: " + e.message);
    if (maxAPI) maxAPI.outlet("failed");
  } finally { busy = false; }
}

if (maxAPI) {
  // analyze {"file": ..., "clip": ...}  (older form: analyze <path>)
  maxAPI.addHandler("analyze", (...parts) => {
    const txt = parts.join(" ");
    let o = null;
    try { o = JSON.parse(txt); } catch (e) {}
    if (o && o.file) run(o.file, o.clip || ""); else run(txt, "");
  });
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

module.exports = { bpmFromName, bpmHint, makePlan, buildCueIndex, findCue, cueKey, audioDuration, maxToPosix };
