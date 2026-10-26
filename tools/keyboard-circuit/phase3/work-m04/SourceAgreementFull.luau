--!strict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local c = assert(workspace:FindFirstChild("KeyboardCircuit_P3_M04_01")) :: Model
assert(c:GetAttribute("PrototypeRevision") == "KC_P3_M04_01")
local origin = c:GetAttribute("Origin") :: Vector3
assert(origin == Vector3.new(2222, 330, -1158))
local holder = Storage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009.M04Sources01
local encoding = game:GetService("EncodingService")
local function hex(value: string): string return (value:gsub(".", function(char) return string.format("%02x", string.byte(char)) end)) end
local function hash(value: string): string return hex(buffer.tostring(encoding:ComputeBufferHash(buffer.fromstring(value), Enum.HashAlgorithm.Sha256))) end
local sources, sourceFailures = {}, {}
local function add(item: LuaSourceContainer, repository: string, scope: string)
	local raw = item.Source
	local normalized = raw:gsub("\r\n", "\n")
	table.insert(sources, {path = item:GetFullName():gsub("^game%.", ""), name = item.Name, class = item.ClassName, bytes = #raw, sha256 = hash(raw), normalizedLFBytes = #normalized, normalizedLFSha256 = hash(normalized), repository = repository, scope = scope})
end
local snapshotCount = 0
for _, item in c.SourceSnapshot:GetChildren() do
	assert(item:IsA("LuaSourceContainer"))
	snapshotCount += 1
	local durable = holder:FindFirstChild(item.Name)
	if not durable or not durable:IsA("LuaSourceContainer") or item.ClassName ~= durable.ClassName or item.Source ~= durable.Source then table.insert(sourceFailures, item.Name) end
	local suffix = if item.Name == "Session" then ".server.luau" elseif item.Name == "KeyboardCircuitPhase2Preview" then ".client.luau" else ".luau"
	add(item, "tools/keyboard-circuit/phase3/work-m04/sources/" .. item.Name .. suffix, "CandidateSnapshot")
end
assert(snapshotCount == 28 and #holder:GetChildren() == 28 and #sourceFailures == 0, "Live snapshot differs from durable preparation")
assert(c.SourceSnapshot:FindFirstChild("ArchiveSkyConfig") and c.SourceSnapshot:FindFirstChild("WarningPlacements"), "Sky configuration and owner warning poses must be durable")
local resources = {parts = 0, pressTargets = 0, colliders = 0, queryParts = 0, touchParts = 0, artParts = 0}
for _, item in c:GetDescendants() do
	if not item:IsA("BasePart") then continue end
	resources.parts += 1
	if item:GetAttribute("Pressable") then resources.pressTargets += 1 end
	if item.CanCollide then resources.colliders += 1 end
	if item.CanQuery then resources.queryParts += 1 end
	if item.CanTouch then resources.touchParts += 1 end
	if item:GetAttribute("MapArtwork") == true then resources.artParts += 1 end
end
for name, expected in {parts = 8808, pressTargets = 2989, colliders = 282, queryParts = 3289, touchParts = 0, artParts = 1894} do
	assert(resources[name] == expected, "Exact M04 inventory differs: " .. name)
end
assert(#c.MapEnvironment.HazardIndicators:GetChildren() == 17, "All owner warning boards must remain present")
add(game.ServerScriptService.Services.StudioDevService, "src/ServerScriptService/Services/StudioDevService.luau", "Global")
add(game.StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController, "src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau", "GlobalUnchanged")
add(game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview, "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau", "Global")
add(game.StarterPlayer.StarterPlayerScripts.ClassicAscentAmbience, "src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau", "Global")
table.sort(sources, function(a, b) return a.path < b.path end)
local active, archived, disabled = {}, {}, true
for _, item in workspace:GetChildren() do if item:IsA("Model") and item.Name:find("KeyboardCircuit", 1, true) then table.insert(active, item.Name) end end
assert(#active == 1 and active[1] == c.Name)
for _, item in Storage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses:GetChildren() do
	table.insert(archived, item.Name)
	for _, source in item:GetDescendants() do if source:IsA("BaseScript") and not source.Disabled then disabled = false end end
end
assert(#archived == 16 and table.find(archived, "KeyboardCircuit_P3_M02_01") and table.find(archived, "KeyboardCircuit_P3_M03_01") and disabled)
table.sort(archived)
local unrelated = {}
for name, expected in {Lobby = {2356, 1243}, GrandArcade = {424, 281}, SGV2_Phase3_F04 = {8795, 8015}, ObstacleKit_Palette = {499, 369}} do
	local item = assert(workspace:FindFirstChild(name))
	local descendants, parts = item:GetDescendants(), 0
	for _, part in descendants do if part:IsA("BasePart") then parts += 1 end end
	assert(#descendants == expected[1] and parts == expected[2], "Unrelated map count changed: " .. name)
	unrelated[name] = {descendants = #descendants, parts = parts}
end
local receipt = {
	passed = true, candidate = c.Name, revision = c:GetAttribute("PrototypeRevision"), mapRevision = c:GetAttribute("MapRevision"), baseCourseRevision = c:GetAttribute("BaseCourseRevision"),
	layout = require(c.SourceSnapshot.Layout).Revision, origin = {origin.X, origin.Y, origin.Z}, descendants = #c:GetDescendants(), resources = resources, snapshotCount = snapshotCount, globalCount = 4, rows = sources,
	sourceHolder = holder:GetFullName(), sourceFailures = sourceFailures, active = active, archived = archived, archivedScriptsDisabled = disabled, unrelated = unrelated, datamodel = "Edit",
	repositoryComparison = "Compare all 32 returned rows to the listed repository files. Prefer exact sha256/bytes; normalizedLF hash permits only CRLF/LF differences.",
	boundary = "Read-only intended experience, owner origin, all 28 snapshot bytes including ArchiveSkyConfig and WarningPlacements equal M04Sources01, four global source hashes including ClassicAscentAmbience and unchanged StudioDevController, one active course, 16 inert archived courses including M02 and M03, and unchanged unrelated map counts. Filesystem agreement remains the calling tool's hash comparison; native code cannot read repository files. No camera/computer control, publication, stored data, human pacing or FPS proof.",
}
shared.KCP3M04SourceAgreementFull01 = receipt
return Http:JSONEncode(receipt)
