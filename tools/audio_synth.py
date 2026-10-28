"""Tiny offline synthesizer + sequencer (numpy). Used by compose_music.py and make_sfx.py.
All music is original; instruments are synthesized from scratch (no samples)."""
import numpy as np, wave, subprocess, os

SR = 32000
NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}

def midi(name):
    """'C#5' -> 73"""
    i = 2 if len(name) > 2 and name[1] in "#b" else 1
    return 12 * (int(name[i:]) + 1) + NOTE[name[:i]]

def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)

def t_axis(n):
    return np.arange(n) / SR

def adsr(n, a=0.01, d=0.1, s=0.7, r=0.1):
    env = np.ones(n) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = min(na, n); nd = min(nd, max(0, n - na)); nr = min(nr, n)
    if na: env[:na] = np.linspace(0, 1, na)
    if nd: env[na:na + nd] = np.linspace(1, s, nd)
    if nr: env[n - nr:] *= np.linspace(1, 0, nr)
    return env

def lowpass(x, cutoff):
    """One-pole low-pass (vectorized via exponential smoothing with lfilter-like recursion in chunks)."""
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    # chunked recursion keeps it reasonably fast
    for i in range(0, len(x), 4096):
        seg = x[i:i + 4096]
        out = np.empty_like(seg)
        for j, v in enumerate(seg):
            acc = (1 - a) * v + a * acc
            out[j] = acc
        y[i:i + 4096] = out
    return y

