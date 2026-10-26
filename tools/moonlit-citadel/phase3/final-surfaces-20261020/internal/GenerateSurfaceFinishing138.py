"""Extend only the final finishing module with the coherent three-material niche seat."""
from collections import defaultdict
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
DIRECTORY=ROOT/'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse'
MANIFEST=HERE.parent/'neighbors/FINAL_POSE138.json'
HASH='cf29b11d3b0238f29c51f4892dff993cb9193fcc1b0f077df277c5f978eb0724'
assert hashlib.sha256(MANIFEST.read_bytes()).hexdigest()==HASH
old=json.loads((HERE.parent/'neighbors/FINAL_POSE136.json').read_text(encoding='utf8'))
new=json.loads(MANIFEST.read_text(encoding='utf8'))
oldops={r['path']:r for r in old['operations']};newops={r['path']:r for r in new['operations']}
assert all(newops.get(k)==v for k,v in oldops.items())
assert set(newops)-set(oldops)=={
    'Decoration/Phase3World/DT_West/WestHighJambNiche/MC_DT_FacadeNiche__Stone',
    'Decoration/Phase3World/DT_West/WestHighJambNiche/MC_DT_FacadeNiche__StoneDark'}
target=DIRECTORY/'SurfaceFinishingPlan.luau'
before=target.read_text(encoding='utf8')
assert hashlib.sha256(target.read_bytes()).hexdigest()=='0c579bc6db8e4e079eac1266c14af16ace7796865d080e79c6c10184223b9e4b'
protected={n:hashlib.sha256((DIRECTORY/n).read_bytes()).hexdigest()for n in
    ('WorldAssembly.luau','VisualAssembly.luau','RouteBuilder.luau','WorldPlan.luau')}


def number(v):return format(v,'.17g')
def vector(v):return 'Vector3.new('+','.join(number(x)for x in v)+')'
def frame(v):
    v=v[:]
    for axis,offset in enumerate((4000,300,2600)):v[axis]-=offset
    return 'CFrame.new('+','.join(number(x)for x in v)+')'
def text(v):return json.dumps(v,ensure_ascii=True)
def entry(op,path):
    a,p=op['expectedAttributes'],op['expectedAppearance'];i='        '
    assert a['Role']=='Decoration'
    assert op['flags']=={'Anchored':True,'CanCollide':False,'CanQuery':False,'CanTouch':False,'DoubleSided':False}
    assert p['Transparency']==0 and p['Reflectance']==0
    return '\n'.join((
        i+'{path='+text(path)+', asset='+text(op['asset'])+', material='+text(op['material'])+', meshId='+text(op['meshId'])+',',
        i+' beforeSize='+vector(op['beforeSize'])+', afterSize='+vector(op['afterSize'])+',',
        i+' beforeFrame='+frame(op['beforeCFrame'])+',',
        i+' afterFrame='+frame(op['afterCFrame'])+',',
        i+' color='+vector(p['Color']).replace('Vector3.new','Color3.new')+', engineMaterial='+p['Material']+',',
        i+' castShadow='+str(p['CastShadow']).lower()+', sourceTriangles='+('nil'if a.get('SourceTriangles')is None else str(a['SourceTriangles']))+'},'))


world=defaultdict(list);route=[]
for op in new['operations']:
    if op['path'].startswith('Decoration/Phase3World/'):
        district,unit,part=op['path'].split('/')[2:];world[district+'/'+unit].append((op,part))
    else:route.append(op)
assert sum(map(len,world.values()))==31 and len(route)==107
head=before[:before.index('local world = {')]
head=head.replace('0f5c0e39cccfc4135ea4217ab82f40681db3136220325c774df7089ffba771b9',HASH)
head=head.replace('ExpectedWorldParts=29','ExpectedWorldParts=31')
tail=before[before.index('local route = {'):]
body=['local world = {']
for key,ops in sorted(world.items()):
    body.append('    ['+text(key)+']={')
    body.extend(entry(op,path)for op,path in ops)
    body.append('    },')
body.append('}\n\n')
after=head+'\n'.join(body)+tail
target.write_text(after,encoding='utf8',newline='\n')
assert all(hashlib.sha256((DIRECTORY/n).read_bytes()).hexdigest()==h for n,h in protected.items())
receipt={'manifest':str(MANIFEST.relative_to(ROOT)),'manifestSHA256':HASH,'source':str(target.relative_to(ROOT)),
    'sourceSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),'sourceBytes':target.stat().st_size,
    'worldTargets':31,'routeTargets':107,'sourceRevision':57,'buildRevision':51,
    'old136OperationsExact':True,'newTargets':sorted(set(newops)-set(oldops)),'otherFourSourceFilesUnchangedByThisUpdate':protected,
    'nativeTouched':False}
(HERE/'SOURCE_IMPLEMENTATION138_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print(json.dumps(receipt))
