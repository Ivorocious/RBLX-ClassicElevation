import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
OUT=HERE/'integration01';OUT.mkdir(exist_ok=True)
plan=json.loads((HERE/'proposal03/art-plan.json').read_text(encoding='utf8'))
plants=[row['after'] for row in plan['replacements'] if row['before']['district']=='RoutePlanting']
assert len(plants)==12
raw=(HERE/'proposal03/ArtRepairPlan.luau').read_text(encoding='utf8')
prefix=['local environmentEdits = {']
for row in plants:prefix.append(' ['+json.dumps(row['name'])+']=true,')
prefix.extend(['}','local plantingMounts = {'])
for row in plants:
    if not row['name'].endswith('CarvedBasin'):continue
    name=row['name'][:-len('CarvedBasin')]
    support='Gallery'+name[7]+('PlanterShelf-1' if name.endswith('Left') else 'PlanterShelf1')
    cf=','.join(f'{value:.12g}' for value in row['localCF'])
    prefix.append(f' [{json.dumps(name)}]={{frame=CFrame.new({cf}),supportName={json.dumps(support)}}},')
prefix.extend(['}', '''local function selected(name, scope)
 return scope==nil or (if environmentEdits[name] then scope=="Environment" else scope=="Architecture")
end
function Art.RevisePlantingMounts(mounts)
 assert(type(mounts)=="table","Art repair requires the authored planting mounts")
 local result, found, seen = {}, {}, {}
 for _, mount in mounts do
  assert(not seen[mount.name],"Duplicate planting mount "..tostring(mount.name));seen[mount.name]=true
  local edit=plantingMounts[mount.name]
  if edit ~= nil then
   assert(mount.supportName==edit.supportName,"Gallery planting support identity changed")
   local copy=table.clone(mount);copy.frame=edit.frame;mount=copy;found[mount.name]=true
  end
  table.insert(result,mount)
 end
 for name in plantingMounts do assert(found[name],"Missing gallery planting mount "..name) end
 return result
end'''])
raw=raw.replace('function Art.Apply(plan)', '\n'.join(prefix)+'\nfunction Art.Apply(plan, scope)\n assert(scope==nil or scope=="Architecture" or scope=="Environment","Unknown art repair scope")')
raw=raw.replace('if retired[data.name] then','if retired[data.name] and selected(data.name,scope) then')
raw=raw.replace('if edit then','if edit and selected(data.name,scope) then')
raw=raw.replace('for name in edits do assert(found[name],','for name in edits do if not selected(name,scope) then continue end; assert(found[name],')
raw=raw.replace('for name in retired do assert(found[name],','for name in retired do if not selected(name,scope) then continue end; assert(found[name],')
(OUT/'ArtRepairPlan.luau').write_text(raw,encoding='utf8')
print(json.dumps({'architectureEdits':56-len(plants),'environmentEdits':len(plants),'architectureRetirements':5,'mounts':len(plants)//2}))
