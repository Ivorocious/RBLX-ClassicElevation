--!nonstrict
local Check = {}
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local Http, ServerStorage = game:GetService("HttpService"), game:GetService("ServerStorage")
local busy = false
local function vector(p) return { p.X, p.Y, p.Z } end
local function top(part) return part.Position + part.CFrame.UpVector * part.Size.Y / 2 end
local function verticalBounds(part)
	local cf, size = part.CFrame, part.Size
	local half = (math.abs(cf.RightVector.Y)*size.X + math.abs(cf.UpVector.Y)*size.Y + math.abs(cf.LookVector.Y)*size.Z)/2
	return part.Position.Y-half, part.Position.Y+half
end
local function measuredGap(a,b)
	local separated = false
	for _,axis in {a.CFrame.RightVector,a.CFrame.LookVector,b.CFrame.RightVector,b.CFrame.LookVector} do
		local function radius(p) return math.abs(p.CFrame.RightVector:Dot(axis))*p.Size.X/2+math.abs(p.CFrame.LookVector:Dot(axis))*p.Size.Z/2 end
		if math.abs((b.Position-a.Position):Dot(axis))>radius(a)+radius(b) then separated=true end
	end
	if not separated then return 0 end
	local function corners(p)
		local out={}
		for _,sign in {{-1,-1},{1,-1},{1,1},{-1,1}} do
			local v=p.CFrame:PointToWorldSpace(Vector3.new(sign[1]*p.Size.X/2,0,sign[2]*p.Size.Z/2))
			table.insert(out,Vector3.new(v.X,0,v.Z))
		end
		return out
	end
	local aa,bb=corners(a),corners(b);local distance=math.huge
	for _,pair in {{aa,bb},{bb,aa}} do
		for _,point in pair[1] do
			for i=1,4 do
				local first,last=pair[2][i],pair[2][i%4+1];local line=last-first
				local alpha=math.clamp((point-first):Dot(line)/line:Dot(line),0,1)
				distance=math.min(distance,(point-first-line*alpha).Magnitude)
			end
		end
	end
	return distance
end
function Check.SelectedCases(course)
	local checkpoints={S1_Nestyard=0,E1_RimSprint=0,S2_EggRollers=1,E2_ChuteCut=1,S3_ShellApproach=2,E3_CrownApproach=2,
		S4_IncubatorApproach=2,S4_TrayApproachB=2,S4_ExitClimb=2,S5_Rookery=3,E4_RoostCut=3,S5_TailBand=3,S6_ShellSpill=4}
	local red,candidates,selected,used={},{},{},{}
	for _,part in course:GetDescendants() do
		local a,b=part:GetAttribute("ERPadName"),part:GetAttribute("ERNextPadName")
		if a and b then red[a..">"..b]=true end
	end
	for name,checkpoint in pairs(checkpoints) do
		local refs=course.Routes[name]:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
		for i=2,#refs do
			local a,b=refs[i-1].Value,refs[i].Value
			if red[a.Name..">"..b.Name] then continue end
			table.insert(candidates,{from=a.Name,to=b.Name,checkpoint=checkpoint,auditedGap=measuredGap(a,b),rise=top(b).Y-top(a).Y,route=name})
		end
	end
	table.sort(candidates,function(a,b)if math.abs(a.auditedGap-b.auditedGap)>.00001 then return a.auditedGap<b.auditedGap end;return a.from<b.from end)
	local function take(category,predicate)
		local chosen
		for _,row in candidates do
			if not used[row.from..">"..row.to] and predicate(row) then
				chosen=row;break
			end
		end
		assert(chosen,"No representative ordinary link for "..category)
		chosen=table.clone(chosen);chosen.category=category;used[chosen.from..">"..chosen.to]=true;table.insert(selected,chosen)
	end
	take("SmallestLevel",function(row)return math.abs(row.rise)<.01 end)
	take("RisingCrown",function(row)return row.route=="E3_CrownApproach"and row.rise>.1 end)
	take("SmallestRemainingRising",function(row)return row.rise>.1 end)
	take("SmallestDescending",function(row)return row.rise<-.1 end)
	take("SmallestExpertDescending",function(row)return row.route=="E4_RoostCut"and row.rise<-.1 end)
	return selected
end
local function inside(part, position)
	local p = part.CFrame:PointToObjectSpace(position)
	return math.abs(p.X) <= part.Size.X / 2 and math.abs(p.Z) <= part.Size.Z / 2
