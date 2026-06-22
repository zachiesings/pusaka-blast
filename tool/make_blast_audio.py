#!/usr/bin/env python3
"""Original Pusaka Blast audio — NOT shared with any other app.

Generates, with pure stdlib only (no samples, no copyrighted material):
  bgm_home.wav  - slow regal "gendhing" for the home screen (slendro, suling lead)
  bgm_game.wav  - driving in-game gamelan groove (pelog-ish, kendang + bonang)
  move.wav      - soft wood "tuk" when a block is lifted/moved
  place.wav     - deeper wood "thock" on placement
  clear.wav     - ascending saron flourish on a line clear
  combo.wav     - brighter, longer bonang run on a combo

All tones are synthesized procedurally (additive + noise). Seamless loops use
integer-beat lengths with a wrap-around tail.
"""
import os, wave, struct, math, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def write(name, buf):
    # normalise
    peak = max(1e-6, max(abs(x) for x in buf))
    g = 0.92 / peak
    path = os.path.join(OUT, name)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x * g)) * 32767)) for x in buf))
    print('wrote', name, '%.1fs' % (len(buf) / SR))


def metal(buf, freq, start, dur, gain=0.5, decay=5.0,
          partials=(1.0, 2.01, 2.71, 3.93, 5.2), amps=(1, .5, .32, .18, .1)):
    """Struck-metal (gamelan) tone: inharmonic partials + soft attack + beating."""
    n0 = int(SR * start); n = int(SR * dur); T = len(buf)
    for i in range(n):
        idx = n0 + i
        if idx >= T: idx -= T
        t = i / SR
        env = math.exp(-decay * t) * (1 - math.exp(-260 * t))
        s = 0.0
        for p, a in zip(partials, amps):
            beat = 1 + 0.004 * math.sin(2 * math.pi * 1.3 * t)  # shimmer
            s += a * math.sin(2 * math.pi * freq * p * beat * t)
        buf[idx] += gain * env * s


def suling(buf, freq, start, dur, gain=0.4):
    """Breathy bamboo-flute lead: sine + vibrato + breath noise."""
    n0 = int(SR * start); n = int(SR * dur); T = len(buf)
    for i in range(n):
        idx = n0 + i
        if idx >= T: idx -= T
        t = i / SR
        env = min(1, t * 8) * min(1, (dur - t) * 5)
        vib = 1 + 0.012 * math.sin(2 * math.pi * 5.5 * t)
        s = math.sin(2 * math.pi * freq * vib * t) + 0.18 * math.sin(2 * math.pi * freq * 2 * vib * t)
        s += 0.06 * (random.random() * 2 - 1)
        buf[idx] += gain * env * s


def kendang(buf, start, low, gain=0.5):
    """Hand-drum hit: pitch-dropping body + click. low=True -> 'dung', else 'tak'."""
    n0 = int(SR * start); dur = 0.18 if low else 0.09; n = int(SR * dur); T = len(buf)
    f0 = 150 if low else 320
    for i in range(n):
        idx = n0 + i
        if idx >= T: idx -= T
        t = i / SR
        env = math.exp(-(18 if low else 34) * t)
        f = f0 * math.exp(-7 * t)
        s = math.sin(2 * math.pi * f * t) + (0.5 if not low else 0.2) * (random.random() * 2 - 1) * math.exp(-60 * t)
        buf[idx] += gain * env * s


def gong(buf, start, gain=0.6):
    metal(buf, 88, start, 3.2, gain=gain, decay=1.1,
          partials=(1, 1.48, 2.0, 2.67, 3.4), amps=(1, .6, .4, .25, .15))


