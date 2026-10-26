"""Original synthesized hazard cues; no external recordings or music."""
import math
import random
import struct
import wave
from pathlib import Path

OUT=Path(__file__).resolve().parent
RATE=24000
random.seed(908)


def save(name,seconds,sample):
    values=[sample(i/RATE) for i in range(round(seconds*RATE))]
    peak=max(abs(v) for v in values) or 1
    with wave.open(str(OUT/(name+".wav")),"wb") as stream:
        stream.setnchannels(1);stream.setsampwidth(2);stream.setframerate(RATE)
        stream.writeframes(b"".join(struct.pack("<h",round(v/peak*24000)) for v in values))


def bell(t):
    s=t%.72
    attack=min(1,s/.006)
    return attack*sum(a*math.sin(math.tau*f*s)*math.exp(-s*d) for f,a,d in [(880,1,5),(1371,.35,8),(2157,.17,12)])


save("crossing_bell",2.88,bell)
save("traffic_engine",2,lambda t: .7*math.sin(math.tau*80*t)+.22*math.sin(math.tau*160*t)+.08*math.sin(math.tau*320*t))
save("swing_air",2,lambda t: random.uniform(-1,1)*math.sin(math.pi*t/2)**2*.25+.05*math.sin(math.tau*120*t)*math.sin(math.pi*t/2)**2)
print("Created three original mono 24 kHz hazard cues.")
