"""Original soundtrack for the remake (Sakuraba-inspired prog-rock / orchestral, all notes written here).
Usage: <python with numpy> tools/compose_music.py [track ...]  -> assets/audio/music/<track>.ogg"""
import sys, os, functools
sys.path.insert(0, os.path.dirname(__file__))
import audio_synth as A
from audio_synth import Song

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets/audio/music")
os.makedirs(OUT, exist_ok=True)

# memoize instruments (same note/duration/velocity reused a lot)
def memo(fn):
    cache = {}
    def w(f, d, v):
        k = (round(f, 3), round(d, 4), v)
        if k not in cache:
            cache[k] = fn(f, d, v)
        return cache[k]
    return w
for name in ["inst_lead", "inst_flute", "inst_brass", "inst_strings", "inst_pad", "inst_organ", "inst_piano", "inst_bell", "inst_pluck", "inst_bass", "inst_synbass", "inst_timpani"]:
    setattr(A, name, memo(getattr(A, name)))

ROCK = {"K": "X.....x.X.x.....", "S": "....X.......X...", "H": "x.x.x.x.x.x.x.x."}
ROCK2 = {"K": "X.x...x.X.x.x.x.", "S": "....X..x....X.x.", "H": "xxxxxxxxxxxxxxxx"}
MARCH = {"K": "X.......X.......", "S": "....x.x.....x.xx", "H": "x...x...x...x..."}
SOFT = {"Z": "x.x.x.x.x.x.x.x.", "K": "X.......x......."}

def title():
    s = Song(116, 32 * 4)
    A1 = "D5:1.5 E5:0.5 F#5:1 A5:1 G5:1.5 F#5:0.5 E5:2 F#5:1.5 G5:0.5 A5:1 B5:1 A5!:3 r:1 B5:1.5 A5:0.5 G5:1 F#5:1 E5:1.5 F#5:0.5 G5:1 A5:1 F#5:1 E5:1 D5:1 E5:1 E5:3 r:1"
    B1 = "B5:2 A5:1 G5:1 A5:2 E5:2 F#5:2 C#6:1 A5:1 B5!:4 G5:1 A5:1 B5:1 D6:1 C#6:2 A5:2 D6!:4 r:4"
    pa = ["D", "A", "Bm", "G", "Em", "A", "D", "A"]
    pb = ["G", "A", "F#m", "Bm", "Em", "A", "D", "D"]
    for rep in range(2):
        o = rep * 64
        s.notes(A.inst_brass if rep else A.inst_lead, A1, o, pan=0.0, gain=1.0)
        s.notes(A.inst_brass, B1, o + 32, gain=1.0)
        if rep:
            s.notes(A.inst_strings, A1, o, octave=-1, gain=0.6, pan=-0.3)
        s.chords(A.inst_strings, pa + pb, o, octave=4, gain=0.7, pan=0.3)
        s.chords(A.inst_brass, pa + pb, o, octave=3, style="stab", gain=0.45)
        s.bassline(A.inst_bass, pa + pb, o, rate=0.5, pattern=(0, 0, 12, 0))
        s.drums(MARCH if rep == 0 else ROCK, o, 16)
        s.drums({"C": "X..............."}, o, 1)
        s.place(A.inst_timpani(A.hz(A.midi("D2")), 1, 1.0), o)
    s.render(os.path.join(OUT, "title.ogg"), reverb=0.3)

