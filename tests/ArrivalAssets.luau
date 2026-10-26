local Assets = require("../src/StarterPlayer/StarterPlayerScripts/Controllers/ArrivalAssets")
local checks = 0
local function check(condition, message) assert(condition, message); checks += 1 end
local function item(class, properties)
	local value = properties or {}
	value.Name = value.Name or class
	if class == "Part" or class == "MeshPart" then value.Transparency = value.Transparency or 0 end
	function value:IsA(wanted)
		return wanted == class or (wanted == "BasePart" and (class == "Part" or class == "MeshPart"))
	end
	return value
end
local floor = item("Part", {CanCollide = true})
local geometry = item("MeshPart", {CanCollide = true, MeshId = "rbxassetid://123"})
local npc = item("MeshPart", {CanCollide = true, MeshId = "rbxassetid://456"})
local wall = item("MeshPart", {CanCollide = true, MeshId = "rbxassetid://789"})
local sound, animation, decal = item("Sound"), item("Animation"), item("Decal")
local lobby = {GetDescendants = function() return {floor, npc, wall, sound, animation, decal} end}
local visuals = Assets.LobbyVisuals(lobby)
check(#visuals == 3 and table.find(visuals, npc) and table.find(visuals, wall) and table.find(visuals, decal), "Lobby art remains eligible for optional warming")
check(not table.find(visuals, sound) and not table.find(visuals, animation), "Entrance does not request lobby audio or animations")
local calls, reported = {}, {}
local function warnOptional(id, status) table.insert(reported, {id = id, status = status}) end
local provider = {}
function provider:PreloadAsync(instances, callback)
	table.insert(calls, instances)
	for _, visual in instances do callback(visual.MeshId or "decal", {Name = "Failure"}) end
end
check(not Assets.WarmOptional(provider, visuals, warnOptional) and #reported == 3, "Unavailable decorative NPC/wall/decal assets are reported")
check(Assets.PreloadFloor(provider, floor, warnOptional) and #calls == 1, "The real primitive floor needs no external asset request after optional failures")
function provider:PreloadAsync(instances, callback)
	check(#instances == 1 and instances[1] == geometry, "Mandatory preload uses only the actual queried floor instance")
	callback("http://www.roblox.com/asset/?id=123", {Name = "Success"})
	callback("rbxassetid://999", {Name = "Failure"})
end
check(Assets.PreloadFloor(provider, geometry, warnOptional), "A missing floor texture does not invalidate loaded physical geometry")
check(reported[#reported].id == "rbxassetid://999", "Optional floor texture failure remains visible in diagnostics")
function provider:PreloadAsync(_, callback) callback("https://assetdelivery.roblox.com/v1/asset?id=123", {Name = "Failure"}) end
local ok, reason = Assets.PreloadFloor(provider, geometry, warnOptional)
check(not ok and reason:find("Spawn floor mesh unavailable", 1, true), "Required collision mesh failure remains fatal across equivalent asset URLs")
function provider:PreloadAsync() error("Required request unavailable") end
ok, reason = Assets.PreloadFloor(provider, geometry, warnOptional)
check(not ok and reason:find("Spawn floor preload failed", 1, true), "A failed mandatory preload call cannot declare readiness")
check(not Assets.WarmOptional(provider, visuals, warnOptional), "An optional preload call error is reported without throwing")
check(not pcall(Assets.PreloadFloor, provider, item("Part", {CanCollide = false}), warnOptional), "Noncollidable art cannot stand in for the actual physical floor")
local shirt, graphic, material, mesh = item("Clothing"), item("ShirtGraphic"), item("SurfaceAppearance"), item("SpecialMesh")
local character = {GetDescendants = function() return {geometry, mesh, decal, material, shirt, graphic, sound, animation, floor} end}
local appearance = Assets.CharacterVisuals(character)
check(#appearance == 6 and table.find(appearance, geometry) and table.find(appearance, shirt) and table.find(appearance, graphic), "Character body/accessory meshes and clothing remain eligible for optional warming")
check(not table.find(appearance, animation) and not table.find(appearance, sound) and not table.find(appearance, floor), "Character appearance warming does not request animations, audio or primitive physics parts")
function provider:PreloadAsync(instances, callback)
	for _, visual in instances do callback(visual.MeshId or "cosmetic", {Name = "Failure"}) end
end
check(not Assets.WarmOptional(provider, appearance, warnOptional), "Character appearance failures are reported without throwing")
check(Assets.PreloadFloor(provider, floor, warnOptional), "Unavailable character cosmetics do not invalidate an actual primitive lobby floor")

local function node(class, name, parent, properties)
	local value = item(class, properties)
	value.Name, value.Parent, value.Children = name, parent, {}
	if parent then table.insert(parent.Children, value) end
	function value:GetFullName() return if self.Parent then self.Parent:GetFullName() .. "." .. self.Name else self.Name end
	function value:FindFirstChildOfClass(wanted)
		for _, child in self.Children do if child:IsA(wanted) then return child end end
		return nil
	end
	function value:GetDescendants()
		local result = {}
		local function visit(root)
			for _, child in root.Children do table.insert(result, child); visit(child) end
		end
		visit(self)
		return result
	end
	return value
end
local function meshPart(name, parent, id, properties)
	local value = node("MeshPart", name, parent, properties or {CanCollide=false})
	value.MeshId = "rbxassetid://" .. id
	return value
end
local structureLobby = node("Model", "Lobby")
local editable = node("Folder", "Editable", structureLobby)
local lower = node("Folder", "01_Lower", editable)
local slab = node("Model", "Lower_Slab_01", lower)
local visibleSlab = meshPart("VisiblePaving", slab, "101")
local duplicateSlab = meshPart("VisiblePavingCopy", slab, "101")
duplicateSlab.MeshId = "https://assetdelivery.roblox.com/v1/asset?id=101"
local movedWall = meshPart("Lower_HallWall_56__Cream__00", structureLobby, "102")
local hiddenMarker = meshPart("Lower_HallWall_HiddenMarker", structureLobby, "103", {Transparency=1})
local plant = meshPart("Foliage", node("Model", "Gardens_Tree_01", lower), "104", {CanCollide=true})
local architecture = node("Folder", "05_Architecture", editable)
local shop = node("Model", "ShopRoom", architecture)
local shopWall = meshPart("RoomWall", shop, "105")
local roomDetail = meshPart("Lower_HallWall_Decor", node("Model", "RoomDetails", shop), "106")
local roomInset = meshPart("FloorPattern", node("Model", "RoomInsets", shop), "107")
local practice = node("Model", "Practice", architecture)
local npcRig = node("Model", "PodiumRacer", practice)
node("Humanoid", "Humanoid", npcRig)
local npcBody = meshPart("UpperTorso", npcRig, "108", {CanCollide=true})
local spawn = meshPart("SpawnPlatform", node("Model", "Spawn", architecture), "109")
local connection = node("Model", "GrandArcadeConnection", structureLobby)
local connectionArch = meshPart("BridgeArch", node("Folder", "Architecture", connection), "110")
local rearWallPart = node("Part", "Lower_RearWall", structureLobby, {CanCollide=false})
local fileMesh = node("SpecialMesh", "Mesh", rearWallPart, {MeshId="rbxassetid://111"})
node("SpecialMesh", "BuiltinMesh", rearWallPart, {MeshId=""})
local inlay = meshPart("Pattern", node("Model", "Lower_FloorInlay_1", lower), "112")
local crest = meshPart("Medallion", node("Model", "Lower_RecordsCrest", lower), "113")
local board = meshPart("Panel", node("Model", "Lower_Board_Wins", lower), "114")
local practiceWall = meshPart("RoomWall", practice, "115")
local bench = meshPart("Seat", node("Model", "Bench_0_-29", lower), "116", {CanCollide=true})
local required = Assets.RequiredLobbyGeometry(structureLobby)
local structural = {visibleSlab, duplicateSlab, movedWall, shopWall, spawn, connectionArch, fileMesh, practiceWall}
check(#required == #structural, "Required lobby geometry selects the eight visible structural instances")
for _, visual in structural do check(table.find(required, visual), "Visible structure is required independently of CanCollide or owner-moved root placement") end
local optional = Assets.LobbyVisuals(structureLobby)
for _, visual in structural do check(not table.find(optional, visual), "Required structure is excluded from the optional preload list") end
for _, visual in {plant, npcBody, roomDetail, roomInset, inlay, crest, board, bench} do
	check(not table.find(required, visual) and table.find(optional, visual), "Decorations and humanoid rigs remain optional, including collidable decorative meshes")
end
check(not table.find(required, hiddenMarker), "Hidden markers cannot become required visible architecture")
local requested = {}
function provider:PreloadAsync(instances, callback)
	requested = instances
	for _, visual in instances do callback(visual.MeshId, {Name="Success"}) end
	callback("rbxassetid://9999", {Name="Failure"})
end
check(Assets.PreloadLobbyGeometry(provider, structureLobby, warnOptional), "All required meshes confirmed with an optional texture failure can enter")
check(#requested == 7 and not table.find(requested, duplicateSlab), "Equivalent normalized mesh IDs preload one actual typed representative")
check(reported[#reported].id == "rbxassetid://9999", "A structural mesh texture failure stays in optional diagnostics")
for _, failedId in {"101", "102"} do
	function provider:PreloadAsync(instances, callback)
		for _, visual in instances do
			local id = visual.MeshId:match("(%d+)$")
			callback("https://assetdelivery.roblox.com/v1/asset?id=" .. id, {Name=if id==failedId then "Failure" else "Success"})
		end
	end
	check(Assets.PreloadFloor(provider, floor, warnOptional), "The invisible primitive floor is still physically available")
	ok, reason = Assets.PreloadLobbyGeometry(provider, structureLobby, warnOptional)
	check(not ok and reason:find("Required lobby mesh unavailable", 1, true), "A visible noncolliding floor or moved wall failure rejects entry despite its working primitive collider")
end
function provider:PreloadAsync(instances, callback)
	for index, visual in instances do if index>1 then callback(visual.MeshId, {Name="Success"}) end end
	callback("rbxassetid://9999", {Name="Success"})
end
ok, reason = Assets.PreloadLobbyGeometry(provider, structureLobby, warnOptional)
check(not ok and reason:find("not confirmed: rbxassetid://101", 1, true), "A missing required callback cannot be replaced by an unrelated successful callback")
function provider:PreloadAsync() error("Required lobby request unavailable") end
ok, reason = Assets.PreloadLobbyGeometry(provider, structureLobby, warnOptional)
check(not ok and reason:find("Lobby geometry preload failed", 1, true), "A required request error rejects entry")
function provider:PreloadAsync(instances, callback)
	callback("101", {Name="Failure"})
	for _, visual in instances do callback(visual.MeshId, {Name="Success"}) end
end
ok, reason = Assets.PreloadLobbyGeometry(provider, structureLobby, warnOptional)
check(not ok and reason:find("Required lobby mesh unavailable", 1, true), "A reported required failure remains a failure even if a later callback says Success")
local emptyContentLobby = node("Model", "Lobby")
meshPart("Lower_HallWall_56", emptyContentLobby, "").MeshId = ""
ok, reason = Assets.PreloadLobbyGeometry(provider, emptyContentLobby, warnOptional)
check(not ok and reason:find("no content ID", 1, true), "A visible required MeshPart without a content ID cannot silently pass")
print(string.format("ArrivalAssets: %d checks passed", checks))
