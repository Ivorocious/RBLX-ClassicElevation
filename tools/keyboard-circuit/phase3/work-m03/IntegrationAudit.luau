--!strict
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local storage, http = game.ServerStorage, game.HttpService
local course = workspace.KeyboardCircuit_P3_M03_01
local old = storage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses.KeyboardCircuit_P2_I09_Experience03
local original = storage.KCP2I09ExperienceNativeRecovery03.KeyboardCircuit_P2_I09_Experience03
local delta = Vector3.new(-20278, 0, 442)

local function relative(root: Instance, item: Instance): string
	return item:GetFullName():sub(#root:GetFullName() + 2)
end

local function signature(item: Instance): string
	local row = item.ClassName
	if item:IsA("BasePart") then
		for _, value in {item.Size.X,item.Size.Y,item.Size.Z,item.Color.R,item.Color.G,item.Color.B} do row ..= "|" .. string.format("%.3f", value) end
		row ..= "|" .. item.Material.Name .. "|" .. tostring(item.CanCollide) .. "|" .. tostring(item.CanQuery) .. "|" .. tostring(item.CanTouch)
		if item:IsA("MeshPart") then row ..= "|" .. item.MeshId .. "|" .. item.TextureID .. "|" .. item.CollisionFidelity.Name end
	elseif item:IsA("TextLabel") then row ..= "|" .. item.Text .. "|" .. tostring(item.TextColor3) .. "|" .. tostring(item.Visible)
	elseif item:IsA("SurfaceGui") then row ..= "|" .. tostring(item.Enabled)
	end
	return row
end

local failures, checked, maximumPositionError, maximumRotationError = {}, {}, 0, 0
for _, name in {"Districts", "RouteLinks", "ExpertRoutes", "Gates", "RecoveryPads", "CheckpointBays"} do
	local bag, count = {}, 0
	for _, item in old[name]:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("TextLabel") or item:IsA("SurfaceGui") then
			local key = relative(old[name], item) .. "|" .. signature(item)
			bag[key] = bag[key] or {}
			table.insert(bag[key], item)
			count += 1
		end
	end
	for _, item in course[name]:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("TextLabel") or item:IsA("SurfaceGui") then
			local key = relative(course[name], item) .. "|" .. signature(item)
			local bucket = bag[key]
			if not bucket or #bucket == 0 then
				if #failures < 15 then table.insert(failures, name .. "." .. key) end
			else
				local choice, minimum = 1, math.huge
				if item:IsA("BasePart") then
					for index, previous in bucket do
						local distance = (previous.Position-item.Position).Magnitude
						if distance < minimum then minimum, choice = distance, index end
					end
					local previous = bucket[choice]
					local rotation = math.max((previous.CFrame.RightVector-item.CFrame.RightVector).Magnitude, (previous.CFrame.UpVector-item.CFrame.UpVector).Magnitude)
					maximumPositionError = math.max(maximumPositionError, minimum)
					maximumRotationError = math.max(maximumRotationError, rotation)
					if minimum > .005 or rotation > .0001 then
						if #failures < 15 then table.insert(failures, name .. "." .. key .. ": pose") end
					end
				end
				table.remove(bucket, choice)
			end
		end
	end
	for key, bucket in bag do if #bucket > 0 and #failures < 15 then table.insert(failures, name .. ": missing " .. key) end end
	checked[name] = count
end
local sourceFailures = {}
for _, item in original.SourceSnapshot:GetChildren() do
	if course.SourceSnapshot[item.Name].Source ~= item.Source then table.insert(sourceFailures, item.Name) end
end

local function axes(cf: CFrame): {Vector3}
	return {cf.RightVector, cf.UpVector, -cf.LookVector}
end
local function extent(axis: Vector3, cf: CFrame, size: Vector3): number
	return math.abs(axis:Dot(cf.RightVector)) * size.X/2 + math.abs(axis:Dot(cf.UpVector)) * size.Y/2 + math.abs(axis:Dot(-cf.LookVector)) * size.Z/2
end
local function overlaps(a: CFrame, aSize: Vector3, b: CFrame, bSize: Vector3): boolean
	local all = axes(a)
	for _, axis in axes(b) do table.insert(all, axis) end
	for _, left in axes(a) do for _, right in axes(b) do local cross = left:Cross(right); if cross.Magnitude > .00001 then table.insert(all, cross.Unit) end end end
	for _, axis in all do
		if math.abs((b.Position-a.Position):Dot(axis)) >= extent(axis,a,aSize)+extent(axis,b,bSize)-.02 then return false end
	end
	return true
end

local contacts, artwork = {}, {}
local partCount, pressableCount, colliderCount = 0, 0, 0
for _, item in course:GetDescendants() do
	if item:IsA("BasePart") then
		partCount += 1
		if item:GetAttribute("Pressable") then pressableCount += 1 end
		if item.CanCollide then colliderCount += 1 end
		if (item.Name == "BankContact" or item.Name == "KeyContact") and item.CanCollide then table.insert(contacts,item) end
	end
end
for _, item in course.MapEnvironment:GetDescendants() do
	if item:IsA("BasePart") then
		assert(not item.CanCollide and not item.CanTouch and not item.CanQuery and not item:GetAttribute("Pressable"), "Artwork physics flag")
		table.insert(artwork, item)
	end
end
local spaceFailures = {}
for _, contact in contacts do
	local cf = contact.CFrame * CFrame.new(0, contact.Size.Y/2+4, 0)
	local size = Vector3.new(contact.Size.X+3,8,contact.Size.Z+3)
	for _, art in artwork do
		if art.Transparency < .9 and overlaps(cf,size,art.CFrame,art.Size) then
			table.insert(spaceFailures,{contact=relative(course,contact),art=relative(course,art)})
		end
	end
end
local recoveries = {}
for _, pad in course.RecoveryPads:GetChildren() do
	local spawn = pad.BankContact:GetAttribute("SpawnCFrame")
	local oldSpawn = old.RecoveryPads[pad.Name].BankContact:GetAttribute("SpawnCFrame")
	local restored = (spawn.Position - oldSpawn.Position - delta).Magnitude
	assert(restored < .005, "Owner placement recovery correction " .. pad.Name)
	table.insert(recoveries,{id=pad.Name,correctionError=restored,spawn={spawn.Position.X,spawn.Position.Y,spawn.Position.Z}})
end
local receipt = {
	candidate=course.Name,revision=course:GetAttribute("PrototypeRevision"),layout=course:GetAttribute("LayoutRevision"),
	geometryPassed=#failures==0,geometryFailures=failures,checked=checked,sourceFailures=sourceFailures,
	maximumPositionError=maximumPositionError,maximumRotationError=maximumRotationError,
	artworkPhysicsPassed=true,artworkParts=#artwork,parts=partCount,pressableCaps=pressableCount,colliders=colliderCount,
	bodyClearancePassed=#spaceFailures==0,bodyClearanceFailures=spaceFailures,contactsChecked=#contacts,recoveries=recoveries,
	boundary="Native Edit inspection. Baseline gameplay parts and text compared as duplicate-safe multisets with .005 stud position tolerance for rebuilding at the owner's moved origin; exact sixteen source texts unchanged. Added artwork has no collision, touch, query or press targets. 3-stud wider and 8-stud tall contact envelopes checked against complete new scenery, not a crowd or rendered-camera proof. Absolute recovery positions rebuilt at the preserved owner placement."
}
shared.KCP3M03Integration01=receipt
return http:JSONEncode(receipt)
