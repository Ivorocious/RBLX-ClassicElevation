local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local V, C = roblox.Vector3, roblox.CFrame
local base = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local parent, hashes = {}, {}
local function load(path, localParent)
	local source = fs.readFile(path)
	hashes[path] = serde.hash('sha256', source)
	return luau.load(source, {environment = {
		Vector3 = V, CFrame = C, script = {Parent = localParent or parent},
		game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = {Origin = V.new(4000, 300, 2600)}}}},
		require = function(value) return value end,
	}})()
end
for _, name in {'ExpertRoutes', 'RouteHazardLayout', 'RouteHazardGoals', 'SupportingObstacles'} do
	parent[name] = load(base .. name .. '.luau')
end
local layout = load(base .. 'Layout.luau')
local worldPath = base .. 'WorldPlan.luau'
if not fs.isFile(worldPath) then worldPath = 'assets/moonlit_citadel/phase3/drafts/WorldPlan.luau' end
local plan, planned = load(worldPath).Get(layout)
local checkerPath = 'tools/moonlit-citadel/phase3/drafts/clearance_check.luau'
local checker = load(checkerPath)
local manifestPaths = {P3 = 'assets/moonlit_citadel/phase3/candidate01/manifest.json', BL02 = 'assets/moonlit_citadel/bl02/manifest.json'}
local manifests, assets, parts = {}, {}, {}
for library, path in manifestPaths do
	local source = fs.readFile(path)
	hashes[path] = serde.hash('sha256', source)
	local manifest = serde.decode('json', source)
	manifests[library], assets[library], parts[library] = manifest, {}, {}
	for _, asset in manifest.assets do assets[library][asset.asset] = asset end
	for _, part in manifest.export_parts do
		parts[library][part.asset] = parts[library][part.asset] or {}
		table.insert(parts[library][part.asset], part)
	end