end
local function classify(reached, clearFall, recovered, controlValid, collision)
	if not controlValid then return "InvalidControl", false end
	if collision then return "InvalidCollision", false end
	if reached then return "WalkedAcrossWithoutJump", false end
	if clearFall then return "BlockedByClearFall", true end
	if recovered then return "UnexplainedRecovery", false end
	return "InconclusiveTimeout", false
end

function Check.Run(services, command)
	assert(RunService:IsStudio() and RunService:IsServer(), "Studio server no-jump checks only")
	assert(not busy, "No-jump checks already running")
	command = command or {}
	assert((command.expectedPlaceId or 85558151074819) == game.PlaceId, "Wrong Studio place")
	assert(command.expectedGameId == nil or command.expectedGameId == game.GameId, "Wrong Studio experience")
	local course = assert(services.CourseService.GetActiveCourse(), "Prepare the owned course first")
	local raceId = services.RaceService.GetCurrentRaceId()
	assert(course:IsDescendantOf(workspace) and course:GetAttribute("CourseId") == "egg_rush_circuit"
		and course:GetAttribute("EROwned") == true and services.RaceService.IsRaceActive() and raceId ~= "", "Wrong official course or race")
	local players = Players:GetPlayers(); table.sort(players, function(a, b) return a.UserId < b.UserId end)
	local player = assert(players[1], "Missing actual Player")
	local character = assert(player.Character)
	local root, humanoid = character.HumanoidRootPart, assert(character:FindFirstChildOfClass("Humanoid"))
	assert(not root.Anchored, "Test character must already be movable")
	local saved = { autoJump = humanoid.AutoJumpEnabled, ownershipAuto = root:GetNetworkOwnershipAuto(), owner = root:GetNetworkOwner() }
	local parent = ServerStorage:FindFirstChild("EggRushNativeNoJumpReceipts")
	if not parent then parent = Instance.new("Folder"); parent.Name = "EggRushNativeNoJumpReceipts"; parent.Parent = ServerStorage end
	local folder = Instance.new("Folder"); folder.Name = Http:GenerateGUID(false); folder.Parent = parent
	local stored = Instance.new("StringValue"); stored.Name = "Report"; stored.Parent = folder
	local report = { ok = false, cases = {}, setups = {}, userId = player.UserId, candidateId = course:GetAttribute("CandidateId"),
		placeId = game.PlaceId, gameId = game.GameId, raceId = raceId, limits = {
			"Five isolated direct center-to-center walking attempts on selected ordinary links; no claim about every gap or every possible approach angle",
			"One listed setup teleport per case and explicit inspection-checkpoint writes; no position, velocity, jump or movement boost during the walking attempt",
			"Auto-jump disabled temporarily; actual jumping, wrong support, other collisions, failed setup or unexplained recovery cannot count as a blocked-gap pass",
			"A clear fall can end a case before later recovery; receipts do not claim a full race or human/crowd/device/FPS validation",
		} }
	local began, movement = os.clock(), Vector3.zero
	local connection, stateConnection, jumpConnection, activeResult, activeStored
	local function persist() stored.Value = Http:JSONEncode(report) end
	folder:SetAttribute("State", "Running"); persist(); busy = true
	local function falls() return assert(services.ResultsService.GetPlayerResult(player), "Missing official result").falls or 0 end
	local function valid()
		local runtime = services.EggRushService.GetDiagnostics()
		return player.Parent == Players and player.Character == character and humanoid.Health > 0
			and services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
			and services.RaceService.GetCurrentRaceId() == raceId and runtime.bound and runtime.raceId == raceId
			and services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing"
			and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01
			and math.abs(workspace.Gravity - 196.2) < .01 and root:GetNetworkOwner() == nil and not root:GetNetworkOwnershipAuto()
			and not humanoid.AutoJumpEnabled
	end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { course }; params.RespectCanCollide = true
	local function standing()
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), params)
		return hit and hit.Instance
	end
	local ok, failure = xpcall(function()
		root:SetNetworkOwner(nil); humanoid.AutoJumpEnabled = false; humanoid.Jump = false
		assert(valid(), "Official Egg Rush16/7.2/196.2 profile, runtime and server control required")
		report.profile = { walk = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, usePower = humanoid.UseJumpPower,
			gravity = workspace.Gravity, autoJump = humanoid.AutoJumpEnabled, serverOwned = root:GetNetworkOwner() == nil }
		connection = RunService.PreSimulation:Connect(function() humanoid:Move(movement, false); humanoid.Jump = false end)
		for index, definition in ipairs(Check.SelectedCases(course)) do
			local result = { from = definition.from, to = definition.to, category = definition.category, auditedGap = definition.auditedGap,
				validAttempt = false, ok = false, classification = "SetupPending", states = {}, stateChanges = {}, samples = {}, unexpectedCollisions = {}, jumpCommands = 0 }
			report.cases[index] = result
			local caseStored = Instance.new("StringValue"); caseStored.Name = "Case" .. index; caseStored.Parent = folder
			activeResult, activeStored = result, caseStored
			local function saveCase() caseStored.Value = Http:JSONEncode(result); persist() end
			saveCase()
			local from, target = course.Obstacles:FindFirstChild(definition.from, true), course.Obstacles:FindFirstChild(definition.to, true)
			assert(from and target and from.Parent == target.Parent and from.Anchored and target.Anchored
				and from.CanCollide and target.CanCollide and typeof(from:GetAttribute("ERTop")) == "Vector3"
				and typeof(target:GetAttribute("ERTop")) == "Vector3" and not from:GetAttribute("ERSupport") and not target:GetAttribute("ERSupport"), "Selected ordinary pads changed")
			for _, part in ipairs(course:GetDescendants()) do
				assert(part:GetAttribute("ERPadName") ~= from.Name or part:GetAttribute("ERNextPadName") ~= target.Name, "Selected pair now crosses a red hazard")
			end
			assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, definition.checkpoint), "Inspection checkpoint setup failed")
			table.insert(report.setups, { kind = "InspectionCheckpoint", case = index, checkpoint = definition.checkpoint })
			movement = Vector3.zero; humanoid:Move(Vector3.zero, false); humanoid.Jump = false
			local position = top(from) + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + .15, 0)
			table.insert(report.setups, { kind = "InitialTeleport", case = index, position = vector(position), part = from:GetFullName() })
			character:PivotTo(CFrame.new(position)); root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
			local setupFalls, setupStart, stable = falls(), os.clock(), 0
			repeat
				RunService.Heartbeat:Wait(); assert(valid(), "Setup controls or official race changed")
				stable = if standing() == from and inside(from, root.Position) and humanoid.FloorMaterial ~= Enum.Material.Air
					and math.abs(root.AssemblyLinearVelocity.Y) < 2 then stable + 1 else 0
				assert(falls() == setupFalls and os.clock() - setupStart < 3, "Setup did not settle safely")
			until stable >= 2 and (character:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow()
			local start, initial, initialFalls = os.clock(), root.Position, falls()
			local invalidControl, reached, clearFall, recovered = false, false, false, false
			local targetStable, lastSample, seenCollisions = 0, -math.huge, {}
			result.validAttempt = true; result.classification = "Walking"; result.initial = vector(initial); result.rise = top(target).Y - top(from).Y
			result.maximumHeight, result.maximumRise, result.maximumUpwardVelocity = initial.Y, 0, 0
			stateConnection = humanoid.StateChanged:Connect(function(oldState, newState)
				table.insert(result.stateChanges, { seconds = os.clock() - start, from = oldState.Name, to = newState.Name, position = vector(root.Position) })
				if newState == Enum.HumanoidStateType.Jumping then invalidControl = true end
			end)
			jumpConnection = humanoid:GetPropertyChangedSignal("Jump"):Connect(function() if humanoid.Jump then invalidControl = true end end)
			local overlaps = OverlapParams.new(); overlaps.FilterType = Enum.RaycastFilterType.Include
			local others = { course }
			for _, other in ipairs(Players:GetPlayers()) do if other ~= player and other.Character then table.insert(others, other.Character) end end
			overlaps.FilterDescendantsInstances = others; overlaps.RespectCanCollide = false
			local bodies = {}
			for _, part in ipairs(character:GetChildren()) do if part:IsA("BasePart") and part.CanCollide then table.insert(bodies, part) end end
			assert(#bodies > 0, "No actual colliding avatar body for interference checks")
			local fromBottom,targetBottom=verticalBounds(from),verticalBounds(target)
			result.clearFallBoundary=math.min(fromBottom,targetBottom)-.1
			result.collidingBodies={}
			for _,body in bodies do table.insert(result.collidingBodies,{part=body.Name,size=vector(body.Size)})end
			repeat
				RunService.Heartbeat:Wait()
				if not valid() or humanoid.Jump or humanoid:GetState() == Enum.HumanoidStateType.Jumping then invalidControl = true end
				local elapsed, support = os.clock() - start, standing()
				local delta = top(target) - root.Position; local flat = Vector3.new(delta.X, 0, delta.Z)
				movement = if flat.Magnitude > .2 then flat.Unit else Vector3.zero
				local floor, state = humanoid.FloorMaterial ~= Enum.Material.Air, humanoid:GetState().Name
				result.states[state] = true
				result.maximumHeight = math.max(result.maximumHeight, root.Position.Y)
				result.maximumRise = math.max(result.maximumRise, root.Position.Y - initial.Y)
				result.maximumUpwardVelocity = math.max(result.maximumUpwardVelocity, root.AssemblyLinearVelocity.Y)
				for _, body in ipairs(bodies) do
					for _, hit in ipairs(workspace:GetPartsInPart(body, overlaps)) do
						if hit == from or hit == target or seenCollisions[hit] then continue end
						if hit.CanCollide or (hit:GetAttribute("ERLethal") == true and hit.Transparency < 1) then
							seenCollisions[hit] = true
							table.insert(result.unexpectedCollisions, { part = hit:GetFullName(), seconds = elapsed, position = vector(root.Position) })
						end
					end
				end
				local groundedTarget = support == target and floor and inside(target, root.Position) and math.abs(root.AssemblyLinearVelocity.Y) < 2
				targetStable = if groundedTarget then targetStable + 1 else 0; reached = targetStable >= 2
				recovered = falls() > initialFalls
				local colliderTop=-math.huge
				for _,body in bodies do local _,highest=verticalBounds(body);colliderTop=math.max(colliderTop,highest)end
				clearFall = support == nil and colliderTop < result.clearFallBoundary and root.AssemblyLinearVelocity.Y < -1
				if elapsed - lastSample >= .05 or reached or clearFall or recovered or invalidControl then
					lastSample = elapsed
					table.insert(result.samples, { seconds = elapsed, position = vector(root.Position), velocityY = root.AssemblyLinearVelocity.Y,
						state = state, floor = tostring(humanoid.FloorMaterial), support = support and support:GetFullName(), insideTarget = inside(target, root.Position),
						jump = humanoid.Jump, autoJump = humanoid.AutoJumpEnabled, targetDistance = flat.Magnitude, colliderTop=colliderTop, falls = falls() - initialFalls })
				end
				result.seconds = elapsed
			until reached or clearFall or recovered or invalidControl or #result.unexpectedCollisions > 0 or os.clock() - start >= 2.5
			movement = Vector3.zero; humanoid:Move(Vector3.zero, false); humanoid.Jump = false
			stateConnection:Disconnect(); stateConnection = nil; jumpConnection:Disconnect(); jumpConnection = nil
			result.targetReached, result.clearFall, result.recovered, result.additionalFalls = reached, clearFall, recovered, falls() - initialFalls
			result.classification, result.ok = classify(reached, clearFall, recovered, not invalidControl, #result.unexpectedCollisions > 0)
			result.validAttempt = not invalidControl and #result.unexpectedCollisions == 0 and (reached or clearFall)
			result.final = vector(root.Position); saveCase()
		end
		report.ok = #report.cases == 5
		for _, result in ipairs(report.cases) do report.ok = report.ok and result.ok and result.validAttempt end
	end, debug.traceback)
	if stateConnection then stateConnection:Disconnect() end
	if jumpConnection then jumpConnection:Disconnect() end
	if connection then connection:Disconnect() end
	busy = false
	local restoreOk, restoreFailure = pcall(function()
		if humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false; humanoid.AutoJumpEnabled = saved.autoJump end
		if root.Parent then if saved.ownershipAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(saved.owner) end end
	end)
	if not ok then
		report.ok = false; report.failure = failure
		if activeResult then
			activeResult.ok, activeResult.validAttempt, activeResult.classification, activeResult.failure = false, false, "InvalidSetupOrRunner", failure
			pcall(function() activeStored.Value = Http:JSONEncode(activeResult) end)
		end
	end
	if not restoreOk then report.ok = false; report.restoreFailure = tostring(restoreFailure) end
	report.seconds, report.receiptPath, report.requiresFreshPrepare = os.clock() - began, folder:GetFullName(), true
	local storedOk, storedFailure = pcall(persist)
	if not storedOk then report.receiptError = tostring(storedFailure) end
	folder:SetAttribute("State", if report.ok then "Complete" else "Failed")
	return report
end
return Check
