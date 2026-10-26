"""Generate the bounded Source56-relative visual finishing recipe from its frozen manifest."""
from collections import defaultdict
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
MANIFEST=HERE.parent/'neighbors/FINAL_POSE136.json'
EXPECTED='0f5c0e39cccfc4135ea4217ab82f40681db3136220325c774df7089ffba771b9'
assert hashlib.sha256(MANIFEST.read_bytes()).hexdigest()==EXPECTED
plan=json.loads(MANIFEST.read_text(encoding='utf8'))
assert plan['count']==136 and len(plan['operations'])==136
world,route=defaultdict(list),[]


def number(v):
    return format(v,'.17g')


def vector(v):
    return 'Vector3.new('+','.join(number(x)for x in v)+')'


def frame(v):
    v=v[:]
    for axis,offset in enumerate((4000,300,2600)):v[axis]-=offset
    return 'CFrame.new('+','.join(number(x)for x in v)+')'


def text(v):
    return json.dumps(v,ensure_ascii=True)


def entry(op,path,indent):
    attrs,appearance=op['expectedAttributes'],op['expectedAppearance']
    assert attrs['Role']=='Decoration'
    assert op['flags']=={'Anchored':True,'CanCollide':False,'CanQuery':False,'CanTouch':False,'DoubleSided':False}
    assert appearance['Transparency']==0 and appearance['Reflectance']==0
    return '\n'.join((
        indent+'{path='+text(path)+', asset='+text(op['asset'])+', material='+text(op['material'])+', meshId='+text(op['meshId'])+',',
        indent+' beforeSize='+vector(op['beforeSize'])+', afterSize='+vector(op['afterSize'])+',',
        indent+' beforeFrame='+frame(op['beforeCFrame'])+',',
        indent+' afterFrame='+frame(op['afterCFrame'])+',',
        indent+' color='+vector(appearance['Color']).replace('Vector3.new','Color3.new')+', engineMaterial='+appearance['Material']+',',
        indent+' castShadow='+str(appearance['CastShadow']).lower()+', sourceTriangles='+('nil'if attrs.get('SourceTriangles')is None else str(attrs['SourceTriangles']))+'},'
    ))


for op in plan['operations']:
    if op['path'].startswith('Decoration/Phase3World/'):
        district,unit,part=op['path'].split('/')[2:]
        world[district+'/'+unit].append((op,part))
    else:
        assert op['path'].startswith('Obstacles/')
        route.append(op)
assert sum(len(v)for v in world.values())==29 and len(route)==107
lines=['--!nonstrict',
    'local Finishing = {Candidate="MC_P3_FINAL_SURFACES_20261020", SourceRevision=57, BuildRevision=51,',
    '    ManifestSHA256="'+EXPECTED+'", ExpectedWorldParts=29, ExpectedRouteParts=107}',
    '',
    '-- These native part poses follow the original separation and deterministic floor-layer pass.',
    'local world = {']
for key,ops in sorted(world.items()):
    lines.append('    ['+text(key)+']={')
    lines.extend(entry(op,part,'        ')for op,part in ops)
    lines.append('    },')
lines.extend(('}', '', 'local route = {'))
lines.extend(entry(op,op['path'],'    ')for op in route)
lines.extend(('}', '', r'''local function originFrame(course)
    assert(course:IsA("Model") and course:GetAttribute("CourseId")=="moonlit_citadel", "Finishing requires the Moonlit course")
    local origin=course:GetAttribute("Origin")
    assert(typeof(origin)=="Vector3", "Course Origin is missing")
    return CFrame.new(origin)
end

local function resolve(parent,path)
    for name in path:gmatch("[^/]+") do
        local nextPart=assert(parent:FindFirstChild(name), "Missing finishing target "..path)
        local matches=0
        for _,child in parent:GetChildren() do if child.Name==name then matches+=1 end end
        assert(matches==1, "Ambiguous finishing target "..path)
        parent=nextPart
    end
    return parent
end

local function closeVector(a,b,tolerance)
    return math.max(math.abs(a.X-b.X),math.abs(a.Y-b.Y),math.abs(a.Z-b.Z))<tolerance
end

local function closeFrame(a,b)
    if not closeVector(a.Position,b.Position,.003) then return false end
    local av,bv={a:GetComponents()},{b:GetComponents()}
    for index=4,12 do if math.abs(av[index]-bv[index])>=.00003 then return false end end
    return true
end

local function prepare(parent,operations,frame)
    local pending={}
    for _,op in operations do
        local part=resolve(parent,op.path)
        assert(part:IsA("MeshPart") and part.Anchored and not part.CanCollide and not part.CanQuery
            and not part.CanTouch and not part.DoubleSided, "Finishing requires an inert visual MeshPart: "..op.path)
        assert(part:GetAttribute("SourceAsset")==op.asset and part:GetAttribute("SourceMaterial")==op.material
            and part:GetAttribute("Role")=="Decoration" and part:GetAttribute("SourceTriangles")==op.sourceTriangles
            and part.MeshId==op.meshId, "Finishing source identity differs: "..op.path)
        assert(part.Transparency==0 and part.Reflectance==0 and part.CastShadow==op.castShadow
            and closeVector(Vector3.new(part.Color.R,part.Color.G,part.Color.B),
                Vector3.new(op.color.R,op.color.G,op.color.B),.00001)
            and part.Material==op.engineMaterial, "Finishing appearance differs: "..op.path)
        assert(closeVector(part.Size,op.beforeSize,.003) and closeFrame(frame:ToObjectSpace(part.CFrame),op.beforeFrame),
            "Finishing expects the original Source56 pose exactly once: "..op.path)
        assert(math.min(op.afterSize.X,op.afterSize.Y,op.afterSize.Z)>.001)
        table.insert(pending,{part=part,size=if op.beforeSize~=op.afterSize then op.afterSize else nil,
            frame=if op.beforeFrame~=op.afterFrame then frame*op.afterFrame else nil})
    end
    return pending
end

local function apply(pending)
    for _,change in pending do
        if change.size then change.part.Size=change.size end
        if change.frame then change.part.CFrame=change.frame end
    end
    return #pending
end

function Finishing.ApplyWorldUnit(course,model,data)
    local operations=world[data.district.."/"..data.name]
    if not operations then return 0 end
    assert(model:IsA("Model") and model.Name==data.name and model.Parent.Name==data.district,
        "Finishing world unit identity differs")
    for _,op in operations do assert(op.asset==data.asset, "Finishing world asset differs") end
    return apply(prepare(model,operations,originFrame(course)))
end

function Finishing.ApplyRoute(course)
    local pending=prepare(course,route,originFrame(course))
    assert(#pending==Finishing.ExpectedRouteParts, "Final route finishing target count differs")
    return apply(pending)
end

return Finishing'''))
source='\n'.join(lines)+'\n'
target=ROOT/'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/SurfaceFinishingPlan.luau'
assert not target.exists(), 'Preserve an existing implementation before regeneration'
target.write_text(source,encoding='utf8',newline='\n')
receipt={'manifest':str(MANIFEST.relative_to(ROOT)),'manifestSHA256':EXPECTED,
    'source':str(target.relative_to(ROOT)),'sourceSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),
    'sourceBytes':target.stat().st_size,'worldTargets':29,'routeTargets':107,'sourceRevision':57,'buildRevision':51,
    'newMeshesIntegrated':False,'nativeTouched':False}
(HERE/'SOURCE_IMPLEMENTATION_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print(json.dumps(receipt))