def iselia():
    s = Song(92, 32 * 4)
    M1 = "B4:1 D5:1 G5:1.5 F#5:0.5 E5:1 D5:1 B4:2 C5:1 E5:1 G5:1 E5:1 D5:3 r:1 B4:1 D5:1 G5:1.5 A5:0.5 B5:1 A5:1 G5:1 E5:1 F#5:1.5 E5:0.5 D5:1 F#5:1 G5:3 r:1"
    M2 = "E5:1.5 F#5:0.5 G5:1 E5:1 D5:2 B4:2 C5:1 D5:1 E5:1 G5:1 B4:3 r:1 E5:1.5 F#5:0.5 G5:1 A5:1 B5:2 G5:2 A5:1 G5:1 E5:1 F#5:1 D5:3 r:1"
    p1 = ["G", "D", "Em", "C", "G", "Am", "D", "G"]
    p2 = ["C", "G", "Am", "Em", "C", "G", "Am7", "D"]
    for rep in range(2):
        o = rep * 64
        s.notes(A.inst_flute, M1, o, pan=0.1)
        s.notes(A.inst_flute, M2, o + 32, pan=0.1)
        if rep:
            s.notes(A.inst_pluck, M1, o, octave=-1, gain=0.5, pan=-0.4)
        s.chords(A.inst_pluck, p1 + p2, o, octave=3, style="arp", arp_rate=0.5, gain=0.55, pan=-0.2)
        s.chords(A.inst_pad, p1 + p2, o, octave=4, gain=0.45)
        s.bassline(A.inst_bass, p1 + p2, o, rate=2, pattern=(0, 7), gain=0.6)
        s.drums(SOFT, o, 16, gain=0.7)
    s.render(os.path.join(OUT, "iselia.ogg"), reverb=0.35)

def field():
    s = Song(112, 32 * 4)
    M1 = "A4:1 C5:1 E5:1.5 D5:0.5 C5:1 A4:1 F5:2 E5:1.5 D5:0.5 C5:1 E5:1 D5:3 r:1 A4:1 C5:1 E5:1 A5:1 G5:1.5 F5:0.5 E5:1 F5:1 D5:1 E5:1 F5:1 D5:1 E5!:3 r:1"
    M2 = "C6:1.5 B5:0.5 A5:1 C6:1 B5:2 G5:2 G5:1.5 A5:0.5 B5:1 E5:1 A5:3 r:1 F5:1 G5:1 A5:1 C6:1 B5:1.5 A5:0.5 G5:1 B5:1 C6:2 E5:2 G#5!:3 r:1"
    p1 = ["Am", "F", "C", "G", "Am", "F", "G", "E"]
    p2 = ["F", "G", "Em", "Am", "F", "G", "C", "E7"]
    for rep in range(2):
        o = rep * 64
        s.notes(A.inst_lead, M1, o)
        s.notes(A.inst_lead if rep == 0 else A.inst_brass, M2, o + 32)
        s.chords(A.inst_strings, p1 + p2, o, octave=4, gain=0.65, pan=0.25)
        s.chords(A.inst_pluck, p1 + p2, o, octave=3, style="arp", arp_rate=0.5, gain=0.4, pan=-0.3)
        s.bassline(A.inst_bass, p1 + p2, o, rate=0.5, pattern=(0, 0, 7, 0, 12, 0, 7, 5))
        s.drums(ROCK if rep else {"K": "X.......X.......", "H": "x.x.x.x.x.x.x.x.", "S": "....X.......X..."}, o, 16, gain=0.8)
    s.render(os.path.join(OUT, "field.ogg"), reverb=0.28)

def temple():
    s = Song(76, 16 * 4)
    M = "D5:2 F5:1 A5:1 G5:3 r:1 Bb5:2 A5:1 G5:1 E5:4 F5:2 E5:1 D5:1 C5:2 A4:2 D5:2 E5:1 F5:1 C#5:4"
    p = ["Dm", "Bb", "Gm", "A", "Dm", "F", "C", "A"]
    for rep in range(2):
        o = rep * 32
        s.notes(A.inst_bell, M, o, pan=0.2, gain=0.9)
        if rep:
            s.notes(A.inst_strings, M, o, octave=-1, gain=0.5, pan=-0.2)
        s.chords(A.inst_organ, p, o, octave=3, gain=0.5)
        s.chords(A.inst_pad, p, o, octave=4, gain=0.5, pan=0.3)
        for bar in range(0, 8, 2):
            s.place(A.inst_timpani(A.hz(A.midi("D2")), 1, 0.8), o + bar * 4)
    s.render(os.path.join(OUT, "temple.ogg"), reverb=0.55)

