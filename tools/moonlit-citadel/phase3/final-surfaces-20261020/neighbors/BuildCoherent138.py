"""Carry the complete niche group together instead of separating its material layers."""
import hashlib
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-records.json').read_text(encoding='utf8'))['editable']['records']
result=json.loads((OWN/'FINAL_POSE136.json').read_text(encoding='utf8'))


def prop(row,key):
    v=row['props'].get(key,row['props'].get(key.lower()))
    return v.get('value')if isinstance(v,dict)else v


for path,record in native.items():
    if '/WestHighJambNiche/'not in path or record['class']!='MeshPart' or path.endswith('__StoneLight'):continue
    assert all(prop(record,k)is False for k in('CanCollide','CanQuery','CanTouch'))
    cf=prop(record,'CFrame');after=cf[:];after[:3]=(np.array(after[:3])+(.08,0,0)).tolist()
    result['operations'].append({'path':path,'meshId':prop(record,'MeshId'),'asset':record['attrs']['SourceAsset'],'material':record['attrs']['SourceMaterial'],
      'beforeSize':prop(record,'Size'),'beforeCFrame':cf,'afterSize':prop(record,'Size'),'afterCFrame':after,
      'flags':{k:prop(record,k)for k in('Anchored','CanCollide','CanQuery','CanTouch','DoubleSided')},
      'expectedAppearance':{k:prop(record,k)for k in('Color','Material','Transparency','Reflectance','CastShadow')},'expectedAttributes':record['attrs'],
      'reasons':['Carry the complete carved niche material group with the existing0.08outward light relief; preserve every original internal relative pose.']})
assert len(result['operations'])==138
result['operations'].sort(key=lambda row:row['path'])
result.update(candidate='MC_FINAL_SURFACES_POSE138_20261020',count=138,
 scope='Apply exactly once after retained-floor Source56;138inert MeshPartpose/sizeoperations including finalinternal03twelve and completeWestHighNichegroupoutwardrelief.',
 replacesPose136='FINAL_POSE136.json is superseded by this coherent complete-niche-group operation manifest.')
target=OWN/'FINAL_POSE138.json';target.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
stage=OWN/'final-kit02-cleaned139-pose138';stage.mkdir(exist_ok=True);(stage/'operations.json').write_bytes(target.read_bytes())
print(json.dumps({'count':138,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}))