end
local occupied, metadata, coverage = {}, {}, {placements = #plan, P3OccupiedBoxes = 0, BL02MaterialBounds = 0, meshParts = 0}
local function record(data, suffix, localCenter, localSize, quality)
	local id = data.name .. ':' .. suffix
	table.insert(occupied, {id = id, frame = data.localCF * C.new(localCenter * data.scale), size = localSize * data.scale})
	metadata[id] = {placement = data.name, district = data.district, asset = data.asset, library = data.library, proxy = quality,
		placementFrame = {data.localCF:GetComponents()}, scale = {data.scale.X, data.scale.Y, data.scale.Z}}
end
for _, data in plan do
	local asset = assert(assets[data.library][data.asset], 'Missing manifest asset: ' .. data.asset)
	coverage.meshParts += #assert(parts[data.library][data.asset], 'Missing mesh parts: ' .. data.asset)
	if data.library == 'P3' then
		assert(asset.occupied_boxes_blender and #asset.occupied_boxes_blender > 0, 'Missing occupied proxies: ' .. data.asset)
		for index, piece in asset.occupied_boxes_blender do
			local low, high = piece.low, piece.high
			local center = V.new((low[1] + high[1]) / 2, (low[3] + high[3]) / 2, -(low[2] + high[2]) / 2)
			local size = V.new(high[1] - low[1], high[3] - low[3], high[2] - low[2])
			record(data, 'Occupied' .. index, center, size, 'Authored occupied box; arch passage excluded')
			coverage.P3OccupiedBoxes += 1
		end
	else
		for _, piece in parts.BL02[data.asset] do
			record(data, piece.material, V.new(table.unpack(piece.roblox_center)), V.new(table.unpack(piece.roblox_size)),
				'Conservative actual material-mesh bounds; internal holes are filled')
			coverage.BL02MaterialBounds += 1
		end
	end
end
assert(coverage.meshParts == planned.meshParts, 'WorldPlan mesh count differs from manifests')
print('Checking actual layout floors=' .. #layout.Surfaces .. '; world placements=' .. #plan .. '; occupied proxies=' .. #occupied)
local result = checker.Run(layout, occupied)
local totals, grouped, routeBody, floorByPath, neighbors = {}, {}, {}, {}, {}
for _, floor in layout.Surfaces do floorByPath['Obstacles/' .. floor.group .. '/' .. floor.name .. '/Contact'] = floor end
local function addConnections(route)
	for i = 2, #route do
		local a, b = route[i - 1].path, route[i].path
		if a == b then continue end
		neighbors[a], neighbors[b] = neighbors[a] or {}, neighbors[b] or {}
		neighbors[a][b], neighbors[b][a] = true, true
	end
end
for mask = 0, 7 do
	local choices = {bit32.band(mask, 1) ~= 0, bit32.band(mask, 2) ~= 0, bit32.band(mask, 4) ~= 0}
	addConnections(layout.GetRoute(choices, {1, 2}))
	if choices[3] then addConnections(layout.GetRoute(choices, {2, 1})) end
end
addConnections(layout.GetCatchRoute('Arch')); addConnections(layout.GetCatchRoute('Upper'))
local function nearbyHops(first, second)
	local queue, seen = {{first, 0}}, {[first] = true}
	for _, item in queue do
		if item[1] == second then return item[2] end
		if item[2] >= 6 then continue end
		for nextPath in neighbors[item[1]] or {} do
			if not seen[nextPath] then seen[nextPath] = true; table.insert(queue, {nextPath, item[2] + 1}) end
		end
	end
	return nil
end
local function floorInfo(floor)
	return {position = {floor.position.X, floor.position.Y, floor.position.Z}, size = {floor.size.X, floor.size.Y, floor.size.Z},
		frame = {(floor.frame or C.new(floor.position)):GetComponents()}}
end
local function prismOverlap(a, b)
	local delta = b.center - a.center
	local axes = {}
	for _, prism in {a, b} do
		table.insert(axes, prism.edges[1]:Cross(prism.edges[2]))
		table.insert(axes, prism.edges[1]:Cross(prism.edges[3]))
		table.insert(axes, prism.edges[2]:Cross(prism.edges[3]))
	end
	for _, first in a.edges do for _, second in b.edges do table.insert(axes, first:Cross(second)) end end
	for _, axis in axes do
		if axis.Magnitude < .00001 then continue end
		local radius = 0
		for _, edge in a.edges do radius += math.abs(axis:Dot(edge)) end
		for _, edge in b.edges do radius += math.abs(axis:Dot(edge)) end
		if math.abs(delta:Dot(axis)) >= radius - .001 then return false end
	end
	return true
end
local function supportedBody(floor, margin)
	local frame = floor.frame or C.new(floor.position)
	return {center = frame.Position + V.yAxis * 3.525,
		edges = {frame.RightVector * (floor.size.X / 2 + margin), V.yAxis * 3.475, -frame.LookVector * (floor.size.Z / 2 + margin)}}
end
local function floorSolid(floor)
	local frame = floor.frame or C.new(floor.position)
	return {center = frame:PointToWorldSpace(V.new(0, -floor.size.Y / 2, 0)),
		edges = {frame.RightVector * floor.size.X / 2, frame.UpVector * floor.size.Y / 2, -frame.LookVector * floor.size.Z / 2}}
end
local residuals = {nonlocal = 0, nearby = 0, actualSupportedOverlap = 0, extraMarginOnly = 0, conservativeAabbOnly = 0}
for _, finding in result.findings do
	if finding.kind == 'RouteBody' then
		local first, second = floorByPath[finding.first], floorByPath[finding.second]
		finding.firstFloor, finding.secondFloor = floorInfo(first), floorInfo(second)
		finding.topCenterDifference = second.position.Y - first.position.Y
		finding.connectionHops = nearbyHops(finding.first, finding.second)
		finding.actualSupportedPrismOverlap = prismOverlap(supportedBody(first, 0), floorSolid(second))
		finding.expandedLocalPrismOverlap = prismOverlap(supportedBody(first, 1), floorSolid(second))
		if finding.actualSupportedPrismOverlap then residuals.actualSupportedOverlap += 1 end
		if first.group == second.group and finding.connectionHops then
			residuals.nearby += 1
			if finding.actualSupportedPrismOverlap then
				finding.assessment = 'Nearby connected seam with actual supported-body overlap; native join verification required'
			elseif finding.expandedLocalPrismOverlap then
				residuals.extraMarginOnly += 1
				finding.assessment = 'Connected seam touches only the extra one-stud outside-footprint margin; actual supported-body prism is clear'
			else
				residuals.conservativeAabbOnly += 1
				finding.assessment = 'Conservative axis-aligned corner/slope overreport; actual supported-body and oriented one-stud margin prisms are clear'
			end
		else
			residuals.nonlocal += 1
			finding.assessment = 'Nonlocal stacked route crossing; repair separation or prove supported clearance with native movement'
		end
		table.insert(routeBody, finding)
		continue
	end
	local info = assert(metadata[finding.first], 'Missing proxy provenance')
	local volumeKind = string.match(finding.second, '^([^:]+):') or finding.kind
	totals[volumeKind] = (totals[volumeKind] or 0) + 1
	local group = grouped[info.placement]
	if not group then
		group = table.clone(info)
		group.count, group.volumeKinds, group.examples = 0, {}, {}
		grouped[info.placement] = group
	end
	group.count += 1
	group.volumeKinds[volumeKind] = (group.volumeKinds[volumeKind] or 0) + 1
	if #group.examples < 8 then table.insert(group.examples, finding.second) end
end
local groups = {}
for _, group in grouped do table.insert(groups, group) end
local function rank(group)
	return (group.volumeKinds.Standing or 0) * 1000 + (group.volumeKinds.Jump or 0) * 500
		+ (group.volumeKinds.Lift or 0) * 1000 + (group.volumeKinds.Weight or 0) * 1000 + (group.volumeKinds.Lantern or 0) * 1000 + group.count
end
table.sort(groups, function(a, b) return rank(a) > rank(b) end)
local output = 'docs/artifacts/moonlit-citadel/phase3/drafts/WORLD_CLEARANCE_REPORT.json'
local worldFindings = #result.findings - #routeBody
local report = {scope = 'Actual typed production Layout and WorldPlan; course-local occupied world geometry; no native scene operation',
	status = if #result.findings == 0 then 'GEOMETRY_SCREEN_CLEAR_NATIVE_UNVERIFIED'
		elseif worldFindings == 0 and residuals.nonlocal == 0 and residuals.actualSupportedOverlap == 0 then 'NO_NONLOCAL_ROUTE_OR_WORLD_INTRUSIONS_SEAM_MARGIN_FLAGS_RETAINED'
		else 'INTRUSIONS_REQUIRE_REPAIR_OR_TARGETED_OCCUPANCY_VERIFICATION',
	sourceHashes = hashes, worldPlanPath = worldPath, manifestPaths = manifestPaths, planned = planned, coverage = coverage,
	checkerCounts = result.counts, rawFindingCount = #result.findings, routeBodyCount = #routeBody, worldFindingCount = worldFindings, seamClassification = residuals,
	worldVolumeTotals = totals, worldGroups = groups, routeBodyFindings = routeBody, findings = result.findings,
	proxyMetadata = metadata, limitations = {
		'P3 occupied boxes use authored structural partitions with hollow arch passages omitted.',
		'BL02 uses actual per-material export bounds; filled internal holes can overreport. Each must be resolved locally, not globally exempted.',
		'Complete supported floor footprint and broad camera/flight volumes are protected; overlap is a geometry screen, not native measured collision.',
		'Raw checker guard is unchanged. Residual body findings are additionally tested against a vertical seven-stud prism over the actual rotated/sloped top, with and without the one-stud outside-footprint margin.',
		'Existing gameplay skins, guides, blockers and apparatus outside WorldPlan are not new world placements; this report is the affected world integration check.',
		'No Studio movement, camera capture, pacing, crowd or performance proof is claimed.'}}
fs.writeFile(output, serde.encode('json', report, true))
local markdown = {'# Actual Phase 3 world clearance recheck', '',
	'**' .. report.status .. '**. This is an affected source-geometry check, not a final reviewer score or native movement/camera pass.', '',
	'Checked actual typed production Layout, SupportingObstacles and WorldPlan using both actual manifests: **' .. #layout.Surfaces .. ' supported floors, ' .. #plan .. ' world placements, ' .. coverage.meshParts .. ' meshes and ' .. planned.triangles .. ' placed world triangles**. All loaded source/manifest hashes are in WORLD_CLEARANCE_REPORT.json.', '',
	'World geometry coverage: ' .. coverage.P3OccupiedBoxes .. ' authored P3 occupied boxes plus ' .. coverage.BL02MaterialBounds .. ' conservative BL02 material-mesh bounds. Hollow P3 arch passages are excluded. All eight route combinations, mirrored Upper Expert and both catches are protected. There are ' .. result.counts.route .. ' route/view volumes and ' .. result.counts.mechanism .. ' mechanism sweep/reserve boxes.', '',
	'**New world intrusions: ' .. worldFindings .. '. Nonlocal route crossings: ' .. residuals.nonlocal .. '. Actual supported-body prism overlaps among residual flags: ' .. residuals.actualSupportedOverlap .. '.**', '',
	'Raw clearance findings are retained: ' .. #routeBody .. ' route-body flags, comprising ' .. residuals.conservativeAabbOnly .. ' conservative axis-aligned corner/slope overreports and ' .. residuals.extraMarginOnly .. ' extra-margin-only connected seams. The underlying guard and authoring margins were not weakened.', '',
	'## Exact residual seam classification', '', '| Lower supported contact | Other contact | Connections | Assessment |', '| --- | --- | --- | --- |'}
for _, finding in routeBody do
	local first = string.gsub(string.gsub(finding.first, '^Obstacles/', ''), '/Contact$', '')
	local second = string.gsub(string.gsub(finding.second, '^Obstacles/', ''), '/Contact$', '')
	table.insert(markdown, '| ' .. first .. ' | ' .. second .. ' | ' .. tostring(finding.connectionHops or '>6') .. ' | ' .. finding.assessment .. ' |')
end
table.insert(markdown, '')
table.insert(markdown, 'The tight prism vertically follows the real sloped/rotated supported footprint, rather than filling its axis-aligned corner space or starting the whole volume at the slope\'s lowest point. The expanded prism additionally includes the same one-stud local footprint margin. Extra-margin-only flags are neighboring transition pieces, outside actual supported standing space; retain focused native movement/view checks at these joins.')
table.insert(markdown, '')
table.insert(markdown, '## Remaining world findings')
table.insert(markdown, '')
if #groups == 0 then table.insert(markdown, 'None in the checked new-world plan. Earlier Gate Court, CP01 fascia and EastWallWalk intrusions are absent in this source snapshot.')
else
	for _, group in groups do table.insert(markdown, '- ' .. group.placement .. ' / ' .. group.asset .. ': ' .. group.count .. ' raw hits; ' .. group.proxy .. '.') end
end
table.insert(markdown, '')
table.insert(markdown, 'Run `.tools/lune-0.10.5/lune.exe run tools/moonlit-citadel/phase3/drafts/CheckWorldPlan.luau` after an affected source change. BL02 bounds remain conservative where holes exist; no candidate-wide exemption was used. Existing apparatus/skins outside WorldPlan, native movement/camera views, human pacing, crowd behavior and device comfort remain separate verification. No production source or Studio state was edited by this check.')
fs.writeFile('docs/artifacts/moonlit-citadel/phase3/drafts/WORLD_CLEARANCE_REPORT.md', table.concat(markdown, '\n') .. '\n')
print('RouteBody=' .. #routeBody .. '; all world findings=' .. (#result.findings - #routeBody))
print(serde.encode('json', totals))
for index = 1, math.min(12, #groups) do print(serde.encode('json', groups[index])) end
print(output)
