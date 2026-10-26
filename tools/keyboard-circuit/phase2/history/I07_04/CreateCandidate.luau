--!strict
local RunService, Storage = game:GetService("RunService"), game:GetService("ServerStorage")
assert(RunService:IsStudio() and not RunService:IsRunning())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local name, holderName = "KeyboardCircuit_P2_I07_TimingFinal", "KCP2I07_TimingFinalSources"
assert(not workspace:FindFirstChild(name) and not Storage:FindFirstChild(holderName), "Inspect existing I07 before retry")
local inputs = assert(shared.KCP2I07FinalInputs)
local original = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local compact = assert(workspace:FindFirstChild("KeyboardCircuit_P2_PacingI06_01"))
shared.KCP2I07Preserved = {}
for _, course in {original, compact, assert(workspace:FindFirstChild("KeyboardCircuit_P2_I07")), assert(workspace:FindFirstChild("KeyboardCircuit_P2_I07_Final"))} do
 local texts = {}
 for _, item in course.SourceSnapshot:GetChildren() do texts[item.Name] = item.Source end
 shared.KCP2I07Preserved[course.Name] = {course=course, sources=texts}
end
local origin = Vector3.new(15000,330,-1600)
assert(#workspace:GetPartBoundsInBox(CFrame.new(origin),Vector3.new(600,150,540))==0,"I07 space occupied")
local holder = Instance.new("Folder")
holder.Name, holder.Parent = holderName, Storage
holder:SetAttribute("KCOwnedPhase2Preparation",true)
local sources = Instance.new("Folder")
sources.Name, sources.Parent = "Sources", holder
for sourceName, data in inputs do
 local item = Instance.new(data.class)
 item.Name, item.Source = sourceName, data.source
 if item:IsA("BaseScript") then item.Disabled = true end
 item.Parent = sources
end
assert(#sources:GetChildren()==16)
local template = assert(Storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey",true))
assert(template:IsA("MeshPart"))
local candidate = require(sources.Course).Build(holder,origin,template)
candidate.Name = name
candidate:SetAttribute("ConstructionIteration",7)
candidate:SetAttribute("PrototypeOnly",true)
candidate:SetAttribute("PrototypeRevision","KC_P2_I07_04")
local snapshot = sources:Clone()
snapshot.Name, snapshot.Parent = "SourceSnapshot", candidate
local sequenceCount, mechanismCount = 0,0
for _,item in candidate:GetDescendants() do
 if item:GetAttribute("SequenceId") then sequenceCount+=1 end
 if item:GetAttribute("MechanismId") then mechanismCount+=1 end
 if item:IsA("BaseScript") then assert(item.Disabled) end
end
assert(sequenceCount==16 and mechanismCount==8 and #candidate.ExpertRoutes:GetChildren()==4 and #candidate.RouteEdges:GetChildren()==29)
for _, saved in shared.KCP2I07Preserved do
 assert(saved.course.Parent == workspace)
 for _,item in saved.course.SourceSnapshot:GetChildren() do assert(item.Source==saved.sources[item.Name]) end
end
candidate.Parent = workspace
snapshot.Session.Disabled = false
shared.KCP2I07FinalBuild = {candidate=candidate, holder=holder, inputs=inputs}
return game:GetService("HttpService"):JSONEncode({created=true,course=candidate:GetFullName(),sources=#snapshot:GetChildren(),sequences=sequenceCount,mechanisms=mechanismCount,expertBranches=4,descendants=#candidate:GetDescendants(),preservedOriginals=4})
