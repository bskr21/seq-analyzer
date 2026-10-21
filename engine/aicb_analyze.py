#!/usr/bin/env python3
"""Sequencer Analyzer - analysis engine.

Usage:  aicb_analyze.py <audio file> [--out result.json] [--engine auto|allin1|heuristic]

Prints progress lines "PROGRESS <text>" to stderr and writes JSON:
{
  "file", "duration", "bpm", "beat_period", "meter", "first_downbeat",
  "tempo_stable", "tempo_range", "engine",
  "bars": number of bars from first_downbeat,
  "sections": [{"label": "VERSE 1", "kind": "verse", "start_bar": 13, "end_bar": 33,
                "start": sec, "end": sec}]
}
Bar numbers are 1-based; bar n starts at first_downbeat + (n-1)*meter*beat_period.
"""
import argparse, json, os, sys, warnings

warnings.filterwarnings("ignore")
import numpy as np


def log(msg):
    print("PROGRESS " + msg, file=sys.stderr, flush=True)


# --------------------------------------------------------------------------- audio
def load_audio(path, sr):
    import librosa
    y, _ = librosa.load(path, sr=sr, mono=True)
    return y


# --------------------------------------------------------------------------- beats / tempo
def track_beats(path, hint=None):
    """Return (beat_times, beat_positions) using madmom's downbeat network; librosa fallback.
    With a BPM hint the tracker only considers tempi within 6% of it (no 2x, 1/2x or 4/3 errors)."""
    lo, hi = (hint * 0.94, hint * 1.06) if hint else (55, 215)
    try:
        from madmom.features.downbeats import RNNDownBeatProcessor, DBNDownBeatTrackingProcessor
        act = RNNDownBeatProcessor()(path)
        res = DBNDownBeatTrackingProcessor(beats_per_bar=[3, 4], fps=100, min_bpm=lo, max_bpm=hi)(act)
        return res[:, 0], res[:, 1].astype(int), "madmom"
    except Exception as e:  # pragma: no cover
        log("madmom unavailable (%s), using librosa beat tracker" % e.__class__.__name__)
        import librosa
        y = load_audio(path, 22050)
        _, beats = librosa.beat.beat_track(y=y, sr=22050, tightness=300, start_bpm=hint or 120.0)
        bt = librosa.frames_to_time(beats, sr=22050)
        return bt, (np.arange(len(bt)) % 4) + 1, "librosa"


def fit_grid(bt, pos):
    """Fit a constant-tempo grid t = a + b*k to the beats. Returns dict."""
    ibi = np.diff(bt)
    med = np.median(ibi)
    k = np.round((bt - bt[0]) / med).astype(int)
    keep = np.ones(len(bt), bool)
    for _ in range(4):  # iterative robust linear fit
        A = np.vstack([np.ones(keep.sum()), k[keep]]).T
        a, b = np.linalg.lstsq(A, bt[keep], rcond=None)[0]
        resid = bt - (a + b * k)
        keep = np.abs(resid) < max(0.03, 3 * np.median(np.abs(resid[keep])))
        k = np.round((bt - a) / b).astype(int)
    # meter = most common max bar position
    meter = 3 if int(max(pos)) == 3 else 4
    # downbeat phase: which k mod meter carries pos==1 most often
    phase = np.bincount((k[pos == 1]) % meter, minlength=meter).argmax()
    # earliest grid downbeat at or after time 0 - half a beat
    kd = phase - meter * int(np.ceil((phase + a / b) / meter))
    while a + b * kd < -0.5 * b:
        kd += meter
    first_db = a + b * kd
    # local tempo stability (8-beat windows, ignore last 4 bars where endings ritard)
    loc = 60.0 / np.convolve(ibi, np.ones(8) / 8, "valid")
    core = loc[: max(1, len(loc) - 16)]
    bpm = 60.0 / b
    stable = bool(np.percentile(np.abs(core - bpm), 90) < 0.02 * bpm)
    return dict(bpm=round(float(bpm), 2), beat_period=float(b), meter=meter,
                first_downbeat=float(first_db), tempo_stable=stable,
                tempo_range=[round(float(np.percentile(core, 5)), 1), round(float(np.percentile(core, 95)), 1)])


