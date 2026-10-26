"""Original C15 locomotive horn and rolling steel; no sampled recordings."""
import math
import random
import struct
import wave
from pathlib import Path
RATE = 24000
OUT = Path(__file__).resolve().parent
rng = random.Random(1509)
def save(name, seconds, sample):
    values = [sample(i/RATE) for i in range(round(seconds*RATE))]
    peak = max(map(abs, values))
    with wave.open(str(OUT/(name+'.wav')), 'wb') as stream:
        stream.setparams((1,2,RATE,0,'NONE','not compressed'))
        stream.writeframes(b''.join(struct.pack('<h',round(v/peak*29000)) for v in values))
def horn(t):
    envelope = 0
    for start, length in [(0.12,1.65),(2.6,2.75)]:
        a=t-start
        if 0<a<length:
            envelope=max(envelope,min(1,a/.14,(length-a)/.3))
    tones=sum(sum(math.sin(math.tau*f*h*t + .035*math.sin(math.tau*5*t))/h**1.35 for h in range(1,8)) for f in [196,246.94,293.66])
    return envelope*(tones+.1*rng.uniform(-1,1))
noise=0
def rumble(t):
    global noise
    noise=.94*noise+.06*rng.uniform(-1,1)
    beat=t%.48
    clack=math.exp(-beat*65)*math.sin(math.tau*640*t)+.6*math.exp(-((t+.105)%.48)*80)*math.sin(math.tau*430*t)
    seam=min(1,t/.03,(5.76-t)/.03)
    return seam*(.5*math.sin(math.tau*42*t)+.23*math.sin(math.tau*84*t)+noise*2+clack*.6)
save('train_horn',5.8,horn)
save('train_rumble',5.76,rumble)
print('Created two original C15 train WAV cues.')
