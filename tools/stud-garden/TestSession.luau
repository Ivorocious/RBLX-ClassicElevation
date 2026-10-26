--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.StudGardenConfig)
local Layout = require(script.Parent.Layout)
local Session = {}

local function vector(value: Vector3): {number}
	return {value.X, value.Y, value.Z}
end

function Session.Start()
	assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(), "Studio server only")
	assert(workspace:GetAttribute("StudGardenTestEnabled") == true, "Explicit test flag required")
	assert(not game.ServerStorage:FindFirstChild("StudGardenTestSession"), "Test session already exists")
	game.ReplicatedStorage.Remotes:WaitForChild("StudioDevControl", 30)
	local dev = require(game.ServerScriptService.Services.StudioDevService)
	local courseService = require(game.ServerScriptService.Services.CourseService)
	local checkpointService = require(game.ServerScriptService.Services.CheckpointService)
	local raceService = require(game.ServerScriptService.Services.RaceService)
	local playerRaceService = require(game.ServerScriptService.Services.PlayerRaceService)
	local hazards = require(game.ServerScriptService.Services.StudGardenService)
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local bridge = Instance.new("Folder")
	bridge.Name, bridge.Parent = "StudGardenTestSession", game.ServerStorage
	local layout = Layout.Get()
	local function snapshot(): any
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local course = courseService.GetActiveCourse()
		if not root or not root:IsA("BasePart") or not humanoid then return {ready=false} end
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, if course then {course} else {}
		params.RespectCanCollide = true
		local hit = workspace:Raycast(root.Position, -Vector3.yAxis * (humanoid.HipHeight + root.Size.Y/2 + 1), params)
		return {ready=true, position=vector(root.Position-Config.Origin), velocity=vector(root.AssemblyLinearVelocity), health=humanoid.Health, anchored=root.Anchored, speed=humanoid.WalkSpeed, jumpHeight=humanoid.JumpHeight, useJumpPower=humanoid.UseJumpPower, floor=tostring(humanoid.FloorMaterial), support=hit and hit.Instance:GetFullName(), checkpoint=checkpointService.GetLatestCheckpointIndex(player), state=raceService.GetRaceState(), status=playerRaceService.GetPlayerStatus(player), courseId=course and course:GetAttribute("CourseId"), diagnostics=hazards.GetDiagnostics(), serverTime=workspace:GetServerTimeNow(), onboardingReady=player:GetAttribute("OnboardingReady")}
	end
	local function place(payload: any): any
		assert(raceService.IsRaceActive() and courseService.GetActiveCourse():GetAttribute("CourseId") == Config.CourseId, "Stud Garden race required")
		local character = player.Character :: Model
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		if payload.checkpoint ~= nil then checkpointService.SetInspectionCheckpointForStudio(player, payload.checkpoint) end
		local position = Config.Origin + Vector3.new(payload.position[1], payload.position[2], payload.position[3]) + Vector3.yAxis * (humanoid.HipHeight + root.Size.Y/2 + 0.2)
		local forward = if payload.forward then Vector3.new(payload.forward[1], 0, payload.forward[3]) else Vector3.zAxis
		character:PivotTo(CFrame.lookAt(position, position+forward))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		root:SetNetworkOwnershipAuto()
		return snapshot()
	end
	local command = Instance.new("BindableFunction")
	command.Name, command.Parent = "Command", bridge
	local crowdResult = Instance.new("StringValue")
	crowdResult.Name, crowdResult.Parent = "CrowdResult", bridge
	local function crowdStudy(): any
		local tools = game.ServerStorage:FindFirstChild("StudGardenTestTools")
		assert(tools and tools:GetAttribute("StudGardenOwnedTest") == true, "Owned crowd test tools required")
		return require(tools.CrowdStudy)
	end
	command.OnInvoke = function(action: string, payload: any): any
		if action == "Snapshot" then return Http:JSONEncode(snapshot()) end
		if action == "StartCrowd" then
			assert(bridge:GetAttribute("CrowdBusy") ~= true, "A crowd case is already running")
			local study = crowdStudy()
			bridge:SetAttribute("CrowdBusy", true)
			crowdResult.Value = ""
			task.spawn(function()
				local ok, report = pcall(study.Run, payload.caseId, {Course=courseService.GetActiveCourse(), TemplatePlayer=player, Duration=payload.duration})
				crowdResult.Value = Http:JSONEncode(if ok then report else {status="error", error=tostring(report)})
				bridge:SetAttribute("CrowdBusy", false)
			end)
			return "started"
		end
		if action == "CrowdReport" then return crowdResult.Value end
		if action == "StopCrowd" then crowdStudy().Cleanup(); return "stopped" end
		if action == "Begin" then
			task.wait(0.2)
			local response = dev.HandleRequest(player, {action="Map", courseId=Config.CourseId})
			assert(response.ok, response.message)
			return Http:JSONEncode(response)
		end
		if action == "Place" then return Http:JSONEncode(place(payload)) end
		if action == "Layout" then
			local route = layout.traversal[payload or "main_main"]
			local result = {}
			for _, point in ipairs(route.waypoints) do table.insert(result, {id=point.id,sequenceId=point.sequenceId,kind=point.kind,position=vector(point.position),size=vector(point.size)}) end
			return Http:JSONEncode(result)
		end
		if action == "Recover" then return require(game.ServerScriptService.Services.RespawnService).RecoverPlayer(player, "StudGardenTestDeliberateRecovery") end
		if action == "Prepare" then
			dev.HandleRequest(player, {action="HoldLobby"})
			task.wait(0.2)
			return Http:JSONEncode(dev.HandleRequest(player, {action="OnboardingPreset", preset="Returning racer"}))
		end
		error("Unknown Stud Garden test action")
	end
	bridge:SetAttribute("Ready", true)
	bridge:SetAttribute("EvidenceScope", "Studio setup and observation; placement is not route-completion evidence")
end

return Session