# --------------------------------------------------------------------------- label helpers
CANON = {
    "intro": "INTRO", "verse": "VERSE", "chorus": "CHORUS", "bridge": "BRIDGE",
    "inst": "INSTRUMENTAL", "solo": "INSTRUMENTAL", "outro": "OUTRO", "break": "BREAKDOWN",
    "prechorus": "PRE CHORUS", "pre-chorus": "PRE CHORUS", "interlude": "INTERLUDE",
}


def number_labels(secs):
    """Merge neighbours with the same kind, then number verses/bridges/pre-choruses."""
    merged = []
    for s in secs:
        if merged and merged[-1]["kind"] == s["kind"]:
            merged[-1]["end_bar"] = s["end_bar"]
        else:
            merged.append(dict(s))
    counts, seen = {}, {}
    for s in merged:
        counts[s["kind"]] = counts.get(s["kind"], 0) + 1
    for s in merged:
        k = s["kind"]
        base = CANON.get(k, k.upper())
        if k in ("verse", "bridge", "prechorus") and counts[k] > 1:
            seen[k] = seen.get(k, 0) + 1
            s["label"] = "%s %d" % (base, seen[k])
        else:
            s["label"] = base
    return merged


# --------------------------------------------------------------------------- progress
CACHE = os.path.join(os.path.expanduser("~"), "Library", "Caches", "AICueBuilder")
TIMING = os.path.join(CACHE, "timing.json")
# seconds of work per second of audio (first-run guesses; learned afterwards)
DEFAULT_RATES = {"decode": 0.01, "beats": 0.12, "demix": 0.45, "model": 0.35, "features": 0.12}


class Progress:
    """Prints "PERCENT <0-100> <eta seconds>" lines; stages are weighted by estimated time."""

    def __init__(self, duration, stages):
        import threading, time
        self.time, self.threading = time, threading
        self.duration = duration
        try:
            self.rates = dict(DEFAULT_RATES, **json.load(open(TIMING)))
        except Exception:
            self.rates = dict(DEFAULT_RATES)
        self.stages = stages
        self.est = {k: max(1.0, self.rates[k] * duration) for k in stages}
        self.done_est = 0.0
        self.t0 = time.time()
        self.cur, self.cur_t0, self.frac = None, None, 0.0
        self.measured = {}
        self._stop = threading.Event()
        threading.Thread(target=self._tick, daemon=True).start()

    def total(self):
        return sum(self.est[k] for k in self.stages)

    def start(self, stage, text):
        if self.cur:
            self.end()
        self.cur, self.cur_t0, self.frac = stage, self.time.time(), 0.0
        log(text)
        self.emit()

    def set_frac(self, f):           # real progress reported by the stage itself
        self.frac = max(self.frac, min(1.0, f))
        self.emit()

    def end(self):
        if not self.cur:
            return
        took = self.time.time() - self.cur_t0
        self.measured[self.cur] = took / max(1.0, self.duration)
        self.done_est += self.est[self.cur]
        self.cur = None
        self.emit()

    def skip(self, stage):
        if stage in self.stages:
            self.stages = [k for k in self.stages if k != stage]

    def emit(self):
        tot = self.total()
        cur_est = self.est.get(self.cur, 0.0)
        frac = self.frac
        if self.cur and frac == 0.0:         # no real progress: estimate from elapsed time
            frac = min(0.95, (self.time.time() - self.cur_t0) / cur_est)
        done = self.done_est + frac * cur_est
        pct = 100.0 * done / tot if tot else 100.0
        elapsed = self.time.time() - self.t0
        eta = elapsed * (tot - done) / done if done > 0.02 * tot else tot - done
        print("PERCENT %d %d" % (min(99, int(pct)), max(0, int(eta))), file=sys.stderr, flush=True)

    def _tick(self):
        while not self._stop.wait(1.0):
            if self.cur:
                self.emit()

    def finish(self):
        self.end()
        self._stop.set()
        try:                              # learn this machine's speed for next time
            os.makedirs(CACHE, exist_ok=True)
            old = dict(DEFAULT_RATES)
            try:
                old.update(json.load(open(TIMING)))
            except Exception:
                pass
            for k, v in self.measured.items():
                old[k] = 0.5 * old.get(k, v) + 0.5 * v if k in old else v
            json.dump(old, open(TIMING, "w"))
        except Exception:
            pass
        print("PERCENT 100 0", file=sys.stderr, flush=True)


