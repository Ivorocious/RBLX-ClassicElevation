"""Reconstruct retained-floor Source56 and scan inter-unit coplanar triangles."""
from collections import Counter, defaultdict
import hashlib
import itertools
import json
from pathlib import Path
import time

import numpy as np

OWN = Path(__file__).resolve().parent
ROOT = next(p for p in OWN.parents if (p / 'default.project.json').exists())
BASE = ROOT / 'tools/moonlit-citadel/phase3/repair-20261019'
NATIVE_PATH = ROOT / 'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json'
FINAL_PATH = ROOT / 'docs/artifacts/moonlit-citadel/phase3/repair-20261019/final/native-snapshot55.json'
META_PATH = BASE / 'overlap/surface-objects54-bound.json'
ARRAY_PATH = BASE / 'overlap/surface-triangles54.npz'
ART_PATH = BASE / 'art/proposal03/art-plan.json'
OPS_PATH = BASE / 'overlap/expected-native-patch-manifest.json'
PLAN_PATH = ROOT / 'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/combined-plan54.json'
GAP = .06
ORIGIN = np.array((4000, 300, 2600))


def read(path): return json.loads(path.read_text(encoding='utf8'))
def prop(row, key):
    value = row['props'].get(key, row['props'].get(key.lower()))
    return value.get('value') if isinstance(value, dict) else value
def pose(data):
    cf = np.array(data['localCF'], dtype=float)
    return cf[:3], cf[3:].reshape(3, 3), np.array(data['scale'], dtype=float)
def unit(row):
    return row['props'].get('Source50Unit', row['props'].get('Detail54Unit', row['nativePath']))
def unit_transform(points, before, after):
    p, r, s = pose(before); q, t, u = pose(after)
    return ((points - p) @ r / s * u) @ t.T + q


def reconstruct():
    meta, art, native = read(META_PATH), read(ART_PATH), read(NATIVE_PATH)['editable']['records']
    final = read(FINAL_PATH)['editable']['records']
    old_plan = {row['name']: row for row in read(PLAN_PATH)['units']}
    edits = {row['before']['name']: row for row in art['replacements']}
    retired = {row['before']['name'] for row in art['retired']}
    ops = {row['path']: row for row in read(OPS_PATH)['operations']}
    arrays = np.load(ARRAY_PATH)
    old_tri, old_owners, old_faces = arrays['triangles'], arrays['owners'], arrays['faces']
    objects, triangles, owners, faces = [], [], [], []
    replaced_assets = {name for name, edit in edits.items() if edit['before']['asset'] != edit['after']['asset']}

    def add(row, points, fs):
        row = dict(row)
        row['index'] = len(objects)
        row['unit'] = unit(row)
        row['bounds'] = [points.min(axis=(0, 1)).tolist(), points.max(axis=(0, 1)).tolist()]
        record = final.get(row['nativePath'], native.get(row['nativePath']))
        if record:
            row['appearance'] = [prop(record, 'Color'), prop(record, 'Material')]
            row['doubleSided'] = prop(record, 'DoubleSided') is True
        row['triangles'] = len(points)
        objects.append(row); triangles.append(points); owners.append(np.full(len(points), row['index'], np.int32)); faces.append(fs)

    errors = []
    for row in meta['objects']:
        name = unit(row)
        if name in retired or name in replaced_assets: continue
        sel = old_owners == row['index']
        points = old_tri[sel].copy()
        if name in edits: points = unit_transform(points, edits[name]['before'], edits[name]['after'])
        op = ops.get(row['nativePath'])
        if op:
            cf = np.array(op['afterCFrame']); rotation = cf[3:].reshape(3, 3)
            points = ((points - op['beforeCoursePosition']) @ rotation / op['beforeSize'] * op['afterSize']) @ rotation.T + cf[:3] - ORIGIN
        record = final.get(row['nativePath'])
        if record and name != 'MC_EC_InnerRavine':
            cf = np.array(prop(record, 'CFrame')); size = np.array(prop(record, 'Size'))
            local = (points.reshape(-1, 3) + ORIGIN - cf[:3]) @ cf[3:].reshape(3, 3)
            lo, hi = local.min(axis=0), local.max(axis=0)
            error = max(np.abs((lo+hi)/2).max(), np.abs(hi-lo-size).max())
            if error > .005: errors.append({'path': row['nativePath'], 'error': float(error)})
        add(row, points, old_faces[sel])
    templates = [r for r in meta['objects'] if unit(r) == 'GalleryHeraldry1']
    for name in sorted(replaced_assets):
        edit = edits[name]
        for row in templates:
            sel = old_owners == row['index']
            points = unit_transform(old_tri[sel], old_plan['GalleryHeraldry1'], edit['after'])
            copy = dict(row)
            copy['name'] = name + '__' + row['name'].split('__')[-1]
            copy['nativePath'] = 'Decoration/Phase3World/' + edit['after']['district'] + '/' + name + '/' + edit['after']['asset'] + '__' + row['name'].split('__')[-1]
            copy['props'] = dict(row['props'], Detail54Unit=name)
            add(copy, points, old_faces[sel])
    assert not errors, errors
    tri, owner, fs = np.concatenate(triangles), np.concatenate(owners), np.concatenate(faces)
    assert len(objects) == 1586, len(objects)
    assert sum(r['triangles'] for r in objects if r['collection'] != 'Unchanged_Source49_Visible_Course') == 271658
    np.savez_compressed(OWN/'current56-triangles.npz', triangles=tri, owners=owner, faces=fs)
    (OWN/'current56-objects.json').write_text(json.dumps({'objects': objects, 'geometry': 'Original54 actual triangle geometry, exact Art03 unit transforms and DT01 template substitutions,200 final native material operations; ER01 floor retained;12 invisible mist anchors excluded.', 'objectsCount': len(objects), 'triangles': len(tri), 'source55BoundErrors': errors}, indent=2)+'\n', encoding='utf8')
    return objects, tri, owner, fs


