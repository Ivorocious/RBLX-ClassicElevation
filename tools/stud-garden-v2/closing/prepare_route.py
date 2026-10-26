"""Declare obsolete cosmetic batches and freeze the scoped native route installer."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'docs/artifacts/stud-garden-v2/closing-20261005'
SOURCE=ROOT/'tools/stud-garden-v2/closing'
manifest=json.loads((OUT.parent/'phase3/f03/manifest.json').read_text())
changed=['Obstacles.G1_SeedShop.TrowelClimb','Obstacles.G1_SeedShop.ForkCrossing',
         'Obstacles.G2_ToolGardenExit.StoredTrowel','Obstacles.G2_ToolGardenExit.StoredFork',
         'Obstacles.G5_HarvestFestival.LastTrowel','Obstacles.G5_HarvestFestival.HarvestFork',
         'Obstacles.G1_SeedShop.SeedShopLandmark']
changed += ['Obstacles.G2_CropGarden.PlayableObjects.'+x for x in ['MergeRefuge','BambooTurn','BambooSouth','BambooReturn','BambooNorth']]
remove=[]
for mesh in manifest['meshes']:
    if not mesh['name'].startswith('F03__surface_'):continue
    if any(group.startswith('Studs_'+p) for group in mesh['sourceGroups'] for p in changed):
        assert all(group.startswith('Studs_') for group in mesh['sourceGroups'])
        remove.append(dict(name=mesh['name'],triangles=mesh['triangles'],sourceGroups=mesh['sourceGroups']))
spec={'removeStudBatches':remove,'changedModels':changed,'reason':'These shallow cosmetic batches span old transformed supports. Removing them avoids floating studs and reduces decorative cost; the remaining scenery meshes are retained.'}
(OUT/'route-spec.json').write_text(json.dumps(spec,indent=2))
code='''assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning(),"Requires intended Edit place")
local root=assert(workspace:FindFirstChild("SGV2_Phase3_F04"))
assert(root:GetAttribute("CandidateId")=="SGV2_Closing_C01_Sample","Requires the sampled candidate")
assert((root:GetPivot().Position-Vector3.new(1563,257,-1053)).Magnitude<.01,"Owner placement changed")
assert(root.CourseInfo:GetAttribute("Enabled")==false,"Expected disabled candidate")
'''
for name in ['NativeKit','ToolFamily','RoutePresentation','RouteClosing']:
    code+=f'local {name}=(function()\n'+(SOURCE/(name+'.luau')).read_text()+'\nend)()\n'
code+='local spec=game:GetService("HttpService"):JSONDecode([====['+json.dumps(spec,separators=(',',':'))+']====])\n'
code+='local result=RouteClosing(root,NativeKit,ToolFamily(NativeKit),RoutePresentation(NativeKit),spec)\n'
code+='local fingerprint=(function()\n'+(SOURCE.parent/'Fingerprint.luau').read_text()+'\nend)()\n'
code+='result.fingerprint=fingerprint(root)\nreturn result\n'
(OUT/'install-route.luau').write_text(code)
print(json.dumps({'scriptBytes':len(code.encode()),'removedCosmeticBatches':len(remove),'removedStudTriangles':sum(m['triangles'] for m in remove)}))
