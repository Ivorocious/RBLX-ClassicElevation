-- Run in Edit on isolated copies before installing C01 into the owner's lobby.
local Test = {}

local function geometryCopy(source: Instance): Instance?
	local copy: Instance
	if source:IsA("BasePart") then
		copy = source:Clone()
		for _, child in copy:GetDescendants() do
			if child:IsA("LuaSourceContainer") or child:IsA("Humanoid") then child:Destroy() end
		end
	elseif source:IsA("Model") or source:IsA("Folder") then
		copy = Instance.new(source.ClassName)
		for _, child in source:GetChildren() do
			local copiedChild = geometryCopy(child)
			if copiedChild then copiedChild.Parent = copy end
		end
		if source:IsA("Model") then (copy :: Model).WorldPivot = source:GetPivot() end
	else
		return nil
	end
	copy.Name = source.Name
	return copy
end

function Test.Run(connection, lobby: Model, stage: Model, import: Model)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	assert(game.PlaceId == 85558151074819)
	assert(not lobby:FindFirstChild("GrandArcadeConnection"), "Run before native installation")
	local fixture = Instance.new("Folder")
	fixture.Name, fixture.Parent = "__GrandArcadeConnectionRecoveryFixture", game:GetService("ServerStorage")
	local ownedLobby, ownedStage = geometryCopy(lobby) :: Model, geometryCopy(stage) :: Model
	ownedLobby.Name, ownedLobby.Parent = "LobbyCopy", fixture
	ownedStage.Name, ownedStage.Parent = "StageCopy", fixture
	local recovery = Instance.new("Folder")
	recovery.Name, recovery.Parent = "Recovery", fixture
	local report = {
		kind = "Native recovery and preflight fixture on isolated Edit copies; no walking proof",
		checks = {}, failures = {}, ownerGeometryMutated = false,
	}
	local function check(name, condition)
		table.insert(report.checks, {name = name, passed = condition == true})
		if condition ~= true then table.insert(report.failures, name) end
	end
	local function saved(value)
		return {
			value = value, parent = value.Parent, name = value.Name, frame = value.CFrame, size = value.Size,
			color = value.Color, material = value.Material, transparency = value.Transparency,
			anchored = value.Anchored, collide = value.CanCollide, query = value.CanQuery, touch = value.CanTouch,
			reflectance = value.Reflectance, shadow = value.CastShadow,
			mesh = if value:IsA("MeshPart") then value.MeshId else nil,
			texture = if value:IsA("MeshPart") then value.TextureID else nil,
		}
	end
	local function sameProperties(row)
		local value = row.value
		return value.Name == row.name and value.CFrame == row.frame and value.Size == row.size
			and value.Color == row.color and value.Material == row.material and value.Transparency == row.transparency
			and value.Anchored == row.anchored and value.CanCollide == row.collide and value.CanQuery == row.query
			and value.CanTouch == row.touch and value.Reflectance == row.reflectance and value.CastShadow == row.shadow
			and (not value:IsA("MeshPart") or value.MeshId == row.mesh and value.TextureID == row.texture)
	end
	local ok, failure = xpcall(function()
		local executableCount = 0
		for _, value in fixture:GetDescendants() do
			if value:IsA("LuaSourceContainer") or value:IsA("Humanoid") then executableCount += 1 end
		end
		check("Geometry copies contain no scripts or humanoids", executableCount == 0)
		local data = connection.Inspect(ownedLobby, ownedStage)
		check("Thirty-five originals validated before installation", #data.originals == 35)
		check("All twenty lamp parts validated together", #data.lamps == 20)
		local originals = {}
		for _, value in data.originals do table.insert(originals, saved(value)) end
		local stagePivot = ownedStage:GetPivot()
		local candidate = connection.Ensure(ownedLobby, ownedStage, import, recovery)
		check("Stage position preserved", ownedStage:GetPivot() == stagePivot)
		check("Connection installed only in isolated lobby", candidate.Parent == ownedLobby)
		local archive = recovery:FindFirstChild("C01")
		check("Recovery records every original", archive and archive:GetAttribute("OriginalCount") == 35 and #archive:GetChildren() == 35)
		local changedOriginals = 0
		for _, row in originals do
			if not sameProperties(row) then changedOriginals += 1 end
			check("Original archived unchanged: " .. row.name, row.value:IsDescendantOf(archive) and sameProperties(row))
		end
		check("No original properties modified", changedOriginals == 0)
		local moved = candidate:FindFirstChild("RepositionedLamps")
		check("Twenty lamp copies installed", moved and #moved:GetChildren() == 20)
		local pads = candidate:FindFirstChild("LampFootings")
		check("Two visible non-colliding lamp footings", pads and #pads:GetChildren() == 2)
		for _, pad in pads:GetChildren() do
			check("Lamp footing follows measured ramp: " .. pad.Name, pad:IsA("BasePart")
				and pad.Transparency == 0 and not pad.CanCollide and not pad.CanQuery and not pad.CanTouch
				and math.abs(pad.Position.Y+pad.Size.Y/2-371.575) < .001
				and math.abs(pad.Position.Z+900) < .001)
		end
		for _, row in data.lamps do
			local copy = moved:FindFirstChild(row.original.Name)
			check("Exact shared lamp offset: " .. row.original.Name,
				copy and copy:IsA("BasePart") and copy.CFrame == row.original.CFrame + row.offset
				and copy.Size == row.original.Size and copy.Color == row.original.Color and copy.Material == row.original.Material
				and copy.CanCollide == row.original.CanCollide and copy.CanQuery == row.original.CanQuery)
		end
		local repeatCandidate = connection.Ensure(ownedLobby, ownedStage, import, recovery)
		check("Repeated Ensure is idempotent", repeatCandidate == candidate and #moved:GetChildren() == 20 and #archive:GetChildren() == 35)
		connection.Restore(ownedLobby, recovery)
		check("Only own candidate parked in recovery", candidate.Parent == recovery and not ownedLobby:FindFirstChild("GrandArcadeConnection"))
		for _, row in originals do check("Restore exact parent and properties: " .. row.name, row.value.Parent == row.parent and sameProperties(row)) end
		local incomplete = ownedStage.Collision:FindFirstChild("LampPost130")
		incomplete.Parent = fixture
		local badOk = pcall(connection.Ensure, ownedLobby, ownedStage, import, recovery)
		check("Missing twentieth lamp part stops preflight", not badOk and not recovery:FindFirstChild("C01") and not ownedLobby:FindFirstChild("GrandArcadeConnection"))
		incomplete.Parent = ownedStage.Collision
		for _, row in originals do check("Failed preflight leaves originals unchanged: " .. row.name, row.value.Parent == row.parent and sameProperties(row)) end
	end, debug.traceback)
	if not ok then table.insert(report.failures, tostring(failure)) end
	report.passed = #report.failures == 0
	report.limitations = "Edit-mode clone fixture proves recoverability and idempotence only; native final appearance and actual player traversal are separate."
	fixture:Destroy()
	return report
end

return Test
