--!strict
local Course = require(script.Parent.Course)
local Environment = require(script.Parent.Environment)
local Map = {}

function Map.Build(parent: Instance, origin: Vector3, template: MeshPart): Model
	local acceptedOrigin = Vector3.new(22500, 330, -1600)
	local root = Course.Build(parent, acceptedOrigin, template)
	local translation = origin - acceptedOrigin
	-- Generate precision curves at their accepted origin before relocating them.
	root:PivotTo(root:GetPivot() + translation)
	local worldPoints = {Origin=true, TopPosition=true, EntryPosition=true, ExitPosition=true, PrecisionStartPosition=true, PrecisionMergePosition=true}
	local worldFrames = {EncounterFrame=true, RestPivot=true, MotionPivot=true, SpawnCFrame=true}
	local instances = root:GetDescendants()
	table.insert(instances, root)
	for _, item in instances do
		for name, value in item:GetAttributes() do
			if worldPoints[name] then item:SetAttribute(name, value + translation)
			elseif worldFrames[name] then item:SetAttribute(name, value + translation) end
		end
		if item:IsA("Vector3Value") then item.Value += translation end
	end
	root.Name = "KeyboardCircuit_P3_M01_01"
	root:SetAttribute("PrototypeRevision", "KC_P3_M01_01")
	root:SetAttribute("CandidateRevision", "KC_P3_M01_01")
	root:SetAttribute("KCPhase2Revision", "KC_P3_M01_01")
	root:SetAttribute("MapRevision", "KC_MAP_M01_01")
	root:SetAttribute("BaseCourseRevision", "KC_P2_I09_03")
	root:SetAttribute("Phase3MapOnly", true)
	root:SetAttribute("PrototypeOnly", true)
	root:SetAttribute("ConstructionIteration", 1)
	-- Existing test entry and participant services use this compatibility flag.
	root:SetAttribute("Phase2Only", true)
	local reservations = root.RoughSurroundings
	reservations:SetAttribute("Purpose", "Inactive Phase 2 placement reservations; retained for recovery")
	for _, item in reservations:GetDescendants() do
		if item:IsA("BasePart") then
			item.Transparency, item.CanCollide, item.CanTouch, item.CanQuery, item.CastShadow = 1, false, false, false, false
			item:SetAttribute("Role", "HistoricalReservation")
		end
	end
	Environment.Build(root, origin, template)
	return root
end

return Map
