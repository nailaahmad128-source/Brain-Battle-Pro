"""Regenerates sound effects + launcher icon. Run: python3 tool/make_assets.py"""
import math, os, struct, wave
from PIL import Image, ImageDraw

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets')

def tone(freq, dur, vol=0.5, shape='sine', slide=0.0, release=0.08):
    n = int(SR * dur); out = []
    for i in range(n):
        t = i / SR
        f = freq + slide * t / dur
        ph = 2 * math.pi * f * t
        if shape == 'saw':
            v = 2 * ((f * t) % 1) - 1
        else:
            v = math.sin(ph) + 0.3 * math.sin(2 * ph)
        env = min(1.0, t / 0.005) * min(1.0, (dur - t) / release)
        out.append(v * env * vol)
    return out

def save(name, samples):
    path = os.path.join(OUT, 'sfx', name + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))

def arp(freqs, d=0.09, vol=0.4):
    s = []
    for f in freqs: s += tone(f, d, vol)
    return s + tone(freqs[-1], 0.25, vol, release=0.2)

os.makedirs(os.path.join(OUT, 'sfx'), exist_ok=True)
os.makedirs(os.path.join(OUT, 'icon'), exist_ok=True)
save('tap', tone(880, 0.06, 0.35, release=0.05))
save('correct', tone(660, 0.08, 0.4) + tone(990, 0.16, 0.4))
save('wrong', tone(190, 0.28, 0.4, 'saw', slide=-70))
save('tick', tone(520, 0.05, 0.3, release=0.04))
save('go', tone(660, 0.07, 0.4) + tone(1320, 0.22, 0.4))
save('win', arp([523, 659, 784, 1047]))
save('levelup', arp([392, 523, 659, 784, 1047, 1319], 0.08))

# Icon: purple -> cyan gradient, white ring + lightning bolt
S = 1024
def bolt(d, cx, cy, sc, fill):
    pts = [(0.12,-0.50),(-0.30,0.08),(-0.02,0.08),(-0.14,0.52),(0.32,-0.12),(0.03,-0.12),(0.12,-0.50)]
    d.polygon([(cx + x * sc, cy + y * sc) for x, y in pts], fill=fill)

grad = Image.new('RGB', (2, 2))
grad.putpixel((0,0), (139, 92, 246)); grad.putpixel((1,0), (90, 120, 240))
grad.putpixel((0,1), (90, 120, 240)); grad.putpixel((1,1), (34, 211, 238))
bg = grad.resize((S, S), Image.BICUBIC)
mask = Image.new('L', (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=230, fill=255)
icon = Image.new('RGBA', (S, S), (0, 0, 0, 0)); icon.paste(bg, (0, 0), mask)
d = ImageDraw.Draw(icon)
d.ellipse([212, 212, S - 212, S - 212], outline=(255, 255, 255, 235), width=34)
bolt(d, S / 2, S / 2, 400, (255, 255, 255, 255))
icon.save(os.path.join(OUT, 'icon', 'icon.png'))

fg = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(fg)
d.ellipse([292, 292, S - 292, S - 292], outline=(34, 211, 238, 255), width=28)
bolt(d, S / 2, S / 2, 290, (255, 255, 255, 255))
fg.save(os.path.join(OUT, 'icon', 'icon_fg.png'))
print('assets generated')