def battle():
    s = Song(168, 32 * 4)
    A1 = "E5:0.5 G5:0.5 B5:0.5 E6:0.5 D6:0.5 B5:0.5 A5:0.5 G5:0.5 E5:0.5 G5:0.5 C6:1 B5:0.5 A5:0.5 G5:1 F#5:0.5 A5:0.5 D6:1 C6:0.5 B5:0.5 A5:1 B5:1.5 D#6:0.5 F#6!:2"
    A2 = "E6:0.5 D6:0.5 B5:0.5 G5:0.5 A5:0.5 B5:0.5 G5:0.5 E5:0.5 C6:1 E6:1 D6:0.5 C6:0.5 B5:1 A5:0.5 B5:0.5 C6:0.5 D6:0.5 F#6:1 D6:1 B5!:3 r:1"
    B = "A5:1 C6:1 E6:1.5 D6:0.5 B5:1 G5:1 E5:2 E5:0.5 G5:0.5 C6:1 B5:0.5 C6:0.5 E6:1 D6:1.5 C6:0.5 B5:1 A5:1 G5:1 B5:1 E6:1.5 F#6:0.5 G6:1 E6:1 C6:2 D6:0.5 C6:0.5 B5:0.5 A5:0.5 B5:1 D6:1 D#6:2 F#6!:2"
    pa = ["Em", "C", "D", "B", "Em", "C", "D", "B"]
    pb = ["Am", "Em", "C", "D", "Em", "C", "D", "B7"]
    for rep in range(2):
        o = rep * 64
        lead = A.inst_lead if rep == 0 else A.inst_organ
        b = s.notes(lead, A1, o, gain=1.0)
        b = s.notes(lead, A2, b)
        s.notes(lead, B, b)
        if rep:
            s.notes(A.inst_lead, A1 + " " + A2, o, octave=-1, gain=0.45, pan=-0.35)
        s.chords(A.inst_lead, pa + pb, o, octave=2, style="power", gain=0.32, pan=0.35)
        s.chords(A.inst_strings, pa + pb, o, octave=4, gain=0.45, pan=-0.3)
        s.bassline(A.inst_synbass, pa + pb, o, rate=0.5, pattern=(0, 0, 12, 0, 0, 12, 7, 10))
        s.drums(ROCK2, o, 16, gain=0.95)
        s.drums({"C": "X..............."}, o, 1)
        s.drums({"C": "X..............."}, o + 32, 1)
    s.render(os.path.join(OUT, "battle.ogg"), reverb=0.18)

def boss():
    s = Song(152, 32 * 4)
    M = "C5:2 Eb5:1 G5:1 Ab5:2 G5:1 F5:1 G5:1.5 F5:0.5 Eb5:1 D5:1 B4:2 D5:2 C5:1 Eb5:1 G5:1 C6:1 Ab5:2 F5:2 Ab5:1 G5:1 F5:1 Eb5:1 D5:2 B4!:2"
    p = ["Cm", "Ab", "Bb", "G", "Cm", "Ab", "Fm", "G7"]
    for rep in range(4):
        o = rep * 32
        s.notes(A.inst_brass if rep % 2 == 0 else A.inst_lead, M, o, octave=0 if rep < 2 else 1, gain=1.0)
        # organ ostinato
        for bar, ch in enumerate(p):
            t = A.chord_tones(ch, 4)
            arp = [t[0], t[1], t[2], t[0] + 12] * 4
            for i, m in enumerate(arp):
                s.place(A.inst_organ(A.hz(m), 0.22 * s.spb, 0.6), o + bar * 4 + i * 0.25, pan=-0.3, gain=0.45)
        s.chords(A.inst_brass, p, o, octave=3, style="stab", gain=0.5, pan=0.3)
        s.bassline(A.inst_synbass, p, o, rate=0.5, pattern=(0, 0, 0, 12, 0, 0, 7, 0))
        s.drums({"K": "XxX.XxX.XxX.XxXx", "S": "....X.......X...", "H": "x.x.x.x.x.x.x.x.", "C": "X..............." if rep % 2 == 0 else "................"}, o, 8, gain=0.95)
    s.render(os.path.join(OUT, "boss.ogg"), reverb=0.2)

