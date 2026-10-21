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
def track_beats(path):
    """Return (beat_times, beat_positions) using madmom's downbeat network; librosa fallback."""
    try:
        from madmom.features.downbeats import RNNDownBeatProcessor, DBNDownBeatTrackingProcessor
        act = RNNDownBeatProcessor()(path)
        res = DBNDownBeatTrackingProcessor(beats_per_bar=[3, 4], fps=100, min_bpm=55, max_bpm=215)(act)
        return res[:, 0], res[:, 1].astype(int), "madmom"
    except Exception as e:  # pragma: no cover
        log("madmom unavailable (%s), using librosa beat tracker" % e.__class__.__name__)
        import librosa
        y = load_audio(path, 22050)
        _, beats = librosa.beat.beat_track(y=y, sr=22050, tightness=300)
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


# --------------------------------------------------------------------------- engine 1: All-In-One
def sections_allin1(path, grid, nbars):
    import allin1
    log("running All-In-One structure model (first run downloads models)")
    work = os.path.join(os.path.expanduser("~"), "Library", "Caches", "AICueBuilder")
    os.makedirs(work, exist_ok=True)
    r = allin1.analyze(path, device="cpu", demix_dir=os.path.join(work, "demix"),
                       spec_dir=os.path.join(work, "spec"), multiprocess=False)
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
    args = ap.parse_args()
    src = os.path.abspath(args.audio)
    import soundfile as sf, tempfile
    path, tmp = src, None
    if os.path.splitext(src)[1].lower() not in (".wav", ".aif", ".aiff", ".flac"):
        # decode compressed audio once (no ffmpeg needed on PATH)
        log("decoding audio")
        import librosa
        y, sr = librosa.load(src, sr=44100, mono=False)
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
        sf.write(tmp, np.atleast_2d(y).T, sr)
        path = tmp
    duration = sf.info(path).duration

    log("detecting beats and tempo")
    bt, pos, beat_engine = track_beats(path)
    grid = fit_grid(bt, pos)
    bar_len = grid["beat_period"] * grid["meter"]
    nbars = int(np.floor((duration - grid["first_downbeat"]) / bar_len + 0.25))
    log("tempo %.2f BPM, %d/4, %d bars" % (grid["bpm"], grid["meter"], nbars))

    secs, engine = None, None
    if args.engine in ("auto", "allin1"):
        try:
            secs, engine = sections_allin1(path, grid, nbars), "allin1"
        except Exception as e:
            if args.engine == "allin1":
                raise
            log("structure model unavailable (%s: %s); using built-in analysis" % (e.__class__.__name__, str(e)[:120]))
    if secs is None:
        secs, engine = sections_heuristic(path, grid, nbars), "heuristic"

    secs = number_labels(secs)
    for s in secs:
        s["start"] = round(grid["first_downbeat"] + (s["start_bar"] - 1) * bar_len, 4)
        s["end"] = round(min(duration, grid["first_downbeat"] + (s["end_bar"] - 1) * bar_len), 4)
    if tmp:
        os.unlink(tmp)
    result = dict(file=src, duration=round(duration, 3), beat_engine=beat_engine, engine=engine,
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
