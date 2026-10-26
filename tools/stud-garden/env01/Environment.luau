--!strict
local Kit = require(script.Parent.Kit)
local Environment = {}

local WALLS = { ToolsToPlanters = true, CropUpperFold = true, CropMainToExpert = true, CropReturnToExpert = true, CropToCandy = true }
local CROPS = { CropCarrot = true, CropStrawberry = true, CropBamboo = true, CropSunflower = true, Flower = true }
local RIBBONS = {
 { path = { "B1Planting", "SunflowerBed1" }, position = Vector3.new(-66, 2.4, 15), length = 44, yaw = 0, crop = "Strawberry" },
 { path = { "M1APlanting", "StrawberryBed1" }, position = Vector3.new(5, 3.4, 202), length = 48, yaw = 0, crop = "Carrot" },
 { path = { "M1BPlanting", "BambooBed2" }, position = Vector3.new(153, 3.4, 208), length = 78, yaw = math.pi / 2, crop = "Strawberry" },
 { path = { "M1CPlanting", "BambooBed1" }, position = Vector3.new(227, 3.4, 170), length = 44, yaw = 0, crop = "Carrot" },
 { path = { "B3Planting", "SunflowerBed1" }, position = Vector3.new(125, 4.4, 22), length = 44, yaw = 0, crop = "Strawberry" },
}

local function move(group: Model, from: CFrame, to: CFrame)
 local delta = to * from:Inverse()
 for _, object in group:GetDescendants() do
  if object:IsA("BasePart") then object.CFrame = delta * object.CFrame end
  if object:IsA("Model") then
   local ok, pivot = pcall(function() return object.WorldPivot end)
   if ok then object.WorldPivot = delta * pivot end
  end
 end
 group.WorldPivot = to
end

local function frameOf(bed: Model): CFrame
 return (bed:FindFirstChild("Soil") :: BasePart).CFrame * CFrame.new(0, 0.28, 0)
end

local function axisHalf(frame: CFrame, size: Vector3): Vector3
 return Vector3.new(
  math.abs(frame.RightVector.X) * size.X / 2 + math.abs(frame.UpVector.X) * size.Y / 2 + math.abs(frame.LookVector.X) * size.Z / 2,
  math.abs(frame.RightVector.Y) * size.X / 2 + math.abs(frame.UpVector.Y) * size.Y / 2 + math.abs(frame.LookVector.Y) * size.Z / 2,
  math.abs(frame.RightVector.Z) * size.X / 2 + math.abs(frame.UpVector.Z) * size.Y / 2 + math.abs(frame.LookVector.Z) * size.Z / 2
 )
end

local function clear(frame: CFrame, size: Vector3, layout: any, origin: CFrame, margin: number): boolean
 local center = origin:PointToObjectSpace(frame.Position)
 local half = axisHalf(origin:ToObjectSpace(frame), size)
 local function overlap(position: Vector3, rectangleSize: Vector3): boolean
  return math.abs(center.X - position.X) < half.X + rectangleSize.X / 2 + margin
   and math.abs(center.Z - position.Z) < half.Z + rectangleSize.Z / 2 + margin
 end
 for _, sequence in layout.sequences do
  for i, point in sequence.points do
   if overlap(point.position, point.size) then return false end
   local following = sequence.points[i + 1]
   if following then
    local midpoint = (point.position + following.position) / 2
    local corridor = Vector3.new(
     math.abs(following.position.X - point.position.X) + math.min(point.size.X, following.size.X),
     2,
     math.abs(following.position.Z - point.position.Z) + math.min(point.size.Z, following.size.Z)
    )
    if overlap(midpoint, corridor) then return false end
   end
  end
 end
 for _, collection in { layout.checkpoints, layout.choices, layout.merges } do
  for _, point in collection do
   if overlap(point.position, point.size) then return false end
   if point.spawnPosition and overlap(point.spawnPosition, point.spawnSize) then return false end
  end
 end
 for _, hazard in layout.hazards do
  for _, rectangle in { hazard.volume, hazard.crossing, hazard.safeBefore, hazard.safeAfter } do
   if overlap(rectangle.position, rectangle.size) then return false end
  end
 end
 if overlap(layout.finish.position, layout.finish.size) or overlap(layout.finish.runoff.position, layout.finish.runoff.size) then return false end
 for _, barrier in layout.barriers do if overlap(barrier.position, barrier.size) then return false end end
 return true
end

