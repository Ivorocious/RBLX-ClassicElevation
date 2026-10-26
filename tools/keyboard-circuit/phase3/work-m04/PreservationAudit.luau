--!strict
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
assert(not game:GetService("RunService"):IsRunning())
local c = workspace:FindFirstChild("KeyboardCircuit_P3_M04_01") or game.ServerStorage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009.KeyboardCircuit_P3_M04_01
local old = game.ServerStorage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009.M02OwnerLiveBeforeTuning
local failures, checked, permitted = {}, 0, {}
local function relative(root: Instance, item: Instance): string
	return item:GetFullName():sub(#root:GetFullName() + 2)
end
local function find(root: Instance, path: string): Instance?
	local node = root
	for name in path:gmatch("[^%.]+") do
		node = node:FindFirstChild(name)
		if not node then return nil end
	end
	return node
end
local replacements = {}
for _, item in c:GetDescendants() do
	if item:IsA("BasePart") then
		local path=relative(c,item)
		replacements[path]=replacements[path] or {}
		table.insert(replacements[path],item)
	end
end
for _, item in old:GetDescendants() do
	if not item:IsA("BasePart") or not (item.CanCollide or item:GetAttribute("Role") == "Lethal" or item:GetAttribute("Pressable")) then continue end
	local path = relative(old, item)
	local arm = false
	if arm then table.insert(permitted, path); continue end
	local bucket, replacement, choice = replacements[path], nil, nil
	local distance = math.huge
	for index, part in bucket or {} do
		local value = (item.Position-part.Position).Magnitude
		if value < distance then distance,replacement,choice=value,part,index end
	end
	if choice then table.remove(bucket,choice) end
	checked += 1
	if not replacement or not replacement:IsA("BasePart") then table.insert(failures, path .. ": missing"); continue end
	if (item.Position-replacement.Position).Magnitude > .005 or (item.Size-replacement.Size).Magnitude > .005
		or (item.CFrame.RightVector-replacement.CFrame.RightVector).Magnitude > .0001
		or (item.CFrame.UpVector-replacement.CFrame.UpVector).Magnitude > .0001
		or item.CanCollide ~= replacement.CanCollide or item.CanQuery ~= replacement.CanQuery or item.CanTouch ~= replacement.CanTouch
		or item:GetAttribute("Role") ~= replacement:GetAttribute("Role") or item:GetAttribute("PressDepth") ~= replacement:GetAttribute("PressDepth") then
		table.insert(failures, path .. ": physical/press change")
	end
end
for _, name in {"ConfigSnapshot", "Course", "Parts", "Layout", "Motion", "Mechanisms", "Progression", "Session", "ForwardGate"} do
	if c.SourceSnapshot[name].Source ~= old.SourceSnapshot[name].Source then table.insert(failures, "Unexpected gameplay source change: " .. name) end
end
local Art = require(c.SourceSnapshot.EnvironmentParts)

local function envelope(source, frame, size)
    local box = {CFrame=frame,Size=size,Position=frame.Position}
    function box:GetFullName() return source:GetFullName()..":CosmeticEnvelope" end
    return box
end
local function collectArt(course)
    local result={}
    for _,item in course.MapEnvironment:GetDescendants() do
        if item:IsA("BasePart") and item.Transparency < .9 then table.insert(result,item)
        elseif typeof(item:GetAttribute("MaxEffectFrame"))=="CFrame" and typeof(item:GetAttribute("MaxEffectSize"))=="Vector3" then
            table.insert(result,envelope(item,item:GetAttribute("MaxEffectFrame"),item:GetAttribute("MaxEffectSize")))
        elseif item:IsA("BasePart") and item:GetAttribute("ArchiveEffectKind") and item:GetAttribute("ArchiveEffectKind")~="Depth" then
            table.insert(result,envelope(item,item.CFrame,item.Size))
        end
    end
    return result
end

local bracket = c.Districts.S03_ClackyCarriage.O05
local bracketRows = {}
for _, pair in {{bracket.BracketLeft, "TopArm"}, {bracket.BracketRight, "BottomArm"}} do
	local main, arm = pair[1], pair[1][pair[2]]
	local keys, overlaps = {}, 0
	for _, key in main:GetDescendants() do if key:IsA("MeshPart") and key:GetAttribute("Pressable") then table.insert(keys, key) end end
	for i = 1, #keys do for j = i + 1, #keys do
		if Art.Overlaps(keys[i].CFrame, keys[i].Size, keys[j].CFrame, keys[j].Size) then overlaps += 1 end
	end end
	assert(#keys == 22 and overlaps == 0, main.Name .. ": duplicate/intersecting cap grids")
	assert(arm:GetAttribute("Columns") == 1 and arm:GetAttribute("Rows") == 2)
	table.insert(bracketRows, {bank=main.Name, caps=#keys, intersectingPairs=overlaps, extensionCells=2})
end
local artParts, newColliders, pressTargets, mechanisms, encounters = 0, 0, 0, 0, 0
local contacts, artwork, spaceFailures = {}, {}, {}
for _, item in c:GetDescendants() do
	if item:IsA("BasePart") and item:GetAttribute("Pressable") then pressTargets += 1 end
	if item:GetAttribute("MechanismId") then mechanisms += 1 end
	if item:GetAttribute("SequenceId") then encounters += 1 end
	if item:IsA("BasePart") and item.CanCollide and (item.Name=="BankContact" or item.Name=="KeyContact") then table.insert(contacts,item) end
end
for _, item in c.MapEnvironment:GetDescendants() do
	if item:IsA("BasePart") then
		artParts += 1
		
		if not item.Anchored or item.CanCollide or item.CanTouch or item.CanQuery or item:GetAttribute("Pressable") then
			newColliders += 1; table.insert(failures, relative(c, item) .. ": interactive artwork")
		end
	end
end
artwork = collectArt(c)
for _, contact in contacts do
	local frame=contact.CFrame*CFrame.new(0,contact.Size.Y/2+4,0)
	local size=Vector3.new(contact.Size.X+3,8,contact.Size.Z+3)
	for _, art in artwork do if Art.Overlaps(frame,size,art.CFrame,art.Size) then
		table.insert(spaceFailures,{contact=relative(c,contact),art=relative(c,art)})
	end end
end
for _, failure in spaceFailures do table.insert(failures,failure.contact..": body/headroom intersects "..failure.art) end
assert(pressTargets == 2989 and mechanisms == 8 and encounters == 16)
assert(c:GetAttribute("RequiredLaps") == 2 and #c.ExpertRoutes:GetChildren() == 2 and #c.RecoveryPads:GetChildren() == 8)
local unrelated = {}
for name, expected in {Lobby={2356,1243},GrandArcade={424,281},SGV2_Phase3_F04={8795,8015},ObstacleKit_Palette={499,369}} do
	local model, parts = assert(workspace:FindFirstChild(name)), 0
	for _, item in model:GetDescendants() do if item:IsA("BasePart") then parts += 1 end end
	unrelated[name] = {descendants=#model:GetDescendants(),parts=parts}
	if #model:GetDescendants() ~= expected[1] or parts ~= expected[2] then table.insert(failures, name .. ": scope count changed") end
end
local result = {passed=#failures==0,candidate=c.Name,revision=c:GetAttribute("CandidateRevision"),unchangedPhysicalAndPressParts=checked,
	intentionalBracketReplacements=#permitted,brackets=bracketRows,pressTargets=pressTargets,mechanisms=mechanisms,encounters=encounters,
	artParts=artParts,interactiveArtParts=newColliders,unrelated=unrelated,failures=failures,contactEnvelopes=#contacts,bodyClearanceFailures=spaceFailures,
	boundary="Native Edit comparison against owner live M02 recovery. Physical and pressed parts, progression and motion sources are preserved. Artwork counts are not FPS or crowd proof."}
shared.KCP3M04Preservation01 = result
return game.HttpService:JSONEncode(result)
