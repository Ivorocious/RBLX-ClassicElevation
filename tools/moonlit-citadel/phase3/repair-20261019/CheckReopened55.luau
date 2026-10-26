local fs,roblox,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde")
local own="docs/artifacts/moonlit-citadel/phase3/repair-20261019/"
local packet=serde.decode("json",fs.readFile(own.."repair_source55_packet_final.json"))
local receipt=serde.decode("json",fs.readFile(own.."repair_final55_receipt.json"))
for _,file in receipt.files do assert(serde.hash("sha256",fs.readFile(own..file.name))==file.sha256,file.name) end
local models=roblox.deserializeModel(fs.readFile(own.."repair_final55_models.rbxm"))
assert(#models==2)
local out={pass=true,models={},moduleSources=0,cleanupRoots=0,packetSHA256=serde.hash("sha256",fs.readFile(own.."repair_source55_packet_final.json"))}
for i,m in models do
 assert(m.Name=="Course_MoonlitCitadel" and m:GetAttribute("SourceRevision")==55 and m:GetAttribute("BuildRevision")==49 and m:GetAttribute("SourcePacketHash")==out.packetSHA256)
 local r={parts=0,meshes=0,colliders=0,walkables=0,hazards=0,arrows=0,worldUnits=0,worldMeshes=0}
 for _,p in m:GetDescendants() do
  if p:IsA("BasePart") then r.parts+=1
   if p:IsA("MeshPart") then r.meshes+=1 end
   if p.CanCollide then r.colliders+=1 end
   if p:GetAttribute("MCWalkable") then r.walkables+=1 end
   if p:GetAttribute("MoonlitHazard") then r.hazards+=1 end
   if p:GetAttribute("GuidanceKind")=="SolidMeshArrow" then r.arrows+=1 end
  end
 end
 for _,v in m.Decoration.Phase3World:GetDescendants() do
  if v:IsA("Model") and v:GetAttribute("MCEditUnit") then r.worldUnits+=1 end
  if v:IsA("MeshPart") then assert(v.Anchored and not v.CanCollide and not v.CanQuery and not v.CanTouch);r.worldMeshes+=1 end
 end
 assert(r.parts==1762 and r.meshes==1468 and r.colliders==147 and r.walkables==135 and r.hazards==55 and r.arrows==19 and r.worldUnits==315 and r.worldMeshes==868)
 assert(m.Finish.Size==roblox.Vector3.new(28,12,24) and m.Decoration.Phase3World:GetAttribute("PlacedTriangles")==259002)
 table.insert(out.models,r)
end
local savedModules={}
for _,root in roblox.deserializeModel(fs.readFile(own.."repair_final55_modules.rbxm")) do
 local all={root};for _,v in root:GetDescendants() do table.insert(all,v) end
 for _,v in all do if v:IsA("LuaSourceContainer") then assert(not savedModules[v.Name]);savedModules[v.Name]=v.Source:gsub("\r\n","\n") end end
end
for _,row in packet.records do assert(savedModules[row.name]==row.source and serde.hash("sha256",row.source)==row.sha256,row.name);out.moduleSources+=1 end
for _,r in roblox.deserializeModel(fs.readFile(own.."repair_cleanup_before.rbxm")) do out.cleanupRoots+=1 end
assert(out.cleanupRoots==12 and out.moduleSources==35)
local library=roblox.deserializeModel(fs.readFile(own.."repair_final55_depth_library.rbxm"))
assert(#library==1 and library[1]:GetAttribute("NativeTriangleSurfacesVerified")==true)
out.nativeDepthFaces=library[1]:GetAttribute("NativeVerifiedTriangles")
assert(out.nativeDepthFaces==18060)
fs.writeFile(own.."final/reopened55-check.json",serde.encode("json",out,true).."\n")
print(serde.encode("json",out))