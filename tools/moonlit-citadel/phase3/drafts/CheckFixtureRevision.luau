local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local V, C = roblox.Vector3, roblox.CFrame
local base = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local packetPath = 'docs/artifacts/moonlit-citadel/phase3/MC_P3_sources07.json'
local output = 'docs/artifacts/moonlit-citadel/phase3/MC_P3_fixture_source_transfer07.json'
local packet = serde.decode('json', fs.readFile(packetPath))
local sources, changedFiles = {}, {}
for _, item in packet.sources do
	assert(serde.hash('sha256', item.source) == item.sha256, 'Packet source hash mismatch: ' .. item.file)
	sources[item.file] = item.source
	if fs.readFile(item.file) ~= item.source then table.insert(changedFiles, item.file) end
end
assert(#changedFiles == 1 and changedFiles[1] == base .. 'Layout.luau', 'Expected only draft Layout revision')
local beforeSource, afterSource = fs.readFile(base .. 'Layout.luau'), sources[base .. 'Layout.luau']
assert(serde.hash('sha256', afterSource) == '7302ed35a2ae393a91f3ce7920844237579649390d2d751a403d2e6336f20847')
local function replaceOnce(source, old, new)
	local first, last = assert(source:find(old, 1, true))
	assert(not source:find(old, last + 1, true), 'Expected one occurrence')
	return source:sub(1, first - 1) .. new .. source:sub(last + 1)
end
local expectedSource = replaceOnce(beforeSource, 'offset = v(-5, 0, 7.5)', 'offset = v(-12.5, 0, 6)')
expectedSource = replaceOnce(expectedSource, 'drop.drop, drop.offset = true, v(13, 0, 7.5)', 'drop.drop, drop.offset = true, v(-6, 0, 0)')
assert(expectedSource == afterSource, 'Unexpected source edits beyond the two Arch inspection offsets')
local function load(path, source, parent)
	return luau.load(source or fs.readFile(path), {environment = {
		Vector3 = V, CFrame = C, script = {Parent = parent or {}},
		game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = {Origin = V.new(4000, 300, 2600)}}}},
		require = function(value) return value end,
	}})()
end
local function layout(source)
	local parent = {}
	for _, name in {'ExpertRoutes', 'RouteHazardLayout', 'RouteHazardGoals', 'SupportingObstacles'} do
		parent[name] = load(base .. name .. '.luau', nil, parent)
	end
	return load(base .. 'Layout.luau', source, parent)
