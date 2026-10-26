local fs=require("@lune/fs")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local luau=require("@lune/luau")
local path="docs/artifacts/stud-garden/milestones/stud-garden-final-sg01-layout04-art03.rbxm"
local root=roblox.deserializeModel(fs.readFile(path))[1]
local origin=roblox.Vector3.new(6500,80,3500)
local result={groups={},protected={},parts=0}
local function vector(v) return {v.X,v.Y,v.Z} end
local function walk(object,path)
 if object:IsA("BasePart") then
 result.parts+=1
 if not path:match("^Art/") then
 table.insert(result.protected,{path=path,size=vector(object.Size),cf={object.CFrame:GetComponents()},color={object.Color.R,object.Color.G,object.Color.B},anchored=object.Anchored,collide=object.CanCollide,touch=object.CanTouch,query=object.CanQuery})
 end
 end
 if object:IsA("Model") and path:match("^Art/") then
 local min,max=roblox.Vector3.new(math.huge,math.huge,math.huge),roblox.Vector3.new(-math.huge,-math.huge,-math.huge)
 local parts=0
 for _,part in object:GetDescendants() do if part:IsA("BasePart") then
 parts+=1
 local p=part.CFrame.Position-origin;local h=part.Size/2
 min=roblox.Vector3.new(math.min(min.X,p.X-h.X),math.min(min.Y,p.Y-h.Y),math.min(min.Z,p.Z-h.Z))
 max=roblox.Vector3.new(math.max(max.X,p.X+h.X),math.max(max.Y,p.Y+h.Y),math.max(max.Z,p.Z+h.Z))
 end end
 table.insert(result.groups,{path=path,family=object:GetAttribute("StudGardenFamily"),parts=parts,min=if parts>0 then vector(min) else nil,max=if parts>0 then vector(max) else nil})
 end
 for _,child in object:GetChildren() do walk(child,if path=="" then child.Name else path.."/"..child.Name) end
end
walk(root,"")
local env={Vector3=roblox.Vector3,CFrame=roblox.CFrame}
local layout=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/StudGarden/Layout.luau"),{environment=env})().Get()
result.route={}
for _,sequence in layout.sequences do if sequence.section=="S02" then
 local points={} for _,p in sequence.points do table.insert(points,{id=p.id,p=vector(p.position),size=vector(p.size)}) end
 table.insert(result.route,{id=sequence.id,points=points})
end end
result.barriers={}
for _,b in layout.barriers do table.insert(result.barriers,{id=b.id,p=vector(b.position),size=vector(b.size)}) end
fs.writeDir("docs/artifacts/stud-garden/environment-01")
fs.writeFile("docs/artifacts/stud-garden/environment-01/baseline-inventory.json",serde.encode("json",result,true))
print("Saved art groups "..#result.groups.."; protected parts "..#result.protected.."; total parts "..result.parts)
for _,g in result.groups do
 if g.family=="RouteFacingPlanting" or g.family=="PetVignette" or g.family=="LandmarkCandyBlossom" or g.family=="LandmarkBeanstalk" or g.family=="LayeredGardenContext" then print(serde.encode("json",g)) end
end
print(serde.encode("json",result.route))
print(serde.encode("json",result.barriers))

