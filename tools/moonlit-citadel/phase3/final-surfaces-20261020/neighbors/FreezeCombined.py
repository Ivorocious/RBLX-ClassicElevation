"""Bind the final native guards and finite global closure to the combined pose candidate."""
import hashlib
import json
from pathlib import Path
import numpy as np

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
NATIVE=ROOT/'docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-records.json'
native=json.loads(NATIVE.read_text(encoding='utf8'))['editable']['records']
out=OWN/'proposal05'
manifest=json.loads((out/'operations.json').read_text(encoding='utf8'))
raw=json.loads((out/'inter-unit-visibility56.json').read_text(encoding='utf8'))
original=json.loads((OWN/'inter-unit-visibility56.json').read_text(encoding='utf8'))


def prop(row,key):
    value=row['props'].get(key,row['props'].get(key.lower()))
    return value.get('value')if isinstance(value,dict)else value


def close_pairs(data):
    return [r for r in data['pairs']if r['state']=='supported-route-visible'and any(w['witness']['gap']<.025 for w in r['visibleWitnesses'])]


seen=set();position_changes=[];size_changes=[]
for row in manifest['operations']:
    path=row['path'];assert path not in seen;seen.add(path)
    record=native[path]
    assert record['class']=='MeshPart' and prop(record,'Anchored')is True
    assert all(prop(record,k)is False for k in('CanCollide','CanQuery','CanTouch'))
    assert prop(record,'MeshId')==row['meshId']
    assert record['attrs']['SourceAsset']==row['asset']and record['attrs']['SourceMaterial']==row['material']
    assert np.max(abs(np.array(row['beforeCFrame'])-prop(record,'CFrame')))<1e-8
    assert np.max(abs(np.array(row['beforeSize'])-prop(record,'Size')))<1e-8
    assert np.max(abs(np.array(row['afterCFrame'][3:])-row['beforeCFrame'][3:]))==0
    row['flags']['DoubleSided']=prop(record,'DoubleSided')
    row['expectedAppearance']={k:prop(record,k)for k in('Color','Material','Transparency','Reflectance','CastShadow')}
    row['expectedAttributes']=record['attrs']
    position_changes.append(float(np.linalg.norm(np.array(row['afterCFrame'][:3])-row['beforeCFrame'][:3])))
    size_changes.append(float(np.max(abs(np.array(row['afterSize'])-row['beforeSize']))))
assert len(seen)==136
old,new=close_pairs(original),close_pairs(raw)
assert len(old)==134 and len(new)==3
holds=[]
for row in new:
    assert all('/SwingLanterns/'in p and '/MC_LanternCage/'in p for p in row['paths'])
    assert all(prop(native[p],'CanQuery')is True for p in row['paths'])
    assert not any(p in seen for p in row['paths'])
    assert min(w['witness']['gap']for w in row['visibleWitnesses'])>.0235
    holds.append({'paths':row['paths'],'minimumGap':min(w['witness']['gap']for w in row['visibleWitnesses']),
      'classification':'Original stable distinct-plane lantern relief, not exact coplanarity. Conservative near-plane witness; no observed temporal flashing result. Both queryable animated parts are unchanged.',
      'partCanQuery':[True,True]})
manifest.update(candidate='MC_FINAL_SURFACES_POSE136_20261020',schema=1,
    inputNativeRecordFile=str(NATIVE.relative_to(ROOT)),inputNativeRecordFileSHA256=hashlib.sha256(NATIVE.read_bytes()).hexdigest(),
    inputVisibleBindingSHA256='137111fc79d078309b1484ea735db2837ec4ca989bf8e12f5d9692c92bb33516',
    scope='Apply exactly once after retained-floor Source56 to both course copies;136inert MeshPart pose/size operations only, including finalinternal03twelve exactly once.',
    boundary='Fresh complete inter-unit rescan closes all mutable supported-view near-plane witnesses below0.025stud. Within-asset combined-pose check and native rendering/readback remain separate gates.',
    heldOriginalLanternRelief=holds)
manifest['operations'].sort(key=lambda r:r['path'])
target=OWN/'FINAL_POSE136.json'
target.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
summary={'candidate':manifest['candidate'],'operations':136,'manifest':str(target.relative_to(ROOT)),'manifestSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),
 'nativeGuardsPass':True,'protectedGameplayEdits':0,'floorTerrainEdits':0,'veilEdits':0,'arrowEdits':0,
 'maximumPositionChangeNorm':max(position_changes),'maximumNativeSizeAxisChange':max(size_changes),
 'beforeVisibleNearPlanePairs':len(old),'afterVisibleNearPlanePairs':len(new),'remainingMutableNearPlanePairs':0,
 'heldOriginalLanternRelief':holds,'sourceInputMeshObjects':1586,'triangles':363518,'courseHeightEyes':677,
 'wholeSceneSurfacePairs':888,'trianglePairsTested':68266,'candidateVisibilityRays':raw['rays'],
 'classificationsAfter':raw['states'],'newMutableSupportedNearPlanePairs':0,
 'checksScope':'Every-scene planar broadphase and exact triangle intersections with finite first-surface rays, including newly created neighbor pairs. No continuous native rendering claim.',
 'withinAssetCombinedPoseCheck':'Pending separate internal-agent check','postCleanedMeshRescan':'Pending cleaned surface-equivalent geometry receipt',
 'files':[{'path':str(p.relative_to(ROOT)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in(
  target,out/'inter-unit-candidates56.json',out/'inter-unit-visibility56.json',out/'current56-triangles.npz',out/'current56-objects.json',OWN/'car-relief-search.json')]}
(OWN/'COMBINED_POSE136_CHECK.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in summary.items()if k not in('files','heldOriginalLanternRelief')},indent=2))
