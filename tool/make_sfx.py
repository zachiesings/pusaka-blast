#!/usr/bin/env python3
"""Generate original gamelan-flavoured SFX into assets/audio/ (pure stdlib).

All tones are synthesized from scratch (additive sine partials + exponential
decay) on a slendro-ish pentatonic scale — no sampled/copyrighted audio.
Reused by both Pusaka apps.
"""
import os
import wave
import struct
import math

SR = 22050

# Slendro-ish pentatonic (approx, in Hz) — gives the "gamelan" colour.
SCALE = {
    'd1': 294.0, 'e1': 330.0, 'g1': 392.0, 'a1': 440.0, 'b1': 494.0,
    'd2': 588.0, 'e2': 660.0, 'g2': 784.0, 'a2': 880.0, 'b2': 988.0,
}


def tone(freq, dur, decay=18.0, partials=(1.0, 0.5, 0.28, 0.12)):
    """One struck-metal note: stacked partials with a fast exponential decay."""
    n = int(SR * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t)
        s = 0.0
        for k, amp in enumerate(partials, start=1):
            # slight inharmonicity for a metallic shimmer
            s += amp * math.sin(2 * math.pi * freq * k * (1 + 0.0008 * k) * t)
        out[i] = env * s
    return out


def mix_seq(notes, gap=0.0):
    """Play notes in sequence (note = (freq, dur, decay))."""
    buf = []
    for (f, d, dc) in notes:
        buf.extend(tone(f, d, dc))
        if gap:
            buf.extend([0.0] * int(SR * gap))
    return buf


def normalize(buf, peak=0.85):
    m = max((abs(x) for x in buf), default=1.0) or 1.0
    return [x / m * peak for x in buf]


def save(name, buf):
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(here, 'assets', 'audio', name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    buf = normalize(buf)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for x in buf:
            frames += struct.pack('<h', int(max(-1, min(1, x)) * 32000))
        w.writeframes(bytes(frames))
    print('wrote', path, f'({len(buf)/SR:.2f}s)')


S = SCALE
# place: one soft mid "tok"
save('place.wav', tone(S['g1'], 0.16, decay=26.0, partials=(1.0, 0.4, 0.15)))
# clear: bright 3-note ascending arpeggio
save('clear.wav', mix_seq([(S['g1'], 0.16, 16), (S['a1'], 0.16, 16), (S['d2'], 0.34, 11)]))
# combo: 4-note sparkle higher up
save('combo.wav', mix_seq([(S['d2'], 0.13, 16), (S['e2'], 0.13, 16),
                           (S['g2'], 0.13, 16), (S['b2'], 0.40, 10)]))
# game over: 3-note gentle descent
save('gameover.wav', mix_seq([(S['d2'], 0.22, 12), (S['b1'], 0.22, 12), (S['g1'], 0.5, 8)]))
# ui tap: tiny click
save('tap.wav', tone(S['a2'], 0.08, decay=40.0, partials=(1.0, 0.3)))