def cross(a, b): return a[0]*b[1] - a[1]*b[0]
def clip(a, b):
    output = list(a)
    if cross(b[1]-b[0], b[2]-b[0]) < 0: b = b[::-1]
    for k in range(3):
        start, end = b[k], b[(k+1)%3]
        source, output = output, []
        if not source: break
        prev = source[-1]; pd = cross(end-start, prev-start)
        for point in source:
            d = cross(end-start, point-start)
            if (d >= -1e-9) != (pd >= -1e-9): output.append(prev+(point-prev)*(pd/(pd-d)))
            if d >= -1e-9: output.append(point)
            prev, pd = point, d
    if len(output) < 3: return 0, None
    polygon = np.array(output)
    area = abs(sum(cross(polygon[i]-polygon[0], polygon[i+1]-polygon[0]) for i in range(1, len(polygon)-1))) * .5
    return area, polygon.mean(axis=0)


def scan(objects, triangles, owners, faces, scope='neighbors'):
    normals = np.cross(triangles[:,1]-triangles[:,0], triangles[:,2]-triangles[:,0])
    lengths = np.linalg.norm(normals, axis=1); valid = lengths > 1e-7
    normals[valid] /= lengths[valid, None]
    original_normals = normals.copy()
    dominant = np.argmax(np.abs(normals), axis=1)
    sign = np.sign(normals[np.arange(len(normals)), dominant]); sign[sign==0]=1
    normals *= sign[:,None]
    distances = np.einsum('ij,ij->i', normals, triangles[:,0])
    groups = {}
    for index in np.flatnonzero(valid):
        normal = tuple(np.rint(normals[index]*1000).astype(int))
        distance = int(round(distances[index]/.08))
        groups.setdefault((int(owners[index]), normal, distance), []).append(int(index))
    surfaces, buckets = [], defaultdict(list)
    for (owner, normal, distance), indices in groups.items():
        idx=np.array(indices,np.int32); n=normals[idx].mean(axis=0); n/=np.linalg.norm(n)
        drop=int(np.argmax(np.abs(n))); axes=[a for a in range(3) if a!=drop]; points=triangles[idx][:,:,axes]
        surfaces.append({'owner':owner,'normal':n,'distance':float(distances[idx].mean()),'indices':idx,'axes':axes,
                         'low':points.min(axis=(0,1)),'high':points.max(axis=(0,1)),'points':points})
        buckets[(normal,distance)].append(len(surfaces)-1)
    candidates=set()
    for (normal, distance), indices in buckets.items():
        other=indices+buckets.get((normal,distance+1),[])
        for first in indices:
            for second in other:
                if first==second and scope=='neighbors': continue
                a,b=surfaces[first],surfaces[second]
                same_unit=objects[a['owner']]['unit']==objects[b['owner']]['unit']
                if scope=='neighbors'and same_unit:continue
                if scope=='within-and-self'and not same_unit:continue
                if abs(a['distance']-b['distance'])>GAP+.001 or np.dot(a['normal'],b['normal'])<1-1e-6:continue
                if a['axes']!=b['axes'] or np.any(np.minimum(a['high'],b['high'])-np.maximum(a['low'],b['low'])<=1e-6):continue
                candidates.add(tuple(sorted((first,second))))
    print(json.dumps({'phase':'broadphase','triangles':len(triangles),'surfaces':len(surfaces),'pairs':len(candidates)}),flush=True)
    hits={}; tested=0
    for counter,(si,sj) in enumerate(sorted(candidates)):
        a,b=surfaces[si],surfaces[sj]; ap,bp=a['points'],b['points'];blo,bhi=bp.min(axis=1),bp.max(axis=1)
        for ai,at in enumerate(ap):
            alo,ahi=at.min(axis=0),at.max(axis=0)
            bs=np.flatnonzero(np.all(np.minimum(ahi,bhi)-np.maximum(alo,blo)>1e-6,axis=1))
            for bi in bs:
                i,j=int(a['indices'][ai]),int(b['indices'][bi]);tested+=1
                if si==sj and i>=j:continue
                if owners[i]==owners[j]and faces[i]==faces[j]:continue
                distances_to_plane=(triangles[j]-triangles[i,0])@normals[i]
                gap=float(np.abs(distances_to_plane).max())
                if gap>GAP:continue
                area,centre=clip(at,bp[bi]);area/=abs(a['normal'][3-sum(a['axes'])])
                if area<.01:continue
                k=tuple(sorted((int(owners[i]),int(owners[j]))))
                item=hits.setdefault(k,{'a':k[0],'b':k[1],'area':0.,'maximumGap':0.,'minimumGap':float('inf'),'trianglePairs':0,'witnesses':[]})
                item['area']+=area;item['maximumGap']=max(item['maximumGap'],gap);item['minimumGap']=min(item['minimumGap'],gap);item['trianglePairs']+=1
                point=np.zeros(3);axes=a['axes'];drop=3-sum(axes);point[axes]=centre
                point[drop]=(np.dot(normals[i],triangles[i,0])-sum(normals[i,axis]*point[axis] for axis in axes))/normals[i,drop]
                item['witnesses'].append({'area':float(area),'gap':gap,'point':point.tolist(),'normalA':original_normals[i].tolist(),'normalB':original_normals[j].tolist(),'faces':[int(faces[i]),int(faces[j])],'triangleIndices':[i,j]})
        if counter and counter%25000==0:print(json.dumps({'phase':'scan','done':counter,'hits':len(hits),'tested':tested}),flush=True)
    old={tuple(sorted(row['paths'])) for row in read(BASE/'overlap/visible-overlap-findings.json')['pairs'] if row['differentNativeAppearance']}
    for item in hits.values():
        chosen=[]; bins=Counter()
        for witness in sorted(item['witnesses'],key=lambda r:(np.dot(r['normalA'],r['normalB'])>.999,r['gap']<.025,r['area']),reverse=True):
            key=tuple(np.rint(np.array(witness['normalA'])*10).astype(int))+(np.dot(witness['normalA'],witness['normalB'])>.999,)
            if bins[key]>=4:continue
            bins[key]+=1;chosen.append(witness)
            if len(chosen)>=40:break
        item['witnesses']=chosen
        item['paths']=[objects[item['a']]['nativePath'],objects[item['b']]['nativePath']]
        item['units']=[objects[item['a']]['unit'],objects[item['b']]['unit']]
        item['appearance']=[objects[item['a']]['appearance'],objects[item['b']]['appearance']]
        item['differentAppearance']=item['appearance'][0]!=item['appearance'][1]
        item['previous184']=tuple(sorted(item['paths'])) in old
    result={'scope':scope+' actual-triangle same/opposite-facing planar scan after Art03 plus200 material corrections; original ER01 floor retained. Positive triangle overlap >=0.01stud2 and maximum plane gap<=0.06stud. Visibility pending.', 'surfacePairs':len(candidates),'trianglePairsTested':tested,'pairs':sorted(hits.values(),key=lambda r:(r['minimumGap']<.025,r['area']),reverse=True)}
    (OWN/'inter-unit-candidates56.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps({'phase':'done','pairs':len(hits),'gapBelow025':sum(r['minimumGap']<.025 for r in hits.values()),'previous184':sum(r['previous184'] for r in hits.values()),'tested':tested}),flush=True)


if __name__=='__main__':
    start=time.monotonic()
    objects,triangles,owners,faces=reconstruct()
    scan(objects,triangles,owners,faces)
    print('seconds',time.monotonic()-start,flush=True)
