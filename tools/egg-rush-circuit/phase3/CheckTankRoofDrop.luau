--!nonstrict
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Check = {Revision = "ER_P3_TANK_ROOF_DROP_A01"}
local EPSILON = 0.001

local function point3(value)
 return {value.X, value.Y, value.Z}
end

local function point2(value)
 return {value.X, value.Y}
end

local function rectangle(part)
 local half = part.Size / 2
 local vertices = {}
 for _, corner in {{-1,-1},{1,-1},{1,1},{-1,1}} do
  local world = part.CFrame:PointToWorldSpace(Vector3.new(corner[1]*half.X, half.Y, corner[2]*half.Z))
  table.insert(vertices, Vector2.new(world.X, world.Z))
 end
 return vertices
end

local function axisValue(point, axis)
 return if axis == "X" then point.X else point.Y
end

local function clip(polygon, axis, boundary, keepGreater)
 local result = {}
 if #polygon == 0 then return result end
 local previous = polygon[#polygon]
 local previousValue = axisValue(previous, axis)
 local previousInside = if keepGreater then previousValue >= boundary else previousValue <= boundary
 for _, current in polygon do
  local currentValue = axisValue(current, axis)
  local currentInside = if keepGreater then currentValue >= boundary else currentValue <= boundary
  if currentInside ~= previousInside then
   local alpha = (boundary - previousValue) / (currentValue - previousValue)
   table.insert(result, previous:Lerp(current, alpha))
  end
  if currentInside then table.insert(result, current) end
  previous, previousValue, previousInside = current, currentValue, currentInside
 end
 return result
end

local function clipToBox(polygon, minX, maxX, minZ, maxZ)
 local result = clip(polygon, "X", minX, true)
 result = clip(result, "X", maxX, false)
 result = clip(result, "Z", minZ, true)
 return clip(result, "Z", maxZ, false)
end

local function area(polygon)
 if #polygon < 3 then return 0 end
 local sum = 0
 for index, p in polygon do
  local q = polygon[index % #polygon + 1]
  sum += p.X * q.Y - q.X * p.Y
 end
 return math.abs(sum) / 2
end

local function serializedPolygon(polygon)
 local result = {}
 for _, point in polygon do table.insert(result, point2(point)) end
 return result
end

local function extrema(polygon)
 local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
 for _, p in polygon do
  minX, maxX = math.min(minX,p.X), math.max(maxX,p.X)
  minZ, maxZ = math.min(minZ,p.Y), math.max(maxZ,p.Y)
 end
 return minX, maxX, minZ, maxZ
end

local function flatBlock(part, label)
 assert(part and part:IsA("Part") and part.Shape == Enum.PartType.Block, label .. " must be a block Part")
 assert(part.CFrame.UpVector:Dot(Vector3.yAxis) > 1 - 0.000001
  and math.abs(part.CFrame.RightVector.Y) < 0.00001 and math.abs(part.CFrame.LookVector.Y) < 0.00001,
  label .. " must be horizontal and upright")
 assert(not part:FindFirstChildWhichIsA("DataModelMesh"), label .. " has a mesh that changes its rendered shape")
end

local function isOnRoof(roof, x, z)
 local localPoint = roof.CFrame:PointToObjectSpace(Vector3.new(x, roof.CFrame.Position.Y, z))
 return math.abs(localPoint.X) <= roof.Size.X/2 + EPSILON and math.abs(localPoint.Z) <= roof.Size.Z/2 + EPSILON
end

local function properties(part)
 return {
  path = part:GetFullName(), class = part.ClassName, size = point3(part.Size),
  frame = {part.CFrame:GetComponents()}, transparency = part.Transparency,
  localTransparencyModifier = part.LocalTransparencyModifier,
  canCollide = part.CanCollide, canQuery = part.CanQuery, canTouch = part.CanTouch,
  collisionGroup = part.CollisionGroup,
 }
end

-- Read-only Edit check; the bounded strip is not a complete falling-avatar simulation.
function Check.Run(course, options)
 assert(RunService:IsStudio() and not RunService:IsRunning(), "Run in stable Studio Edit mode")
 assert(course and course:IsA("Model") and course:IsDescendantOf(Workspace), "Pass the actual Workspace course model")
 options = options or {}
 local westWidth = options.WestWidth or 16
 local spacing = options.Spacing or 2
 assert(type(westWidth) == "number" and westWidth > 0 and westWidth <= 32, "WestWidth must be within (0, 32]")
 assert(type(spacing) == "number" and spacing >= 0.5 and spacing <= 4, "Spacing must be within [0.5, 4]")

 local tray = assert(course.Obstacles.Mechanisms:FindFirstChild("SidewaysTray"), "Missing outward tray")
 local contact = assert(tray:FindFirstChild("TrayContact"), "Missing outward tray contact")
 local fall = assert(course.FallZones:FindFirstChild("FallZone_Main"), "Missing fall zone")
 local service = assert(course.Decoration.HatcheryWorld.Incubation:FindFirstChild("TankEastService"), "Missing TankEastService")
 local roof = assert(service:FindFirstChild("RoofDeck"), "Missing TankEastService RoofDeck")
 flatBlock(contact, "TrayContact")
 flatBlock(fall, "FallZone_Main")
 flatBlock(roof, "RoofDeck")

 local travel = tray:GetAttribute("Travel")
 assert(typeof(travel) == "Vector3", "Tray travel must be a Vector3")
 local worldTravel = tray:GetPivot():VectorToWorldSpace(travel)
 assert(math.abs(worldTravel.X) < EPSILON and math.abs(worldTravel.Y) < EPSILON and math.abs(worldTravel.Z) > EPSILON,
  "Expected the outward tray to travel only along world Z")
 local trayCorners = rectangle(contact)
 local west, east, startMinZ, startMaxZ = extrema(trayCorners)
 local rectangleArea = (east-west) * (startMaxZ-startMinZ)
 assert(math.abs(area(trayCorners)-rectangleArea) < 0.01, "Expected an axis-aligned tray contact")
 local minZ, maxZ = math.min(startMinZ,startMinZ+worldTravel.Z), math.max(startMaxZ,startMaxZ+worldTravel.Z)
 local minX, maxX = west-westWidth, west
 local trayTop = contact.CFrame:PointToWorldSpace(Vector3.new(0,contact.Size.Y/2,0)).Y
 local fallTop = fall.CFrame:PointToWorldSpace(Vector3.new(0,fall.Size.Y/2,0)).Y
 local roofTop = roof.CFrame:PointToWorldSpace(Vector3.new(0,roof.Size.Y/2,0)).Y
 assert(trayTop > fallTop + EPSILON, "Tray must be above the fall zone")

 local roofCorners = rectangle(roof)
 local roofIntersection = clipToBox(roofCorners,minX,maxX,minZ,maxZ)
 local roofArea = area(roofIntersection)
 local fallCorners = rectangle(fall)
 local fallIntersection = clipToBox(fallCorners,minX,maxX,minZ,maxZ)
 local prismArea = (maxX-minX)*(maxZ-minZ)
 local fallCoverageArea = area(fallIntersection)
 local roofInHeight = roofTop >= fallTop - EPSILON and roofTop <= trayTop + EPSILON
 local roofWithinRaySegment = roofTop >= fallTop + EPSILON and roofTop <= trayTop - EPSILON
 local roofVisible = roof.Transparency < 1 and roof.LocalTransparencyModifier < 1

 local collisionGroup = options.CollisionGroup or "Default"
 assert(type(collisionGroup) == "string" and collisionGroup ~= "", "CollisionGroup must be a nonempty string")
 local rays = RaycastParams.new()
 rays.RespectCanCollide = true
 rays.CollisionGroup = collisionGroup
 rays.IgnoreWater = true
 local rows, hits = {}, {}
 local countX, countZ = math.ceil((maxX-minX)/spacing), math.ceil((maxZ-minZ)/spacing)
 local report = {
  revision = Check.Revision, candidate = course:GetAttribute("CandidateId"),
  course = course:GetFullName(), collisionGroup = collisionGroup,
  collisionGroupExplicit = options.CollisionGroup ~= nil,
  tray = properties(contact), roof = properties(roof), fallZone = properties(fall),
  trayTravelWorld = point3(worldTravel), trayTopY = trayTop, roofTopY = roofTop, fallTopY = fallTop,
  dropFromTrayToRoof = trayTop-roofTop, roofAboveFallZone = roofTop-fallTop,
  prism = {minX=minX,maxX=maxX,minZ=minZ,maxZ=maxZ,bottomY=fallTop,topY=trayTop,
   westWidth=westWidth,area=prismArea,description="West of the moving outward tray, across its full swept Z span and down to the fall-zone top"},
  roofFootprint = serializedPolygon(roofCorners), roofIntersection = serializedPolygon(roofIntersection),
  roofIntersectionArea = roofArea, roofTopInsidePrismHeight = roofInHeight,
  roofTopCoveredByRaySegment = roofWithinRaySegment, roofVisibleByProperties = roofVisible,
  fallZoneIntersectionArea = fallCoverageArea, fallZoneCoversPrism = math.abs(prismArea-fallCoverageArea) < 0.01,
  rays = {spacingRequested=spacing,columns=countX,rows=countZ,total=0,roofSamples=0,
   roofSamplesUnblockedAboveRoof=0,roofSamplesBlockedAboveRoof=0,hits=hits,roofSampleResults=rows},
  limits = {
   "The prism spans the entire tray travel and full vertical drop within the stated westward width; it is not every possible sideways trajectory.",
   "The flat block footprint intersection is exact for its CFrame and Size; it does not establish which pixels another object hides.",
   "Downward rays are samples, not full-volume coverage. They respect CanCollide and the selected collision group, but not moving-avatar size, motion or touch events.",
   "Default is an assumed ray collision group unless the actual racer's group is supplied; ignored water and other local client visibility may differ.",
   "This checks one roof, one tray side and the static Edit scene. A moving-avatar fall and recovery are separate evidence.",
  },
 }

 local function sample(x,z,kind)
  local origin = Vector3.new(x,trayTop-EPSILON,z)
  local hit = Workspace:Raycast(origin,Vector3.new(0,fallTop-trayTop+2*EPSILON,0),rays)
  local onRoof = roofArea > EPSILON and roofWithinRaySegment and isOnRoof(roof,x,z)
  local blockedAboveRoof = hit ~= nil and hit.Position.Y >= roofTop-EPSILON
  report.rays.total += 1
  if hit then
   local basePart = hit.Instance:IsA("BasePart")
   table.insert(hits,{sample={x,z},kind=kind,path=hit.Instance:GetFullName(),position=point3(hit.Position),
    canCollide=if basePart then hit.Instance.CanCollide else nil,
    collisionGroup=if basePart then hit.Instance.CollisionGroup else nil,aboveRoof=blockedAboveRoof})
  end
  if onRoof then
   report.rays.roofSamples += 1
   if blockedAboveRoof then report.rays.roofSamplesBlockedAboveRoof += 1
   else report.rays.roofSamplesUnblockedAboveRoof += 1 end
   table.insert(rows,{sample={x,z},kind=kind,blockedAboveRoof=blockedAboveRoof,
    firstHit=if hit then hit.Instance:GetFullName() else nil,firstHitY=if hit then hit.Position.Y else nil})
  end
 end

 for column=1,countX do
  local x = minX+(column-.5)*(maxX-minX)/countX
  for row=1,countZ do
   local z = minZ+(row-.5)*(maxZ-minZ)/countZ
   sample(x,z,"grid")
  end
 end
 if roofArea > EPSILON and roofWithinRaySegment then
  local center = Vector2.zero
  for _, vertex in roofIntersection do center += vertex end
  center /= #roofIntersection
  sample(center.X,center.Y,"roofIntersectionInterior")
 end

 report.visibleRoofInPrism = roofArea > EPSILON and roofInHeight and roofVisible
 report.finding = if report.visibleRoofInPrism then "VISIBLE_FLAT_ROOF_WITHIN_DEFINED_FALL_PRISM" else "NO_VISIBLE_FLAT_ROOF_IN_DEFINED_PRISM"
 return report
end

return Check