local function reshapeBed(bed: Model, frame: CFrame, width: number, length: number, ground: number, top: number, colors: any)
 local height = top - ground
 local shapes = {
  Soil = { Vector3.new(0,-0.28,0), Vector3.new(width,0.55,length), colors.Soil },
  LongTrim1 = { Vector3.new(0,-0.48,-length/2), Vector3.new(width+0.35,1.05,0.38), colors.Honey },
  LongTrim2 = { Vector3.new(0,-0.48,length/2), Vector3.new(width+0.35,1.05,0.38), colors.Honey },
  EndTrim1 = { Vector3.new(-width/2,-0.48,0), Vector3.new(0.38,1.05,length), colors.HoneyLight },
  EndTrim2 = { Vector3.new(width/2,-0.48,0), Vector3.new(0.38,1.05,length), colors.HoneyLight },
  SoilFoundation = { Vector3.new(0,-height/2-0.35,0), Vector3.new(width-0.15,height,length-0.15), colors.SoilLight },
  GrassEdge = { Vector3.new(0,-0.35,0), Vector3.new(width+0.22,0.32,length+0.22), colors.LeafLight },
  GroundSoilPatch = { Vector3.new(0,ground-top+0.025,0), Vector3.new(width+1.4,0.05,length+1.2), colors.Soil },
 }
 for name, data in shapes do
  local part = bed:FindFirstChild(name)
  if part and part:IsA("BasePart") then part.CFrame, part.Size, part.Color = frame * CFrame.new(data[1]), data[2], data[3] end
 end
 bed:SetAttribute("EnvironmentRevision", "SG_ENV_01")
 bed:SetAttribute("SurfaceIntent", "Fully planted scenery outside the unchanged racing corridor")
end

local function leaves(parent: Model, frame: CFrame, index: number, colors: any)
 local foliage = Kit.LeafMass(parent, frame * CFrame.Angles(0, index * 1.13, 0), 1.05 + (index % 3) * 0.1, colors)
 foliage.Name = "Foliage" .. index
 return foliage
end

local function ribbon(bed: Model, record: any, layout: any, origin: CFrame, colors: any, option: string): boolean
 local width = 8.4
 local length = if option == "TerracedRows" then record.length else math.min(record.length, 22)
 local frame = origin * CFrame.new(record.position) * CFrame.Angles(0, record.yaw, 0)
 if not clear(frame, Vector3.new(width + 1.5, 1, length + 1.5), layout, origin, 1.7) then return false end
 local oldFrame = frameOf(bed)
 local existing = {}
 for _, child in bed:GetChildren() do
  if child:IsA("Model") and CROPS[child:GetAttribute("StudGardenFamily")] then table.insert(existing, { model=child, frame=oldFrame }) end
 end
 move(bed, oldFrame, frame)
 reshapeBed(bed, frame, width, length, layout.groundY, record.position.Y, colors)
 local count = #existing
 for index, item in existing do
  local offset = Vector3.new(if index % 2 == 0 then -1.35 else 1.35,0.06,(index/(count+1)-0.5)*(length-5))
  local first = item.model:GetChildren()[1]
  local localFrame = frame
  if first and first:IsA("BasePart") then
   local family = item.model:GetAttribute("StudGardenFamily")
   local y = if family == "CropSunflower" then 1.9 elseif family == "CropBamboo" then 2.1 elseif family == "CropCarrot" then 1.45 elseif family == "CropStrawberry" then 0.36 else 0.3
   local scale = item.model:GetAttribute("AuthoredScale") or 1
   localFrame = first.CFrame * CFrame.new(0,-y*scale,0)
  end
  move(item.model, localFrame, frame * CFrame.new(offset) * CFrame.Angles(0,index*0.8,0))
 end
 local mass = Kit.Model(bed,"Environment01","ConnectedPlantedBorder")
 local stations = math.min(7,math.max(3,math.floor(length/9)))
 for station=1,stations do
  local z = (station/(stations+1)-0.5)*(length-5)
  leaves(mass,frame*CFrame.new(if station%2==0 then -0.65 else 0.65,0.02,z),station,colors)
  if station%2==0 then Kit[record.crop](mass,frame*CFrame.new(2.25,0.04,z+1.25)*CFrame.Angles(0,station*0.6,0),1.2,colors) end
 end
 return true
end

local function sprinklerBorders(art: Model, origin: CFrame, layout: any, colors: any)
 local borders = art.CloseGarden.H01PlantedBorders
 for row, x in { 2, 44 } do
  local bed = borders:FindFirstChild("MixedCropBorder"..row) :: Model
  local frame = frameOf(bed)
  reshapeBed(bed,frame,9,46,layout.groundY,2.2,colors)
  local group = Kit.Model(bed,"Environment01","SprinklerCropMass")
  for index=1,6 do
   leaves(group,frame*CFrame.new(if row==1 then -1.4 else 1.4,0.02,(index-3.5)*6.8),index,colors)
  end
  for index=1,2 do
   Kit.Flower(group,frame*CFrame.new(if row==1 then 2.6 else -2.6,0.03,if index==1 then -16 else 16),1.1,colors,colors.White)
  end
 end
