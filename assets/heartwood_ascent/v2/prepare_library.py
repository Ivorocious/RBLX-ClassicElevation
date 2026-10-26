"""Produce source metadata and the owned-template normalization recipe."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent
repo=ROOT.parents[2]
source=json.loads((ROOT/'asset-manifest.json').read_text())['objects']
old=json.loads((ROOT.parent/'v1/asset-manifest.json').read_text())['objects']
source += [x for x in old if x['name'] in ('HA_FoldingLeaf','HA_Seedpod','HA_Fern')]
imports=json.loads((ROOT/'imported-assets.json').read_text())
imports.update({k:v for k,v in json.loads((ROOT.parent/'v1/imported-assets.json').read_text()).items() if k in ('HA_FoldingLeaf','HA_Seedpod','HA_Fern')})
def vec(a):return 'Vector3.new('+', '.join(f'{x:.9g}' for x in a)+')'
rows={}
for x in source:
    lo=x['bounds_min'];hi=x['bounds_max'];c=[(a+b)/2 for a,b in zip(lo,hi)]
    rows[x['name']]={'size':[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]],'center':[c[0],c[2],-c[1]],'triangles':x['triangles'],'package':x['package'],**imports[x['name']]}
manifest='-- Generated from HA03 checked Blender bounds and completed owned imports.\nreturn {\n'
for name,r in rows.items():
    manifest+=f'    ["{name}"] = {{size = {vec(r["size"])}, center = {vec(r["center"])}, triangles = {r["triangles"]}, package = "{r["package"]}", mesh = "{r["mesh"]}", texture = "{r["texture"]}"}},\n'
manifest+='}\n'
(repo/'src/ServerStorage/CourseBuilders/HeartwoodAscent/ArtManifest.luau').write_text(manifest)
normalizer='''local manifest = loadstring(game.ServerStorage.CourseBuilders.HeartwoodAscent.ArtManifest.Source)()
local libraries=game.ServerStorage.AssetLibraries
assert(not libraries:FindFirstChild("HeartwoodV1HA03"),"Preserve existing library")
local library=Instance.new("Folder");library.Name="HeartwoodV1HA03";library.Parent=libraries
library:SetAttribute("State","Creating")
task.spawn(function()
 local made=0
 local ok,err=pcall(function()
  for name,data in manifest do
   local source
   for _,pack in {"HeartwoodStructureHA03","HeartwoodFoliageHA03","HeartwoodFlowersHA03GroundedEntrance"} do
    local found=game.ServerStorage.AssetImports[pack]:FindFirstChild(name,true)
    if found then source=found;break end
   end
   if not source then source=libraries.HeartwoodV1:FindFirstChild(name) end
   assert(source and source:IsA("MeshPart"),"Missing owned mesh "..name)
   local solid=data.package=="flowers" or data.package=="structure" and (name:match("^HA_Hollow") or name:match("^HA_Buttress") or name:match("^HA_Shelf") or name=="HA_RootSpan" or name=="HA_HeartwoodSocket" or name:match("^HA_Bough_0[0-3]$"))
   local p=if solid then game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(data.mesh),{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition}) else source:Clone()
   p.Name=name;p.Size=data.size;p.CFrame=CFrame.new(data.center);p.PivotOffset=CFrame.identity
   p.TextureID=data.texture;p.Color=Color3.new(1,1,1);p.Material=Enum.Material.SmoothPlastic
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=library
   p:SetAttribute("ArtTriangles",data.triangles);made+=1;library:SetAttribute("Created",made)
  end
  local leaf=libraries.HeartwoodV1.HA_LeafCollisionChecked:Clone();leaf.Parent=library
 end)
 library:SetAttribute("State",if ok then "Complete" else "Failed");library:SetAttribute("Error",if ok then nil else tostring(err))
end)
return {library=library:GetFullName(),templates=53,asynchronous=true}
'''
(ROOT/'normalize_imports.luau').write_text(normalizer)
print(json.dumps({'metadata':len(rows),'normalizer':str(ROOT/'normalize_imports.luau')}))
