--!strict
local Parts = require(script.Parent.Parts)
local Layout = require(script.Parent.Layout)
local RouteStudy = {}

function RouteStudy.Build(parent: Instance, origin: Vector3): Model
	local study = Parts.Model(parent, "CheapWholeRouteStudy")
	study:SetAttribute("PlanningProofOnly", true)
	study:SetAttribute("MechanismsImplemented", "None; S02 and H06 proofs are separate")
	study:SetAttribute("TargetLaps", 3)
	study:SetAttribute("WorkingCapacity", 20)
	local platforms = {}
	for _,id in Layout.Main do
		local node = Layout.Nodes[id]
		local cp = id:sub(1, 2) == "CP" or id == "F00"
		local width, depth = if cp then 18 else 12, if cp then 16 else 10
		local unit = Parts.Model(study, id)
		local block = Parts.Block(unit, "StudySurface", Vector3.new(width, 1, depth), CFrame.new(origin + Vector3.new(node[1], node[2] - .5, node[3])), Parts.Palette[node[4]][1])
		Parts.Legend(block, id)
		unit.PrimaryPart = block
		unit:SetAttribute("SequenceId", id)
		if cp then unit:SetAttribute("RecoveryBay", true) end
		if cp then Parts.CheckpointFlag(unit, CFrame.new(origin + Vector3.new(node[1] - 7, node[2], node[3] + 6)), if id == "F00" then "LAP" else id) end
		platforms[id] = block
	end
	local links = Parts.Model(study, "OrderedNormalConnections")
	local function connect(from: string, to: string, branch: boolean)
		local a, b = platforms[from], platforms[to]
		local delta = b.Position - a.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		local distance = flat.Magnitude
		local count = math.max(1, math.ceil(distance / 10) - 1)
		for i = 1, count do
			local t = i / (count + 1)
			local center = a.Position:Lerp(b.Position, t)
			local width = if branch then 2.4 else 7
			local cf = CFrame.lookAt(center, center + flat.Unit)
			local part = Parts.Block(links, from .. "_to_" .. to .. "_" .. i, Vector3.new(width, 1, 6), cf, if branch then Parts.Palette.Thocky[2] else a.Color)
			part:SetAttribute("ConnectionFrom", from)
			part:SetAttribute("ConnectionTo", to)
			part:SetAttribute("StudyOnly", true)
			part:SetAttribute("ConnectionIndex", i)
		end
	end
	for i,from in Layout.Main do connect(from, Layout.Main[i % #Layout.Main + 1], false) end
	for _,branch in Layout.Branches do
		local node = Layout.Nodes[branch.id]
		local part = Parts.Block(study, branch.id, Vector3.new(3, 1, 3), CFrame.new(origin + Vector3.new(node[1], node[2] - .5, node[3])), Parts.Palette[node[4]][2])
		Parts.Legend(part, branch.id, nil, Color3.new(1, 1, 1))
		platforms[branch.id] = part
		connect(branch.from, branch.id, true)
		connect(branch.id, branch.before, true)
	end
	return study
end

return RouteStudy
