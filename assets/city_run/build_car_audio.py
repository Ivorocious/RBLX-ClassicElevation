"""Generate original, seam-safe City Run market-car audio cues.

Both files are mono 24 kHz WAV loops under seven seconds.  The layers are
periodic over the full loop so a runtime Sound can loop without a click or a
hard restart at the seam.  No external recording is used.
"""

import math
import random
import struct
import wave
from pathlib import Path


OUT = Path(__file__).resolve().parent
RATE = 24_000
DURATION = 6.8
TAU = math.tau


def periodic_noise(phase, seed, layers=10):
    rng = random.Random(seed)
    value = 0.0
    for layer in range(1, layers + 1):
        value += rng.uniform(-1.0, 1.0) * math.sin(TAU * (layer * phase + rng.random())) / math.sqrt(layer)
    return value / 3.6


def engine_sample(phase):
    # A rising-and-falling throttle cycle drives separate combustion, intake,
    # exhaust, and belt layers. Every carrier completes an integer number of
    # cycles across the loop, which keeps both value and phase seam-safe.
    throttle = 0.48 + 0.42 * (0.5 - 0.5 * math.cos(TAU * phase))
    revs = 1.0 + 0.24 * math.sin(TAU * phase) + 0.08 * math.sin(2 * TAU * phase)
    carrier = 286.0 * phase + 21.0 * math.sin(TAU * phase) + 5.0 * math.sin(2 * TAU * phase)
    combustion = sum(
        amplitude * math.sin(TAU * (carrier * harmonic) + offset)
        for harmonic, amplitude, offset in [(1, 0.50, 0.0), (2, 0.23, 0.31), (3, 0.13, 1.1), (5, 0.07, 2.0), (7, 0.04, 0.5)]
    )
    intake = (0.12 + 0.18 * throttle) * math.sin(TAU * (92.0 * phase + 3.0 * math.sin(TAU * phase)))
    belt = 0.08 * math.sin(TAU * (520.0 * phase + 9.0 * math.sin(2 * TAU * phase)))
    exhaust = (0.10 + 0.26 * throttle) * math.sin(TAU * (142.0 * phase + 4.0 * math.sin(TAU * phase) + 0.2))
    low = 0.21 * math.sin(TAU * (38.0 * phase + 2.0 * math.sin(TAU * phase)))
    texture = 0.055 * periodic_noise(phase, 1701, 18)
    return revs * (0.70 * combustion + intake + belt + exhaust + low) + texture


def tire_sample(phase):
    # Road rumble, tread pulses, sidewall resonance, and a light gravel layer.
    tread = math.sin(TAU * (96.0 * phase)) + 0.55 * math.sin(TAU * (192.0 * phase + 0.19))
    road = 0.36 * math.sin(TAU * (18.0 * phase + 0.8 * math.sin(TAU * phase)))
    sidewall = 0.18 * math.sin(TAU * (47.0 * phase + 4.0 * math.sin(2 * TAU * phase)))
    gravel = 0.16 * periodic_noise(phase, 441, 24)
    return 0.36 * tread + road + sidewall + gravel


def save_loop(name, sample_function, seed):
    frame_count = round(DURATION * RATE)
    values = [sample_function(index / frame_count) for index in range(frame_count)]
    # Fade only the tail into the first sample so the runtime loop has an exact
    # zero-value seam without muting the attack or the rev movement.
    fade = round(0.018 * RATE)
    for index in range(fade):
        blend = (index + 1) / fade
        values[-fade + index] = values[-fade + index] * (1.0 - blend) + values[0] * blend
    peak = max(abs(value) for value in values) or 1.0
    pcm = b"".join(struct.pack("<h", max(-32767, min(32767, round(value / peak * 30_000)))) for value in values)
    path = OUT / name
    with wave.open(str(path), "wb") as stream:
        stream.setparams((1, 2, RATE, len(values), "NONE", "not compressed"))
        stream.writeframes(pcm)
    with wave.open(str(path), "rb") as stream:
        assert stream.getnchannels() == 1
        assert stream.getsampwidth() == 2
        assert stream.getframerate() == RATE
        assert stream.getnframes() == frame_count
    samples = struct.unpack("<" + "h" * frame_count, pcm)
    seam_delta = abs(samples[0] - samples[-1])
    if seam_delta > 2_500:
        raise ValueError(f"{name} seam delta is too large: {seam_delta}")
    print({"file": str(path), "frames": frame_count, "seconds": DURATION, "seamDelta": seam_delta, "seed": seed})


save_loop("car_engine_rev.wav", engine_sample, 1701)
save_loop("car_tire_roll.wav", tire_sample, 441)
print("Created original mono 24 kHz seam-safe C17 market-car loops.")
