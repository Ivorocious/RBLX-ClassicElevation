--!strict
local R,H,E=game:GetService("RunService"),game:GetService("HttpService"),game:GetService("EncodingService")
assert(R:IsStudio() and not R:IsRunning() and game.PlaceId==85558151074819 and game.GameId==10191126818)
local c=workspace.KeyboardCircuit_P2_I09_Experience03
assert(c:GetAttribute("PrototypeRevision")=="KC_P2_I09_03" and c:GetAttribute("RequiredLaps")==2)
local rows={}
local function add(s)
 local sha=buffer.tostring(E:ComputeBufferHash(buffer.fromstring(s.Source),Enum.HashAlgorithm.Sha256)):gsub(".",function(ch)return string.format("%02x",string.byte(ch))end)
 table.insert(rows,{name=s.Name,path=s:GetFullName(),sha256=sha,bytes=#s.Source,class=s.ClassName})
end
for _,s in c.SourceSnapshot:GetChildren() do if s:IsA("LuaSourceContainer") then add(s) end end
add(game.ServerScriptService.Services.StudioDevService)
add(game.StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController)
add(game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview)
table.sort(rows,function(a,b)return a.path<b.path end)
assert(#rows==19)
local count=0
for _,v in workspace:GetChildren() do if v.Name:match("^KeyboardCircuit_") and v:IsA("Model") then count+=1 end end
assert(count==1)
local function partCount(model)
 local count=0
 for _,v in model:GetDescendants() do if v:IsA("BasePart") then count+=1 end end
 return count
end
local unrelated={}
for _,name in {"Lobby","GrandArcade","SGV2_Phase3_F04","ObstacleKit_Palette"} do unrelated[name]=partCount(assert(workspace:FindFirstChild(name))) end
assert(unrelated.Lobby==1243 and unrelated.GrandArcade==281 and unrelated.SGV2_Phase3_F04==8015 and unrelated.ObstacleKit_Palette==369)
local archived={}
for _,old in game.ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses:GetChildren() do
 for _,v in old:GetDescendants() do if v:IsA("BaseScript") then assert(v.Disabled) end end
 table.insert(archived,old.Name)
end
assert(#archived==12)
local start=c.CheckpointBays.F00.BankContact.Position
local expected=c.CheckpointBays.F00:GetAttribute("TopPosition")-Vector3.new(0,.575,0)
local offset=(start-expected).Magnitude
assert(offset<.001)
local result={candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),layout=require(c.SourceSnapshot.Layout).Revision,datamodel="Edit",rows=rows,passed=true,
 requiredLaps=2,workspaceCourseCount=count,parts=partCount(c),descendants=#c:GetDescendants(),placementOffset=offset,unrelatedPartCounts=unrelated,archived=archived,
 boundary="Read-only Edit-mode identity, placement, preserved scope and source agreement. Only one Keyboard Circuit course in Workspace; older courses remain inert in ServerStorage. No FPS, human pacing or owner acceptance claim."}
return H:JSONEncode(result)
