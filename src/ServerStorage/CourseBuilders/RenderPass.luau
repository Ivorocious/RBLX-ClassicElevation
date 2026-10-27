--!strict
-- Edit-time render pass. Tiny decoration stops casting shadows, and chosen maps let meshes simplify at distance.
-- Plan only reports; Apply changes one map per undo step. Neither runs automatically.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local RenderPass = {}

RenderPass.Version = "2026-10-27"
RenderPass.MaxTinySide = 2
-- Very large meshes can visibly switch detail as the camera moves, so they keep Precise.
RenderPass.LargeMeshSide = 150

export type Target = {
	root: Instance,
	shadows: boolean,
	detail: boolean,
}

export type Report = {
	map: string,
	shadowParts: { BasePart },
	detailParts: { MeshPart },
	keptLargeMeshes: { MeshPart },
	tinySkipped: { [string]: number },
}

local GAMEPLAY_ATTRIBUTE_WORDS = { "Hazard", "Motion", "Conveyor", "Kit", "Phase", "Checkpoint" }
-- Moving obstacles keep their shadows so players can read the motion.
local GAMEPLAY_GROUP_NAMES = { Checkpoints = true, FallZones = true, OwnerEdits = true, Moving = true }

function RenderPass.Targets(): { Target }
	local library = ServerStorage:FindFirstChild("CourseLibrary")
	local function course(name: string): Instance?
		return if library then library:FindFirstChild(name) else nil
	end
	local wanted = {
		{ root = workspace:FindFirstChild("Lobby"), shadows = true, detail = true },
		{ root = course("Course_KeyboardCircuit"), shadows = true, detail = false },
		{ root = course("Course_StudGarden"), shadows = true, detail = false },
		{ root = course("Course_CityRun"), shadows = true, detail = false },
		{ root = course("Course_MoonlitCitadel"), shadows = false, detail = true },
	}
	local targets: { Target } = {}
	for _, entry in wanted do
		if entry.root ~= nil then
			table.insert(targets, entry :: Target)
		end
	end
	return targets
end

local function isGameplayMarked(instance: Instance): boolean
	if #CollectionService:GetTags(instance) > 0 then
		return true
	end
	for name in instance:GetAttributes() do
		for _, word in GAMEPLAY_ATTRIBUTE_WORDS do
			if string.find(name, word, 1, true) then
				return true
			end
		end
	end
	return false
end

local function isGameplayGroup(group: Instance, cache: { [Instance]: boolean }): boolean
	local known = cache[group]
	if known == nil then
		known = GAMEPLAY_GROUP_NAMES[group.Name] == true
			or string.find(group.Name, "Hazard", 1, true) ~= nil
			or isGameplayMarked(group)
		cache[group] = known
	end
	return known
end

local function insideGameplayGroup(part: BasePart, root: Instance, cache: { [Instance]: boolean }): boolean
	local ancestor = part.Parent
	while ancestor ~= nil and ancestor ~= root do
		if isGameplayGroup(ancestor, cache) then
			return true
		end
		ancestor = ancestor.Parent
	end
	return false
end

local function longestSide(part: BasePart): number
	local size = part.Size
	return math.max(size.X, size.Y, size.Z)
end

local function count(skipped: { [string]: number }, reason: string)
	skipped[reason] = (skipped[reason] or 0) + 1
end

function RenderPass.Plan(target: Target): Report
	local report: Report = {
		map = target.root:GetFullName(),
		shadowParts = {},
		detailParts = {},
		keptLargeMeshes = {},
		tinySkipped = {},
	}
	local groupCache: { [Instance]: boolean } = {}

	for _, part in target.root:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		if target.shadows and part.CastShadow and part.Transparency < 1 and longestSide(part) <= RenderPass.MaxTinySide then
			if part.CanCollide then
				count(report.tinySkipped, "standOn")
			elseif part.CanTouch then
				count(report.tinySkipped, "touch")
			elseif not part.Anchored then
				count(report.tinySkipped, "unanchored")
			elseif isGameplayMarked(part) or insideGameplayGroup(part, target.root, groupCache) then
				count(report.tinySkipped, "gameplay")
			else
				table.insert(report.shadowParts, part)
			end
		end

		if target.detail and part:IsA("MeshPart") and part.RenderFidelity == Enum.RenderFidelity.Precise then
			if longestSide(part) > RenderPass.LargeMeshSide then
				table.insert(report.keptLargeMeshes, part)
			else
				table.insert(report.detailParts, part)
			end
		end
	end

	return report
end

function RenderPass.Apply(target: Target): Report
	assert(not RunService:IsRunning(), "Stop Play before running the render pass")
	local report = RenderPass.Plan(target)
	local recording = ChangeHistoryService:TryBeginRecording("RenderPass " .. target.root.Name)
	assert(recording ~= nil, "Another Studio change is still recording; try again")

	local changed = 0
	local function step()
		changed += 1
		if changed % 500 == 0 then
			task.wait()
		end
	end
	for _, part in report.shadowParts do
		part.CastShadow = false
		step()
	end
	for _, mesh in report.detailParts do
		mesh.RenderFidelity = Enum.RenderFidelity.Automatic
		step()
	end
	target.root:SetAttribute("RenderPass", RenderPass.Version)

	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	return report
end

return RenderPass
