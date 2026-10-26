"""Build the isolated study installer from the exact exported placement manifest."""
import json
from pathlib import Path
root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text())
studies=json.loads((root/'studies.json').read_text())
payload=json.dumps(dict(manifest=manifest,studies=studies),separators=(',',':'))
code='local data = game:GetService("HttpService"):JSONDecode([==['+payload+']==])\n'+r'''
assert(game.PlaceId == 85558151074819, "Wrong experience")
assert(not game:GetService("RunService"):IsRunning(), "Edit mode required")
assert(not workspace:FindFirstChild("__ShipwreckCove_Phase1"), "Study exists; inspect before revision")
local root = Instance.new("Model")
root.Name = "__ShipwreckCove_Phase1"
root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
root:SetAttribute("Build", data.studies.build)
root:SetAttribute("Purpose", "Small asset fit studies; not a race course")
local origin = Vector3.new(-600, 50, 0)
root:SetAttribute("Origin", origin)
local byId = {}
for _,r in data.manifest.assets do byId[r.id] = r end
local function part(parent, name, cf, size)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.CFrame = cf
    p.Anchored = true; p.CanCollide = true; p.CanTouch = false; p.CanQuery = true
    p.Transparency = 1; p.Material = Enum.Material.SmoothPlastic
    p.Color = Color3.fromRGB(178,166,137)
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p:SetAttribute("StudyOwned", true); p.Parent = parent
    return p
end
for i,row in data.studies.placements do
    local group = root:FindFirstChild(row.group)
    if not group then group=Instance.new("Model");group.Name=row.group;group.Parent=root end
    local holder = Instance.new("Model")
    holder.Name = string.format("%03d_%s",i,row.asset)
    holder:SetAttribute("Asset",row.asset);holder:SetAttribute("PlacementIndex",i)
    local pos = row.pos
    local base = CFrame.new(origin + Vector3.new(pos[1],pos[3],-pos[2])) * CFrame.Angles(0,math.rad(row.yaw),0)
    holder:SetAttribute("Mount",base);holder:SetAttribute("Scale",Vector3.new(table.unpack(row.scale)))
    holder:SetAttribute("VisualOnly",row.visualOnly == true)
    holder.Parent=group
    for k,col in (if row.visualOnly then {} else byId[row.asset].colliders) do
        local c,s=col.center,col.size
        local sx,sy,sz=row.scale[1],row.scale[3],row.scale[2]
        local cf=base*CFrame.new(c[1]*sx,c[2]*sy,c[3]*sz)*CFrame.Angles(0,0,math.rad(col.rollDegrees or 0))
        local p=part(holder,"Collider"..k,cf,Vector3.new(s[1]*sx,s[2]*sy,s[3]*sz))
        p:SetAttribute("Collider",true)
    end
end
root.Parent=workspace
local n=0 for _,p in root:GetDescendants() do if p:IsA("BasePart") then n+=1 end end
return game:GetService("HttpService"):JSONEncode({build=data.studies.build,proxyColliders=n,origin=tostring(origin),status="Simple colliders installed; run install-visuals next"})
'''
(root/'install-colliders.luau').write_text(code)
print(json.dumps(dict(bytes=len(code),placements=len(studies['placements']))))
