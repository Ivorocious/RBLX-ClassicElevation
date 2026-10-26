"""Build bounded native collision pieces from the authored solid primitives."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('folder',type=Path)
args=parser.parse_args()
pieces=json.loads((args.folder/'placement-pieces.json').read_text())
colliders=[];omitted=Counter()
for index,piece in enumerate(pieces):
    if piece['detail']!='solid' or piece['kind'] in ('surface studs','root skin'):
        continue
    if max(v[1] for v in piece['vertices'])<=2.4:
        omitted['below_fall_volume']+=1;continue
    primitive=piece.get('primitive')
    if not primitive:
        if piece['kind']=='produce' and len(piece['vertices'])==80:
            vertices=piece['vertices']
            center=[sum(v[k] for v in vertices)/len(vertices) for k in range(3)]
            rings=[vertices[start:start+16] for start in range(0,80,16)]
            for lower,upper in zip(rings,rings[1:]):
                radius=min(math.hypot(v[0]-center[0],v[2]-center[2]) for v in lower+upper)*math.cos(math.pi/16)-.15
                low,high=lower[0][1],upper[0][1]
                colliders.append(dict(group=piece['group'],sourcePiece=index,kind=piece['kind'],
                    shape='Cylinder',center=[center[0],(low+high)/2,center[2]],normal=[0,1,0],
                    size=[max(.05,high-low-.03),radius*2,radius*2]))
            continue
        omitted[piece['kind']+'_nonprimitive']+=1;continue
    common={'group':piece['group'],'sourcePiece':index,'kind':piece['kind']}
    if primitive['shape']=='Block':
        size=primitive['size']
        colliders.append(dict(common,shape='Block',center=primitive['center'],yaw=primitive['yaw'],
            size=[max(.05,size[0]-.76),max(.05,size[1]-.06),max(.05,size[2]-.76)]))
    else:
        r1,r2=primitive['radius'],primitive['topRadius']
        segments=max(1,math.ceil(abs(r1-r2)/.22))
        normal=primitive['normal'];depth=primitive['depth']
        for segment in range(segments):
            fraction=(segment+.5)/segments
            center=[primitive['center'][i]+normal[i]*depth*(fraction-.5) for i in range(3)]
            sides=len(piece['vertices'])//2
            minimum=min(r1+(r2-r1)*segment/segments,r1+(r2-r1)*(segment+1)/segments)
            radius=minimum*math.cos(math.pi/sides)-min(.38,minimum*.3)-.02
            colliders.append(dict(common,shape='Cylinder',center=center,normal=normal,
                size=[max(.05,depth/segments-.02),max(.05,radius*2),max(.05,radius*2)]))
result={'colliders':colliders,'count':len(colliders),'byKind':dict(Counter(p['kind'] for p in colliders)),
    'omitted':dict(omitted),'limits':[
        'Small invisible collision pieces follow individual visible solids; no broad color-batch boxes.',
        'Boxes sit inside the beveled footprint and within 0.03 studs of the un-beveled top.',
        'Tapered rods use short inscribed cylinders, with polygon and bevel inset; collision may underfill visibly rounded edges.',
        'Pumpkin bodies use four inscribed cylinders; sculpted lobes remain visual relief.',
        'Natural leaf meshes remain decorative; their upward faces passed the conservative no-inbound-reach screen.',
        'Low foliage remains below the original fall-volume top; runtime recovery is not verified.',
        'R305 playable geometry and root collision remain unchanged.']}
(args.folder/'collision.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:result[k] for k in ('count','byKind','omitted')}))
