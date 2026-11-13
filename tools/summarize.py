"""Summarise matrix.sh output: node counts, whether native text is in each dump, TalkBack order.

usage: summarize.py <out dir> <variant/mode> ...
Each TalkBack focus rectangle is labelled with the smallest node from the full dump that contains
the rectangle's centre and has text or a content description.
"""
import re
import sys
import xml.etree.ElementTree as ET

NATIVE = ('Native text', 'Native single text', 'Web text')


def nodes(path):
    out = []
    for n in ET.parse(path).iter('node'):
        x0, y0, x1, y1 = map(int, re.findall(r'\d+', n.get('bounds')))
        out.append((n.get('text') or n.get('content-desc') or '', (x0, y0, x1, y1), n.get('class')))
    return out


def label(full, rect):
    cx, cy = (rect[0] + rect[2]) // 2, (rect[1] + rect[3]) // 2
    hits = [(abs((b[2] - b[0]) * (b[3] - b[1])), t) for t, b, _ in full
            if t and b[0] <= cx <= b[2] and b[1] <= cy <= b[3]]
    return min(hits)[1] if hits else f'?{rect}'


d = sys.argv[1]
for combo in sys.argv[2:]:
    n = combo.replace('/', '-')
    full, comp = nodes(f'{d}/{n}-full.xml'), nodes(f'{d}/{n}-comp.xml')
    has = lambda ns: any(t.startswith(NATIVE) for t, _, _ in ns)
    steps = []
    for line in open(f'{d}/{n}-tb.txt'):
        m = re.match(r'(\d+) \((\d+), (\d+), (\d+), (\d+)\)', line)
        steps.append(label(full, tuple(map(int, m.groups()[1:]))) if m else 'none')
    print(f'{combo}: full {len(full)} nodes, native text {has(full)} | '
          f'compressed {len(comp)} nodes, native text {has(comp)}')
    print('  next:', ' > '.join(steps[:8]))
    print('  prev:', ' > '.join(steps[8:]))
    print('  reached native text by swipe:', any(s.startswith(NATIVE) for s in steps))
