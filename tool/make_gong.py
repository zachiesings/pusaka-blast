#!/usr/bin/env python3
"""Generate a deep gamelan gong SFX -> assets/audio/gong.wav (pure stdlib)."""
import os, wave, struct, math
SR = 22050
def gong(dur=2.4, f=98.0):
    n = int(SR*dur); out = []
    parts = ((1.0,1.0),(0.7,1.48),(0.5,2.13),(0.3,2.97),(0.18,4.16),(0.1,5.43))
    for i in range(n):
        t = i/SR
        env = math.exp(-1.6*t) * (1-math.exp(-120*t))
        shimmer = 1 + 0.02*math.sin(2*math.pi*3.2*t)
        s = 0
        for amp, mult in parts:
            s += amp*(math.sin(2*math.pi*f*mult*shimmer*t) + math.sin(2*math.pi*f*mult*1.004*t))
        out.append(env*s*0.4)
    m = max(abs(x) for x in out) or 1
    return [x/m*0.9 for x in out]
here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(here,'assets','audio','gong.wav')
buf = gong()
with wave.open(out,'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b''.join(struct.pack('<h', int(max(-1,min(1,x))*32000)) for x in buf))
print('wrote', out, f'({len(buf)/SR:.1f}s)')
