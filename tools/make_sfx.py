"""Synthesized sound effects -> assets/audio/sfx/<id>.wav (mono 32 kHz)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import audio_synth as A
from audio_synth import SR, t_axis, lp_fast, hp_fast, hz, midi

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets/audio/sfx")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(11)

def sec(s):
    return int(s * SR)

def noise(n):
    return rng.standard_normal(n)

def sweep(f0, f1, dur, shape="sine"):
    n = sec(dur); t = t_axis(n)
    f = f0 * (f1 / f0) ** (t / dur)
    ph = np.cumsum(f) / SR
    if shape == "square":
        return np.where(ph % 1 < 0.5, 1.0, -1.0)
    if shape == "saw":
        return 2 * (ph % 1) - 1
    return np.sin(2 * np.pi * ph)

def env(n, a, decay):
    t = t_axis(n)
    e = np.exp(-t * decay)
    na = max(1, sec(a))
    e[:na] *= np.linspace(0, 1, na)
    return e

def bandnoise(dur, lo, hi):
    return hp_fast(lp_fast(noise(sec(dur)), hi), lo)

def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out

def seq_tones(notes, step, inst=A.inst_bell, vel=0.9):
    total = sec(step * len(notes) + 1.0)
    out = np.zeros(total)
    for i, nm in enumerate(notes):
        x = inst(hz(midi(nm)), step * 1.5, vel)
        s = sec(step * i)
        e = min(total, s + len(x))
        out[s:e] += x[: e - s]
    return out

def save(name, x, gain=0.9):
    x = x / max(np.max(np.abs(x)), 1e-9) * gain
    nz = np.nonzero(np.abs(x) > 1e-3)[0]
    x = x[: (nz[-1] + sec(0.02)) if len(nz) else len(x)]
    x[-min(len(x), sec(0.01)):] *= np.linspace(1, 0, min(len(x), sec(0.01)))
    A.write_wav(os.path.join(OUT, name + ".wav"), x)
    print("SFX", name, round(len(x) / SR, 2), "s")

def build():
    # --- UI
    n = sec(0.05); save("ui_cursor", np.sin(2 * np.pi * 1320 * t_axis(n)) * env(n, 0.002, 60), 0.5)
    save("ui_confirm", mix(np.sin(2 * np.pi * 880 * t_axis(sec(0.07))) * env(sec(0.07), 0.002, 30),
                           np.pad(np.sin(2 * np.pi * 1320 * t_axis(sec(0.12))) * env(sec(0.12), 0.002, 25), (sec(0.06), 0))), 0.6)
    save("ui_cancel", sweep(700, 350, 0.12) * env(sec(0.12), 0.002, 20), 0.55)
    save("ui_error", A.square(160, t_axis(sec(0.18))) * env(sec(0.18), 0.002, 12) * 0.5, 0.45)
    save("text", np.sin(2 * np.pi * 1800 * t_axis(sec(0.02))) * env(sec(0.02), 0.001, 150), 0.25)
    # --- combat
    for i, (f0, f1, d) in enumerate([(2500, 600, 0.14), (3200, 700, 0.12), (2000, 400, 0.2)]):
        w = bandnoise(d, 400, 6000) * env(sec(d), 0.02, 18) * (0.5 + 0.5 * sweep(f0, f1, d))
        save(f"slash{i + 1}", w, 0.7)
    n = sec(0.22); t = t_axis(n)
    save("hit", mix(np.sin(2 * np.pi * np.cumsum(90 + 200 * np.exp(-t * 40)) / SR) * env(n, 0.001, 14),
                    bandnoise(0.12, 800, 5000) * env(sec(0.12), 0.001, 35) * 0.7), 0.85)
    save("hit_heavy", mix(np.sin(2 * np.pi * np.cumsum(60 + 180 * np.exp(-t * 30)) / SR) * env(n, 0.001, 10),
                          bandnoise(0.2, 300, 4000) * env(sec(0.2), 0.001, 20)), 0.95)
    save("crit", mix(np.sin(2 * np.pi * np.cumsum(70 + 260 * np.exp(-t * 30)) / SR) * env(n, 0.001, 10),
                     bandnoise(0.18, 1000, 9000) * env(sec(0.18), 0.001, 22),
                     np.sin(2 * np.pi * 2400 * t_axis(sec(0.5))) * env(sec(0.5), 0.001, 7) * 0.4), 0.95)
    n = sec(0.4); t = t_axis(n)
    save("guard", mix(sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, d in ((1250, 9), (2210, 12), (3480, 16))),
                      bandnoise(0.05, 2000, 9000) * env(sec(0.05), 0.001, 60)), 0.6)
    save("enemy_attack", bandnoise(0.25, 200, 2500) * env(sec(0.25), 0.03, 10) * (0.6 + 0.4 * sweep(300, 120, 0.25)), 0.6)
    n = sec(0.6); t = t_axis(n)
    save("ko", sweep(500, 80, 0.6, "square") * env(n, 0.005, 4) * 0.5 + lp_fast(noise(n), 400) * env(n, 0.005, 6), 0.6)
    save("enemy_die", mix(sweep(900, 60, 0.7, "saw") * env(sec(0.7), 0.005, 5) * 0.4, bandnoise(0.7, 200, 3000) * env(sec(0.7), 0.01, 6)), 0.6)
    # --- magic
    n = sec(1.0); t = t_axis(n)
    save("cast", sum(np.sin(2 * np.pi * f * (1 + t * 0.6) * t) * 0.3 for f in (660, 990, 1320)) * np.clip(t * 3, 0, 1) * env(n, 0.0, 2.5), 0.5)
    save("fire", mix(lp_fast(noise(sec(0.7)), 1800) * env(sec(0.7), 0.01, 5), np.sin(2 * np.pi * np.cumsum(80 + 120 * np.exp(-t_axis(sec(0.7)) * 8)) / SR) * env(sec(0.7), 0.002, 6)), 0.85)
    save("earth", mix(lp_fast(noise(sec(0.9)), 300) * env(sec(0.9), 0.02, 4) * 1.5, bandnoise(0.3, 500, 3000) * env(sec(0.3), 0.001, 15) * 0.6), 0.9)
    n = sec(0.6); t = t_axis(n)
    save("water", sum(np.sin(2 * np.pi * (500 + 900 * ((t * k) % 1)) * t) * env(n, 0.005, 5) * 0.3 for k in (7, 11, 13)), 0.6)
    save("wind", bandnoise(0.8, 600, 4000) * np.sin(np.pi * np.clip(t_axis(sec(0.8)) / 0.8, 0, 1)) * (0.6 + 0.4 * sweep(400, 1600, 0.8)), 0.6)
    save("lightning", mix(bandnoise(0.08, 2000, 12000) * env(sec(0.08), 0.0005, 30) * 1.5, lp_fast(noise(sec(1.0)), 250) * env(sec(1.0), 0.02, 3) * 1.2), 0.95)
    save("light", seq_tones(["C6", "E6", "G6", "C7"], 0.06), 0.6)
    save("heal", seq_tones(["G5", "C6", "E6", "G6", "C7"], 0.09), 0.6)
    save("buff", seq_tones(["C5", "G5", "C6"], 0.08, A.inst_organ), 0.5)
    save("arte", mix(bandnoise(0.35, 300, 6000) * env(sec(0.35), 0.05, 7) * (0.5 + 0.5 * sweep(300, 2400, 0.35)), sweep(200, 800, 0.35, "saw") * env(sec(0.35), 0.03, 6) * 0.3), 0.75)
    save("over_limit", mix(sweep(200, 1600, 0.8, "saw") * np.clip(t_axis(sec(0.8)) * 2, 0, 1) * 0.4, bandnoise(0.8, 1000, 8000) * np.clip(t_axis(sec(0.8)) * 1.5, 0, 1) * 0.4), 0.8)
    save("unison", mix(*[A.inst_brass(hz(midi(m)), 1.2, 1.0) for m in ("C4", "G4", "C5", "E5", "G5")], bandnoise(1.2, 300, 6000) * env(sec(1.2), 0.3, 2) * 0.3), 0.9)
    # --- field / events
    save("encounter", mix(sweep(300, 2400, 0.5, "saw") * env(sec(0.5), 0.005, 2) * 0.35, bandnoise(0.5, 1500, 9000) * np.clip(t_axis(sec(0.5)) * 2, 0, 1) * env(sec(0.5), 0, 1) * 0.5, np.pad(A.drum_crash(0, 1, 1.0), (sec(0.45), 0))), 0.85)
    save("ring", mix(lp_fast(noise(sec(0.4)), 2500) * env(sec(0.4), 0.005, 9), sweep(400, 900, 0.3) * env(sec(0.3), 0.003, 10) * 0.5), 0.6)
    save("stun", mix(A.square(1200, t_axis(sec(0.25))) * 0.2 * env(sec(0.25), 0.001, 12), bandnoise(0.25, 3000, 9000) * env(sec(0.25), 0.001, 14)), 0.5)
    save("item", seq_tones(["E6", "G6", "B6", "E7"], 0.07), 0.6)
    save("key_item", seq_tones(["C6", "E6", "G6", "C7", "G6", "C7"], 0.08), 0.65)
    save("chest", mix(A.drum_tom(140, 0.4, 0.8), np.pad(seq_tones(["G5", "D6", "G6"], 0.07), (sec(0.12), 0))), 0.7)
    save("coins", mix(*[np.pad(np.sin(2 * np.pi * f * t_axis(sec(0.15))) * env(sec(0.15), 0.001, 25), (sec(d), 0)) for f, d in ((2600, 0), (3100, 0.05), (2800, 0.1))]), 0.5)
    save("save", seq_tones(["A5", "E6", "A6", "C#7", "E7"], 0.1), 0.6)
    save("door", mix(lp_fast(noise(sec(0.35)), 900) * env(sec(0.35), 0.03, 7), A.drum_tom(90, 0.4, 0.6)), 0.6)
    save("level_up", seq_tones(["C5", "E5", "G5", "C6", "E6", "G6"], 0.07, A.inst_brass), 0.7)
    save("title_get", seq_tones(["G5", "B5", "D6", "G6"], 0.09, A.inst_brass), 0.65)
    save("skit", seq_tones(["E6", "C6"], 0.08, A.inst_piano), 0.5)
    save("cook", mix(lp_fast(noise(sec(0.8)), 3000) * (0.3 + 0.2 * np.sin(2 * np.pi * 9 * t_axis(sec(0.8)))) * env(sec(0.8), 0.05, 2), np.pad(seq_tones(["C6", "G6"], 0.08), (sec(0.6), 0))), 0.55)
    save("explosion", mix(lp_fast(noise(sec(1.4)), 500) * env(sec(1.4), 0.005, 2.5) * 1.5, bandnoise(0.3, 800, 6000) * env(sec(0.3), 0.001, 12)), 0.95)
    save("flash", mix(sweep(800, 3000, 0.6) * env(sec(0.6), 0.02, 4) * 0.3, seq_tones(["C7", "G6"], 0.1)), 0.55)

if __name__ == "__main__":
    build()
