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
    """(own text, bounds, text of all descendants) per node."""
    out = []
    for n in ET.parse(path).iter('node'):
        bounds = tuple(map(int, re.findall(r'\d+', n.get('bounds'))))
        texts = [d.get('text') or d.get('content-desc') for d in n.iter('node')]
        out.append((n.get('text') or n.get('content-desc') or '', bounds, ' + '.join(t for t in texts if t)))
    return out


def label(full, rect):
    """The node whose bounds best match the focus rectangle; a node without own text is a group."""
    dist, text, group = min((sum(abs(a - b) for a, b in zip(r, rect)), t, g) for t, r, g in full)
    if dist > 20:
        return f'?{rect}'
    return text or f'[{group}]'


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
    print('  reached native text by swipe:', any(x in s for s in steps for x in NATIVE))