end

local function dividerGardens(art: Model, course: Model, layout: any, origin: CFrame, colors: any)
 local group = Kit.Model(art.Environment01,"DividerGardens","PlantedDividerFaces")
 for _, record in layout.barriers do
  if not WALLS[record.id] then continue end
  local alongX = record.size.X > record.size.Z
  local length = math.max(record.size.X, record.size.Z)
  local width = math.min(record.size.X, record.size.Z)
  local frame = origin * CFrame.new(record.position) * CFrame.Angles(0,if alongX then 0 else math.pi/2,0)
  local wall = Kit.Model(group,record.id,"DividerPlanting")
  for side=-1,1,2 do
   for band=1,2 do
    Kit.Part(wall,"TimberCourse"..side.."_"..band,frame*CFrame.new(0,-record.size.Y/2+4.4+band*4.0,side*(width/2+0.1)),Vector3.new(length,0.45,0.14),if band==1 then colors.WoodDark else colors.HoneyLight,{studs=false})
   end
   local stations=math.max(2,math.ceil(length/23))
   for station=1,stations do
    local x=(station/(stations+1)-0.5)*length
    local top=frame*CFrame.new(x,record.size.Y/2-1.0,side*(width/2+0.12))
    Kit.Part(wall,"TrailingStem"..side.."_"..station,top*CFrame.new(0,-3.8,0),Vector3.new(0.28,7.5,0.2),colors.Leaf,{studs=false})
    for leaf=1,2 do
     Kit.Part(wall,"WallLeaf"..side.."_"..station.."_"..leaf,top*CFrame.new(if leaf==1 then -0.85 else 0.8,-leaf*2.25,side*0.24)*CFrame.Angles(0,0,if leaf==1 then 0.35 else -0.4),Vector3.new(2.7,1.45,0.38),if leaf==1 then colors.LeafLight else colors.Leaf)
    end
    Kit.Part(wall,"Flower"..side.."_"..station,top*CFrame.new(0.1,-6.2,side*0.26),Vector3.new(0.85,0.7,0.35),if station%2==0 then colors.PinkLight else colors.Cream)
    Kit.Part(wall,"TopCrown"..side.."_"..station,top*CFrame.new(0,1.05,0)*CFrame.Angles(0,0,side*0.12),Vector3.new(math.min(15,length/stations*0.8),1.7,2.6),colors.LeafLight)
   end
  end
 end
end

local function landmarks(art: Model, colors: any, origin: CFrame)
 for _, model in art:GetDescendants() do
  if not model:IsA("Model") then continue end
  local family=model:GetAttribute("StudGardenFamily")
  if family=="LandmarkCandyBlossom" then
   local trunk=model:FindFirstChild("PinkTrunk") :: BasePart
   local scale=model:GetAttribute("AuthoredScale") or 1
   local frame=trunk.CFrame*CFrame.new(0,-4.6*scale,0)
   local nearGround=origin:PointToObjectSpace(frame.Position).Y<0
   local stretch=if nearGround then Vector3.new(1.35,1.3,1.3) else Vector3.new(1.4,1.0,1.35)
   for _, part in model:GetChildren() do
    if part:IsA("BasePart") then
     local relative=frame:ToObjectSpace(part.CFrame)
     part.CFrame=frame*CFrame.new(relative.Position*stretch)*relative.Rotation
     part.Size*=stretch
     if part.Name:sub(1,5)=="Crown" then part.Color=if part.Name=="CrownBase" then colors.Aqua else colors.AquaLight end
    end
   end
   local group=Kit.Model(model,"Environment01","VariedCandyCrown")
   for index,data in { {-4.2,11.4,2.1,4.8,2.6,4.2},{2.8,13.2,-1.8,4.8,2.8,4.5},{-0.9,14.2,0.9,4.9,1.8,4.7} } do
    Kit.Part(group,"CrownLobe"..index,frame*CFrame.new(Vector3.new(data[1],data[2],data[3])*scale*stretch),Vector3.new(data[4],data[5],data[6])*scale,if index%2==0 then colors.Aqua else colors.AquaLight)
   end
   model:SetAttribute("EnvironmentRevision","SG_ENV_01")
  elseif family=="LandmarkBeanstalk" then
   for _,part in model:GetChildren() do
    if not part:IsA("BasePart") then continue end
    if part.Name:sub(1,9)=="LeafBlade" then part.Size*=Vector3.new(1.35,1.1,1.18)
    elseif part.Name:sub(1,7)=="LeafTip" then part.Size*=Vector3.new(1.3,1.1,1.15)
    elseif part.Name:sub(1,7)=="BeanPod" then (part :: Part).Shape=Enum.PartType.Ball;part.Size*=Vector3.new(1.05,1.12,1.05) end
   end
   model:SetAttribute("EnvironmentRevision","SG_ENV_01")
  end
 end
