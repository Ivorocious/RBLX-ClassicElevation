local Preview = {}
local backupName = "__StudGardenSkyPreviewBackup"

local function editOnly()
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Edit mode required")
	assert(game.PlaceId == 85558151074819, "Wrong experience")
end

function Preview.Restore()
	editOnly()
	local backup = game.ServerStorage:FindFirstChild(backupName)
	if not backup then return {restored=false, reason="No preview is active"} end
	for _, group in backup:GetChildren() do
		if not group:IsA("Folder") then continue end
		local target = group.Target.Value
		assert(target, "Preview target disappeared: " .. group.Name)
		if group:GetAttribute("CreatedForPreview") then
			target:Destroy()
		else
			for key, value in group.Original:GetAttributes() do target[key] = value end
		end
	end
	backup:Destroy()
	return {restored=true}
end

function Preview.Apply()
	editOnly()
	assert(not game.ServerStorage:FindFirstChild(backupName), "Restore the current preview first")
	local config = assert(loadstring(game.ReplicatedStorage.Config.StudGardenAmbienceConfig.Source))()
	local lighting = game:GetService("Lighting")
	local backup = Instance.new("Folder")
	backup.Name, backup.Parent = backupName, game.ServerStorage
	local function apply(name, target, properties, created)
		local group = Instance.new("Folder")
		group.Name = name
		group:SetAttribute("CreatedForPreview", created)
		local reference = Instance.new("ObjectValue")
		reference.Name, reference.Value, reference.Parent = "Target", target, group
		local original = Instance.new("Folder")
		original.Name, original.Parent = "Original", group
		for key in properties do original:SetAttribute(key, target[key]) end
		group.Parent = backup
		for key, value in properties do target[key] = value end
	end
	local ok, failure = xpcall(function()
		apply("Lighting", lighting, config.Lighting, false)
		for class, properties in {Sky=config.Sky, Atmosphere=config.Atmosphere} do
			local target = lighting:FindFirstChildOfClass(class)
			local created = target == nil
			if not target then
				target = Instance.new(class)
				target.Name, target.Parent = "StudGardenPreview" .. class, lighting
			end
			apply(class, target, properties, created)
		end
		local correction = Instance.new("ColorCorrectionEffect")
		correction.Name, correction.Parent = "StudGardenGiantsBackyardPreview", lighting
		local properties = table.clone(config.ColorCorrection)
		properties.Enabled = true
		apply("ColorCorrection", correction, properties, true)
	end, debug.traceback)
	if not ok then Preview.Restore(); error(failure) end
	return {preview=true, backup=backup:GetFullName(), restoreBefore="Play or saving the place"}
end

return Preview