def lp_fast(x, cutoff):
    """Cheap FFT brickwall-ish low-pass with a soft roll-off (fast, for whole tracks)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1 / (1 + (f / cutoff) ** 4)
    return np.fft.irfft(X, len(x))

def hp_fast(x, cutoff):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1 - 1 / (1 + (f / max(cutoff, 1)) ** 4)
    return np.fft.irfft(X, len(x))

def saw(f, t):
    return 2 * ((t * f) % 1.0) - 1

def square(f, t, duty=0.5):
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)

def tri(f, t):
    return 2 * np.abs(saw(f, t)) - 1

# ---------------- instruments: (freq, seconds, velocity) -> mono samples ----------------
def inst_lead(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t * 3 - 0.3, 0, 1)
    ph = np.cumsum(f * vib) / SR
    x = 0.6 * (2 * (ph % 1) - 1) + 0.4 * np.where(ph % 1 < 0.5, 1, -1)
    return x * adsr(n, 0.01, 0.15, 0.75, 0.08) * vel * 0.32

def inst_flute(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    vib = 1 + 0.008 * np.sin(2 * np.pi * 5 * t) * np.clip(t * 2.5 - 0.2, 0, 1)
    ph = np.cumsum(f * vib) / SR
    x = np.sin(2 * np.pi * ph) + 0.18 * np.sin(4 * np.pi * ph) + 0.05 * np.random.randn(n) * np.exp(-t * 8)
    return x * adsr(n, 0.05, 0.1, 0.85, 0.12) * vel * 0.35

def inst_brass(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    x = sum(saw(f * d, t) for d in (1.0, 1.004, 0.996)) / 3
    bright = np.clip(t * 8, 0, 1)
    x = x * (0.6 + 0.4 * bright)
    return x * adsr(n, 0.04, 0.2, 0.8, 0.12) * vel * 0.26

def inst_strings(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    x = sum(saw(f * d, t + p) for d, p in ((1.0, 0), (1.006, 0.13), (0.994, 0.31), (2.003, 0.07)))
    return x / 4 * adsr(n, 0.25, 0.3, 0.85, 0.35) * vel * 0.22

def inst_pad(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    x = sum(tri(f * d, t + p) for d, p in ((1.0, 0), (1.008, 0.2), (0.992, 0.4), (0.5, 0.1)))
    return x / 4 * adsr(n, 0.5, 0.4, 0.9, 0.6) * vel * 0.25

def inst_organ(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    lfo = 1 + 0.3 * np.sin(2 * np.pi * 6.5 * t)
    x = sum(a * np.sin(2 * np.pi * f * h * t) for h, a in ((0.5, 0.5), (1, 1.0), (2, 0.6), (3, 0.35), (4, 0.25), (6, 0.12)))
    return x / 2.8 * lfo * adsr(n, 0.005, 0.05, 0.9, 0.05) * vel * 0.28

def inst_piano(f, dur, vel):
    n = int(max(dur, 0.6) * SR); t = t_axis(n)
    x = sum(a * np.sin(2 * np.pi * f * h * t) * np.exp(-t * (1.5 + h * 0.9)) for h, a in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.06)))
    x *= adsr(n, 0.003, 0.05, 1.0, 0.08)
    return x * vel * 0.33

def inst_bell(f, dur, vel):
    n = int(max(dur, 1.2) * SR); t = t_axis(n)
    x = sum(a * np.sin(2 * np.pi * f * h * t) * np.exp(-t * d) for h, a, d in ((1, 1, 1.6), (2.76, 0.5, 2.5), (5.4, 0.25, 4), (8.93, 0.12, 6)))
    return x * vel * 0.22

def inst_pluck(f, dur, vel):
    """Karplus-Strong harp/guitar."""
    n = int(max(dur, 0.8) * SR)
    p = max(2, int(SR / f))
    buf = np.random.uniform(-1, 1, p)
    out = np.empty(n)
    idx = 0
    for i in range(n):
        out[i] = buf[idx]
        nxt = (idx + 1) % p
        buf[idx] = 0.497 * (buf[idx] + buf[nxt])
        idx = nxt
    return out * vel * 0.42

def inst_bass(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    x = 0.7 * saw(f, t) + 0.5 * np.sin(2 * np.pi * f * t)
    x = np.tanh(x * 1.5)
    return x * adsr(n, 0.005, 0.12, 0.65, 0.05) * vel * 0.38

def inst_synbass(f, dur, vel):
    n = int(dur * SR); t = t_axis(n)
    x = square(f, t, 0.35) * 0.6 + saw(f * 1.003, t) * 0.4
    return np.tanh(x * 2) * adsr(n, 0.003, 0.08, 0.6, 0.03) * vel * 0.3

def inst_timpani(f, dur, vel):
    n = int(1.4 * SR); t = t_axis(n)
    x = np.sin(2 * np.pi * f * t * (1 + 0.1 * np.exp(-t * 20))) * np.exp(-t * 2.5) + 0.2 * np.random.randn(n) * np.exp(-t * 30)
    return x * vel * 0.5

# drums (pitch ignored)
def drum_kick(f, dur, vel):
    n = int(0.35 * SR); t = t_axis(n)
    fr = 50 + 110 * np.exp(-t * 35)
    x = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 9)
    return x * vel * 0.9

def drum_snare(f, dur, vel):
    n = int(0.3 * SR); t = t_axis(n)
    noise = hp_fast(np.random.randn(n), 1500)
    x = 0.7 * noise * np.exp(-t * 16) + 0.5 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25)
    return x * vel * 0.45

def drum_hat(f, dur, vel):
    n = int(0.06 * SR); t = t_axis(n)
    return hp_fast(np.random.randn(n), 7000) * np.exp(-t * 60) * vel * 0.22

def drum_ohat(f, dur, vel):
    n = int(0.3 * SR); t = t_axis(n)
    return hp_fast(np.random.randn(n), 6500) * np.exp(-t * 10) * vel * 0.18

def drum_crash(f, dur, vel):
    n = int(1.8 * SR); t = t_axis(n)
    return hp_fast(np.random.randn(n), 4000) * np.exp(-t * 2.2) * vel * 0.25

def drum_tom(f, dur, vel):
    n = int(0.4 * SR); t = t_axis(n)
    fr = f * (1 + 0.5 * np.exp(-t * 20))
    return np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 8) * vel * 0.6

def drum_shaker(f, dur, vel):
    n = int(0.09 * SR); t = t_axis(n)
    return hp_fast(np.random.randn(n), 5000) * np.sin(np.pi * np.clip(t / 0.09, 0, 1)) * vel * 0.15

DRUMS = {"K": drum_kick, "S": drum_snare, "H": drum_hat, "O": drum_ohat, "C": drum_crash, "T": drum_tom, "Z": drum_shaker}

# ---------------- sequencing ----------------
class Song:
    def __init__(self, bpm, beats, swing=0.0):
        self.bpm = bpm
        self.spb = 60.0 / bpm
        self.length = int(beats * self.spb * SR)
        self.L = np.zeros(self.length + SR * 3)
        self.R = np.zeros(self.length + SR * 3)
        self.swing = swing

    def place(self, x, beat, pan=0.0, gain=1.0):
        s = int(beat * self.spb * SR)
        if s >= len(self.L):
            return
        e = min(len(self.L), s + len(x))
        x = x[: e - s] * gain
        self.L[s:e] += x * np.sqrt(0.5 * (1 - pan))
        self.R[s:e] += x * np.sqrt(0.5 * (1 + pan))

    def notes(self, inst, seq, start=0.0, pan=0.0, gain=1.0, octave=0, legato=0.95, transpose=0):
        """seq: 'D5:1 F#5:0.5 r:0.5 A5:2' ; chords with '+': 'D4+F#4+A4:4'. Velocity suffix '!'=accent, '.'=soft."""
        b = start
        for tok in seq.split():
            name, d = tok.rsplit(":", 1)
            d = float(d)
            vel = 0.85
            if name.endswith("!"):
                vel, name = 1.0, name[:-1]
            elif name.endswith("."):
                vel, name = 0.6, name[:-1]
            if name != "r":
                for nn in name.split("+"):
                    m = midi(nn) + 12 * octave + transpose
                    self.place(inst(hz(m), d * self.spb * legato, vel), b, pan, gain)
            b += d
        return b

    def drums(self, pattern, start, bars, beats_per_bar=4, gain=1.0, steps=16):
        """pattern: dict lane-> string of length `steps` per bar ('x' hit, 'X' accent, '.' rest)."""
        step = beats_per_bar / steps
        for bar in range(bars):
            for lane, pat in pattern.items():
                for i, ch in enumerate(pat):
                    if ch in "xX":
                        v = 1.0 if ch == "X" else 0.7
                        b = start + bar * beats_per_bar + i * step
                        if self.swing and i % 2 == 1:
                            b += step * self.swing
                        pan = {"H": 0.3, "O": 0.3, "Z": -0.3, "T": -0.2}.get(lane, 0.0)
                        self.place(DRUMS[lane](0 if lane != "T" else 110 + 30 * (i % 3), step * self.spb, v), b, pan, gain)

    def chords(self, inst, prog, start, beats_per_chord=4, octave=4, gain=1.0, style="pad", pan=0.0, bass_inst=None, bass_oct=2, arp_rate=0.5):
        """prog: list like ['D', 'Bm', 'G', 'A7']. style: pad | arp | stab | power."""
        b = start
        for ch in prog:
            tones = chord_tones(ch, octave)
            if style == "pad":
                for m in tones:
                    self.place(inst(hz(m), beats_per_chord * self.spb, 0.7), b, pan, gain)
            elif style == "arp":
                seq = tones + [tones[1], tones[2] + 12 if len(tones) > 2 else tones[0] + 12]
                k = 0
                bb = 0.0
                while bb < beats_per_chord - 1e-6:
                    self.place(inst(hz(seq[k % len(seq)]), arp_rate * self.spb * 1.6, 0.7), b + bb, pan + (0.2 if k % 2 else -0.2), gain)
                    k += 1
                    bb += arp_rate
            elif style == "stab":
                for bb in (0, 1.5, 3):
                    if bb < beats_per_chord:
                        for m in tones:
                            self.place(inst(hz(m), 0.4 * self.spb, 0.8), b + bb, pan, gain)
            elif style == "power":
                root = tones[0]
                for bb in np.arange(0, beats_per_chord, 0.5):
                    for m in (root, root + 7, root + 12):
                        self.place(inst(hz(m), 0.45 * self.spb, 0.9 if bb % 1 == 0 else 0.7), b + bb, pan, gain)
            if bass_inst:
                root = chord_tones(ch, bass_oct)[0]
                self.place(bass_inst(hz(root), beats_per_chord * self.spb * 0.5, 0.9), b, 0, gain)
                self.place(bass_inst(hz(root + (7 if beats_per_chord >= 4 else 0)), beats_per_chord * self.spb * 0.45, 0.75), b + beats_per_chord / 2, 0, gain)
            b += beats_per_chord
        return b

    def bassline(self, inst, prog, start, beats_per_chord=4, octave=2, rate=0.5, gain=1.0, pattern=(0, 0, 12, 0, 7, 0, 12, 7)):
        b = start
        for ch in prog:
            root = chord_tones(ch, octave)[0]
            bb, k = 0.0, 0
            while bb < beats_per_chord - 1e-6:
                self.place(inst(hz(root + pattern[k % len(pattern)]), rate * self.spb * 0.9, 0.9 if k % 2 == 0 else 0.75), b + bb, 0, gain)
                bb += rate
                k += 1
            b += beats_per_chord
        return b

    def render(self, path, reverb=0.25, loop=True, master=0.9):
        L, R = self.L, self.R
        if reverb > 0:
            L, R = _reverb(L, R, reverb)
        if loop:
            # fold the tail back onto the start so the loop point is seamless
            tail = len(L) - self.length
            L[: tail] += L[self.length:]
            R[: tail] += R[self.length:]
            L, R = L[: self.length], R[: self.length]
        else:
            nz = np.nonzero(np.abs(L) + np.abs(R) > 1e-4)[0]
            end = (nz[-1] + SR // 4) if len(nz) else len(L)
            L, R = L[:end], R[:end]
        L, R = lp_fast(L, 9500), lp_fast(R, 9500)     # warm master: tame harsh saw/hat highs
        L, R = hp_fast(L, 30), hp_fast(R, 30)         # remove DC/sub rumble
        peak = max(np.max(np.abs(L)), np.max(np.abs(R)), 1e-9)
        L, R = np.tanh(L / peak * 1.15) * master, np.tanh(R / peak * 1.15) * master
        write_ogg(path, L, R)

def _reverb(L, R, wet):
    n = int(2.2 * SR)
    t = t_axis(n)
    rng = np.random.default_rng(3)
    irL = rng.standard_normal(n) * np.exp(-t * 3.2)
    irR = rng.standard_normal(n) * np.exp(-t * 3.2)
    irL[: int(0.02 * SR)] = 0
    irR[: int(0.027 * SR)] = 0
    irL = lp_fast(irL, 5000); irR = lp_fast(irR, 5000)
    irL /= np.sqrt(np.sum(irL ** 2)); irR /= np.sqrt(np.sum(irR ** 2))
    m = len(L) + n
    nfft = 1 << (m - 1).bit_length()
    FL, FR = np.fft.rfft(L, nfft), np.fft.rfft(R, nfft)
    wL = np.fft.irfft(FL * np.fft.rfft(irL, nfft), nfft)[: len(L)]
    wR = np.fft.irfft(FR * np.fft.rfft(irR, nfft), nfft)[: len(R)]
    s = np.max(np.abs(L)) / max(np.max(np.abs(wL)), 1e-9)
    return L + wL * s * wet, R + wR * s * wet

QUAL = {"": (0, 4, 7), "m": (0, 3, 7), "7": (0, 4, 7, 10), "m7": (0, 3, 7, 10), "maj7": (0, 4, 7, 11), "sus4": (0, 5, 7),
        "sus2": (0, 2, 7), "dim": (0, 3, 6), "aug": (0, 4, 8), "add9": (0, 4, 7, 14), "m9": (0, 3, 7, 14), "5": (0, 7, 12)}

def chord_tones(name, octave):
    i = 2 if len(name) > 1 and name[1] in "#b" else 1
    root, q = name[:i], name[i:]
    if "/" in q:
        q = q.split("/")[0]
    base = 12 * (octave + 1) + NOTE[root]
    return [base + iv for iv in QUAL.get(q, QUAL[""])]

def write_wav(path, L, R=None, sr=SR):
    data = np.stack([L, R if R is not None else L], axis=1) if R is not None else L[:, None]
    pcm = (np.clip(data, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(pcm.shape[1]); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes(pcm.tobytes())

def write_ogg(path, L, R):
    tmp = path + ".tmp.wav"
    write_wav(tmp, L, R)
    subprocess.run(["sox", tmp, "-C", "4", path], check=True)   # OGG Vorbis q4 (sox; Homebrew ffmpeg is broken here)
    os.remove(tmp)