end
local before, after = layout(beforeSource), layout(afterSource)
local function same(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if type(a) ~= 'table' then return a == b end
	for key, value in a do if not same(value, b[key]) then return false end end
	for key in b do if a[key] == nil then return false end end
	return true
end
local function encode(value)
	if typeof(value) == 'Vector3' then return {_t = 'v', value = {value.X, value.Y, value.Z}} end
	if typeof(value) == 'CFrame' then return {_t = 'c', value = {value:GetComponents()}} end
	if type(value) ~= 'table' then return value end
	local result = {}
	for key, child in value do result[key] = encode(child) end
	return result
end
local fields, changedFields = {}, {}
for key, value in before do
	if type(value) == 'function' then continue end
	fields[key] = same(value, after[key])
	if not fields[key] then table.insert(changedFields, key) end
end
for key, value in after do
	if before[key] == nil and type(value) ~= 'function' then table.insert(changedFields, key) end
end
local world = load(base .. 'WorldPlan.luau')
local worldBefore, countsBefore = world.Get(before)
local worldAfter, countsAfter = world.Get(after)
local routes = {}
for name, spec in {NNN = {{false, false, false}, {1, 2}}, EEE = {{true, true, true}, {1, 2}}, EEEMirror = {{true, true, true}, {1, 1}}} do
	routes[name] = {same = same(before.GetRoute(spec[1], spec[2]), after.GetRoute(spec[1], spec[2])), nodes = #after.GetRoute(spec[1], spec[2])}
end
local catchBefore, catchAfter = before.GetCatchRoute('Arch'), after.GetCatchRoute('Arch')
local catchChanges, catchPathsSame = {}, #catchBefore == #catchAfter
for index, node in catchBefore do
	if node.path ~= catchAfter[index].path then catchPathsSame = false end
	if not same(node, catchAfter[index]) then
		table.insert(catchChanges, {index = index, before = encode(node), after = encode(catchAfter[index])})
	end
end
assert(#catchChanges == 2 and catchChanges[1].index == 2 and catchChanges[2].index == 3)
for _, change in catchChanges do
	local a, b = table.clone(catchBefore[change.index]), table.clone(catchAfter[change.index])
	a.offset, b.offset = nil, nil
	assert(same(a, b), 'Arch node changed beyond offset')
end
assert(catchAfter[2].offset == V.new(-12.5, 0, 6) and catchAfter[3].offset == V.new(-6, 0, 0))
local clearance = load(base .. 'DecorativeClearance.luau')
local beforeCorridors, afterCorridors = clearance.Prepare(before), clearance.Prepare(after)
local archResults, changedArchResults, changedArchGeometry = {}, {}, {}
for index, arch in before.ArchSkins do
	local a, reasonA = clearance.Suggest(before, arch)
	local b, reasonB = clearance.Suggest(after, after.ArchSkins[index])
	local geometrySame, resultSame = same(a, b), same(a, b) and reasonA == reasonB
	table.insert(archResults, {index = index, group = arch.group, name = arch.name, geometrySame = geometrySame,
		resultSame = resultSame, before = encode({suggestion = a, reason = reasonA}), after = encode({suggestion = b, reason = reasonB})})
	if not resultSame then table.insert(changedArchResults, archResults[#archResults]) end
	if not geometrySame then table.insert(changedArchGeometry, archResults[#archResults]) end
end
local worldSame, worldCountsSame = same(worldBefore, worldAfter), same(countsBefore, countsAfter)
local routeSame = routes.NNN.same and routes.EEE.same and routes.EEEMirror.same
local upperSame = same(before.GetCatchRoute('Upper'), after.GetCatchRoute('Upper'))
local geometryUnchanged = #changedFields == 0 and worldSame and worldCountsSame and #changedArchGeometry == 0
local report = {ok = geometryUnchanged and routeSame and upperSame and catchPathsSame and #changedArchResults == 0,
	sourceOnly = true, candidate = packet.candidate, sourcePacket = packetPath,
	declaredSource07ProductionHash = '2fca1ae828506447017b8b75ed8a6f7e47a4d311b43f29e83847de3a267357a3',
	beforeLayoutHash = serde.hash('sha256', beforeSource), afterLayoutHash = serde.hash('sha256', afterSource),
	packetSourcesChecked = #packet.sources, changedSourceFiles = changedFiles, exactTwoOffsetSourceEdit = true,
	geometryUnchanged = geometryUnchanged, layoutFields = fields, changedLayoutFields = changedFields,
	worldPlanSame = worldSame, worldCountsSame = worldCountsSame, worldPlacements = #worldAfter,
	mainRoutes = routes, upperCatchSame = upperSame, archCatchPathsSame = catchPathsSame,
	archCatchNodes = #catchAfter, archCatchChanges = catchChanges,
	decorativeClearance = {beforeCorridors = beforeCorridors, afterCorridors = afterCorridors,
		archesChecked = #archResults, allResultsSame = #changedArchResults == 0, allGeometrySame = #changedArchGeometry == 0,
		changedResults = changedArchResults, changedGeometry = changedArchGeometry, results = archResults},
	boundary = 'Compares generated source geometry and all decorative arch decisions; does not install source or mutate Studio, and does not claim native source07 playback.'}
fs.writeFile(output, serde.encode('json', report, true))
print(serde.encode('json', {ok = report.ok, output = output, geometryUnchanged = geometryUnchanged,
	changedSourceFiles = changedFiles, worldPlacements = #worldAfter, archesChecked = #archResults,
	changedArchResults = #changedArchResults, changedArchGeometry = #changedArchGeometry,
	beforeCorridors = beforeCorridors, afterCorridors = afterCorridors, mainRoutesSame = routeSame,
	archCatchPathsSame = catchPathsSame, archCatchOffsetChanges = #catchChanges}, true))
