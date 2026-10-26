local fs, luau, roblox, serde, process = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde"), require("@lune/process")
local environment = {}
for name, value in roblox do environment[name] = value end
local C = table.clone(roblox.CFrame)
local V = roblox.Vector3
-- This bundled Lune lookAt reverses target Z; use Roblox's actual basis.
function C.lookAt(origin, target, up)
 local look = (target - origin).Unit
 local right = look:Cross(up or V.yAxis).Unit
 return roblox.CFrame.fromMatrix(origin, right, right:Cross(look), -look)
end
environment.CFrame = C
local directory = "src/ServerStorage/CourseBuilders/EggRush/RestartR01/"
for _, name in {"Builder", "Study", "Sample", "Checks"} do
 assert(luau.load(fs.readFile(directory .. name .. ".luau")))
end
local sample = luau.load(fs.readFile(directory .. "Sample.luau"), {environment = environment})()
environment.script = {Parent = {Sample = "RestartR01Sample"}}
environment.require = function(module)
 assert(module == "RestartR01Sample", "Unexpected Study dependency")
 return sample
end
local study = luau.load(fs.readFile(directory .. "Study.luau"), {environment = environment})()
local kit = roblox.Instance.new("Folder")
kit.Name = "PhysicalContactsOnlyKitSubstitute"
for _, name in {"ShellFragment", "ShellLeafWide", "ShellLeafCrown", "ShellHingeWide", "ShellHingeCrown", "RockSupportLow",
 "BareRock", "WarningBeacon", "WorkshopBay", "SortingShed", "MintPipeArch", "PipeElbow", "PipeStraight", "ShrubGroup", "NestRing", "EggDisplay"} do
 local model = roblox.Instance.new("Model")
 model.Name, model.Parent = name, kit
 model:SetAttribute("ERAsset", name)
 local part = roblox.Instance.new("Part")
 part.Name, part.Parent = "ArtSubstitute", model
 part.Size, part.CFrame, part.Position = V.one, C.identity, V.zero
 if name == "WarningBeacon" then part:SetAttribute("ERMaterial", "Amber") end
