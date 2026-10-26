--!nonstrict
local RunService, Players, Http = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0)
local Control = require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local services = Control.Services()
local tools = game.ReplicatedStorage.MoonlitPhase2Tools
local report = {candidate = "MC_P2_C01_R06", evidenceKind = "Diagnostic ordinary Crown contact trace", events = {}}
local recent, course, hazards = {}, nil, {}
local function xyz(v) return {v.X, v.Y, v.Z} end
local function frame()
	local player = Players:GetPlayers()[1]
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local human = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not human or root.Position.Y < 400 then return end
	local body = {}
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 and part.CanQuery then
			body[#body + 1] = {part = part, name = part.Name, position = xyz(part.Position), frame = {part.CFrame:GetComponents()}, size = xyz(part.Size)}
		end
	end
	local value = {at = workspace:GetServerTimeNow(), root = xyz(root.Position), velocity = xyz(root.AssemblyLinearVelocity),
		humanoid = human:GetState().Name, health = human.Health, progress = player:GetAttribute("MCPhase2Progress"), body = {}}
	local parts = {}
	for _, row in body do parts[#parts + 1] = row.part; row.part = nil; value.body[#value.body + 1] = row end
	return value, parts
end
local function record(kind, hazard, actual, sample)
	if #report.events >= 200 then return end
	report.events[#report.events + 1] = {kind = kind, at = workspace:GetServerTimeNow(), hazard = hazard:GetFullName(),
		actual = actual, frame = sample, preceding = table.clone(recent), diagnostics = services.MoonlitCitadelService.GetDiagnostics()}
	tools:SetAttribute("R06CrownTraceEvents", #report.events)
end
RunService.Stepped:Connect(function()
	local active = workspace:FindFirstChild("RaceCourse")
	if active ~= course then
		course, hazards = active, {}
		if course then
			assert(course:GetAttribute("CandidateId") == report.candidate)
			for _, part in course:GetDescendants() do
				if part:IsA("BasePart") and part:GetAttribute("MoonlitHazard") == true and part.Parent.Name:find("CrownApproach_Hurdle") then
					hazards[#hazards + 1] = part
					part.Touched:Connect(function(hit)
						local player = Players:GetPlayerFromCharacter(hit.Parent)
						if player then record("Touched", part, {name = hit.Name, position = xyz(hit.Position)}, frame()) end
					end)
				end
			end
		end
	end
	if not course or not services.RaceService.IsRaceActive() then return end
	local sample, parts = frame()
	if not sample then return end
	recent[#recent + 1] = sample
	if #recent > 12 then table.remove(recent, 1) end
	local params = OverlapParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, parts
	for _, hazard in hazards do
		local hits = workspace:GetPartsInPart(hazard, params)
		if #hits > 0 then
			local actual = {}
			for _, part in hits do actual[#actual + 1] = {name = part.Name, position = xyz(part.Position)} end
			record("PreHeartbeatBodyOverlap", hazard, actual, sample)
		end
	end
end)
local previous
while script.Parent do
	local command = tools:GetAttribute("R06CrownTraceSave")
	if command and command ~= previous then
		previous = command
		report.endedAt = workspace:GetServerTimeNow()
		report.finalDiagnostics = services.MoonlitCitadelService.GetDiagnostics()
		tools:SetAttribute("R06CrownTraceSaved", Control.SaveReport(command, report))
	end
	task.wait(.1)
end
