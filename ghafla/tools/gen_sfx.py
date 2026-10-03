#!/usr/bin/env python3
"""Génère les bruitages du jeu (PCM 16 bits mono, 22 050 Hz) dans assets/audio/*.sfx.

Aucune dépendance, aucun échantillon externe : tout est synthétisé (bruit filtré, sinusoïdes, enveloppes).
Choix de conception : uniquement des sons de la vie quotidienne (pas, papier, bois, vent, gouttes),
jamais de musique ni de mélodie. Le format .sfx est un fichier WAV ; l'extension évite l'import de l'éditeur.

Usage : python3 tools/gen_sfx.py
"""
import math
import os
import random
import struct

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


def n(seconds):
    return int(seconds * RATE)


def noise(count, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(count)]


def lowpass(x, cutoff):
    a = 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)
    y = []
    s = 0.0
    for v in x:
        s += a * (v - s)
        y.append(s)
    return y


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [v - l for v, l in zip(x, lp)]


def bandpass(x, lo, hi):
    return highpass(lowpass(x, hi), lo)


def env_exp(count, decay, attack=0.004):
    out = []
    at = max(1, int(attack * RATE))
    for i in range(count):
        t = i / RATE
        a = min(1.0, i / at)
        out.append(a * math.exp(-t * decay))
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def add(*tracks):
    size = max(len(t) for t in tracks)
    out = [0.0] * size
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def offset(x, seconds):
    return [0.0] * n(seconds) + x


def sine(count, freq, phase=0.0):
    return [math.sin(2.0 * math.pi * freq * i / RATE + phase) for i in range(count)]


def normalize(x, peak=0.85):
    m = max(abs(v) for v in x) or 1.0
    return [v * peak / m for v in x]


def fade_edges(x, ms=6):
    k = int(ms / 1000.0 * RATE)
    for i in range(min(k, len(x))):
        g = i / k
        x[i] *= g
        x[-1 - i] *= g
    return x


def loopable(x, overlap):
    """Rend un son bouclable : la fin est fondue avec le début."""
    k = n(overlap)
    head = x[:k]
    body = x[: len(x) - k]
    for i in range(k):
        g = i / k
        body[i] = body[i] * g + x[len(x) - k + i] * (1.0 - g)
    _ = head
    return body


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in samples)
    header = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVE"
    header += b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, RATE, RATE * 2, 2, 16)
    header += b"data" + struct.pack("<I", len(data))
    path = os.path.join(OUT, name + ".sfx")
    with open(path, "wb") as f:
        f.write(header + data)
    print("  %-8s %5.2f s  %6d octets" % (name, len(samples) / RATE, len(data) + 44))


def step(rng):
    c = n(0.16)
    thud = mul(sine(c, 78.0), env_exp(c, 34.0))
    scuff = mul(lowpass(noise(c, rng), 1400.0), env_exp(c, 40.0, 0.002))
    return normalize(add([v * 0.9 for v in thud], [v * 0.9 for v in scuff]), 0.7)


def page(rng):
    c = n(0.5)
    body = bandpass(noise(c, rng), 1800.0, 7000.0)
    # le papier « glisse » : une enveloppe en cloche, avec un peu de grain
    env = [math.sin(math.pi * (i / c)) ** 1.6 * (0.75 + 0.25 * math.sin(i * 0.09)) for i in range(c)]
    return fade_edges(normalize(mul(body, env), 0.6))


def unlock(rng):
    def tick(freq, decay):
        c = n(0.12)
        return mul(add(sine(c, freq), bandpass(noise(c, rng), 1500.0, 4500.0)), env_exp(c, decay, 0.001))

    return normalize(add(tick(1450.0, 60.0), offset(tick(980.0, 50.0), 0.11), offset([v * 0.5 for v in tick(620.0, 40.0)], 0.2)), 0.7)


