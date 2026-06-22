#!/usr/bin/env python3
"""Premium 'Pendopo Emas' app icon — warm radial gradient + carved gold frame +
a kawung medallion. Pure stdlib (zlib+struct), no PIL."""
import os, zlib, struct, math

W = H = 1024
buf = bytearray(W * H * 4)

def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
def setpx(x, y, rgb, a=255):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4; sa = a / 255
        for k in range(3): buf[i+k] = int(buf[i+k]*(1-sa) + rgb[k]*sa)
        buf[i+3] = 255

BG_IN = (0x4A, 0x2E, 0x12)   # warm center
BG_OUT = (0x16, 0x0E, 0x06)  # dark edge
GOLD = (0xF2, 0xB7, 0x3C)
GOLD_LT = (0xFC, 0xD6, 0x75)
GOLD_DK = (0x8A, 0x5A, 0x1E)
CREAM = (0xF7, 0xEF, 0xE2)
cx = cy = W / 2

# radial gradient background
for y in range(H):
    for x in range(W):
        d = math.hypot(x - cx, y - cy) / (W * 0.62)
        d = min(1, d)
        rgb = lerp(BG_IN, BG_OUT, d ** 1.3)
        i = (y * W + x) * 4
        buf[i], buf[i+1], buf[i+2], buf[i+3] = rgb[0], rgb[1], rgb[2], 255

def ring(r, width, color, a=255):
    for y in range(int(cy - r - width), int(cy + r + width)):
        for x in range(int(cx - r - width), int(cx + r + width)):
            dd = math.hypot(x - cx, y - cy)
            if abs(dd - r) <= width:
                fade = 1 - abs(dd - r) / width
                setpx(x, y, color, int(a * fade))

# carved gold frame (double ring)
ring(430, 10, GOLD, 230)
ring(404, 4, GOLD_DK, 180)

def diamond(ccx, ccy, s, rgb, a):
    for y in range(int(ccy - s), int(ccy + s)):
        for x in range(int(ccx - s), int(ccx + s)):
            if abs(x - ccx) + abs(y - ccy) <= s:
                fade = 1 - (abs(x-ccx)+abs(y-ccy))/s * 0.0
                setpx(x, y, rgb, a)

def disc(ccx, ccy, r, rgb, a=255):
    for y in range(int(ccy - r), int(ccy + r)):
        for x in range(int(ccx - r), int(ccx + r)):
            if math.hypot(x - ccx, y - ccy) <= r:
                setpx(x, y, rgb, a)

# central kawung medallion: gold disc w/ depth + 4 petals + jewel
disc(cx, cy, 250, GOLD_DK, 255)
disc(cx, cy, 238, GOLD, 255)
disc(cx, cy, 238, GOLD_LT, 60)   # top sheen-ish flat
# 4 petals (kawung)
for k in range(4):
    ang = math.pi / 4 + k * math.pi / 2
    px = cx + math.cos(ang) * 120
    py = cy + math.sin(ang) * 120
    diamond(px, py, 95, BG_IN, 200)
    diamond(px, py, 70, GOLD, 255)
    diamond(px, py, 70, GOLD_LT, 70)
# center jewel
disc(cx, cy, 50, BG_IN, 230)
diamond(cx, cy, 34, GOLD_LT, 255)
disc(cx, cy, 12, CREAM, 220)

def write_png(path):
    raw = bytearray(); stride = W * 4
    for y in range(H):
        raw.append(0); raw.extend(buf[y*stride:(y+1)*stride])
    comp = zlib.compress(bytes(raw), 9)
    def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t+d) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) + chunk(b'IDAT', comp) + chunk(b'IEND', b''))

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(here, 'assets', 'icon', 'app_icon.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
write_png(out)
print('wrote', out)
