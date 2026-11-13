"""Print the bounding box of TalkBack's blue focus rectangle in a series of screenshots.

usage: focus.py <dir> <prefix> <count>   reads <dir>/<prefix>1.png .. <prefix><count>.png
Pure standard library PNG decoding, so it runs with `python3 -I`.
"""
import struct
import sys
import zlib


def load(p):
    d = open(p, 'rb').read(); pos = 8; idat = b''
    while pos < len(d):
        l, = struct.unpack('>I', d[pos:pos + 4]); t = d[pos + 4:pos + 8]; c = d[pos + 8:pos + 8 + l]; pos += 12 + l
        if t == b'IHDR': w, h, bd, ct = struct.unpack('>IIBB', c[:10])
        if t == b'IDAT': idat += c
    raw = zlib.decompress(idat); bpp = {2: 3, 6: 4}[ct]; st = w * bpp; rows = []; prev = bytearray(st); i = 0
    for y in range(h):
        f = raw[i]; line = bytearray(raw[i + 1:i + 1 + st]); i += 1 + st
        if f == 1:
            for x in range(bpp, st): line[x] = (line[x] + line[x - bpp]) & 255
        elif f == 2:
            for x in range(st): line[x] = (line[x] + prev[x]) & 255
        elif f == 3:
            for x in range(st): line[x] = (line[x] + (((line[x - bpp] if x >= bpp else 0) + prev[x]) >> 1)) & 255
        elif f == 4:
            for x in range(st):
                a = line[x - bpp] if x >= bpp else 0; b = prev[x]; c = prev[x - bpp] if x >= bpp else 0
                p = a + b - c; pa = abs(p - a); pb = abs(p - b); pc = abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line); prev = line
    return w, h, bpp, rows


d, pre, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
for k in range(1, n + 1):
    w, h, bpp, rows = load(f'{d}/{pre}{k}.png'); xs = []; ys = []
    for y in range(0, h, 2):
        r = rows[y]
        for x in range(0, w, 2):
            R, G, B = r[x * bpp], r[x * bpp + 1], r[x * bpp + 2]
            # TalkBack's default focus colour on the test device; adjust if the theme differs.
            if R < 60 and 70 < G < 120 and B > 200: xs.append(x); ys.append(y)
    print(k, (min(xs), min(ys), max(xs), max(ys)) if xs else None, len(xs))