def victory():
    s = Song(136, 12)
    s.notes(A.inst_brass, "G4:0.5 C5:0.5 E5:0.5 G5!:1.5 E5:0.5 G5:0.5 C6!:4", 0, gain=1.0)
    s.notes(A.inst_lead, "G4:0.5 C5:0.5 E5:0.5 G5:1.5 E5:0.5 G5:0.5 C6:4", 0, octave=-1, gain=0.5)
    for b, ch in ((0, "C"), (2, "F"), (3, "G"), (4, "C")):
        for m in A.chord_tones(ch, 4):
            s.place(A.inst_strings(A.hz(m), (4 if b == 4 else 1) * s.spb, 0.8), b)
    s.place(A.drum_crash(0, 1, 1.0), 4)
    s.place(A.inst_timpani(A.hz(A.midi("C2")), 1, 1.0), 4)
    s.drums({"S": "x.xxx.x.X......."}, 0, 1, gain=0.6)
    s.render(os.path.join(OUT, "victory.ogg"), reverb=0.3, loop=False)

def sad():
    s = Song(66, 16 * 4)
    M = "E5:2 D5:1 C5:1 C5:2 A4:2 G4:1 C5:1 E5:1 G5:1 F5:2 E5:1 D5:1 E5:2 A5:2 F5:1.5 E5:0.5 D5:2 B4:1 C5:1 D5:1 E5:1 E5:4"
    p = ["Am", "F", "C", "G", "Am", "Dm", "E", "E"]
    for rep in range(2):
        o = rep * 32
        s.notes(A.inst_strings if rep else A.inst_piano, M, o, gain=1.0 if rep else 0.9)
        s.chords(A.inst_piano, p, o, octave=3, style="arp", arp_rate=1.0, gain=0.5, pan=-0.2)
        s.chords(A.inst_pad, p, o, octave=4, gain=0.4, pan=0.2)
        s.bassline(A.inst_bass, p, o, rate=4, pattern=(0,), gain=0.4)
    s.render(os.path.join(OUT, "sad.ogg"), reverb=0.5)

def tension():
    s = Song(132, 16 * 4)
    p = ["Fm", "Db", "Eb", "C", "Fm", "Db", "Bbm", "C"]
    for rep in range(2):
        o = rep * 32
        for bar, ch in enumerate(p):
            t = A.chord_tones(ch, 4)
            for i, m in enumerate([t[0], t[0], t[1], t[0], t[2], t[0], t[1], t[0]]):
                s.place(A.inst_strings(A.hz(m), 0.45 * s.spb, 0.8), o + bar * 4 + i * 0.5, pan=-0.2, gain=0.6)
        s.notes(A.inst_brass, "F4:4 Ab4:2 G4:2 Bb4:4 G4:4 C5:4 Db5:2 C5:2 Bb4:4 E4!:4", o, gain=0.7)
        s.bassline(A.inst_synbass, p, o, rate=1, pattern=(0, 0, 0, 12))
        s.drums({"T": "X..X..X...X..X..", "K": "X.......X.......", "S": "............X..."}, o, 8, gain=0.8)
    s.render(os.path.join(OUT, "tension.ogg"), reverb=0.3)

def world():
    s = Song(100, 32 * 4)
    M1 = "C5:1 F5:1 A5:1.5 G5:0.5 G5:1.5 E5:0.5 C5:2 D5:1 F5:1 A5:1 D6:1 Bb5!:3 r:1 Bb5:1.5 A5:0.5 G5:1 F5:1 E5:1 F5:1 G5:2 A5:1.5 G5:0.5 F5:1 A5:1 G5:3 r:1"
    M2 = "D6:2 C6:1 Bb5:1 C6:2 G5:2 A5:1 C6:1 E6:1 C6:1 D6!:3 r:1 Bb5:1 A5:1 G5:1 Bb5:1 A5:1 G5:1 E5:2 F5!:4 r:4"
    p1 = ["F", "C", "Dm", "Bb", "Gm", "C", "F", "C"]
    p2 = ["Bb", "C", "Am", "Dm", "Gm", "C", "F", "F"]
    for rep in range(2):
        o = rep * 64
        s.notes(A.inst_brass, M1, o)
        s.notes(A.inst_brass, M2, o + 32)
        s.notes(A.inst_strings, M1 + " " + M2, o, octave=-1 if rep == 0 else 1, gain=0.5, pan=-0.3)
        s.chords(A.inst_strings, p1 + p2, o, octave=4, gain=0.6, pan=0.3)
        s.bassline(A.inst_bass, p1 + p2, o, rate=1, pattern=(0, 7, 12, 7))
        s.drums(MARCH, o, 16, gain=0.75)
        for bar in range(16):
            s.place(A.inst_timpani(A.hz(A.chord_tones((p1 + p2)[bar], 2)[0]), 1, 0.7), o + bar * 4)
    s.render(os.path.join(OUT, "world.ogg"), reverb=0.35)