# ---------------------------------------------------------------- HOME (regal)
def make_home():
    BPM = 80; BEAT = 60 / BPM; BEATS = 32
    buf = [0.0] * int(SR * BEAT * BEATS)
    sl = {1: 264, 2: 297, 3: 352, 5: 396, 6: 440, 8: 528, 9: 594}  # slendro-ish
    for b in range(0, BEATS, 8): gong(buf, b * BEAT, 0.6)
    for b in range(4, BEATS, 8): metal(buf, 132, b * BEAT, 2.0, 0.32, decay=2.0)  # kempul
    # saron balungan (slow nuclear melody)
    bal = [6, 5, 3, 5, 6, 8, 6, 5, 3, 2, 3, 5, 6, 5, 3, 1]
    for i, d in enumerate(bal):
        metal(buf, sl[d], i * 2 * BEAT, 1.8, 0.34, decay=3.2)
    # suling lead floating above, sparse
    lead = [(0, 9, 3), (6, 8, 2), (12, 9, 2), (16, 6, 4), (24, 8, 3), (28, 9, 4)]
    for st, note, ln in lead:
        suling(buf, sl[note], st * BEAT, ln * BEAT * 0.9, 0.3)
    write('bgm_home.wav', buf)


# ------------------------------------------------------------- GAME (driving)
def make_game():
    BPM = 116; BEAT = 60 / BPM; BEATS = 16
    buf = [0.0] * int(SR * BEAT * BEATS)
    pl = {1: 280, 2: 312, 3: 372, 4: 416, 5: 468, 8: 560, 9: 624}  # pelog-ish bright
    # gong cycle + kempul
    for b in range(0, BEATS, 8): gong(buf, b * BEAT, 0.5)
    for b in range(2, BEATS, 4): metal(buf, 140, b * BEAT, 1.2, 0.26, decay=2.6)
    # kendang groove (syncopated) per beat: pattern over 4 beats
    pat = [('d', 0), ('t', 1.5), ('d', 2), ('t', 2.5), ('t', 3.5)]
    for bar in range(BEATS // 4):
        for kind, off in pat:
            kendang(buf, (bar * 4 + off) * BEAT, kind == 'd', 0.5)
    # bonang ostinato (fast interlocking), original riff
    riff = [1, 3, 5, 3, 4, 3, 2, 1, 1, 3, 5, 8, 9, 8, 5, 4]
    for i, d in enumerate(riff):
        metal(buf, pl[d], i * BEAT, 0.7, 0.3, decay=5.5)
    # peking double-time accent on a few
    for i in [0, 4, 8, 12]:
        metal(buf, pl[riff[i]] * 2, i * BEAT, 0.4, 0.16, decay=7)
    write('bgm_game.wav', buf)


# ------------------------------------------------------------------- SFX
def make_sfx():
    # move: soft wood tuk (short, bright click + woody body)
    n = int(SR * 0.10); b = [0.0] * n
    for i in range(n):
        t = i / SR; env = math.exp(-40 * t)
        b[i] = env * (0.6 * math.sin(2 * math.pi * 720 * math.exp(-8 * t) * t) +
                      0.4 * (random.random() * 2 - 1) * math.exp(-120 * t))
    write('move.wav', b)
    # place: deeper wood thock
    n = int(SR * 0.16); b = [0.0] * n
    for i in range(n):
        t = i / SR; env = math.exp(-26 * t)
        b[i] = env * (0.7 * math.sin(2 * math.pi * 240 * math.exp(-6 * t) * t) +
                      0.3 * (random.random() * 2 - 1) * math.exp(-80 * t))
    write('place.wav', b)
    # clear: ascending saron flourish (4 quick notes up)
    sc = [372, 416, 468, 560]; b = [0.0] * int(SR * 0.5)
    for k, f in enumerate(sc):
        metal(b, f, k * 0.07, 0.4, 0.6, decay=6)
    write('clear.wav', b)
    # combo: brighter, longer bonang run (6 notes up + sparkle)
    sc = [280, 372, 468, 560, 624, 744]; b = [0.0] * int(SR * 0.7)
    for k, f in enumerate(sc):
        metal(b, f, k * 0.06, 0.5, 0.55, decay=6)
    metal(b, 880, 0.42, 0.3, 0.3, decay=8)
    write('combo.wav', b)


if __name__ == '__main__':
    make_home(); make_game(); make_sfx()
    print('done — original Pusaka Blast audio')
