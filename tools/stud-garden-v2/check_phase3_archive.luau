local fs=require("@lune/fs")
local process=require("@lune/process")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local fingerprint=require("./Fingerprint")
local roots=roblox.deserializeModel(fs.readFile(assert(process.args[1])))
assert(#roots==1)
local root=roots[1]
local counts={parts=0,scripts=0,meshes=0,colliders=0}
for _,p in root:GetDescendants() do
    if p:IsA("BasePart") then counts.parts+=1;if p.CanCollide then counts.colliders+=1 end end
    if p:IsA("MeshPart") then counts.meshes+=1 end
    if p:IsA("LuaSourceContainer") then counts.scripts+=1 end
end
local result={name=root.Name,candidate=root:GetAttribute("CandidateId"),fingerprint=fingerprint(root),counts=counts}
assert(result.fingerprint.hash=="470ecc4d" and counts.parts==4955 and counts.scripts==0,"Saved archive differs")
fs.writeFile(assert(process.args[2]),serde.encode("json",result,true))
print(serde.encode("json",result))
