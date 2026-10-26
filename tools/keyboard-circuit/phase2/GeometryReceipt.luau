local c = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local s = game.ServerStorage
local builders = s.CourseBuilders.KeyboardCircuitPhase2
local units, contacts, blockers, mismatches, failures = {}, {}, {}, {}, {}
local counts = {descendants = #c:GetDescendants(), parts = 0, meshes = 0, colliders = 0, queryParts = 0, touchParts = 0, lights = 0, constraints = 0, surfaceGuis = 0, mechanisms = 0, sequences = 0}
local meshIds, textures = {}, {}
local function v(p) return {p.X, p.Y, p.Z} end
local function row(item)
 return {path = item:GetFullName():sub(#c:GetFullName() + 2), position = v(item.Position), cf = {item.CFrame:GetComponents()}, size = v(item.Size), role = item:GetAttribute("Role")}
end
for _, item in c:GetDescendants() do
 if item:GetAttribute("SequenceId") or item:GetAttribute("GateId") or item:GetAttribute("ExpertId") then
  local id = item:GetAttribute("SequenceId") or item:GetAttribute("GateId") or item:GetAttribute("ExpertId")
  local a, b = item:GetAttribute("EntryPosition"), item:GetAttribute("ExitPosition")
  units[id] = {path = item:GetFullName():sub(#c:GetFullName() + 2), entry = a and v(a), exit = b and v(b), family = item:GetAttribute("KeyFamily"), recovery = item:GetAttribute("RecoveryCheckpoint"), precisionLandings = item:GetAttribute("PrecisionLandings")}
 end
 if item:GetAttribute("MechanismId") then counts.mechanisms += 1 end
 if item:GetAttribute("SequenceId") then counts.sequences += 1 end
 if item:IsA("BasePart") then
  counts.parts += 1
  if item.CanCollide then counts.colliders += 1 end
  if item.CanQuery then counts.queryParts += 1 end
  if item.CanTouch then counts.touchParts += 1 end
  if item.Name == "BankContact" or item.Name == "KeyContact" then table.insert(contacts, row(item))
  elseif item.CanCollide then table.insert(blockers, row(item)) end
 end
 if item:IsA("MeshPart") then
  counts.meshes += 1
  meshIds[item.MeshId], textures[item.TextureID] = true, true
  local visible = 0
  for _, gui in item:GetChildren() do if gui:IsA("SurfaceGui") and gui.Enabled then visible += 1 end end
  if visible ~= 1 or utf8.len(item:GetAttribute("KeyLegend") or "") ~= 1 then table.insert(failures, item:GetFullName()) end
 end
 if item:IsA("SurfaceGui") then counts.surfaceGuis += 1 end
 if item:IsA("Light") then counts.lights += 1 end
 if item:IsA("Constraint") then counts.constraints += 1 end
 if item:IsA("ObjectValue") and item.Value and not item.Value:IsDescendantOf(c) then table.insert(failures, item:GetFullName() .. " external object") end
 if item:IsA("WeldConstraint") and (not item.Part0:IsDescendantOf(c) or not item.Part1:IsDescendantOf(c)) then table.insert(failures, item:GetFullName() .. " external weld") end
end
for _, model in {c, s.CourseAssetKits.KeyboardCircuit_Phase2EditableKit_K02} do
 for _, source in builders:GetChildren() do
  local snapshot = model.SourceSnapshot:FindFirstChild(source.Name)
  if not snapshot or snapshot.Source:gsub("\r\n", "\n") ~= source.Source:gsub("\r\n", "\n") then table.insert(mismatches, model.Name .. ":" .. source.Name) end
 end
end
local function keys(map) local list = {}; for key in map do table.insert(list, key) end; table.sort(list); return list end
local pivot, size = c:GetBoundingBox()
return game:GetService("HttpService"):JSONEncode({revision = c:GetAttribute("KCPhase2Revision"), iteration = c:GetAttribute("ConstructionIteration"), counts = counts, contacts = contacts, blockers = blockers, units = units, meshIds = keys(meshIds), textureIds = keys(textures), sourceMismatches = mismatches, failures = failures, routeEdges = #c.RouteEdges:GetChildren(), recoveryBanks = #c.RecoveryPads:GetChildren(), gates = #c.Gates:GetChildren(), bounds = {position = v(pivot.Position), size = v(size)}, limits = "Actual native Edit construction/rest poses and source agreement; dynamic gameplay requires separate playtest receipts"})