end

function Environment.Representative(course: Model, cfg: any, layout: any, option: string?): any
 local choice=option or "TerracedRows"
 assert(choice=="TerracedRows" or choice=="CourtyardPockets","Unknown S02 composition")
 assert(course:GetAttribute("CourseId")=="stud_garden" and course:GetAttribute("LayoutRevision")=="SG_LAYOUT_04","Preserve the intended course layout")
 local art=course:FindFirstChild("Art") :: Model
 assert(art and not art:FindFirstChild("Environment01"),"Preserve the existing scenery revision")
 assert(art:GetAttribute("ArtRevision")=="SG_ART_03","A fresh art baseline is required")
 local colors=Kit.Colors(cfg.Palette)
 local origin=CFrame.new(cfg.Origin)
 local before=Kit.Inventory(course).parts
 local group=Kit.Model(art,"Environment01","StudGardenEnvironmentRevision")
 group:SetAttribute("Revision","SG_ENV_01")
 group:SetAttribute("Scope","S02 and neighboring landmark forms; awaiting native visual review")
 group:SetAttribute("Composition",choice)
 local results={option=choice,recomposedBeds={},skippedBeds={}}
 for _,record in RIBBONS do
  local bed=art.S02Finished:FindFirstChild(record.path[1]):FindFirstChild(record.path[2]) :: Model
  if ribbon(bed,record,layout,origin,colors,choice) then table.insert(results.recomposedBeds,table.concat(record.path,"/")) else table.insert(results.skippedBeds,table.concat(record.path,"/")) end
 end
 sprinklerBorders(art,origin,layout,colors)
 dividerGardens(art,course,layout,origin,colors)
 landmarks(art,colors,origin)
 local petFrame=origin*CFrame.new(-5,2.2,116)*CFrame.Angles(0,-math.pi/2,0)
 if clear(petFrame,Vector3.new(9,1,9),layout,origin,1.7) then
  local bed=Kit.Planter(group,petFrame,Vector3.new(8,1,8),colors)
  bed.Name="SprinklerRabbitGarden"
  Kit.Part(bed,"RootSoil",petFrame*CFrame.new(0,-3.7,0),Vector3.new(7.8,7.4,7.8),colors.SoilLight)
  Kit.Rabbit(bed,petFrame*CFrame.new(0,0.06,0),1.15,colors)
  Kit.Carrot(bed,petFrame*CFrame.new(2.3,0.02,-1.7),0.9,colors)
  Kit.Flower(bed,petFrame*CFrame.new(-2.6,0.02,-2.4),1.0,colors,colors.PinkLight)
  results.petAdded=true
 end
 results.inventory=Kit.Inventory(course)
 results.addedParts=results.inventory.parts-before
 assert(results.addedParts<=600,"Representative scenery exceeds its staging resource allowance")
 group:SetAttribute("AddedParts",results.addedParts)
 art:SetAttribute("EnvironmentRevision","SG_ENV_01_S02")
 return results
end

local function cropRoot(model: Model): CFrame
 local scale = model:GetAttribute("AuthoredScale") or 1
 local family = model:GetAttribute("StudGardenFamily")
 if family == "CropCarrot" then return model.RootShoulder.CFrame * CFrame.new(0, -1.45 * scale, 0) end
 if family == "CropStrawberry" then return model.BerryTip.CFrame * CFrame.new(0, -0.36 * scale, 0) end
 if family == "CropSunflower" then return model.Stem.CFrame * CFrame.new(0, -1.9 * scale, 0) end
 if family == "CropBamboo" then return model.Stem1.CFrame * CFrame.new(1.08 * scale, -2.1 * scale, 0) end
 return model.Leaves.CFrame * CFrame.new(0, -0.3 * scale, 0)
end

