#!/usr/bin/env python3
"""Render Pusaka Blast audio from a license-clear SoundFont (FluidR3_GM, shipped
in Debian main as `fluid-soundfont-gm`, DFSG-free / redistributable) using
fluidsynth + mido. Real recorded samples replace the old additive synth → punchy
SFX + an upbeat, humanized original BGM. Existing asset paths kept (drop-in):
  assets/audio/{tap,move,place,clear,combo,gong,gameover}.wav
  assets/audio/{bgm_home,bgm_game}.wav

All sounds are GM-rendered originals (no copyrighted material). The 'gong' uses
the closest GM voice (Tubular Bells) — FLAGGED in AUDIO-CREDITS.md.
"""
import os, re, sys, subprocess, random

import mido
from mido import Message, MidiFile, MidiTrack, MetaMessage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
AUD = os.path.join(ROOT, "assets", "audio")
SF2 = os.environ.get("SF2", "/usr/share/sounds/sf2/FluidR3_GM.sf2")
SR = 44100
TPB = 480
random.seed(20260624)


def sh(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def fsynth(mid, wav, gain=0.5, room=0.2, level=0.10):
    # Conservative gain + LIGHT reverb → headroom, no internal clipping.
    sh(["fluidsynth", "-ni", "-g", str(gain), "-F", wav, "-r", str(SR),
        "-o", "synth.reverb.active=1", "-o", f"synth.reverb.room-size={room}",
        "-o", "synth.reverb.width=0.5", "-o", f"synth.reverb.level={level}",
        SF2, mid])


def peak_db(path):
    r = subprocess.run(["ffmpeg", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
                       stderr=subprocess.PIPE, stdout=subprocess.DEVNULL, text=True).stderr
    m = re.search(r"max_volume:\s*(-?\d+(?:\.\d+)?) dB", r)
    return float(m.group(1)) if m else 0.0


def render(name, events, ch_progs, bpm, gain=0.9, room=0.5, level=0.4, norm=-14, loop=False):
    mf = MidiFile(ticks_per_beat=TPB)
    tr = MidiTrack(); mf.tracks.append(tr)
    tr.append(MetaMessage("set_tempo", tempo=mido.bpm2tempo(bpm), time=0))
    for ch, prog in ch_progs.items():
        tr.append(Message("program_change", channel=ch, program=prog, time=0))
    events = sorted(events, key=lambda e: (e[0], 0 if e[1] == "off" else 1))
    last = 0
    for tick, typ, ch, note, vel in events:
        dt = max(0, tick - last); last = tick
        msg = "note_on" if typ == "on" else "note_off"
        tr.append(Message(msg, channel=ch, note=note, velocity=vel, time=dt))
    mid = os.path.join(AUD, f"_{name}.mid")
    raw = os.path.join(AUD, f"_{name}.raw.wav")
    out = os.path.join(AUD, f"{name}.wav")
    mf.save(mid)
    # Force headroom + light, clean reverb regardless of caller values (old hot
    # gain + heavy reverb caused clipping / "sember").
    fsynth(mid, raw, gain=0.5, room=min(room, 0.35), level=min(level, 0.15))
    # Peak-normalise (pure gain, no loudness limiter) to a clean target, keeping
    # the callers' relative loudness intent (norm) but never clipping.
    target = min(-2.0, norm + 8.0)
    gain_db = target - peak_db(raw)
    pre = "" if loop else "silenceremove=start_periods=1:start_threshold=-50dB,"
    # Clean tail fade on SFX (length-independent: reverse, fade-in 50ms, reverse)
    # → crisp tails, no harsh cutoff. Loops keep their seam intact (no fade).
    post = "" if loop else ",areverse,afade=t=in:d=0.05,areverse"
    sh(["ffmpeg", "-y", "-i", raw, "-af", f"{pre}volume={gain_db:.2f}dB{post}",
        "-ac", "1", "-ar", str(SR), "-c:a", "pcm_s16le", out])
    os.remove(mid); os.remove(raw)


def n(ch, note, start, dur, vel, humanize=True):
    if humanize:
        vel = max(1, min(127, vel + random.randint(-8, 8)))
        start = max(0, start + random.randint(-10, 10))
    return [(start, "on", ch, note, vel), (start + dur, "off", ch, note, 0)]


def main():
    if not os.path.exists(SF2):
        print("SoundFont not found:", SF2); sys.exit(1)
    os.makedirs(AUD, exist_ok=True)
    b = TPB

    # ---- SFX ----
    # tap: soft marimba blip
    render("tap", n(0, 84, 0, b // 3, 70, False), {0: 12}, 120, room=0.3, norm=-16)
    # move: very soft high tick
    render("move", n(0, 88, 0, b // 4, 52, False), {0: 12}, 120, room=0.25, norm=-18)
    # place: woody thunk
    render("place", n(0, 60, 0, b // 2, 84, False), {0: 12}, 120, room=0.35, norm=-14)
    # clear: bright glockenspiel run up
    ev = []
    for i, p in enumerate([72, 76, 79, 84]):
        ev += n(0, p, i * (b // 6), b // 2, 96, False)
    render("clear", ev, {0: 9}, 150, room=0.5, level=0.45, norm=-12)
    # combo: higher, faster sparkle run
    ev = []
    for i, p in enumerate([79, 83, 86, 91, 95]):
        ev += n(0, p, i * (b // 8), b // 2, 100, False)
    render("combo", ev, {0: 9}, 160, room=0.55, level=0.5, norm=-11)
    # gong: deep Tubular Bell strike (closest GM voice — flagged)
    render("gong", n(0, 43, 0, b * 4, 118, False), {0: 14}, 80, room=0.85, level=0.6, norm=-10)
    # gameover: soft descending minor cadence (piano)
    ev = n(0, 64, 0, b, 80, False) + n(0, 60, b, b, 76, False) + n(0, 56, 2 * b, b * 2, 70, False)
    render("gameover", ev, {0: 0}, 96, room=0.6, norm=-15)

    # ---- BGM: upbeat humanized keraton groove (home) ----
    ev = []
    bars, beat = 4, b
    chords = [[48, 52, 55], [43, 47, 50], [45, 48, 52], [41, 45, 48]]  # C G Am F
    bass = [36, 31, 33, 29]
    pent = [60, 62, 64, 67, 69, 72]
    for bar in range(bars):
        base = bar * 4 * beat
        ch = chords[bar % 4]
        ev += n(0, bass[bar % 4], base, beat, 90)
        ev += n(0, bass[bar % 4], base + 2 * beat, beat, 82)
        for off in (1, 3):
            for note in ch:
                ev += n(1, note + 12, base + off * beat + beat // 2, beat // 2, 48)
        # vibraphone melody sparkle
        for k in range(4):
            ev += n(2, pent[(bar * 2 + k) % len(pent)] + 12, base + k * beat, beat, 60)
        for k in (0, 2):
            ev += n(9, 36, base + k * beat, beat // 2, 96)
        for s in (1, 3):
            ev += n(9, 38, base + s * beat, beat // 2, 84)
        for h in range(8):
            ev += n(9, 42, base + h * (beat // 2), beat // 4, 54)
    render("bgm_home", ev, {0: 33, 1: 4, 2: 11, 9: 0}, 104, room=0.6, level=0.45, norm=-17, loop=True)

    # ---- BGM: driving in-game loop ----
    ev = []
    for bar in range(4):
        base = bar * 4 * beat
        ch = chords[bar % 4]
        for k in range(4):
            ev += n(0, bass[bar % 4] - 12, base + k * beat, beat, 96)  # steady bass pulse
        for off in range(8):
            for note in ch:
                ev += n(1, note + 12, base + off * (beat // 2), beat // 3, 44)
        for k in (0, 2):
            ev += n(9, 36, base + k * beat, beat // 2, 104)
        for s in (1, 3):
            ev += n(9, 38, base + s * beat, beat // 2, 90)
        for h in range(8):
            ev += n(9, 42, base + h * (beat // 2), beat // 4, 60)
    render("bgm_game", ev, {0: 33, 1: 4, 9: 0}, 124, room=0.4, level=0.35, norm=-16, loop=True)

    print("Blast audio render complete.")


if __name__ == "__main__":
    main()
