--!nonstrict
assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and not game.RunService:IsRunning())
local H,E=game.HttpService,game.EncodingService;local httpBefore=H.HttpEnabled
local ok,raw=pcall(function()H.HttpEnabled=true;return H:GetAsync("http://127.0.0.1:56115/towerland_source45_packet.json")end);H.HttpEnabled=httpBefore;assert(ok,raw)
local function hash(text)
 local d=E:ComputeBufferHash(buffer.fromstring(text),Enum.HashAlgorithm.Sha256);local out={};for i=0,buffer.len(d)-1 do table.insert(out,string.format("%02x",buffer.readu8(d,i)))end;return table.concat(out)
end
assert(hash(raw)=="6409b94517f5fb061e1bf2df1a073c2d948f8f0b74401d7548b493fa2b8954d3")
local packet=H:JSONDecode(raw);assert(packet.sourceRevision==45 and #packet.records==20)
local archive=game.ServerStorage.MoonlitP3ReworkRecovery.TowerLandscape20261013
local fresh=archive:FindFirstChild("FullModules45")
if not fresh then fresh=Instance.new("Folder");fresh.Name,fresh.Parent="FullModules45",archive end
local before=archive:FindFirstChild("BeforeArtSource45")
if not before then before=Instance.new("Folder");before.Name,before.Parent="BeforeArtSource45",archive end
local sources={}
for _,r in packet.records do
 assert(hash(r.source)==r.sha256)
 local parent=if r.name=="MoonlitCitadelAmbienceConfig" then game.ReplicatedStorage.Config else game.ServerStorage.CourseBuilders.MoonlitCitadelCourse
 local module=parent:FindFirstChild(r.name)
 if not module then module=Instance.new("ModuleScript");module.Name,module.Parent=r.name,parent end
 if hash(module.Source:gsub("\r\n","\n"))~=r.sha256 then local old=module:Clone();old.Parent=before;module.Source=r.source end
 assert(hash(module.Source:gsub("\r\n","\n"))==r.sha256)
 table.insert(sources,{name=r.name,sha256=r.sha256})
 if r.name~="MoonlitCitadelAmbienceConfig" then
  local copy=fresh:FindFirstChild(r.name) or Instance.new("ModuleScript");copy.Name=r.name
  copy.Source=if r.name=="WorldAssembly" then r.source:gsub("require%(script.Parent.Parent.MoonlitCitadel.MeshKit%)","require(game.ServerStorage.CourseBuilders.MoonlitCitadel.MeshKit)") else r.source
  copy.Parent=fresh
 end
end
local storedPacket=archive:FindFirstChild("Source45PacketChunks") or Instance.new("Folder");storedPacket.Name,storedPacket.Parent="Source45PacketChunks",archive
for offset=1,#raw,180000 do local name=tostring(math.floor((offset-1)/180000)+1);local c=storedPacket:FindFirstChild(name) or Instance.new("StringValue");c.Name,c.Value,c.Parent=name,raw:sub(offset,offset+179999),storedPacket end
local assembly,layout=require(fresh.WorldAssembly),require(fresh.Layout)
local plan,planned=require(fresh.WorldPlan).Get(layout);assert(not planned.fullMapPending and #planned.plantingMounts==6)
local reports={}
for _,course in {workspace.Course_MoonlitCitadel,game.ServerStorage.CourseLibrary.Course_MoonlitCitadel} do
 local pivot=course:GetPivot()
 local older=course.Decoration.Phase3World
 local preserved=Instance.new("Folder");preserved.Name=if course.Parent==workspace then "BeforeSource45EditableArt" else "BeforeSource45StoredArt";preserved.Parent=archive
 older.Parent=preserved
 local built,w,counts=xpcall(function()return assembly.Apply(course,layout)end,debug.traceback)
 course.WorldPivot=pivot
 if not built then local partial=course.Decoration:FindFirstChild("Phase3World");if partial then partial.Name,partial.Parent=preserved.Name.."_Partial",archive end;older.Parent=course.Decoration;error(w)end
 course:SetAttribute("SourceRevision",45);course:SetAttribute("BuildRevision",39)
 course:SetAttribute("CandidateId",packet.candidate);course:SetAttribute("SourcePacketHash","6409b94517f5fb061e1bf2df1a073c2d948f8f0b74401d7548b493fa2b8954d3")
 w:SetAttribute("ArtRepairStage","FinishedCandidate45")
 local total={parts=0,meshes=0,colliders=0,floors=0,red=0,lights=0}
 for _,p in course:GetDescendants() do
  if p:IsA("BasePart") then total.parts+=1;if p:IsA("MeshPart")then total.meshes+=1 end;if p.CanCollide then total.colliders+=1 end
   if p:GetAttribute("MCWalkable")==true then total.floors+=1 end;if p:GetAttribute("MoonlitHazard")==true then total.red+=1 end
  elseif p:IsA("Light") then total.lights+=1 end
 end
 table.insert(reports,{path=course:GetFullName(),descendants=#course:GetDescendants(),total=total,world={units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles,mounts=#counts.plantingMounts}})
 task.wait()
end
return H:JSONEncode({ok=true,sourceRevision=45,buildRevision=39,sourcePacketHash="6409b94517f5fb061e1bf2df1a073c2d948f8f0b74401d7548b493fa2b8954d3",sources=sources,models=reports,httpRestored=H.HttpEnabled==httpBefore})