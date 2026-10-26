--!strict
local Assets = {}

local function contentKey(value: string): string
	local id = value:match("^rbxassetid://(%d+)") or value:match("[?&]id=(%d+)") or value:match("^(%d+)$")
	return if id then "asset:" .. id else value
end

local function visualDescendants(root: Instance): {Instance}
	local visuals = {}
	for _, item in root:GetDescendants() do
		if item:IsA("MeshPart") or item:IsA("SpecialMesh") or item:IsA("Decal") or item:IsA("Texture")
			or item:IsA("SurfaceAppearance") or item:IsA("Clothing") or item:IsA("ShirtGraphic") then
			table.insert(visuals, item)
		end
	end
	return visuals
end

local structurePrefixes = {
	"Lower_Slab_", "Arrival_Slab_", "Shops_Slab_", "Roof_Slab_", "Stairs_Stair_",
	"Lower_HallWall_", "Lower_RearWall", "Arrival_StairBackWall_", "SideWallTrim_",
	"Lower_Ceiling_", "Lower_GrandPillar_", "Lower_EntryColumn_", "Guardrails_Rail_",
	"SideGuard_", "Practice_Opening_", "ShopRoom_Opening_", "Shops_LandingReturn_",
}
local decorationPrefixes = {
	"RoomDetails", "RoomInsets", "RoomInserts", "Inserts", "Bench_", "Gardens_", "Planter_", "Vine_",
	"Lower_SocialBench_", "Lower_SocialGarden_", "Lower_FloorInlay_", "Lower_GatheringCrest",
	"Lower_RecordsCrest", "Lower_RouteInlays", "Lower_Board_",
}
local function startsWithAny(name: string, prefixes: {string}): boolean
	for _, prefix in prefixes do if name:sub(1, #prefix) == prefix then return true end end
	return false
end
local function isLobbyStructure(mesh: Instance, lobby: Instance): boolean
	local surface = if mesh:IsA("MeshPart") then mesh else mesh.Parent
	if not surface or not surface.Parent or not surface:IsA("BasePart") or surface.Transparency >= 1 then return false end
	local structural = false
	local current: Instance? = surface
	while current and current ~= lobby do
		if startsWithAny(current.Name, decorationPrefixes) or (current:IsA("Model") and current:FindFirstChildOfClass("Humanoid")) then return false end
		if startsWithAny(current.Name, structurePrefixes) or current.Name:find("_Pier_", 1, true) then structural = true end
		local parent = current.Parent
		if parent and parent.Name == "05_Architecture" and parent.Parent and parent.Parent.Name == "Editable"
			and (current.Name == "ShopRoom" or current.Name == "Practice" or current.Name == "Spawn") then structural = true end
		if current.Name == "Architecture" and parent and parent.Name == "GrandArcadeConnection" and parent.Parent == lobby then structural = true end
		current = parent
	end
	return current == lobby and structural
end

function Assets.RequiredLobbyGeometry(lobby: Instance): {Instance}
	local geometry = {}
	for _, item in lobby:GetDescendants() do
		if (item:IsA("MeshPart") or (item:IsA("SpecialMesh") and item.MeshId ~= "")) and isLobbyStructure(item, lobby) then
			table.insert(geometry, item)
		end
	end
	return geometry
end

function Assets.LobbyVisuals(lobby: Instance): {Instance}
	local required = {}
	for _, item in Assets.RequiredLobbyGeometry(lobby) do required[item] = true end
	local visuals = visualDescendants(lobby)
	for index = #visuals, 1, -1 do if required[visuals[index]] then table.remove(visuals, index) end end
	return visuals
end

function Assets.CharacterVisuals(character: Instance): {Instance}
	return visualDescendants(character)
end

function Assets.WarmOptional(provider: any, visuals: {Instance}, report: (string, string) -> ()): boolean
	local failed = false
	local ok, reason = pcall(function()
		provider:PreloadAsync(visuals, function(id, status)
			if status.Name ~= "Success" then failed = true; report(tostring(id), status.Name) end
		end)
	end)
	if not ok then report(tostring(reason), "RequestError") end
	return ok and not failed
end

function Assets.PreloadLobbyGeometry(provider: any, lobby: Instance, reportOptional: (string, string) -> ()): (boolean, string?)
	local representatives, required, order = {}, {}, {}
	for _, mesh in Assets.RequiredLobbyGeometry(lobby) do
		local id = (mesh :: any).MeshId :: string
		if id == "" then return false, "Required lobby mesh has no content ID: " .. mesh:GetFullName() end
		local key = contentKey(id)
		if not required[key] then
			required[key] = {id = id, confirmed = false}
			table.insert(order, key)
			table.insert(representatives, mesh)
		end
	end
	if #representatives == 0 then return true, nil end
	local failure: string? = nil
	local ok, reason = pcall(function()
		provider:PreloadAsync(representatives, function(id, status)
			local entry = required[contentKey(tostring(id))]
			if entry then
				if status.Name == "Success" then entry.confirmed = true
				else failure = failure or ("Required lobby mesh unavailable: " .. tostring(id) .. " (" .. status.Name .. ")") end
			elseif status.Name ~= "Success" then reportOptional(tostring(id), status.Name) end
		end)
	end)
	if not ok then return false, "Lobby geometry preload failed: " .. tostring(reason) end
	if failure then return false, failure end
	for _, key in order do
		if not required[key].confirmed then return false, "Required lobby mesh not confirmed: " .. required[key].id end
	end
	return true, nil
end

function Assets.PreloadFloor(provider: any, floor: BasePart, reportOptional: (string, string) -> ()): (boolean, string?)
	assert(floor:IsA("BasePart") and floor.CanCollide, "Actual collidable floor required")
	if not floor:IsA("MeshPart") or floor.MeshId == "" then return true, nil end
	local meshKey = contentKey(floor.MeshId)
	local failure: string? = nil
	local ok, reason = pcall(function()
		-- Keep the instance so Roblox fetches its mesh with the correct content type.
		provider:PreloadAsync({floor}, function(id, status)
			if status.Name == "Success" then return end
			if contentKey(tostring(id)) == meshKey then
				failure = "Spawn floor mesh unavailable: " .. tostring(id) .. " (" .. status.Name .. ")"
			else reportOptional(tostring(id), status.Name) end
		end)
	end)
	if not ok then return false, "Spawn floor preload failed: " .. tostring(reason) end
	return failure == nil, failure
end

return Assets
