from pathlib import Path
import json
R=Path('assets/city_run/v3');F=R/'final03'
base=(R/'build_stage2_installer.py').read_text().split("code=r'''",1)[1].split("'''",1)[0]
inject="""local finalLibrary=assert(SS:FindFirstChild("CityRunFinal03Library"),"Final library missing")
for _,p in finalLibrary:GetDescendants() do if p:IsA("MeshPart")then library[p.Name]=p end end
"""
base=base.replace('for _,v in plan.placements do assert',inject+'for _,v in plan.placements do assert')
base=base.replace('p.CastShadow=not string.find(v.asset,"Skyline")','p.CastShadow=not string.find(v.asset,"Skyline")\n if string.sub(v.asset,1,4)=="F03_" then p.CollisionFidelity=Enum.CollisionFidelity.Box;p.RenderFidelity=Enum.RenderFidelity.Automatic end')
accents="""local accents=Instance.new('Folder');accents.Name='V3Accents';accents.Parent=course.Decoration
for _,v in plan.accentParts or {} do
 local p=Instance.new('Part');p.Name=v.name;p.Size=Vector3.new(unpack(v.size));p.CFrame=CFrame.new(unpack(v.pos))
 p.Color=Color3.fromRGB(unpack(v.color));p.Material=Enum.Material[v.material]
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p:SetAttribute('V3Build',plan.build);p.Parent=accents
end
"""
base=base.replace('course.WorldPivot=pivot',accents+'course.WorldPivot=pivot')
base=base.replace('PLAN_JSON' ,json.dumps(json.loads((F/'layout.json').read_text()),separators=(',',':')))
(F/'install.luau').write_text(base)
print('Ready',len(base))
