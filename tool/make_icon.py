#!/usr/bin/env python3
"""Generate assets/icon/app_icon.png — a batik-style Block-Blast mark.

Pure stdlib (zlib + struct), no PIL. Draws a 2x2 set of batik tiles (the game's
block colors) with a kawung diamond motif and a gamelan-gold frame.
"""
import os
import zlib
import struct
import math

W = H = 1024
buf = bytearray(W * H * 4)

BG = (0x1F, 0x18, 0x10)
GOLD = (0xE3, 0xB2, 0x3C)
CREAM = (0xF3, 0xE5, 0xC8)
TILE_COLORS = [
    (0x7A, 0x3B, 0x2E),  # terracotta
    (0x1F, 0x4E, 0x5F),  # indigo
    (0xB5, 0x83, 0x2E),  # sogan gold
    (0x6E, 0x3B, 0x5C),  # plum
]


def put(x, y, rgb, a=255):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4
        sa = a / 255.0
        for k in range(3):
            buf[i + k] = int(buf[i + k] * (1 - sa) + rgb[k] * sa)
        buf[i + 3] = 255


def fill(rgb):
    for y in range(H):
        for x in range(W):
            i = (y * W + x) * 4
            buf[i] = rgb[0]; buf[i + 1] = rgb[1]; buf[i + 2] = rgb[2]; buf[i + 3] = 255


def rounded_rect(x0, y0, x1, y1, r, rgb, a=255):
    for y in range(int(y0), int(y1)):
        for x in range(int(x0), int(x1)):
            dx = min(x - x0, x1 - 1 - x)
            dy = min(y - y0, y1 - 1 - y)
            if dx < r and dy < r:
                if (r - dx) ** 2 + (r - dy) ** 2 > r * r:
                    continue
            put(x, y, rgb, a)


def diamond(cx, cy, s, rgb, a):
    for y in range(int(cy - s), int(cy + s)):
        for x in range(int(cx - s), int(cx + s)):
            if abs(x - cx) + abs(y - cy) <= s:
                put(x, y, rgb, a)


def tile(x0, y0, size, color):
    pad = size * 0.06
    rounded_rect(x0 + pad, y0 + pad, x0 + size - pad, y0 + size - pad, size * 0.18, color)
    # top highlight
    rounded_rect(x0 + pad, y0 + pad, x0 + size - pad, y0 + size * 0.45,
                 size * 0.18, (255, 255, 255), a=32)
    # kawung diamond (outline approximated by two diamonds)
    cx, cy = x0 + size / 2, y0 + size / 2
    diamond(cx, cy, size * 0.27, CREAM, 70)
    diamond(cx, cy, size * 0.20, color, 255)
    diamond(cx, cy, size * 0.07, CREAM, 90)


fill(BG)
# outer gold frame
rounded_rect(70, 70, W - 70, H - 70, 150, GOLD, a=255)
rounded_rect(92, 92, W - 92, H - 92, 132, BG, a=255)

# 2x2 batik tiles
grid = 360
gx = (W - grid * 2) / 2
gy = (H - grid * 2) / 2
order = [TILE_COLORS[0], TILE_COLORS[1], TILE_COLORS[2], TILE_COLORS[3]]
idx = 0
for r in range(2):
    for c in range(2):
        tile(gx + c * grid, gy + r * grid, grid, order[idx])
        idx += 1


def write_png(path):
    raw = bytearray()
    stride = W * 4
    for y in range(H):
        raw.append(0)
        raw.extend(buf[y * stride:(y + 1) * stride])
    comp = zlib.compress(bytes(raw), 9)

    def chunk(typ, data):
        return (struct.pack('>I', len(data)) + typ + data +
                struct.pack('>I', zlib.crc32(typ + data) & 0xffffffff))

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', comp) + chunk(b'IEND', b''))


here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = os.path.join(here, 'assets', 'icon', 'app_icon.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
write_png(out)
print('wrote', out)
