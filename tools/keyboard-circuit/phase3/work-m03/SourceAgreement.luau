--!strict
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local c=workspace.KeyboardCircuit_P3_M03_01
local encoding=game:GetService("EncodingService")
local function hex(value) return (value:gsub(".",function(char)return string.format("%02x",string.byte(char))end)) end
local sources={}
local function add(item)
 local data=buffer.fromstring(item.Source)
 table.insert(sources,{path=item:GetFullName():gsub("^game%.",""),name=item.Name,class=item.ClassName,bytes=buffer.len(data),sha256=hex(buffer.tostring(encoding:ComputeBufferHash(data,Enum.HashAlgorithm.Sha256)))})
end
for _, item in c.SourceSnapshot:GetChildren() do add(item) end
add(game.ServerScriptService.Services.StudioDevService)
add(game.StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController)
add(game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview)
table.sort(sources,function(a,b)return a.path<b.path end)
local active, archived, disabled={}, {}, true
for _,item in workspace:GetChildren() do if item.Name:match("^KeyboardCircuit") then table.insert(active,item.Name) end end
local older=game.ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses
for _,item in older:GetChildren() do
 table.insert(archived,item.Name)
 for _,script in item:GetDescendants() do if script:IsA("BaseScript") and not script.Disabled then disabled=false end end
end
table.sort(archived)
local unrelated={}
for _,name in {"Lobby","GrandArcade","SGV2_Phase3_F04","ObstacleKit_Palette"} do
 local item=assert(workspace:FindFirstChild(name));local parts=0
 for _,part in item:GetDescendants() do if part:IsA("BasePart") then parts+=1 end end
 unrelated[name]={descendants=#item:GetDescendants(),parts=parts}
end
local origin=c:GetAttribute("Origin")
return game.HttpService:JSONEncode({candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),mapRevision=c:GetAttribute("MapRevision"),baseCourseRevision=c:GetAttribute("BaseCourseRevision"),layout=require(c.SourceSnapshot.Layout).Revision,origin={origin.X,origin.Y,origin.Z},descendants=#c:GetDescendants(),rows=sources,active=active,archived=archived,archivedScriptsDisabled=disabled,unrelated=unrelated,datamodel="Edit",boundary="Read-only intended experience identity, preserved owner placement, exact source bytes, one active course, scoped inert archives and unrelated map counts. No camera or computer control, publication, stored data, human pacing or FPS proof."})