def desert():
    s = Song(100, 16 * 4)
    M = "D5:1 Eb5:0.5 F#5:0.5 G5:1 A5:1 Bb5:1.5 A5:0.5 G5:1 F#5:1 G5:1 F#5:1 Eb5:1 F#5:1 D5:3 r:1 A5:1 Bb5:1 C6:1 Bb5:1 A5:1.5 G5:0.5 F#5:2 G5:1 F#5:0.5 Eb5:0.5 D5:1 Eb5:1 D5!:4"
    p = ["D", "Eb", "D", "Cm", "Gm", "D", "Eb", "D"]
    for rep in range(2):
        o = rep * 32
        s.notes(A.inst_flute, M, o, pan=0.15)
        for bar, ch in enumerate(p):
            t = A.chord_tones(ch, 3)
            for i, m in enumerate([t[0], t[0] + 12, t[1], t[0] + 12, t[2], t[0] + 12, t[1], t[2]]):
                s.place(A.inst_pluck(A.hz(m), 0.5 * s.spb, 0.7), o + bar * 4 + i * 0.5, pan=-0.3, gain=0.5)
        s.chords(A.inst_pad, p, o, octave=4, gain=0.35)
        s.bassline(A.inst_bass, p, o, rate=1, pattern=(0, 0, 7, 0), gain=0.6)
        s.drums({"T": "X..x..X.X..x..x.", "Z": "x.x.x.x.x.x.x.x.", "K": "X.......X......."}, o, 8, gain=0.75)
    s.render(os.path.join(OUT, "desert.ogg"), reverb=0.3)

def gameover():
    s = Song(70, 20)
    s.notes(A.inst_piano, "E5:2 D5:2 C5:2 A4:2 F4:2 A4:1 D5:1 B4:4 A4:4", 0)
    s.chords(A.inst_strings, ["Am", "F", "Dm", "E", "Am"], 0, octave=3, gain=0.6)
    s.render(os.path.join(OUT, "gameover.ogg"), reverb=0.5, loop=False)

def ending():
    s = Song(84, 16 * 4)
    A1 = "D5:1.5 E5:0.5 F#5:1 A5:1 G5:1.5 F#5:0.5 E5:2 F#5:1.5 G5:0.5 A5:1 B5:1 A5:3 r:1 B5:1.5 A5:0.5 G5:1 F#5:1 E5:1.5 F#5:0.5 G5:1 A5:1 F#5:1 E5:1 D5:1 E5:1 D5:4"
    p = ["D", "A", "Bm", "G", "Em", "A", "D", "D"]
    for rep in range(2):
        o = rep * 32
        s.notes(A.inst_piano if rep == 0 else A.inst_flute, A1, o)
        s.chords(A.inst_piano, p, o, octave=3, style="arp", arp_rate=1.0, gain=0.45, pan=-0.2)
        s.chords(A.inst_strings, p, o, octave=4, gain=0.5, pan=0.2)
        s.bassline(A.inst_bass, p, o, rate=4, pattern=(0,), gain=0.4)
    s.render(os.path.join(OUT, "ending.ogg"), reverb=0.45)

TRACKS = {"title": title, "iselia": iselia, "field": field, "temple": temple, "battle": battle, "boss": boss, "victory": victory,
          "sad": sad, "tension": tension, "world": world, "desert": desert, "gameover": gameover, "ending": ending}

if __name__ == "__main__":
    names = sys.argv[1:] or list(TRACKS)
    for n in names:
        TRACKS[n]()
        print("MUSIC", n, os.path.getsize(os.path.join(OUT, n + ".ogg")) // 1024, "KB")
