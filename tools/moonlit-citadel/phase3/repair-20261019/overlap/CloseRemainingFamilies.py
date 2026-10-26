"""Check only the existing184 visible material cases against art03 and finite physical rules."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if (p/'default.project.json').exists())
ART=ROOT/'tools/moonlit-citadel/phase3/repair-20261019/art/proposal03/art-plan.json'
art=json.loads(ART.read_text(encoding='utf8'))
assert hashlib.sha256(ART.read_bytes()).hexdigest()=='3b21f8f113b5daa8ab7489cdd1d00f4fee1d0b66642d45c4b6cdfecc06420117'
revised={row['before']['name']:row for row in art['replacements']}
retired={row['before']['name']for row in art['retired']}
objects=json.loads((OWN/'surface-objects54-bound.json').read_text(encoding='utf8'))['objects']
native=json.loads((ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json').read_text(encoding='utf8'))['editable']['records']
findings=json.loads((OWN/'visible-overlap-findings.json').read_text(encoding='utf8'))
npz=np.load(OWN/'surface-triangles54.npz');triangles,owners=npz['triangles'],npz['owners']
ORIGIN=np.array((4000,300,2600))
operations={}


def prop(row,key):
 value=row['props'].get(key,row['props'].get(key.lower()))
 return value.get('value')if isinstance(value,dict)else value


def pose(row):
 path=row['nativePath'];record=native[path];cf=np.array(prop(record,'CFrame'));size=np.array(prop(record,'Size'))
 point=cf[:3]-ORIGIN;rotation=cf[3:].reshape(3,3)
 unit=row['props'].get('Source50Unit',row['props'].get('Detail54Unit'))
 if unit in retired:return None
 if unit in revised:
  edit=revised[unit];old,new=edit['before'],edit['after']
  if old['asset']!=new['asset']:return None
  acf,bcf=np.array(old['localCF']),np.array(new['localCF']);ar,br=acf[3:].reshape(3,3),bcf[3:].reshape(3,3)
  oldscale,newscale=np.array(old['scale']),np.array(new['scale'])
  point=bcf[:3]+br@((ar.T@(point-acf[:3]))/oldscale*newscale)
  rotation=br@ar.T@rotation;size=size/oldscale*newscale
 return point,rotation,size


for row in objects:
 current=pose(row)
 if current is None:continue
 point,rotation,size=current;after_size=size.copy();shift=np.zeros(3);rules=[]
 path=row['nativePath'];asset=native[path]['attrs'].get('SourceAsset');material=native[path]['attrs'].get('SourceMaterial')
 unit=row['props'].get('Source50Unit',row['props'].get('Detail54Unit'))
 if path.endswith('/MC_FloorStone__Floor'):after_size+=(-.08,0,-.08);rules.append('floor')
 if asset=='MC_WindowFrame'and material=='Stone':after_size+=(-.12,-.12,0);rules.append('window')
 if asset=='MC_ER_LanternBracket'and material=='Iron'and unit and 'WheelSupport'in unit:shift[2]+=.06;rules.append('wheel')
 if asset=='MC_AR_MasonryMass'and material=='Stone':after_size+=(-.08,0,-.08);rules.append('masonry')
 if unit=='UpperMachineWindowBay1'and material=='Stone':shift[0]+=.08;rules.append('upper-bay')
 if unit=='NorthWestRaisedCourt'and material=='StoneLight':shift[2]+=.06;rules.append('northwest-court')
 if unit=='CrownBaseUnifiedShell'and material=='StoneLight':shift[2]+=.08;rules.append('crown-joint')
 if unit=='CrownBaseUnifiedShell'and material=='StoneDark':
  axis=int(np.argmax(np.abs(rotation.T@np.array((1,0,0)))))
  assert abs(rotation[0,axis])>.99999
  after_size[axis]+=.12;rules.append('crown-side-trim')
 if asset=='MC_DT_ChimneyVent'and material=='StoneLight':shift[1]+=.06;rules.append('chimney-cap')
 if asset=='MC_AR_GalleryRoof46'and material=='SlateBand'and unit in ('JunctionEastSeatedRoof','JunctionWestSeatedRoof'):shift[0]+=.06;rules.append('roof-stripe')
 if asset=='MC_WeightIron'and material=='Iron':shift[0]+=.06;rules.append('weight-iron')
 if asset in ('MC_WeightIron','MC_CarIronBrass')and material=='Brass':shift[2]+=.06;rules.append('moving-brass')
 if asset=='MC_GuideIron'and material=='Brass'and '/GalleryExpertShortcut_LiftNeedle1_Red40/IronBrassPost'in path:
  shift[1]-=.06;rules.append('post-base')
 if rules:
  assert np.all(after_size>.001),(path,after_size)
  if np.any(after_size!=size):assert np.all(after_size>.1),(path,after_size)
  assert prop(native[path],'CanCollide')is False and prop(native[path],'CanTouch')is False,path
  operations[row['index']]={'nativePath':path,'unit':unit,'asset':asset,'material':material,'rules':rules,
                           'art03SizeBefore':size.tolist(),'nativeSizeAfter':after_size.tolist(),
                           'art03PositionBefore':point.tolist(),'courseLocalPositionDelta':shift.tolist(),
                           'art03PositionAfter':(point+shift).tolist(),'nativeRotation':rotation.flatten().tolist()}


def transformed(index,triangle):
 row=objects[index];current=pose(row)
 if current is None:return None
 point,rotation,size=current;old=native[row['nativePath']];cf=np.array(prop(old,'CFrame'));oldsize=np.array(prop(old,'Size'))
 local=(triangle+ORIGIN-cf[:3])@cf[3:].reshape(3,3)
 target=operations.get(index);newsize=np.array(target['nativeSizeAfter'])if target else size
 targetpoint=point+np.array(target['courseLocalPositionDelta'])if target else point
 return (local/oldsize*newsize)@rotation.T+targetpoint


checks=[]
for pair in findings['pairs']:
 if not pair['differentNativeAppearance']:continue
 gaps=[];state='separated';normals=[]
 for witness in pair['visibleWitnesses']:
  i,j=witness['faceWitness']['triangleIndices'];a=transformed(int(owners[i]),triangles[i]);b=transformed(int(owners[j]),triangles[j])
  if a is None or b is None:state='retired-or-replaced';break
  an=np.cross(a[1]-a[0],a[2]-a[0]);an/=np.linalg.norm(an)
  bn=np.cross(b[1]-b[0],b[2]-b[0]);bn/=np.linalg.norm(bn)
  normals.append(float(np.dot(an,bn)))
  distance=(b-a[0])@an
  gaps.append(0. if distance.min()<=0<=distance.max() else float(np.abs(distance).min()))
 if state!='retired-or-replaced':
  if min(normals)<1-1e-6:state='no-longer-parallel'
  elif min(gaps)<.025:state='needs-closure'
 checks.append({'paths':pair['paths'],'beforeMinimumGap':pair['minimumGap'],'afterMinimumWitnessGap':min(gaps)if gaps else None,'state':state})
report={'scope':'Finite184 previously measured visible material pairs after art03 plus explicit physical corrections; no global rescan or native appearance claim',
        'artPlan':str(ART.relative_to(ROOT)),'artPlanSHA256':hashlib.sha256(ART.read_bytes()).hexdigest(),
        'operations':list(operations.values()),'checks':checks,'states':dict(Counter(row['state']for row in checks)),
        'rules':dict(Counter(rule for row in operations.values()for rule in row['rules'])),'pass':all(row['state']!='needs-closure'for row in checks),
        'studioTouched':False,'productionChanged':False}
(OWN/'remaining-family-closure.proposed.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps({'pass':report['pass'],'rules':report['rules'],'states':report['states'],
                  'remaining':[row for row in checks if row['state']=='needs-closure']}))
