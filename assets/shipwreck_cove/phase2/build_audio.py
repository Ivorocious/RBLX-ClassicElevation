"""Original mono cue synthesis, no recordings or third-party samples."""
import math,random,struct,wave
from pathlib import Path
random.seed(2309)
root=Path(__file__).resolve().parent
rate=24000
def save(name,duration,fn):
    samples=[fn(i/rate)for i in range(round(duration*rate))]
    peak=max(abs(x)for x in samples)
    with wave.open(str(root/(name+'.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate)
        out.writeframes(b''.join(struct.pack('<h',round(x/peak*26000))for x in samples))
save('cannon_fuse',1.8,lambda t:random.uniform(-1,1)*(.15+.5*t/1.8)*(min(1,t/.05))*min(1,(1.8-t)/.06))
save('cannon_blast',1.7,lambda t:min(1,t/.006)*(random.uniform(-1,1)*math.exp(-t*8)+.7*math.sin(2*math.pi*(80*t-12*t*t))*math.exp(-t*4)))
save('tide_warning',2.5,lambda t:random.uniform(-1,1)*(.1+.7*(t/2.5)**2)*min(1,t/.08)*min(1,(2.5-t)/.1))
save('tide_surge',3,lambda t:random.uniform(-1,1)*math.sin(math.pi*t/3)**.7+.08*math.sin(2*math.pi*55*t)*math.sin(math.pi*t/3))
print('Created four original mono 24 kHz cues.')
