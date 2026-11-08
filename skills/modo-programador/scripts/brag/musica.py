"""Banda sonora original del video: 120 BPM, La menor (Am-F-C-G), 21 s.
Uso: python musica.py <salida.wav>"""
import sys, wave
import numpy as np

SR, DUR, BPM = 44100, 21.0, 120
BEAT = 60 / BPM
N = int(SR * DUR)
t = np.arange(N) / SR
CORTES = [3.5, 6.0, 10.0, 14.0, 18.0]
CLIC = 12.0
rng = np.random.default_rng(7)

def hz(m): return 440 * 2 ** ((m - 69) / 12)
# acordes por compás (2 s): Am F C G
ACORDES = [[57, 60, 64], [53, 57, 60], [48, 55, 60], [55, 59, 62]]
RAIZ = [45, 41, 48, 43]

def lp(x, fc):  # paso bajo de un polo
    a = np.exp(-2 * np.pi * fc / SR); y = np.empty_like(x); s = 0.0
    for i, v in enumerate(x): s = (1 - a) * v + a * s; y[i] = s
    return y

def env(n, at, rel):
    e = np.ones(n); a = int(at * SR); r = int(rel * SR)
    if a: e[:a] = np.linspace(0, 1, a)
    if r: e[-r:] *= np.linspace(1, 0, r)
    return e

def poner(buf, x, t0, gan=1.0):
    i = int(round(t0 * SR)); j = min(N, i + len(x))
    if i < N: buf[i:j] += gan * x[:j - i]

pad, bajo, pluck, bombo, hat, sfx = (np.zeros(N) for _ in range(6))

for c in range(11):  # 11 compases de 2 s
    t0 = c * 2 * BEAT * 2; ac = ACORDES[c % 4]
    if t0 >= DUR: break
    # pad: sierras desafinadas, filtradas
    n = int(2.0 * SR); tt = np.arange(n) / SR; x = np.zeros(n)
    for m in ac + [ac[0] + 12]:
        for d in (-0.06, 0.06):
            f = hz(m) * 2 ** (d / 12); x += 2 * ((tt * f) % 1) - 1
    poner(pad, lp(x, 900) * env(n, 0.35, 0.4) / 8, t0)
    # bajo: corcheas sobre la raíz (desde la revelación, se apaga en el cierre)
    for k in range(8):
        tk = t0 + k * BEAT / 2
        if not (3.5 <= tk < 18.0): continue
        nn = int(0.22 * SR); tt = np.arange(nn) / SR; f = hz(RAIZ[c % 4])
        x = np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(4 * np.pi * f * tt)
        poner(bajo, x * np.exp(-tt * 9) * env(nn, 0.004, 0.03), tk, 0.9 if k % 2 == 0 else 0.6)
    # arpegio de pulsación en corcheas
    arp = ac + [ac[1] + 12, ac[2] + 12, ac[1] + 12, ac[0] + 12, ac[2]]
    for k in range(8):
        tk = t0 + k * BEAT / 2
        if tk >= 20.0: continue
        nn = int(0.5 * SR); tt = np.arange(nn) / SR; f = hz(arp[k] + 12)
        x = 2 * np.abs(2 * ((tt * f) % 1) - 1) - 1  # triángulo
        g = 0.55 if tk < 3.5 else 0.8
        poner(pluck, x * np.exp(-tt * 7) * env(nn, 0.003, 0.05), tk, g)

for b in range(int(DUR / BEAT)):
    tb = b * BEAT
    if 3.5 <= tb < 18.0:  # bombo suave en cada pulso
        nn = int(0.35 * SR); tt = np.arange(nn) / SR
        f = 48 + 60 * np.exp(-tt * 30)
        poner(bombo, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 9), tb)
    if 6.0 <= tb < 18.0:  # charles en contratiempo, al fondo
        nn = int(0.05 * SR); x = np.diff(rng.standard_normal(nn + 1))
        poner(hat, x * np.exp(-np.arange(nn) / SR * 70), tb + BEAT / 2, 0.5)

for tc in CORTES:  # barrido que termina en el corte + campanita afinada (La)
    nn = int(0.45 * SR); x = lp(rng.standard_normal(nn), 2500)
    poner(sfx, x * np.linspace(0, 1, nn) ** 2 * 0.5, tc - 0.45)
    nn = int(0.8 * SR); tt = np.arange(nn) / SR
    x = np.sin(2 * np.pi * hz(81) * tt) + 0.4 * np.sin(2 * np.pi * hz(88) * tt)
    poner(sfx, x * np.exp(-tt * 6) * 0.35, tc)
nn = int(0.12 * SR); tt = np.arange(nn) / SR  # clic del filtro Sub-14
poner(sfx, np.sin(2 * np.pi * hz(93) * tt) * np.exp(-tt * 45) * 0.3, CLIC)
# acorde final de La menor en el cierre
nn = int(3.0 * SR); tt = np.arange(nn) / SR; x = np.zeros(nn)
for m in [57, 60, 64, 69]: x += np.sin(2 * np.pi * hz(m) * tt) * np.exp(-tt * 1.2)
poner(sfx, x * 0.18 * env(nn, 0.01, 1.0), 18.0)

mezcla = pad * 0.55 + bajo * 0.35 + pluck * 0.22 + bombo * 0.6 + hat * 0.05 + sfx * 0.5
# reverb sencilla: ecos con realimentación, en estéreo
def eco(x, ms, fb):
    d = int(SR * ms / 1000); y = x.copy()
    for i in range(d, len(y)): y[i] += fb * y[i - d]
    return y
L = mezcla + 0.18 * lp(eco(mezcla, 113, 0.35), 3000)
R = mezcla + 0.18 * lp(eco(mezcla, 151, 0.35), 3000)
est = np.stack([L, R], 1)
est *= env(N, 0.02, 0.6)[:, None]  # cola final suave
est = np.tanh(est / np.abs(est).max() * 1.1) * 0.89
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((est * 32767).astype('<i2').tobytes())
print('ok', DUR, 's')
