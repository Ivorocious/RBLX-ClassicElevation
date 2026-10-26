-- Read-only Edit-mode checks for the C09 preservation and editable-component contract.
-- Run `require(thisModule).Run()` from the Studio command bar or Luau executor.
local Test = {}

local function countDescendants(root, predicate)
	local count = 0
	for _, item in root:GetDescendants() do
		if predicate(item) then
			count += 1
		end
	end
	return count
end

local function componentStats(root)
	local models = 0
	local parts = 0
	local missingEditable = 0
	local missingSection = 0
	local badPhysics = 0
	local collidable = 0

	for _, item in root:GetDescendants() do
		if item:IsA("Model") then
			models += 1
			if item:GetAttribute("EditableUnit") ~= true then
				missingEditable += 1
			end
			if item:GetAttribute("Section") == nil then
				missingSection += 1
			end
		elseif item:IsA("BasePart") then
			parts += 1
			if not item.Anchored or not item.CanQuery or item.CanTouch then
				badPhysics += 1
			end
			if item.CanCollide then
				collidable += 1
			end
		end
	end

	return {
		models = models,
		parts = parts,
		missingEditable = missingEditable,
		missingSection = missingSection,
		badPhysics = badPhysics,
		collidable = collidable,
	}
end

local function findComponentRoot(course, depthRoot, name)
	local rules = {
		{ prefix = "BranchDirections2_", root = course.Decoration.BranchDirections2 },
		{ prefix = "BranchDirections4_", root = course.Decoration.BranchDirections4 },
		{ prefix = "BranchDirections8_", root = course.Decoration.BranchDirections8 },
		{ prefix = "MarketCloseFronts_", root = course.Decoration.MarketCloseFronts },
		{ prefix = "MarketArch_", root = course.Decoration.MarketEditableProps.MarketArch },
		{ prefix = "OwnerFacade_", root = course.OwnerEdits.OwnerCourtyardBuilding.EditableFacade },
	}

	for _, rule in rules do
		if string.sub(name, 1, #rule.prefix) == rule.prefix then
			return rule.root, string.sub(name, #rule.prefix + 1)
		end
	end

	if string.sub(name, 1, #"CourtyardDepth_") == "CourtyardDepth_"
		or string.sub(name, 1, #"GroundRing_") == "GroundRing_" then
		return depthRoot, name
	end

	return nil, nil
end

function Test.Run()
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and not RunService:IsRunning(), "C09 preservation audit requires Studio Edit mode")
	assert(game.PlaceId == 85558151074819, "Unexpected experience")

	local course = assert(workspace:FindFirstChild("Course_CityRun"), "Course_CityRun is missing")
	local revision = course:GetAttribute("CityRunRevision")
	local reviewBuildId = course:GetAttribute("ReviewBuildId")
	assert(revision == "C09", "Expected CityRunRevision C09")
	assert(reviewBuildId == "C09_05_Park", "Expected final C09 park review build")
	assert(course:GetAttribute("ManualEditing") == true, "ManualEditing flag is missing")
	assert(course:GetAttribute("EditableSurfaceCount") == 209, "EditableSurfaceCount changed")

	local obstacles = assert(course:FindFirstChild("Obstacles"), "Obstacles folder is missing")
	local walkingSurfaces = assert(obstacles:FindFirstChild("WalkingSurfaces"), "WalkingSurfaces folder is missing")
	local walkingModels = 0
	local walkingParts = 0
	local walkingPrimaryMissing = 0
	local walkingCollidableModels = 0
	for _, model in walkingSurfaces:GetChildren() do
		if model:IsA("Model") then
			walkingModels += 1
			if model.PrimaryPart == nil then
				walkingPrimaryMissing += 1
			end
			local hasCollidablePart = false
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") then
					walkingParts += 1
					if item.CanCollide then
						hasCollidablePart = true
					end
				end
			end
			if hasCollidablePart then
				walkingCollidableModels += 1
			end
		end
	end
	assert(walkingModels == 209, "Walking-surface model count changed")
	assert(walkingParts == 1231, "Walking-surface BasePart count changed")
	assert(walkingPrimaryMissing == 0, "A walking-surface model has no PrimaryPart")
	assert(walkingCollidableModels == 209, "A walking-surface model lost its collidable part")

	local checkpoints = assert(course:FindFirstChild("Checkpoints"), "Checkpoints folder is missing")
	local checkpointCount = 0
	for index = 1, 9 do
		local checkpoint = checkpoints:FindFirstChild(string.format("Checkpoint_%03d", index))
		assert(checkpoint and checkpoint:IsA("BasePart"), "Checkpoint order or name changed")
		checkpointCount += 1
	end
	assert(#checkpoints:GetChildren() == checkpointCount, "Unexpected checkpoint child")

	local ownerKillStrips = assert(obstacles:FindFirstChild("OwnerKillStrips"), "OwnerKillStrips folder is missing")
	local killParts = 0
	local totalKillGroupParts = 0
	for _, item in ownerKillStrips:GetDescendants() do
		if item:IsA("BasePart") then
			totalKillGroupParts += 1
			if item:GetAttribute("HazardType") == "Kill" then
				killParts += 1
				assert(item.CanTouch and item.CanQuery, "A kill part lost touch or query")
			end
		end
	end
	assert(killParts == 15, "HazardType=Kill count changed from final C09 arrangement")
	assert(totalKillGroupParts == 18, "OwnerKillStrips physical BasePart count changed from final C09 arrangement")

	local invisibleWalls = assert(course.OwnerEdits:FindFirstChild("InvisibleWalls"), "InvisibleWalls folder is missing")
	assert(countDescendants(invisibleWalls, function(item)
		return item:IsA("BasePart")
	end) == 10, "Invisible-wall count changed")

	local ownerBuilding = assert(course.OwnerEdits:FindFirstChild("OwnerCourtyardBuilding"), "OwnerCourtyardBuilding is missing")
	for _, name in {
		"CourtStairBase__Brick__00",
		"CourtStairBase__Cream__00",
		"CourtStairBase__Roof__00",
		"CourtStairBase__Stone__00",
	} do
		local part = ownerBuilding:FindFirstChild(name)
		assert(part and part:IsA("BasePart"), "Original owner-building part is missing: " .. name)
	end

	local archive = assert(game:GetService("ServerStorage"):FindFirstChild("CityRun_C09_Archive"), "C09 archive is missing")
	local replaced = assert(archive:FindFirstChild("ReplacedMergedGeometry"), "C09 replacement archive is missing")
	for name, expectedParts in {
		BranchDirections2 = 4,
		BranchDirections4 = 4,
		BranchDirections8 = 4,
		MarketCloseFronts = 11,
		MarketArch = 3,
	} do
		local root = assert(replaced:FindFirstChild(name), "Archived original is missing: " .. name)
		local parts = countDescendants(root, function(item)
			return item:IsA("BasePart")
		end)
		assert(parts == expectedParts, "Archived original changed: " .. name)
	end

	local depthRoot = course.Decoration:FindFirstChild("CourtyardDepth") or archive:FindFirstChild("CourtyardDepth")
	assert(depthRoot, "CourtyardDepth is missing from the live course and archive")
	local depthStats = componentStats(depthRoot)
	assert(depthStats.models == 43 and depthStats.parts == 81, "CourtyardDepth component count changed")

	local componentRoots = {
		BranchDirections2 = course.Decoration.BranchDirections2,
		BranchDirections4 = course.Decoration.BranchDirections4,
		BranchDirections8 = course.Decoration.BranchDirections8,
		MarketCloseFronts = course.Decoration.MarketCloseFronts,
		MarketArch = course.Decoration.MarketEditableProps.MarketArch,
		OwnerFacade = ownerBuilding.EditableFacade,
	}
	local expectedStats = {
		BranchDirections2 = { models = 14, parts = 14 },
		BranchDirections4 = { models = 14, parts = 14 },
		BranchDirections8 = { models = 14, parts = 14 },
		MarketCloseFronts = { models = 44, parts = 110 },
		MarketArch = { models = 7, parts = 7 },
		OwnerFacade = { models = 37, parts = 98 },
	}
	local records = {}
	for name, root in componentRoots do
		local stats = componentStats(root)
		local expected = expectedStats[name]
		assert(stats.models == expected.models and stats.parts == expected.parts, "Editable component count changed: " .. name)
		assert(stats.missingEditable == 0 and stats.missingSection == 0, "Editable attributes missing: " .. name)
		assert(stats.badPhysics == 0, "Generated visual physics changed: " .. name)
		records[name] = stats
	end
	records.CourtyardDepth = depthStats

	local manifest = require(game.ServerStorage.CourseBuilders.CityRun.C09Manifest)
	local manifestMeshes = 0
	local manifestComponents = 0
	local calibrationComponents = 0
	for _ in manifest.meshes do
		manifestMeshes += 1
	end
	for _ in manifest.components do
		manifestComponents += 1
	end
	for _, definition in manifest.components do
		if definition.section == "Calibration" then
			calibrationComponents += 1
		end
	end
	assert(manifestMeshes == 342, "C09 manifest mesh count changed")
	assert(manifestComponents == 177 and calibrationComponents == 4, "C09 manifest component count changed")

	local expectedGroups = 0
	for name, definition in manifest.components do
		if definition.section ~= "Calibration" then
			expectedGroups += 1
			local root, childName = findComponentRoot(course, depthRoot, name)
			assert(root and childName, "Unexpected C09 component prefix: " .. name)
			local model = root:FindFirstChild(childName)
			assert(model and model:IsA("Model"), "C09 component group is missing: " .. name)
			assert(model:GetAttribute("EditableUnit") == true, "EditableUnit missing: " .. name)
			assert(model:GetAttribute("Section") == definition.section, "Component section changed: " .. name)
		end
	end
	assert(expectedGroups == 173, "C09 editable-group count changed")

	local seenMeshes = {}
	local actualMeshes = 0
	local function checkMeshRoot(root)
		for _, item in root:GetDescendants() do
			if item:IsA("BasePart") then
				actualMeshes += 1
				assert(manifest.meshes[item.Name] ~= nil, "Unexpected C09 mesh: " .. item.Name)
				assert(not seenMeshes[item.Name], "Duplicate C09 mesh: " .. item.Name)
				seenMeshes[item.Name] = true
			end
		end
	end
	for _, root in componentRoots do
		checkMeshRoot(root)
	end
	checkMeshRoot(depthRoot)
	for _, item in replaced:GetChildren() do
		if item:IsA("BasePart") and string.sub(item.Name, 1, 6) == "Marker" then
			actualMeshes += 1
			assert(manifest.meshes[item.Name] ~= nil, "Unexpected C09 calibration mesh: " .. item.Name)
			assert(not seenMeshes[item.Name], "Duplicate C09 calibration mesh: " .. item.Name)
			seenMeshes[item.Name] = true
		end
	end
	for name in manifest.meshes do
		assert(seenMeshes[name], "Manifest mesh is missing from the C09 result: " .. name)
	end
	assert(actualMeshes == manifestMeshes, "C09 mesh reconciliation count changed")

	return {
		passed = true,
		revision = revision,
		reviewBuildId = reviewBuildId,
		courseDescendants = #course:GetDescendants(),
		walkingSurfaceModels = walkingModels,
		walkingSurfaceParts = walkingParts,
		checkpointParts = checkpointCount,
		hazardTypeKillParts = killParts,
		ownerKillGroupBaseParts = totalKillGroupParts,
		invisibleWallParts = 10,
		originalOwnerBuildingParts = 4,
		manifestMeshes = manifestMeshes,
		editableGroups = expectedGroups,
		records = records,
		limitations = "Edit-mode structure and manifest checks only; traversal, jump feel, camera composition, collision feel, and multiplayer remain separate reviews.",
	}
end

return Test