# --------------------------------------------------------------------------- stems (Demucs) with live progress
def demix(path, prog):
    """Separate stems with HTDemucs; returns the folder holding bass/drums/other/vocals.wav."""
    import subprocess, re
    out = os.path.join(CACHE, "demix")
    stem_dir = os.path.join(out, "htdemucs", os.path.splitext(os.path.basename(path))[0])
    import shutil
    shutil.rmtree(stem_dir, ignore_errors=True)          # never reuse stems from another song
    p = subprocess.Popen([sys.executable, "-m", "demucs.separate", "--out", out, "--name", "htdemucs",
                          "--device", "cpu", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    buf, err = b"", b""
    pat = re.compile(rb"(\d{1,3})%\|")
    while True:
        ch = p.stderr.read(64)
        if not ch:
            break
        err = (err + ch)[-4000:]
        buf = (buf + ch)[-200:]
        m = pat.findall(buf)
        if m:
            prog.set_frac(int(m[-1]) / 100.0)
    if p.wait() != 0:
        raise RuntimeError("stem separation failed: " + err.decode(errors="ignore").strip().splitlines()[-1][:200])
    return stem_dir


def vocal_share(stem_dir):
    """Fraction of the mix energy that is lead/backing vocals (0..1)."""
    import soundfile as sf
    e = {}
    for s in ("bass", "drums", "other", "vocals"):
        y, _ = sf.read(os.path.join(stem_dir, s + ".wav"), dtype="float32")
        e[s] = float(np.mean(y.astype(np.float64) ** 2))
    return e["vocals"] / max(1e-12, sum(e.values()))


# --------------------------------------------------------------------------- engine 1: All-In-One
def sections_allin1(path, grid, nbars):
    import allin1, contextlib, io
    with contextlib.redirect_stdout(io.StringIO()):     # keep its chatter out of our output
        r = allin1.analyze(path, device="cpu", demix_dir=os.path.join(CACHE, "demix"),
                           spec_dir=os.path.join(CACHE, "spec"), multiprocess=False)
    bar_len = grid["beat_period"] * grid["meter"]
    to_bar = lambda t: int(round((t - grid["first_downbeat"]) / bar_len)) + 1
    secs = []
    for seg in r.segments:
        if seg.label in ("start", "end"):
            continue
        a, b = max(1, to_bar(seg.start)), min(nbars + 1, to_bar(seg.end))
        if b > a:
            secs.append(dict(kind=seg.label, start_bar=a, end_bar=b))
    return secs


# --------------------------------------------------------------------------- engine 2: heuristic
def bar_features(path, grid, nbars):
    import librosa
    sr, hop = 22050, 512
    y = load_audio(path, sr)
    yh, yp = librosa.effects.hpss(y)
    C = librosa.feature.chroma_cqt(y=yh, sr=sr, hop_length=hop)
    S = np.abs(librosa.stft(y, hop_length=hop))
    f = librosa.fft_frequencies(sr=sr)
    bar_len = grid["beat_period"] * grid["meter"]
    edges = grid["first_downbeat"] + bar_len * np.arange(nbars + 1)
    fr = librosa.time_to_frames(np.clip(edges, 0, None), sr=sr, hop_length=hop)
    sync = lambda X: librosa.util.sync(X, fr, aggregate=np.mean)[:, 1:nbars + 1] if fr[0] > 0 else \
        librosa.util.sync(X, fr, aggregate=np.mean)[:, :nbars]
    db = lambda x: 20 * np.log10(x + 1e-6)
    bands = [(20, 200), (200, 2000), (2000, 5000), (5000, 11000)]
    E = np.vstack([db(sync(S[(f >= a) & (f < b)].mean(0)[None])[0]) for a, b in bands])
    perc = db(sync(librosa.feature.rms(y=yp, hop_length=hop))[0])
    tot = db(sync(librosa.feature.rms(y=y, hop_length=hop))[0])
    Cb = sync(C)
    Cb = Cb / (np.linalg.norm(Cb, axis=0, keepdims=True) + 1e-9)
    return np.vstack([E, perc[None]]), tot, Cb


def sections_heuristic(path, grid, nbars):
    log("measuring energy and harmony per bar")
    E, _tot, Cb = bar_features(path, grid, nbars)
    n = E.shape[1]
    loud_bar = E[:4].mean(0)                      # average band level per bar (dB)
    peak = np.percentile(loud_bar, 95)
    end = n                                       # trailing ring-out / fade
    while end > 4 and loud_bar[end - 1] < peak - 15:
        end -= 1
    stop = np.zeros(n, bool)                      # one-bar band stops
    for i in range(1, end - 1):
        if loud_bar[i] < min(loud_bar[i - 1], loud_bar[i + 1]) - 6:
            stop[i] = True
    good = ~stop

    def seg_mean(a, b):
        idx = [i for i in range(max(0, a), min(end, b)) if good[i]]
        return E[:, idx].mean(1) if idx else None

    bounds = [0, end]
    for b in range(4, end, 4):                    # phrase grid: every 4 bars
        m1, m2 = seg_mean(b - 4, b), seg_mean(b, b + 4)
        if m1 is None or m2 is None:
            continue
        score = float(np.linalg.norm(m1 - m2)) + (3.0 if stop[b - 1] else 0.0)
        if score > 3.0:
            bounds.append(b)
    bounds = sorted(set(bounds))
    segs = [(bounds[i], bounds[i + 1]) for i in range(len(bounds) - 1)]
    log("found %d sections" % len(segs))

    desc = []
    for a, b in segs:
        idx = [i for i in range(a, b) if good[i]] or list(range(a, b))
        desc.append(dict(a=a, b=b, e=E[:, idx].mean(1), loud=float(loud_bar[idx].mean()), chroma=Cb[:, a:b]))
    N = len(desc)

    def similar(d1, d2):
        if np.linalg.norm(d1["e"] - d2["e"]) > 2.5:
            return False
        L = min(d1["chroma"].shape[1], d2["chroma"].shape[1], 8)
        return float(np.mean(np.sum(d1["chroma"][:, :L] * d2["chroma"][:, :L], axis=0))) > 0.75

    def sounds_like(d1, d2):                      # same band colour, ignoring bass level
        return float(np.linalg.norm(d1["e"][1:] - d2["e"][1:])) < 3.5

    cluster = [-1] * N
    nc = 0
    for i in range(N):
        if cluster[i] < 0:
            cluster[i] = nc
            for j in range(i + 1, N):
                if cluster[j] < 0 and similar(desc[i], desc[j]):
                    cluster[j] = nc
            nc += 1
    body = range(1, N - 1) if N > 2 else range(N)
    occ = {c: [i for i in body if cluster[i] == c] for c in range(nc)}
    core = [c for c in occ if len(occ[c]) >= 2]
    kinds = [None] * N
    med = float(np.median([d["loud"] for d in desc]))
    if core:
        chorus = max(core, key=lambda c: (len(occ[c]), occ[c][-1]))
        rest = [c for c in core if c != chorus]
        verse = min(rest, key=lambda c: occ[c][0]) if rest else None
        first_core = min(occ[c][0] for c in core)
        last_core = max(occ[c][-1] for c in core)
        for i in range(N):
            c = cluster[i]
            if i < first_core and c not in core:
                kinds[i] = "intro"
            elif i > last_core and c not in core:
                kinds[i] = "outro"
            elif c == chorus:
                kinds[i] = "chorus"
            elif c == verse:
                kinds[i] = "verse"
            elif c in core:
                kinds[i] = "prechorus" if all(j + 1 < N and cluster[j + 1] == chorus for j in occ[c]) else "interlude"
        intro_idx = [i for i in range(N) if kinds[i] == "intro"]
        quiet = lambda i: desc[i]["loud"] < med - 3
        for i in range(N):  # neighbouring quiet pieces form one breakdown
            if kinds[i] is None and quiet(i) and ((i > 0 and kinds[i - 1] in (None, "break") and quiet(i - 1))
                                                  or (i + 1 < N and kinds[i + 1] is None and quiet(i + 1))):
                kinds[i] = "break"
        for i in range(N):
            if kinds[i] is not None:
                continue
            d = desc[i]
            if d["b"] - d["a"] <= 4:
                kinds[i] = "interlude"
            elif d["loud"] < med - 3:
                kinds[i] = "break"
            elif any(sounds_like(d, desc[j]) for j in intro_idx):
                kinds[i] = "inst"
            else:
                kinds[i] = "bridge"
    else:
        kinds = ["verse"] * N
        if N > 1:
            kinds[0], kinds[-1] = "intro", "outro"
    out = []
    for i, d in enumerate(desc):
        if i == 0 and kinds[0] == "intro" and d["b"] - d["a"] <= 4 and d["loud"] < med - 3:
            continue                              # quiet count-in / pad stays unlabeled
        out.append(dict(kind=kinds[i], start_bar=d["a"] + 1, end_bar=d["b"] + 1))
    if out:
        out[-1]["end_bar"] = n + 1                # fold the ring-out into the last section
    return out


# --------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("audio")
    ap.add_argument("--out")
    ap.add_argument("--engine", default="auto", choices=["auto", "allin1", "heuristic"])
    ap.add_argument("--bpm-hint", type=float, default=None,
                    help="expected tempo (from the file/clip name); detection stays within 6%% of it")
    ap.add_argument("--vocal-threshold", type=float, default=0.12,
                    help="below this share of vocal energy the song is treated as instrumental")
    args = ap.parse_args()
    src = os.path.abspath(args.audio)
    import soundfile as sf, shutil
    os.makedirs(CACHE, exist_ok=True)
    try:
        duration = sf.info(src).duration
    except Exception:
        import librosa
        duration = librosa.get_duration(path=src)
    stages = ["decode", "beats"] + (["demix", "model"] if args.engine != "heuristic" else []) + ["features"]
    prog = Progress(duration, stages)

    # work on a WAV copy named after the song (no ffmpeg needed; stable stem-folder name)
    prog.start("decode", "decoding audio")
    base = os.path.splitext(os.path.basename(src))[0]
    path = os.path.join(CACHE, base + ".wav")
    if os.path.splitext(src)[1].lower() in (".wav", ".aif", ".aiff", ".flac"):
        shutil.copyfile(src, path) if src.lower().endswith(".wav") else sf.write(path, sf.read(src)[0], sf.info(src).samplerate)
    else:
        import librosa
        y, sr = librosa.load(src, sr=44100, mono=False)
        sf.write(path, np.atleast_2d(y).T, sr)
    duration = sf.info(path).duration

    prog.start("beats", "detecting beats and tempo")
    hint = args.bpm_hint if args.bpm_hint and 40 <= args.bpm_hint <= 250 else None
    if hint:
        log("using tempo hint %g BPM" % hint)
    bt, pos, beat_engine = track_beats(path, hint)
    grid = fit_grid(bt, pos)
    bar_len = grid["beat_period"] * grid["meter"]
    nbars = int(np.floor((duration - grid["first_downbeat"]) / bar_len + 0.25))
    log("tempo %.2f BPM, %d/4, %d bars" % (grid["bpm"], grid["meter"], nbars))

    secs, engine, vshare, note = None, None, None, ""
    if args.engine in ("auto", "allin1"):
        try:
            prog.start("demix", "separating stems (vocals, drums, bass, other)")
            stems = demix(path, prog)
            vshare = vocal_share(stems)
            if args.engine == "auto" and vshare < args.vocal_threshold:
                note = "instrumental track (vocals %.0f%%): using repetition analysis" % (100 * vshare)
                log(note)
                prog.skip("model")
            else:
                prog.start("model", "running AI structure model (vocals %.0f%%)" % (100 * vshare))
                secs = sections_allin1(path, grid, nbars)
                kinds = {x["kind"] for x in secs}
                if args.engine == "auto" and not ({"verse", "chorus"} & kinds):
                    note = "AI model found no verse/chorus: using repetition analysis"
                    log(note)
                    secs = None
                else:
                    engine = "allin1"
        except Exception as e:
            if args.engine == "allin1":
                raise
            note = "AI model unavailable (%s): using repetition analysis" % e.__class__.__name__
            log(note + " - " + str(e)[:160])
            prog.skip("model")
    if secs is None:
        prog.start("features", "finding repeated sections")
        secs, engine = sections_heuristic(path, grid, nbars), "heuristic"
    else:
        prog.skip("features")
    prog.finish()

    secs = number_labels(secs)
    for s in secs:
        s["start"] = round(grid["first_downbeat"] + (s["start_bar"] - 1) * bar_len, 4)
        s["end"] = round(min(duration, grid["first_downbeat"] + (s["end_bar"] - 1) * bar_len), 4)
    import shutil
    try:
        os.unlink(path)
    except OSError:
        pass
    shutil.rmtree(os.path.join(CACHE, "demix", "htdemucs", base), ignore_errors=True)
    result = dict(file=src, duration=round(duration, 3), beat_engine=beat_engine, engine=engine,
                  vocal_share=None if vshare is None else round(vshare, 3), note=note, bpm_hint=hint,
                  bars=nbars, sections=secs, **grid)
    js = json.dumps(result, indent=1)
    if args.out:
        with open(args.out, "w") as f:
            f.write(js)
    else:
        print(js)
    log("done")


if __name__ == "__main__":
    main()
