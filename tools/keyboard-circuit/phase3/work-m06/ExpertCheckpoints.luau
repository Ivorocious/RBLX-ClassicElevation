--!strict
local ExpertCheckpoints = {}
ExpertCheckpoints.Revision = "KC_P3_M06_01"

local routes = {
	X03 = {checkpoint = "Checkpoint_001", recovery = "R1", landings = 13},
	X02 = {checkpoint = "Checkpoint_005", recovery = "R3", landings = 12},
}

function ExpertCheckpoints.Apply(course: Model): Model
	assert(course:GetAttribute("CourseId") == "keyboard_circuit", "Keyboard Circuit required")
	assert(course:GetAttribute("SharedCourseRevision") == "KC_P3_M05_01", "Shared M05 course required")
	local plans = {}
	local seen = {}
	for _, route in course.Obstacles.ExpertRoutes:GetChildren() do
		local id = route:GetAttribute("ExpertId")
		local definition = routes[id]
		assert(definition and route:IsA("Model") and not seen[id], "Unexpected Expert route")
		seen[id] = true
		assert(route:GetAttribute("RecoveryCheckpoint") == definition.recovery, "Wrong Expert recovery bank")
		local checkpoint = course.Checkpoints:FindFirstChild(definition.checkpoint)
		assert(checkpoint and checkpoint:IsA("BasePart"), "Missing shared checkpoint")
		assert(checkpoint:GetAttribute("RecoveryGate") == definition.recovery, "Wrong shared checkpoint bank")
		assert(typeof(checkpoint:GetAttribute("RespawnCFrame")) == "CFrame", "Safe-bank pose missing")
		local contacts = {}
		for _, child in route:GetChildren() do
			local index = tonumber(child.Name:match("^PrecisionLanding(%d+)$"))
			if not index then continue end
			assert(child:IsA("Model") and index >= 1 and index <= definition.landings and not contacts[index], "Unexpected precision landing")
			local contact = child:FindFirstChild("KeyContact")
			assert(contact and contact:IsA("BasePart") and contact.Anchored and contact.CanCollide and contact:GetAttribute("Role") == "Walkable", "Precision support missing")
			contacts[index] = contact
		end
		for index = 1, definition.landings do
			local contact = assert(contacts[index], "Missing precision landing")
			table.insert(plans, {id = id, index = index, contact = contact, checkpoint = checkpoint, recovery = definition.recovery})
		end
		local existing = checkpoint:FindFirstChild("AlternateTriggers")
		assert(not existing or existing:IsA("Folder"), "AlternateTriggers must be a Folder")
	end
	assert(seen.X03 and seen.X02 and #plans == 25, "Both complete Expert routes required")
	for _, plan in plans do
		local checkpoint, contact = plan.checkpoint, plan.contact
		local folder = checkpoint:FindFirstChild("AlternateTriggers")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name, folder.Parent = "AlternateTriggers", checkpoint
		end
		local name = string.format("%s_%02d", plan.id, plan.index)
		local trigger = folder:FindFirstChild(name)
		if not trigger then
			trigger = Instance.new("Part")
			trigger.Name, trigger.Parent = name, folder
		end
		assert(trigger:IsA("Part"), "Expert trigger must be a Part")
		trigger.CFrame = contact.CFrame + Vector3.new(0, 3.5, 0)
		trigger.Size = Vector3.new(contact.Size.X, 7, contact.Size.Z)
		trigger.Anchored, trigger.Transparency = true, 1
		trigger.CanCollide, trigger.CanTouch, trigger.CanQuery, trigger.CastShadow = false, true, false, false
		trigger:SetAttribute("ExpertRouteId", plan.id)
		trigger:SetAttribute("PrecisionLandingIndex", plan.index)
		trigger:SetAttribute("CheckpointIndex", checkpoint:GetAttribute("CheckpointIndex"))
		trigger:SetAttribute("RecoveryGate", plan.recovery)
		-- Finishing a precision landing saves the corresponding permanent bank, never the small key.
		trigger:SetAttribute("RespawnCFrame", checkpoint:GetAttribute("RespawnCFrame"))
		trigger:SetAttribute("RespawnAreaSize", checkpoint:GetAttribute("RespawnAreaSize"))
	end
	course:SetAttribute("ExpertCheckpointRevision", ExpertCheckpoints.Revision)
	course:SetAttribute("ExpertCheckpointTriggers", #plans)
	course:SetAttribute("CandidateRevision", ExpertCheckpoints.Revision)
	course:SetAttribute("MapRevision", "KC_MAP_M06_01")
	return course
end

return ExpertCheckpoints
