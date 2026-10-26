local fs=require("@lune/fs")
local process=require("@lune/process")
local roblox=require("@lune/roblox")
local luau=require("@lune/luau")
local serde=require("@lune/serde")
local fingerprint=require("./Fingerprint")
local path=assert(process.args[1],"archive path required")
local sources=assert(process.args[2],"frozen source directory required")
local first=roblox.deserializeModel(fs.readFile(path))
local second=roblox.deserializeModel(roblox.serializeModel(first))
local result={offline=true,archive=path,roots={},scripts=0,instances=0,sourceBytes=0,parts=0,colliders=0,meshes=0,labels=0}
for i,root in first do
 local a,b=fingerprint(root),fingerprint(second[i])
 assert(a.hash==b.hash and a.parts==b.parts,"Geometry changed in binary round trip")
 table.insert(result.roots,{name=root.Name,geometry=a,roundTripExact=true})
 for _,v in root:GetDescendants() do
  result.instances+=1
  if v:IsA("BasePart") then
   result.parts+=1
   if v.CanCollide then result.colliders+=1 end
   if v:IsA("MeshPart") then result.meshes+=1 end
  elseif v:IsA("ModuleScript") then
   assert(v.Source==fs.readFile(sources.."/"..v.Name..".luau"),"Frozen source differs from archive: "..v.Name)
   luau.load(v.Source,{debugName=v.Name})
   result.scripts+=1;result.sourceBytes+=#v.Source
  elseif v:IsA("TextLabel") then result.labels+=1 end
 end
end
assert(result.scripts==21,"Expected complete source package")
result.limits="Binary round trip preserves the checked part properties at 0.00001 precision; scripts match the frozen files and compile. This is not a Studio import or runtime test."
local output=process.args[3]
if output then fs.writeFile(output,serde.encode("json",result,true)) end
print(serde.encode("json",result))