end
local course = study.Build(kit)
assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1)
assert(course.CourseInfo:GetAttribute("Enabled") == false and course.CourseInfo:GetAttribute("LapCount") == 3)
assert(#course.Checkpoints:GetChildren() == 4 and course.Decoration:FindFirstChild("Shellworks_R01"))
assert(not course.Decoration:FindFirstChild("WorldFinished") and not course.Decoration:FindFirstChild("MechanismFinished"))
local o = course.Obstacles
local approach = course.Routes.S3_ShellApproach:GetChildren()
table.sort(approach, function(a, b) return a.Name < b.Name end)
assert(#approach == 4, "The selected sample has four short approach fragments")
for _, ref in approach do
 local pad = assert(ref.Value)
 assert(pad.CanCollide and pad.CanQuery and pad.Anchored and pad:IsDescendantOf(o.S3_ShellApproach))
 assert(pad.Size.X == 8 and pad.Size.Z == 4.5, "Approach contact remains a short landing")
 assert(math.abs((pad.CFrame.Position + pad.CFrame.UpVector * pad.Size.Y / 2 - pad:GetAttribute("ERTop")).Magnitude) < 1e-4)
end
local red = o.Shellworks_RedHop
assert(red:GetAttribute("ERLethal") == true and red.Transparency < 1 and red.CanQuery and not red.CanCollide)
assert(red:GetAttribute("ERPadName") == approach[2].Value.Name and red:GetAttribute("ERNextPadName") == approach[3].Value.Name)
local shells, sounds = 0, 0
for _, model in o.Mechanisms:GetChildren() do
 if model:GetAttribute("ERMechanism") ~= "ShellLip" then continue end
 shells += 1
 local contact = model.ShellContact
 local localFrame = model.WorldPivot:ToObjectSpace(contact.CFrame)
 local expert = model.Name:match("^Crown") ~= nil
 local width = if expert then 6 else 10
 assert((localFrame.Position - V.new(0, -1.25, -6.25)).Magnitude < 1e-3, "Contact follows the measured hinge pivot")
 assert((contact.Size - V.new(width, 2.5, 3.5)).Magnitude < 1e-5)
 assert(math.abs(localFrame.UpVector:Dot(V.yAxis) - 1) < 1e-5 and math.abs(localFrame.LookVector:Dot(-V.zAxis) - 1) < 1e-5)
 local nearEdge = -localFrame.Position.Z - contact.Size.Z / 2
 local farEdge = -localFrame.Position.Z + contact.Size.Z / 2
 assert(nearEdge >= 4.5 - 1e-3 and farEdge <= 8 + 1e-3, "No contact may span the rear open recess")
 assert(math.abs(localFrame.Position.Y + contact.Size.Y / 2) < 1e-3, "Contact top matches visible front lip top0")
 assert(contact.CanCollide and contact.CanQuery and contact:GetAttribute("ERSupport") == true)
 local colliders = 0
 for _, part in model:GetDescendants() do
  if not part:IsA("BasePart") or not part.CanCollide then continue end
  colliders += 1
  assert(part.CanQuery and part.Anchored and part:GetAttribute("ERSupport") == true, "Every colliding moving part must be intentional support")
  local frame = model.WorldPivot:ToObjectSpace(part.CFrame)
  assert(frame.UpVector:Dot(V.yAxis) > .99999 and frame.LookVector:Dot(-V.zAxis) > .99999, "Rest support boxes use the measured shell frame")
  local minimum, maximum = frame.Position - part.Size / 2, frame.Position + part.Size / 2
  local half = (width + 2) / 2
  assert(minimum.X >= -half - 1e-3 and maximum.X <= half + 1e-3
   and minimum.Z >= -8 - 1e-3 and maximum.Z <= 1e-3
   and minimum.Y >= -3.4 - 1e-3 and maximum.Y <= 1e-3, "Moving support extends outside the shell body")
  local recessLow, recessHigh = V.new(-half + 2, -2.5, -4.5), V.new(half - 2, 0, -1.4)
  local crossesRecess = math.min(maximum.X, recessHigh.X) - math.max(minimum.X, recessLow.X) > 1e-3
   and math.min(maximum.Y, recessHigh.Y) - math.max(minimum.Y, recessLow.Y) > 1e-3
   and math.min(maximum.Z, recessHigh.Z) - math.max(minimum.Z, recessLow.Z) > 1e-3
  assert(not crossesRecess, "A moving contact fills the open cup above its actual lower floor")
 end
 assert(colliders == 8, "Eight solid contacts reproduce the visible shell volumes")
 local lamp = assert(model.Warning.Value)
 local sound = lamp:FindFirstChild("WarningSound")
 assert(sound and sound:IsA("Sound") and sound.SoundId ~= "" and sound.Volume > 0)
 sounds += 1
end
local referencedShells = #course.Routes.R01_NormalShells:GetChildren() + #course.Routes.E3_MovingCrown:GetChildren()
assert(shells == referencedShells and sounds == shells, "Every fresh referenced Normal/Crown shell has one configured warning sound")

local function surface(part)
 local corners = {}
 for _, signs in {{-1,-1}, {1,-1}, {1,1}, {-1,1}} do
  local point = part.CFrame * V.new(signs[1] * part.Size.X / 2, 0, signs[2] * part.Size.Z / 2)
  table.insert(corners, V.new(point.X, 0, point.Z))
 end
 return {part = part, corners = corners, top = part.CFrame.Position.Y + part.CFrame.UpVector.Y * part.Size.Y / 2}
end
local function interval(points, axis)
 local low, high = math.huge, -math.huge
 for _, point in points do low = math.min(low, point:Dot(axis)); high = math.max(high, point:Dot(axis)) end
 return low, high
end
local function pointSegment(point, first, last)
 local delta = last - first
 return (point - first - delta * math.clamp((point - first):Dot(delta) / delta:Dot(delta), 0, 1)).Magnitude
end
local function gap(a, b)
 local separated = false
 for _, points in {a.corners, b.corners} do
  for i = 1, 2 do
   local edge = points[i + 1] - points[i]
   local axis = V.new(-edge.Z, 0, edge.X).Unit
   local al, ah = interval(a.corners, axis)
   local bl, bh = interval(b.corners, axis)
   if ah < bl or bh < al then separated = true end
  end
 end
 if not separated then return 0 end
 local distance = math.huge
 for _, pair in {{a, b}, {b, a}} do
  for _, point in pair[1].corners do
   for i = 1, 4 do distance = math.min(distance, pointSegment(point, pair[2].corners[i], pair[2].corners[i % 4 + 1])) end
  end
 end
 return distance
end
local jumpVelocity = math.sqrt(2 * 196.2 * 7.2)
local function reach(rise)
 local discriminant = jumpVelocity * jumpVelocity - 2 * 196.2 * rise
 return if discriminant < 0 then -1 else 16 * (jumpVelocity + math.sqrt(discriminant)) / 196.2
end
local function name(part)
 return if part.Name == "ShellContact" then part.Parent.Name .. ".ShellContact" else part.Name
end
local function footprint(part)
 local shapes = {surface(part)}
 if part.Name == "ShellContact" then return shapes end
 for _, sibling in part.Parent:GetChildren() do
  if sibling:IsA("BasePart") and sibling.CanCollide and sibling.Name:match("^" .. part.Name .. "_Shoulder") then
   table.insert(shapes, surface(sibling))
  end
 end
 return shapes
end
local function actualGap(first, last)
 local distance = math.huge
 for _, a in footprint(first) do
  for _, b in footprint(last) do distance = math.min(distance, gap(a, b)) end
 end
 return distance
end
local tight, touching, links = {}, {}, {}
for _, line in {"Normal", "Expert"} do
 local points = sample.Points(course, line)
 assert(points[1].part == o.CP2_Pocket and points[#points].part == o.Shell_ExitWait)
 for i = 2, #points do
  local a, b = surface(points[i - 1].part), surface(points[i].part)
  local distance, rise = actualGap(a.part, b.part), b.top - a.top
  local allowed = reach(rise)
  local centralGap = gap(a, b)
  if i <= 6 then
   assert(distance >= 4.5 and distance <= allowed - .4, "Shared approach needs an open gap and jump reach margin")
  end
  local row = string.format("%s %s -> %s actualGap%.3f centralGap%.3f rise%.3f pointReach%.3f", line, name(a.part), name(b.part), distance, centralGap, rise, allowed)
  table.insert(links, {line = line, from = name(a.part), to = name(b.part), actualGap = distance, centralGap = centralGap, rise = rise, pointReach = allowed})
  print("LINK " .. row)
  if distance > allowed then table.insert(tight, row) end
  if distance < .01 then table.insert(touching, row) end
  assert(a.part:IsDescendantOf(course) and b.part:IsDescendantOf(course), "Routes must reference actual candidate contacts")
 end
end
for _, routeName in {"S3_ShellApproach", "E3_CrownApproach", "R01_NormalShells", "E3_MovingCrown"} do
 for _, ref in course.Routes[routeName]:GetChildren() do
  assert(ref:IsA("ObjectValue") and ref.Value and ref.Value:IsDescendantOf(course))
 end
end
print(string.format("R01_PHYSICAL_BOUNDARIES shells%d warnings%d; upper rear recess remains empty above floor-2.5; all front contacts top0", shells, sounds))
print(string.format("R01_SAMPLE_GEOMETRY %d links beyond ideal point reach; %d touching/overlapping links", #tight, #touching))
for _, row in tight do print("TIGHT " .. row) end
for _, row in touching do print("TOUCHING " .. row) end
print("LIMITS Physical surfaces and pivots only; substitute noncolliding art supplies no native mesh, appearance, audible sound, actual jump, wait, recovery or owner-approval proof.")
local artifactDirectory = "docs/artifacts/egg-rush-circuit/phase1/restart-r01/"
local routeEnvironment=table.clone(environment)
routeEnvironment.game={GetService=function()return {}end}
local routeLists=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/NativeTraversal.luau"),{environment=routeEnvironment})()
local studyMetrics={candidateId="ER_P1_R01",phase=1,laps=3,lines={},nativeVerified=false,
 limits="Static route distances and contact counts only. Distance/speed ignores jumps, moving waits, alignment, mistakes and recovery; it is not race pacing proof."}
for _,line in {"Normal","Expert"}do
 local path=routeLists.Points(course,line)
 local length,minHeight,maxHeight=0,math.huge,-math.huge
 for i,node in path do
  local point=node.part.CFrame.Position
  minHeight=math.min(minHeight,point.Y);maxHeight=math.max(maxHeight,point.Y)
  if i>1 then
   local delta=point-path[i-1].part.CFrame.Position
   length+=V.new(delta.X,0,delta.Z).Magnitude
  end
 end
 table.insert(studyMetrics.lines,{line=line,contacts=#path,horizontalStudsPerLap=length,
  minimumContactCenterY=minHeight,maximumContactCenterY=maxHeight,
  threeLapDistanceOver16=length*3/16})
end
fs.writeFile(artifactDirectory.."rough-study-metrics.json",serde.encode("json",studyMetrics,true).."\n")
fs.writeFile(artifactDirectory .. "geometry-checks.json", serde.encode("json", {
 candidateId = "ER_P1_R01", phase = 1, scope = "Offline actual Study/Sample physical surfaces; noncolliding art substitutes",
 nativeVerified = false, ownerApproval = false, shells = shells, configuredWarnings = sounds,
 links = links, beyondIdealReach = tight, touching = touching,
 limits = "Bounds are geometry only. No native mesh, human control, actual jump/recovery, audible sound, crowd, device or FPS proof.",
}, true) .. "\n")

if table.find(process.args, "--poses") then
 local function components(frame) return {frame:GetComponents()} end
 local function vector(value) return {value.X, value.Y, value.Z} end
 local function artAncestor(instance)
  local current = instance.Parent
  while current and current ~= course do
   if current:GetAttribute("ERArt") == true then return true end
   current = current.Parent
  end
  return false
 end
 local poses, nativeParts, contacts, mechanisms = {}, {}, {}, {}
 for _, instance in course:GetDescendants() do
  if instance:IsA("Model") and instance:GetAttribute("ERArt") == true then
   local substitute = assert(instance:FindFirstChild("ArtSubstitute"))
   table.insert(poses, {asset = assert(instance:GetAttribute("ERAsset")), name = instance.Name,
    path = instance:GetFullName(), pivotCFrame = components(instance.WorldPivot), scale = vector(substitute.Size)})
  elseif instance:IsA("BasePart") and not artAncestor(instance) then
   local samplePart = instance:IsDescendantOf(course.Decoration.Shellworks_R01)
    or instance:IsDescendantOf(o.S3_ShellApproach) or instance.Name:match("^Shell_")
    or instance.Name == "CP2_Pocket" or instance.Name == "Shellworks_RedHop" or instance.Name:match("^Choice_")
   local parent = instance.Parent
   local shellMechanism = parent and parent:IsA("Model") and parent:GetAttribute("ERMechanism") == "ShellLip"
   if samplePart or shellMechanism then
    local row = {name = instance.Name, path = instance:GetFullName(), size = vector(instance.Size),
     cframe = components(instance.CFrame), transparency = instance.Transparency, canCollide = instance.CanCollide,
     mechanism = if shellMechanism then parent.Name else nil}
    if instance.CanCollide then table.insert(contacts, row) end
    if instance.Transparency < 1 then
     local color = instance.Color
     row.color = {color.R, color.G, color.B}
     row.material, row.topSurface = tostring(instance.Material), tostring(instance.TopSurface)
     table.insert(nativeParts, row)
    end
   end
  elseif instance:IsA("Model") and instance:GetAttribute("ERMechanism") == "ShellLip" then
   table.insert(mechanisms, {name = instance.Name, pivotCFrame = components(instance.WorldPivot),
    closedAngleDegrees = instance:GetAttribute("ClosedAngleDegrees"), rotationAxis = vector(instance:GetAttribute("RotationAxis"))})
  end
 end
 fs.writeFile(artifactDirectory .. "sample-poses.json", serde.encode("json", {
  candidateId = "ER_P1_R01", phase = 1, origin = vector(study.Origin),
  sourcePaths = {directory .. "Study.luau", directory .. "Sample.luau"},
  source = "Actual Study/Sample placement with unit-size noncolliding art substitutes carrying ERAsset names",
  pose = "Open rest pose, with physical contacts and selected native visible sample parts",
  decisionPoint = vector(o.Shell_ForkWait:GetAttribute("ERTop")),
  art = poses, nativeParts = nativeParts, contacts = contacts, mechanisms = mechanisms,
  nativeVerified = false, ownerApproval = false,
  limits = "Offline placement visualization input only; not a native import, rendered Studio view, collision/playback test or owner assessment.",
 }, true) .. "\n")
 print(string.format("R01_POSES art%d nativeParts%d contacts%d mechanisms%d", #poses, #nativeParts, #contacts, #mechanisms))
end
assert(#tight == 0, "Review the listed R01 links beyond ideal point-jump reach before native movement")
assert(#touching == 0, "Sample consecutive contacts must keep open gaps")