local function lowFoliage(model: Model, frame: CFrame?, amount: number?, colors: any)
 local originalScale = model:GetAttribute("AuthoredScale") or 1
 local root = frame or model.BranchStem.CFrame * CFrame.new(0, -2.9 * originalScale, 0)
 local scale = amount or originalScale
 local shapes = {
  BranchStem = {Vector3.new(0, 1.3, 0), Vector3.new(0.35, 2.6, 0.35), CFrame.identity, colors.Leaf},
  SlopedLeaf1 = {Vector3.new(-0.55, 1.1, 0), Vector3.new(3.45, 1.05, 3.55), CFrame.Angles(0.2, -0.35, 0.18), colors.Leaf},
  SlopedLeaf2 = {Vector3.new(0.55, 2.15, 0.35), Vector3.new(3.25, 1.1, 3.15), CFrame.Angles(-0.23, 1.2, -0.2), colors.LeafLight},
  SlopedLeaf3 = {Vector3.new(-0.15, 3.2, -0.1), Vector3.new(2.45, 0.95, 2.6), CFrame.Angles(0.22, 2.9, 0.14), colors.GrassLight},
  LeafVein = {Vector3.new(0.55, 2.43, 0.35), Vector3.new(0.12, 0.1, 2.6), CFrame.Angles(-0.23, 1.2, -0.2), colors.GrassLight},
 }
 for name, data in shapes do
  local part = model:FindFirstChild(name) :: BasePart
  part.CFrame = root * CFrame.new(data[1] * scale) * data[3]
  part.Size, part.Color = data[2] * scale, data[4]
 end
 model.WorldPivot = root
 model:SetAttribute("EnvironmentForm", "Low stepped crop foliage")
 model:SetAttribute("EnvironmentFoliageScale", scale)
end

local function cropIdentity(model: Model, minimumScale: number)
 local scale = model:GetAttribute("AuthoredScale") or 1
 local frame = cropRoot(model)
 local factor = math.max(1, minimumScale / scale)
 for _, part in model:GetChildren() do
  if not part:IsA("BasePart") then continue end
  local relative = frame:ToObjectSpace(part.CFrame)
  part.CFrame = frame * CFrame.new(relative.Position * factor) * relative.Rotation
  part.Size *= factor
  if part.Name:sub(1,4) == "Root" then part.Color = Color3.fromRGB(233,126,44)
  elseif part.Name:sub(1,5) == "Berry" then part.Color = if part.Name == "BerryShoulder" then Color3.fromRGB(238,76,57) else Color3.fromRGB(207,47,49) end
 end
 model:SetAttribute("AuthoredScale", scale * factor)
end

