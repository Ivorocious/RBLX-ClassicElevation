"""Freeze the full Kit02/all139+coherent138 independent scene verification."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
SCENE=OWN/'final-kit02-cleaned139-pose138'
WITHIN=OWN/'final-kit02-cleaned139-pose138-within'
KIT=OWN.parent/'mesh-cleanup/proposal02'
NATIVE=ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-records.json'
native=json.loads(NATIVE.read_text(encoding='utf8'))['editable']['records']
manifest=json.loads((OWN/'FINAL_POSE138.json').read_text(encoding='utf8'))
neighbors=json.loads((SCENE/'inter-unit-visibility56.json').read_text(encoding='utf8'))
within=json.loads((WITHIN/'inter-unit-visibility56.json').read_text(encoding='utf8'))
meta=json.loads((SCENE/'current56-objects.json').read_text(encoding='utf8'))
binding=json.loads((OWN/'cleaned-kit02-base139/CLEANED_AXIS_BINDING.json').read_text(encoding='utf8'))


def prop(row,key):
    value=row['props'].get(key,row['props'].get(key.lower()))
    return value.get('value')if isinstance(value,dict)else value


def visible_close(data):
    return [r for r in data['pairs']if r['state']=='supported-route-visible'and any(w['witness']['gap']<.025 for w in r['visibleWitnesses'])]


def visible_exact(data):
    return [r for r in data['pairs']if r['state']=='supported-route-visible'and any(w['witness']['gap']<.0005 and np.dot(w['witness']['normalA'],w['witness']['normalB'])>.999 for w in r['visibleWitnesses'])]


ops={r['path']:r for r in manifest['operations']}
assert len(ops)==138
for path,row in ops.items():
    record=native[path]
    assert record['class']=='MeshPart'and prop(record,'Anchored')is True
    assert all(prop(record,k)is False for k in('CanCollide','CanQuery','CanTouch'))
    assert prop(record,'MeshId')==row['meshId']
    assert prop(record,'Size')==row['beforeSize']and prop(record,'CFrame')==row['beforeCFrame']
    assert record['attrs']['SourceAsset']==row['asset']and record['attrs']['SourceMaterial']==row['material']
    assert record['attrs']==row['expectedAttributes']
    assert all(prop(record,k)==v for k,v in row['flags'].items())
    assert all(prop(record,k)==v for k,v in row['expectedAppearance'].items())
    assert row['afterCFrame'][3:]==row['beforeCFrame'][3:]
assert not visible_exact(neighbors)and not visible_exact(within)
close_n=visible_close(neighbors);close_w=visible_close(within)
assert len(close_n)==3 and all('/SwingLanterns/'in row['paths'][0]for row in close_n)
assert not [row for row in close_w if row['a']!=row['b']]
for row in close_w:
    path=row['paths'][0]
    if path in ops:assert ops[path]['afterSize']==ops[path]['beforeSize']
residuals=[]
for row in close_n+close_w:
    residuals.append({'paths':row['paths'],'samePart':row['a']==row['b'],'differentAppearance':row['differentAppearance'],
      'minimumSupportedWitnessGap':min(w['witness']['gap']for w in row['visibleWitnesses']),
      'category':'Original queryable animated lantern distinct-plane relief,unchanged'if '/SwingLanterns/'in row['paths'][0]else 'Original same-material distinct-depth relief;nativeSize unchanged and oriented surface union preserved',
      'witnesses':row['visibleWitnesses']})
world=[r for r in meta['objects']if r['collection']!='Unchanged_Source49_Visible_Course']
assert len(world)==869
niche=[r for p,r in ops.items()if '/WestHighJambNiche/'in p]
assert len(niche)==3
assert all(r['afterSize']==r['beforeSize']and np.max(abs(np.array(r['afterCFrame'][:3])-r['beforeCFrame'][:3]-(.08,0,0)))<1e-8 for r in niche)
report={'pass':True,'candidate':'MC_FINAL_SURFACES_POSE138_KIT02_20261020',
 'poseManifest':str((OWN/'FINAL_POSE138.json').relative_to(ROOT)),'poseManifestSHA256':hashlib.sha256((OWN/'FINAL_POSE138.json').read_bytes()).hexdigest(),
 'poseTargets':138,'meshReplacementFamilies':7,'meshReplacementInstances':139,'inertNativeGuardsPass':True,
 'source56FullNativeBindingSHA256':'784deaac536a2aaa75bdd53800909c517fd22d83e39349ebb413dea9c3204dcd',
 'source56VisibleNativeBindingSHA256':'137111fc79d078309b1484ea735db2837ec4ca989bf8e12f5d9692c92bb33516',
 'cleanedOriginalTriangleBindings':{'instances':139,'maximumVertexAndTriangleError':max(r['maximumOriginalTriangleVertexError']for r in binding['checks']),
   'nativeLocalFromBlender':'(-Bx,+Bz,+By)','actualReplacementPolygonIdsUsed':True},
 'scene':{'visibleObjects':1586,'allVisibleTriangles':367069,'sceneryMeshes':len(world),'sceneryTriangles':sum(r['triangles']for r in world)},
 'freshInterUnit':{'candidatePartPairs':len(neighbors['pairs']),'trianglePairsTested':70986,'visibilityRays':neighbors['rays'],'states':neighbors['states'],
   'supportedExactPairs':0,'supportedClosePairs':len(close_n),'mutableSupportedClosePairs':0,'newMutableSupportedClosePairs':0},
 'freshSelfAndWithinUnit':{'candidatePartPairs':len(within['pairs']),'trianglePairsTested':981221,'visibilityRays':within['rays'],'states':within['states'],
   'supportedExactPairs':0,'supportedClosePairs':len(close_w),'differentPartSupportedClosePairs':0,
   'samePartNonzeroReliefFamilies':dict(Counter(row['paths'][0].split('/')[-1]for row in close_w))},
 'supportedEyes':677,'totalTrianglePairsTested':1052207,'totalVisibilityRays':neighbors['rays']+within['rays'],
 'completeNicheGroupRelativePosePreserved':True,'protectedContactQueryTouchColliderArrowEdits':0,'terrainFloorEdits':0,'veilEdits':0,
 'residuals':residuals,
 'limits':[
  'Offline source-bound geometry and finite first-surface rays; no temporal native render,all-camera,performance or owner-acceptance claim.',
  'Exact means visible witness gap<0.0005stud,normaldot>0.999,positive projected overlap>=0.01stud2. Broader planar scan acceptsgap<=0.06stud.',
  'At most40representative witnesses per partpair with16nearest eligible supported eyes per witness; a missing witness is not an exhaustive absence proof.',
  'Normal grouping quantizes at0.001; meaningfully angled intersections and normal-bin-edge cases are outside this planar scan.',
  'Three original queryable lantern reliefs0.0235900879 remain unchanged; no exactcoplanarity,querygeometry preserved,no observed flashing conclusion.',
  'Same-part distinct-depth surface relief remains explicitly listed; stable geometric ordering does not itself prove native temporal appearance.',
  'Kit02Blender-localnewpolygontriangles are used; imported native triangulation diagonal differences require separate oriented-surface proof. Root owns final native MeshId/pose/source parity and focused Play checks.'
 ]}
target=OWN/'FINAL_SCENE138_KIT02_CHECK.json';target.write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
files=[OWN/'FINAL_POSE138.json',target,OWN/'cleaned-kit02-base139/CLEANED_AXIS_BINDING.json',KIT/'cleanup-local-geometry.npz',KIT/'cleanup-proof.json',
 SCENE/'current56-triangles.npz',SCENE/'current56-objects.json',SCENE/'inter-unit-candidates56.json',SCENE/'inter-unit-visibility56.json',
 WITHIN/'inter-unit-candidates56.json',WITHIN/'inter-unit-visibility56.json']
files += [p for p in OWN.glob('*.py')]
freeze={'candidate':report['candidate'],'pass':True,'files':[{'path':str(p.relative_to(ROOT)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(files)]}
(OWN/'FINAL_NEIGHBOR_FREEZE138.json').write_text(json.dumps(freeze,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in report.items()if k not in('residuals','limits')},indent=2))