def door(rng):
    c = n(0.9)
    creak = []
    ph = 0.0
    for i in range(c):
        t = i / RATE
        f = 190.0 + 60.0 * math.sin(t * 9.0) + 40.0 * t
        ph += 2.0 * math.pi * f / RATE
        creak.append(math.sin(ph) * math.sin(ph * 2.7))
    creak = bandpass(creak, 150.0, 900.0)
    envc = [math.sin(math.pi * (i / c)) ** 1.5 * 0.5 for i in range(c)]
    knock_c = n(0.2)
    knock = mul(lowpass(noise(knock_c, rng), 500.0), env_exp(knock_c, 22.0, 0.002))
    return fade_edges(normalize(add(mul(creak, envc), offset([v * 1.2 for v in knock], 0.7)), 0.7))


def wind(rng):
    c = n(1.8)
    x = lowpass(noise(c, rng), 700.0)
    y = lowpass(noise(c, rng), 2200.0)
    env = [math.sin(math.pi * (i / c)) ** 2 for i in range(c)]
    return fade_edges(normalize(mul(add(x, [v * 0.4 for v in y]), env), 0.6))


def heart(rng):
    def beat(delay, gain):
        c = n(0.22)
        t = mul(sine(c, 56.0), env_exp(c, 20.0, 0.006))
        return offset([v * gain for v in t], delay)

    return normalize(add(beat(0.0, 1.0), beat(0.24, 0.7)), 0.85)


def air(rng):
    c = n(8.0)
    base = lowpass(noise(c, rng), 420.0)
    hiss = lowpass(noise(c, rng), 1700.0)
    env = [0.6 + 0.4 * math.sin(2.0 * math.pi * i / c * 2.0 + 0.7) * math.sin(2.0 * math.pi * i / c) for i in range(c)]
    x = mul(add(base, [v * 0.25 for v in hiss]), env)
    return normalize(loopable(x, 1.0), 0.5)


def drip(rng):
    """Gouttes d'eau dans la grotte, en boucle : rares, graves et douces (un « ploc » feutré), sur un souffle presque inaudible.
    Volontairement discret : c'est un fond, pas un signal."""
    c = n(12.0)
    rumble = [v * 0.10 for v in lowpass(noise(c, rng), 120.0)]
    tracks = [rumble]
    t = 1.2
    while t < 10.5:
        f0 = rng.uniform(420.0, 640.0)
        dc = n(0.3)
        tone = []
        ph = 0.0
        for i in range(dc):
            f = f0 * (1.0 + 0.35 * (i / dc))
            ph += 2.0 * math.pi * f / RATE
            tone.append(math.sin(ph))
        drop = lowpass(mul(tone, env_exp(dc, 16.0, 0.004)), 1400.0)
        tracks.append(offset([v * rng.uniform(0.12, 0.24) for v in drop], t))
        t += rng.uniform(2.4, 4.6)
    x = add(*tracks)[:c]
    return normalize(loopable(x, 0.8), 0.32)

def step_wood(rng):
    """Pas sur un plancher : un toc sourd, une résonance de planche."""
    c = n(0.22)
    thud = mul(sine(c, 105.0), env_exp(c, 30.0))
    knock = mul(bandpass(noise(c, rng), 250.0, 900.0), env_exp(c, 38.0, 0.001))
    board = mul(sine(c, 330.0), env_exp(c, 55.0, 0.001))
    return normalize(add([v * 0.8 for v in thud], knock, [v * 0.18 for v in board]), 0.7)


def step_stone(rng):
    """Pas sur la pierre : un choc mat, sans claquement aigu."""
    c = n(0.24)
    click = mul(bandpass(noise(c, rng), 400.0, 1800.0), env_exp(c, 48.0, 0.002))
    body = mul(sine(c, 120.0), env_exp(c, 34.0))
    return normalize(add([v * 0.5 for v in click], [v * 0.7 for v in body]), 0.6)