local function recomposeBed(bed: Model, frame: CFrame, width: number, length: number, ground: number, top: number, colors: any)
 move(bed, frameOf(bed), frame)
 reshapeBed(bed, frame, width, length, ground, top, colors)
 local crops = {}
 for _, object in bed:GetChildren() do
  if object:IsA("Model") and CROPS[object:GetAttribute("StudGardenFamily")] then table.insert(crops, object) end
 end
 for index, crop in crops do
  local offset = CFrame.new(if index % 2 == 0 then -1.25 else 1.25, 0.06, (index / (#crops + 1) - 0.5) * (length - 8))
  move(crop, cropRoot(crop), frame * offset * CFrame.Angles(0, index * 0.9, 0))
 end
end

local function timberTerraces(art: Model, layout: any, origin: CFrame, colors: any)
 for _, record in layout.barriers do
  if not WALLS[record.id] then continue end
  local wall = art.Environment01.DividerGardens[record.id] :: Model
  local skin = art.CloseGarden.DividerSkins[record.id] :: Model
  local length = math.max(record.size.X, record.size.Z)
  local width = math.min(record.size.X, record.size.Z)
  local frame = origin * CFrame.new(record.position) * CFrame.Angles(0, if record.size.X > record.size.Z then 0 else math.pi/2, 0)
  local soilHeight = math.clamp(record.adjacentTop - layout.groundY + 0.4, 2, record.size.Y - 2)
  local boardHeight = (record.size.Y - soilHeight) / 4
  for side = -1, 1, 2 do
   local face = skin:FindFirstChild("SoilFace" .. side) :: BasePart
   face.Color = colors.Soil
   for band = 1, 4 do
    local name = "TimberCourse" .. side .. "_" .. band
    local board = wall:FindFirstChild(name) :: BasePart?
    local boardFrame = frame * CFrame.new(if band % 2 == 0 then 0.05 else -0.05, -record.size.Y/2 + soilHeight + (band - 0.5) * boardHeight, side * (width/2 + 0.14))
    local size = Vector3.new(length + 0.1, boardHeight - 0.06, 0.2)
    local color = if band % 2 == 0 then colors.Honey else colors.TerracottaLight
    if board then board.CFrame, board.Size, board.Color = boardFrame, size, color
    else Kit.Part(wall, name, boardFrame, size, color, {studs=false}) end
   end
   local stations = math.max(2, math.ceil(length/23))
   for station = 1, stations do
    local x = (station/(stations+1) - 0.5) * length + (if station % 2 == 0 then 2.0 else -2.0)
    local stem = wall:FindFirstChild("TrailingStem" .. side .. "_" .. station) :: BasePart
    local top = frame * CFrame.new(x, record.size.Y/2 - 0.5, side * (width/2 + 0.28))
    stem.CFrame, stem.Size = top * CFrame.new(0,-2.7,0) * CFrame.Angles(0,0,side*0.1), Vector3.new(0.32,5.8,0.28)
    for leaf = 1, 2 do
     local part = wall:FindFirstChild("WallLeaf" .. side .. "_" .. station .. "_" .. leaf) :: BasePart
     part.CFrame = top * CFrame.new(if leaf == 1 then -0.8 else 0.85, -1.35 - leaf*1.15, side*0.15) * CFrame.Angles(0,0,if leaf == 1 then 0.2 else -0.18)
     part.Size = Vector3.new(if leaf == 1 then 3.4 else 2.8, 2.0, 0.5)
    end
    local bloom = wall:FindFirstChild("Flower" .. side .. "_" .. station) :: BasePart
    bloom.CFrame, bloom.Size = top * CFrame.new(0.1,-4.45,side*0.33), Vector3.new(1.1,0.85,0.45)
    local crown = wall:FindFirstChild("TopCrown" .. side .. "_" .. station) :: BasePart
    crown.CFrame = top * CFrame.new(0,0.25,0) * CFrame.Angles(0,station*0.11,side*0.08)
    crown.Size = Vector3.new(math.min(10,length/stations*0.55),1.75,2.8)
    crown.Color = if station % 2 == 0 then colors.Leaf else colors.LeafLight
   end
  end
  for _, part in skin:GetChildren() do
   if part:IsA("BasePart") and part.Name:sub(1,11) == "TimberStile" then part.Color = colors.WoodDark end
  end
 end
end

local function candyForms(model: Model, colors: any, origin: CFrame, ground: number)
 local trunk = model.PinkTrunk :: BasePart
 local scale = trunk.Size.Y / 9.2
 local root = trunk.CFrame * CFrame.new(0,-trunk.Size.Y/2,0)
 local shapes = {
  CrownBase = {Vector3.new(0,8.8,0), Vector3.new(9.2,4.2,8.8)},
  CrownStepA = {Vector3.new(-3.1,10.7,-1.2), Vector3.new(5.5,3.9,6.6)},
  CrownStepB = {Vector3.new(3.6,9.7,1.1), Vector3.new(5.0,3.6,6.4)},
  CrownTop = {Vector3.new(-0.8,12.4,0.3), Vector3.new(5.2,3.2,5.5)},
  CrownFrontStep = {Vector3.new(0.4,8.5,-4.1), Vector3.new(5.0,2.6,3.8)},
  CrownLobe1 = {Vector3.new(-4.4,8.5,2.5), Vector3.new(4.0,3.6,4.8)},
  CrownLobe2 = {Vector3.new(3.3,11.0,-3.1), Vector3.new(4.0,3.6,4.4)},
  CrownLobe3 = {Vector3.new(0.2,11.8,3.7), Vector3.new(4.8,3.4,4.2)},
 }
 for name, data in shapes do
  local part = model:FindFirstChild(name) or model.Environment01:FindFirstChild(name)
  part.CFrame, part.Size = root * CFrame.new(data[1] * scale), data[2] * scale
  part.Color = if name == "CrownBase" or name == "CrownStepB" or name == "CrownLobe3" then colors.Aqua else colors.AquaLight
 end
 for index, name in {"BranchA", "BranchB"} do
  local part = model:FindFirstChild(name) :: BasePart
  part.CFrame = root * CFrame.new((if index == 1 then -1.6 else 1.7) * scale, (if index == 1 then 6.8 else 7.5) * scale, -0.25 * scale) * CFrame.Angles(0,0,if index == 1 then -0.5 else 0.48)
  part.Size = Vector3.new(4.6,1.25,1.35) * scale
 end
 trunk.Size = Vector3.new(2.05,9.2,2.05) * scale
 for index = 1, 3 do
  local fruit = model:FindFirstChild("CandyFruit" .. index) :: BasePart
  fruit.CFrame = root * CFrame.new((index - 2) * 3.0 * scale, (7.1 + index*0.25) * scale, -4.1 * scale)
  fruit.Size = Vector3.new(1.45,1.6,1.45) * scale
 end
 local bed = model:FindFirstChild("PlantedBed")
 if bed then reshapeBed(bed, frameOf(bed), 15, 14, ground, origin:PointToObjectSpace(root.Position).Y, colors) end
end

local function vineForms(model: Model, colors: any)
 local scale = model:GetAttribute("AuthoredScale") or 1
 local first = model.Stem1 :: Part
 local root = CFrame.new(first.CFrame.Position - Vector3.new(math.sin(0.68)*1.1,1.5,math.cos(0.68)*1.1) * scale)
 for index = 1, 10 do
  local angle = index*0.68
  local part = model:FindFirstChild("Stem" .. index) :: Part
  part.Shape = Enum.PartType.Cylinder
  part.CFrame = root * CFrame.new(math.sin(angle)*0.38*scale,(index-0.5)*3*scale,math.cos(angle)*0.38*scale) * CFrame.Angles(0,angle,math.pi/2)
  part.Size, part.Color = Vector3.new(3.5,3.15,3.15) * scale, colors.Leaf
  local a = root:PointToWorldSpace(Vector3.new(math.sin(angle-0.34+2)*1.8,(index-1)*3,math.cos(angle-0.34+2)*1.8)*scale)
  local b = root:PointToWorldSpace(Vector3.new(math.sin(angle+0.34+2)*1.8,index*3,math.cos(angle+0.34+2)*1.8)*scale)
  local wrap = model:FindFirstChild("TwiningVine" .. index) :: Part
  wrap.Shape = Enum.PartType.Cylinder
  wrap.CFrame = CFrame.lookAt((a+b)/2,b) * CFrame.Angles(0,math.pi/2,0)
  wrap.Size, wrap.Color = Vector3.new((a-b).Magnitude+0.1,0.72*scale,0.72*scale), colors.GrassLight
 end
 for index = 1, 5 do
  local angle, y = index*2.35,4.5+index*4.6
  local frame = root * CFrame.new(math.sin(angle)*3.35*scale,y*scale,math.cos(angle)*3.35*scale) * CFrame.Angles(0,angle,0) * CFrame.Angles(0.18,0,0.08)
  local blade, tip = model:FindFirstChild("LeafBlade"..index) :: BasePart, model:FindFirstChild("LeafTip"..index) :: BasePart
  blade.CFrame, blade.Size = frame, Vector3.new(5.2,1.0,5.5)*scale
  tip.CFrame, tip.Size = frame*CFrame.new(0,-0.12*scale,3.6*scale)*CFrame.Angles(0,math.pi,0), Vector3.new(3.4,0.9,3.6)*scale
  Kit.Part(model,"LeafVein"..index,frame*CFrame.new(0,0.25*scale,1.25*scale),Vector3.new(0.15,0.15,6.0)*scale,colors.GrassLight,{studs=false})
 end
 for index = 1, 4 do
  local angle, y = index*1.8,14.2+index*3.6
  local position = Vector3.new(math.sin(angle)*4.3,y-0.3,math.cos(angle)*4.3)*scale
  local pod = model:FindFirstChild("BeanPod"..index) :: Part
  pod.Shape, pod.Size = Enum.PartType.Cylinder, Vector3.new(3.35,1.65,1.65)*scale
  pod.CFrame, pod.Color = root*CFrame.new(position)*CFrame.Angles(0,angle,math.pi/2+0.12), colors.GrassLight
  local tip = model:FindFirstChild("PodTip"..index) :: Part
  tip.Shape, tip.Size = Enum.PartType.Ball, Vector3.new(1.58,1.58,1.58)*scale
  tip.CFrame = root*CFrame.new(position+Vector3.new(0.17,-1.45,0)*scale)
  local stem = model:FindFirstChild("PodStem"..index) :: BasePart
  stem.CFrame, stem.Size = root*CFrame.new(position+Vector3.new(0,2.05,0)*scale), Vector3.new(0.22,1.6,0.22)*scale
 end
 local bed = model.PlantedBed :: Model
 reshapeBed(bed,frameOf(bed),18,16,-5,-5,colors)
 for _, child in bed:GetChildren() do
  if child:IsA("Model") and child:GetAttribute("StudGardenFamily") == "Flower" then
   local frame = cropRoot(child)
   local p = root:ToObjectSpace(frame).Position
   move(child,frame,root*CFrame.new(p.X*1.55,0.03,p.Z*1.45))
  end
 end
end

function Environment.CorrectRepresentative(course: Model, cfg: any, layout: any): any
 assert(course:GetAttribute("CourseId") == "stud_garden" and course:GetAttribute("LayoutRevision") == "SG_LAYOUT_04", "Preserve the intended course")
 local art = course.Art :: Model
 assert(art:GetAttribute("EnvironmentRevision") == "SG_ENV_01_S02" and not art.Environment01:GetAttribute("Correction"), "Correction requires the preserved reviewed candidate A")
 local colors, origin = Kit.Colors(cfg.Palette), CFrame.new(cfg.Origin)
 local before = Kit.Inventory(course).parts
 for _, object in art:GetDescendants() do
  if not object:IsA("Model") then continue end
  local family = object:GetAttribute("StudGardenFamily")
  local selected = object:IsDescendantOf(art.S02Finished) or object:IsDescendantOf(art.Environment01) or object:IsDescendantOf(art.CloseGarden.H01PlantedBorders)
  for _, name in {"CandyGroveNear", "CandyGroveReturn", "VineInnerGarden", "VineEntryGarden"} do
   local neighbor = art.LandmarkPlanting:FindFirstChild(name)
   if neighbor and object:IsDescendantOf(neighbor) then selected = true end
  end
  if family == "GardenLeafMass" and selected then lowFoliage(object,nil,nil,colors)
  elseif selected and (family == "CropCarrot" or family == "CropStrawberry") then cropIdentity(object,1.35)
  elseif family == "LandmarkCandyBlossom" then candyForms(object,colors,origin,layout.groundY)
  elseif family == "LandmarkBeanstalk" then vineForms(object,colors) end
 end
 timberTerraces(art,layout,origin,colors)
 local right = art.S02Finished.M1BPlanting.CarrotBed1 :: Model
 local rightFrame = origin*CFrame.new(153,3.4,245)*CFrame.Angles(0,math.pi/2,0)
 assert(clear(rightFrame,Vector3.new(10,1,87),layout,origin,1.7), "Open-side row conflicts with protected movement")
 recomposeBed(right,rightFrame,8.4,86,layout.groundY,3.4,colors)
 local mass = Kit.Model(right,"Environment01","LowMixedCropTerrace")
 for index, z in {-34,-9,27} do
  local foliage = Kit.LeafMass(mass,rightFrame*CFrame.new(0.5,0.03,z),1.05,colors)
  lowFoliage(foliage,nil,nil,colors)
 end
 for index, z in {-21,18} do
  local crop = Kit.Strawberry(mass,rightFrame*CFrame.new(-2.0,0.06,z)*CFrame.Angles(0,index*0.8,0),1.35,colors)
  cropIdentity(crop,1.35)
 end
 local pet = art.Environment01.SprinklerRabbitGarden :: Model
 local petFrame = origin*CFrame.new(3,2.2,116)*CFrame.Angles(0,-math.pi/2,0)
 assert(clear(petFrame,Vector3.new(9,1,9),layout,origin,1.7), "Pet garden conflicts with recovery")
 move(pet,frameOf(pet),petFrame)
 local front = pet.LongTrim1 :: BasePart
 front.CFrame, front.Size = petFrame*CFrame.new(0,-0.24,-4), Vector3.new(8.35,0.35,0.38)
 local rabbit = pet.Rabbit :: Model
 local rabbitFrame = rabbit.Body.CFrame*CFrame.new(0,-0.83*1.15,-0.28*1.15)
 move(rabbit,rabbitFrame,petFrame*CFrame.new(0,0.06,0)*CFrame.Angles(0,-0.12,0))
 local border = art.CloseGarden.H01PlantedBorders.MixedCropBorder1
 for _, object in border.Environment01:GetChildren() do
  if object:IsA("Model") and object:GetAttribute("StudGardenFamily") == "GardenLeafMass" then
   local root = object.BranchStem.CFrame*CFrame.new(0,-1.3*(object:GetAttribute("AuthoredScale") or 1),0)
   if math.abs(origin:PointToObjectSpace(root.Position).Z-83)<9 then
    lowFoliage(object,root*CFrame.new(-2.0,0,0),0.9,colors)
   end
  end
 end
 local result = {candidate="SG_ENV_01_S02_B", inventory=Kit.Inventory(course)}
 result.correctionAddedParts = result.inventory.parts-before
 result.totalAddedParts = result.inventory.parts-3805
 assert(result.correctionAddedParts<=60 and result.totalAddedParts<=600, "Correction exceeds its bounded resource allowance")
 art.Environment01:SetAttribute("Correction","CropTerraces_B")
 art.Environment01:SetAttribute("AddedParts",result.totalAddedParts)
 art.Environment01:SetAttribute("Scope","S02 crop terraces and neighboring landmark forms; awaiting representative rereview")
 art:SetAttribute("EnvironmentRevision","SG_ENV_01_S02_B")
 art:SetAttribute("ArtParts",Kit.Inventory(art).parts)
 art:SetAttribute("CloseGardenParts",Kit.Inventory(art.CloseGarden).parts)
 -- Explicit group pivots keep reshaped models stable when exported.
 for _, object in art:GetDescendants() do
  if object:IsA("Model") and object.Name == "Environment01" then
   pcall(function() object.WorldPivot = object.WorldPivot end)
  end
 end
 return result
end

return Environment

