assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0 and game.GameId == 0)
assert(not game:GetService("RunService"):IsRunning(), "Install shared-flow seed in Edit")
local library = game.ServerStorage.CourseLibrary
assert(not library:FindFirstChild("Course_MoonlitCitadel_SharedFlowSeed"))
local origin = Vector3.new(4000, 300, 2600)
local course = Instance.new("Model")
course.Name = "Course_MoonlitCitadel_SharedFlowSeed"
course:SetAttribute("CourseId", "moonlit_citadel")
course:SetAttribute("CandidateId", "MC_P2_FLOW_SEED")
course:SetAttribute("IntegrationFixtureOnly", true)
local function folder(name)
	local item = Instance.new("Folder"); item.Name, item.Parent = name, course; return item
end
for _, name in {"CourseInfo", "Checkpoints", "Obstacles", "FallZones", "RouteMarkers", "Decoration", "Bounds"} do folder(name) end
for key, value in {CourseId="moonlit_citadel",DisplayName="Moonlit shared-flow test",RaceFormat="PointToPoint",LapCount=1,CheckpointCount=4,Enabled=true} do course.CourseInfo:SetAttribute(key,value) end
local function part(parent, name, point, size, collide, visible)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, CFrame.new(origin + point)
	item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, collide, true, true
	item.Transparency, item.Parent = if visible then 0 else 1, parent
	return item
end
part(course.Obstacles,"FlowTestFloor",Vector3.new(30,-1,0),Vector3.new(110,2,32),true,true)
local start = part(course,"Start",Vector3.new(0,3,0),Vector3.new(24,6,20),false)
start:SetAttribute("RespawnCFrame",CFrame.new(origin+Vector3.new(0,4,0)))
start:SetAttribute("RespawnAreaSize",Vector3.new(16,0,12))
for index=1,4 do
	local cp=part(course.Checkpoints,string.format("Checkpoint_%03d",index),Vector3.new(index*15,3,0),Vector3.new(10,6,18),false)
	cp:SetAttribute("CheckpointIndex",index)
	cp:SetAttribute("RespawnCFrame",CFrame.new(origin+Vector3.new(index*15,4,7)))
	cp:SetAttribute("RespawnAreaSize",Vector3.new(6,0,6))
end
part(course,"Finish",Vector3.new(78,3,0),Vector3.new(10,6,20),false)
part(course.FallZones,"FlowTestFall",Vector3.new(30,-12,0),Vector3.new(150,4,60),false)
course.Parent=library
return "Shared-flow seed installed; controlled integration proof only"
