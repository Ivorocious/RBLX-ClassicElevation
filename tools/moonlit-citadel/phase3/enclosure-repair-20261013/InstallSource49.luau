--!nonstrict
assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and not game.RunService:IsRunning())
local H,E=game.HttpService,game.EncodingService;local httpBefore=H.HttpEnabled
local ok,raw=pcall(function()H.HttpEnabled=true;return H:GetAsync("http://127.0.0.1:56117/enclosure_source49_packet.json")end);H.HttpEnabled=httpBefore;assert(ok,raw)
local function hash(text)
 local d=E:ComputeBufferHash(buffer.fromstring(text),Enum.HashAlgorithm.Sha256);local out={};for i=0,buffer.len(d)-1 do table.insert(out,string.format("%02x",buffer.readu8(d,i)))end;return table.concat(out)
end
assert(hash(raw)=="7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca")
local packet=H:JSONDecode(raw);assert(packet.sourceRevision==49 and #packet.records==26)
local archive=game.ServerStorage.MoonlitP3ReworkRecovery.EnclosureRepair20261013
local fresh=archive:FindFirstChild("FullModules49")
if not fresh then fresh=Instance.new("Folder");fresh.Name,fresh.Parent="FullModules49",archive end
local before=archive:FindFirstChild("BeforeArtSource49")
if not before then before=Instance.new("Folder");before.Name,before.Parent="BeforeArtSource49",archive end
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
local storedPacket=archive:FindFirstChild("Source49PacketChunks") or Instance.new("Folder");storedPacket.Name,storedPacket.Parent="Source49PacketChunks",archive
for offset=1,#raw,180000 do local name=tostring(math.floor((offset-1)/180000)+1);local c=storedPacket:FindFirstChild(name) or Instance.new("StringValue");c.Name,c.Value,c.Parent=name,raw:sub(offset,offset+179999),storedPacket end
local assembly,layout=require(fresh.WorldAssembly),require(fresh.Layout)
local plan,planned=require(fresh.WorldPlan).Get(layout);assert(not planned.fullMapPending and #planned.plantingMounts==6)
local reports={}
local P=require(archive.ProtectedCourse)
local c=archive.ProtectedBaseline48:GetChildren();table.sort(c,function(a,b)return tonumber(a.Name)<tonumber(b.Name)end);local a={};for _,v in c do a[#a+1]=v.Value end;local baseline=H:JSONDecode(table.concat(a))
assert(P.Compare(baseline.editable,P.Capture(workspace.Course_MoonlitCitadel)).pass,"Editable Phase2 changed before art")
assert(P.Compare(baseline.stored,P.Capture(game.ServerStorage.CourseLibrary.Course_MoonlitCitadel)).pass,"Stored Phase2 changed before art")
for _,course in {workspace.Course_MoonlitCitadel,game.ServerStorage.CourseLibrary.Course_MoonlitCitadel} do
 local pivot=course:GetPivot()
 local older=course.Decoration.Phase3World
 local preserved=Instance.new("Folder");preserved.Name=if course.Parent==workspace then "BeforeSource49EditableArt" else "BeforeSource49StoredArt";preserved.Parent=archive
 older.Parent=preserved
 local built,w,counts=xpcall(function()return assembly.Apply(course,layout)end,debug.traceback)
 course.WorldPivot=pivot
 if not built then local partial=course.Decoration:FindFirstChild("Phase3World");if partial then partial.Name,partial.Parent=preserved.Name.."_Partial",archive end;older.Parent=course.Decoration;error(w)end
 course:SetAttribute("SourceRevision",49);course:SetAttribute("BuildRevision",43)
 course:SetAttribute("CandidateId",packet.candidate);course:SetAttribute("SourcePacketHash","7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca")
 w:SetAttribute("ArtRepairStage","FinishedCandidate49")
 local protected=P.Compare(if course.Parent==workspace then baseline.editable else baseline.stored,P.Capture(course));assert(protected.pass,"Protected course changed during art")
 local total={parts=0,meshes=0,colliders=0,floors=0,red=0,lights=0}
 for _,p in course:GetDescendants() do
  if p:IsA("BasePart") then total.parts+=1;if p:IsA("MeshPart")then total.meshes+=1 end;if p.CanCollide then total.colliders+=1 end
   if p:GetAttribute("MCWalkable")==true then total.floors+=1 end;if p:GetAttribute("MoonlitHazard")==true then total.red+=1 end
  elseif p:IsA("Light") then total.lights+=1 end
 end
 table.insert(reports,{path=course:GetFullName(),descendants=#course:GetDescendants(),total=total,world={units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles,mounts=#counts.plantingMounts}})
 task.wait()
end
return H:JSONEncode({ok=true,sourceRevision=49,buildRevision=43,sourcePacketHash="7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca",sources=sources,models=reports,httpRestored=H.HttpEnabled==httpBefore})