def step_grass(rng):
    """Pas sur l'herbe ou le sable : un froissement doux, presque sans choc."""
    c = n(0.24)
    swish = mul(bandpass(noise(c, rng), 1200.0, 6000.0), [math.sin(math.pi * (i / c)) ** 1.4 for i in range(c)])
    soft = mul(lowpass(noise(c, rng), 300.0), env_exp(c, 30.0, 0.004))
    return fade_edges(normalize(add(swish, [v * 0.8 for v in soft]), 0.55))


def crickets(rng):
    """Grillons de nuit, en boucle : rafales de petites pulsations aiguës."""
    c = n(8.0)
    tracks = []
    for voice in range(4):
        f = rng.uniform(4100.0, 5200.0)
        t = rng.uniform(0.0, 1.5)
        while t < 7.4:
            burst = rng.randint(3, 6)
            for b in range(burst):
                pc = n(0.035)
                tone = mul(sine(pc, f), [math.sin(math.pi * i / pc) for i in range(pc)])
                tracks.append(offset([v * rng.uniform(0.18, 0.3) for v in tone], t + b * 0.06))
            t += rng.uniform(1.1, 2.6)
    x = add(*tracks)[:c]
    x = lowpass(x, 6500.0)
    return normalize(loopable(x, 0.5), 0.35)


def cloth(rng):
    """Étoffe qui claque doucement au vent (linge, fanions), en boucle."""
    c = n(6.0)
    base = bandpass(noise(c, rng), 400.0, 2600.0)
    env = []
    for i in range(c):
        t = i / RATE
        gust = 0.5 + 0.5 * math.sin(2.0 * math.pi * t / 6.0 * 2.0 + 0.9)
        flap = 0.55 + 0.45 * math.sin(2.0 * math.pi * (5.0 + 2.0 * gust) * t)
        env.append(gust * flap)
    return normalize(loopable(mul(base, env), 0.6), 0.5)


def hum(rng):
    """Bourdonnement très discret d'une flamme de lampe, en boucle (100 Hz et harmoniques, pile pour boucler)."""
    c = n(3.0)
    x = [0.0] * c
    for k, g in [(100.0, 1.0), (200.0, 0.5), (300.0, 0.22)]:
        ph = rng.uniform(0.0, 6.28)
        for i in range(c):
            x[i] += g * math.sin(2.0 * math.pi * k * i / RATE + ph)
    flicker = lowpass(noise(c, rng), 14.0)
    x = [v * (0.75 + 1.8 * f) for v, f in zip(x, flicker)]
    return normalize(loopable(x, 0.3), 0.4)


def shimmer(rng):
    """Frémissement d'une page de lumière, en boucle : un bruissement de papier doux et espacé, sans aigus ni mélodie."""
    c = n(5.0)
    tracks = []
    t = 0.2
    while t < 4.4:
        gc = n(rng.uniform(0.12, 0.26))
        grain = mul(bandpass(noise(gc, rng), 1600.0, 4800.0), [math.sin(math.pi * i / gc) ** 2 for i in range(gc)])
        tracks.append(offset([v * rng.uniform(0.3, 0.8) for v in grain], t))
        t += rng.uniform(0.35, 0.9)
    x = add(*tracks)[:c]
    return normalize(loopable(lowpass(x, 5000.0), 0.5), 0.32)

def main():
    rng = random.Random(1234)
    print("Écriture dans", os.path.normpath(OUT))
    for name, fn in [("step", step), ("page", page), ("unlock", unlock), ("door", door), ("wind", wind), ("heart", heart), ("air", air), ("drip", drip),
                     ("step_wood", step_wood), ("step_stone", step_stone), ("step_grass", step_grass),
                     ("crickets", crickets), ("cloth", cloth), ("hum", hum), ("shimmer", shimmer)]:
        write(name, fn(rng))


if __name__ == "__main__":
    main()
