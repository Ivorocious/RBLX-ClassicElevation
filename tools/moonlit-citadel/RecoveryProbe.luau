assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer(), "Studio server only")
assert(game.PlaceId == 0 and game.GameId == 0, "Use the isolated local fixture")
local config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local root = workspace[config.BlenderRootName]
local player = game.Players:GetPlayers()[1]
local http = game:GetService("HttpService")
local results = {}
local function progress()
	for _, row in http:JSONDecode(root:GetAttribute("PreviewReport")).players do
		if row.userId == player.UserId then return row end
	end
	error("Player is not enrolled")
end
local function enter(area)
	root:SetAttribute("RequestedArea", area)
	root:SetAttribute("PreviewCommand", "Enter")
	task.wait(1)
	assert(root:GetAttribute("PreviewState") == "Running", root:GetAttribute("PreviewFailure"))
end
local function place(frame)
	local character = player.Character
	character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(frame)
end
local function contact(name, frame, expected)
	local before = progress().recoveries
	place(frame)
	task.wait(.65)
	local row = progress()
	local passed = row.recoveries == before + 1 and row.lastRecovery == expected
	table.insert(results, {name = name, passed = passed, before = before, progress = row, position = tostring(player.Character.HumanoidRootPart.Position)})
	assert(passed, name .. " did not produce the expected local recovery")
	task.wait(.85)
end
enter("LanternStudy")
local waitPart = root.LanternStudy.NormalWait1.PrimaryPart
place(CFrame.new(waitPart.Position + Vector3.new(0, 4, 0)))
task.wait(1)
local before = progress().recoveries
local litFrames, frames = 0, 0
local began = os.clock()
repeat
	task.wait(.03)
	local light = root.LanternStudy.SwingLanterns.SwingBand1.CageAndCore.MC_LanternCore:FindFirstChildWhichIsA("PointLight", true)
	assert(light and light.Enabled, "Moving lantern light is missing")
	frames += 1
	if (player.Character.HumanoidRootPart.Position - light.Parent.Position).Magnitude < light.Range then litFrames += 1 end
until os.clock() - began > 12.2
local row = progress()
local safe = row.recoveries == before and litFrames > 0
table.insert(results, {name = "MovingLightWithoutCageContact", passed = safe, seconds = 12.2, frames = frames, litFrames = litFrames, progress = row})
assert(safe, "Light-only waiting caused recovery or never entered light range")
local cage = root.LanternStudy.SwingLanterns.SwingBand1
local core = cage.CageAndCore.MC_LanternCore:FindFirstChildWhichIsA("BasePart", true)
contact("ImportedCoreContact", CFrame.new(core.Position), "LanternCage")
contact("ImportedCageEdgeContact", CFrame.new(cage.PrimaryPart.CFrame:PointToWorldSpace(Vector3.new(1.7, -.4, 0))), "LanternCage")
enter("UpperSample")
contact("NeonRedContact", root.UpperSample["NeonReset_-9"].PrimaryPart.CFrame, "RedContact")
local sampleOrigin = config.SampleOrigin + config.BlenderOffset
contact("FallOutsideRedCoverage", CFrame.new(sampleOrigin + Vector3.new(0, -23, 23)), "FallBounds")
contact("LateralMiss", CFrame.new(sampleOrigin + Vector3.new(85, 5, 23)), "FallBounds")
enter("RoughRoute")
place(root.RoughRoute.Finish.CFrame)
task.wait(.5)
row = progress()
local ordered = row.checkpoint == 0 and not row.finished
table.insert(results, {name = "FinishCannotSkipCheckpoints", passed = ordered, progress = row})
assert(ordered, "Unordered rough-route finish accepted")
local roughOrigin = config.RoughOrigin + config.BlenderOffset
contact("FallBeforeFirstCheckpoint", CFrame.new(roughOrigin + Vector3.new(-80, -24, 70)), "FallBounds")
enter("LanternStudy")
player:LoadCharacterAsync()
task.wait(1.3)
row = progress()
local position = player.Character.HumanoidRootPart.Position
local saved = config.LanternOrigin + config.BlenderOffset + Vector3.new(-8, 3, 0)
local replaced = row.checkpoint == 1 and row.area == "LanternStudy" and (position - saved).Magnitude < 2
table.insert(results, {name = "CharacterReplacementRetainsLocalCheckpoint", passed = replaced, progress = row, position = tostring(position)})
assert(replaced, "Character replacement lost local saved recovery")
return {candidate = root:GetAttribute("CandidateId"), setup = "Controlled server placement for contact/recovery checks; these are not traversal runs", tests = results}
