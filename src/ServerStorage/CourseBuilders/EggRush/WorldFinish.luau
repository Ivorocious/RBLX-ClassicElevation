--!nonstrict
local WorldFinish = {}
local Finish = require(script.Parent.Finish)
local Authoring = require(script.Parent.Authoring)

local function W(x, y, z)
 return Authoring.WorldPoint(Vector3.new(x, y, z))
end

local function group(parent, name)
 local folder = Instance.new("Folder")
 folder.Name = name
 folder.Parent = parent
 return folder
end

local function hideArt(instance)
 for _, part in ipairs(instance:GetDescendants()) do
  if part:IsA("BasePart") then
   part.Transparency = 1
   part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
  end
 end
 if instance:IsA("BasePart") then
  instance.Transparency = 1
  instance.CanCollide, instance.CanTouch, instance.CanQuery = false, false, false
 end
end

local function recolor(model, role, color)
 for _, part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and part:GetAttribute("ERMaterial") == role then part.Color = color end
 end
end

local function steppedSupport(kit, pad, parent, top)
 top = top or pad:GetAttribute("ERTop")
 local neck = top-Vector3.new(0,2.2,0)
 Finish.Skin(kit,"RockSupportLow",parent,CFrame.new(neck)*pad.CFrame.Rotation,
  Vector3.new(pad.Size.X/10,.8,pad.Size.Z/6))
 local shoulder = neck-Vector3.new(0,8,0)
 Finish.Skin(kit,"BareRock",parent,CFrame.new(shoulder)*pad.CFrame.Rotation,
  Vector3.new(pad.Size.X*1.6/7,(shoulder.Y-279.8)/7,pad.Size.Z*1.55/5.4))
end

local function completePads(root, kit, parent)
 local finishedGroups = {S3_ShellApproach=true, E3_CrownApproach=true}
 local finishedWaits = {Shell_ForkWait=true, Shell_MiddleWait=true, Shell_ExitWait=true}
 for _, pad in ipairs(root.Obstacles:GetDescendants()) do
  if not pad:IsA("BasePart") or typeof(pad:GetAttribute("ERTop")) ~= "Vector3" then continue end
  if pad:IsDescendantOf(root.Obstacles.Mechanisms) or finishedWaits[pad.Name] then continue end
  if finishedGroups[pad.Parent.Name] or pad.Transparency >= 1 then continue end
  Finish.CoverPad(kit, pad, parent)
  steppedSupport(kit, pad, parent)
 end
 local start = root.Start
 Finish.CoverPad(kit, start, parent)
 local top = start.Position + start.CFrame.UpVector * start.Size.Y/2
 steppedSupport(kit,start,parent,top)
end

local function decision(kit, parent, text, x, y, z, target, color)
 local position = W(x, y, z)
 local frame = CFrame.lookAt(position, Vector3.new(target.X, position.Y, target.Z))
 local footing = position-Vector3.new(0,4.7,0)
 Finish.Skin(kit,"RockSupportStandard",parent,CFrame.new(footing),Vector3.new(.3,(footing.Y-279.8)/20,.5))
 local post = Finish.Skin(kit, "PipeStraight", parent,
  CFrame.new(position-Vector3.new(0,4.5,0))*CFrame.Angles(math.pi/2,0,0), Vector3.new(.18,.18,.45))
 post.Name = text.."_DecisionPost"
 local board = Finish.Skin(kit, "GateLintel", parent, frame, Vector3.new(.35,.65,.18))
 board.Name = text.."_Decision"
 recolor(board, "Coral", color)
 local gui = Instance.new("BillboardGui")
 gui.Name, gui.Adornee = "RouteChoice", board:FindFirstChildWhichIsA("BasePart", true)
 gui.StudsOffsetWorldSpace = frame.Position-gui.Adornee.Position+Vector3.new(0,4,0)
 gui.Size, gui.MaxDistance, gui.AlwaysOnTop = UDim2.fromOffset(170,36), 75, false
 gui.LightInfluence = 0
 gui.Parent = board
 local label = Instance.new("TextLabel")
 label.Size, label.BackgroundTransparency = UDim2.fromScale(1,1), 1
 label.Text, label.Font, label.TextScaled = text, Enum.Font.GothamBold, true
 label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(52,55,68), .8
 label.Parent = gui
end

function WorldFinish.Build(root, kit)
 assert(root:GetAttribute("EROwned") == true and root:GetAttribute("CourseId") == "egg_rush_circuit")
 assert(root.Decoration:FindFirstChild("ShellworksFinished"), "Preserve the inspected Shellworks sample first")
 assert(not root.Decoration:FindFirstChild("WorldFinished"), "World finish already exists")
 assert(type(Finish.CoverPad) == "function" and type(Finish.Support) == "function", "Expose existing pad helpers")
 for _, name in ipairs({"ShellPad","RockSupportStandard","RockSupportLow","BareRock","ShrubGroup",
  "EggCoral","EggDisplay","NestRing","GuardianBody","EggChute","ShellBowl","SortingShed",
  "NurseryWallBay","WorkshopBay","MintPipeArch","MintArchWindow","IncubatorHousing","RailPair","PipeStraight","PipeElbow","GateLintel"}) do
  assert(kit:FindFirstChild(name), "Missing admitted kit unit "..name)
 end
 local art = group(root.Decoration, "WorldFinished")
 local pads = group(art, "LandingIslands")
 completePads(root, kit, pads)
 task.wait()
 local function place(parent, name, x, y, z, scale, yaw)
  return Finish.Skin(kit, name, parent, CFrame.new(W(x,y,z))*CFrame.Angles(0,math.rad(yaw or 0),0), scale)
 end
 local function island(parent, position, width, depth, rotation)
  return Finish.Skin(kit, "RockSupportStandard", parent, CFrame.new(position)*(rotation or CFrame.identity),
   Vector3.new(width/10, math.max(1,position.Y-279.8)/20, depth/6))
 end
 local function building(parent, name, x, y, z, scale, yaw, width, depth)
  local model = place(parent,name,x,y,z,scale,yaw)
  island(parent,W(x,y,z),width,depth,CFrame.Angles(0,math.rad(yaw or 0),0))
  return model
 end
 local function grove(parent, x, y, z, scale)
  scale = scale or 1
  island(parent,W(x,y,z),8.85*scale+2.5,4.35*scale+2.2)
  return place(parent,"ShrubGroup",x,y,z,Vector3.one*scale)
 end
 local function bareSupport(parent, position, width, depth, rotation)
  return Finish.Skin(kit,"BareRock",parent,CFrame.new(position)*(rotation or CFrame.identity),
   Vector3.new(width/7,(position.Y-279.8)/7,depth/5.4))
 end
 local function bank(parent, name, frame, width, depth)
  local model = Finish.Skin(kit,"RockSupportStandard",parent,frame,
   Vector3.new(width/8.6,(frame.Position.Y-279.8)/20,depth/4.98))
  model.Name = name
  return model
 end
 local function room(parent, frame, width, depth, height)
  Finish.Skin(kit,"NurseryWallBay",parent,frame,Vector3.new(width/14.8,height,1))
  Finish.Skin(kit,"WorkshopBay",parent,frame*CFrame.new(0,0,-depth)*CFrame.Angles(0,math.pi,0),
   Vector3.new(width/16,height*.88,1))
  for _, side in ipairs({-1,1}) do
   Finish.Skin(kit,"WorkshopBay",parent,frame*CFrame.new(side*(width/2-1.4),0,-depth/2)*CFrame.Angles(0,side*math.pi/2,0),
    Vector3.new(depth/16,height*.88,1))
  end
  Finish.Skin(kit,"SortingShed",parent,frame*CFrame.new(0,0,-depth/2),
   Vector3.new((width+.8)/12,height*1.12,(depth+1.2)/9))
 end
 local function compound(parent, name, x, y, z, width, depth, height, yaw, annexWidth, side)
  local rooms = group(parent,name)
  local frame = CFrame.new(W(x,y,z))*CFrame.Angles(0,math.rad(yaw),0)
  local offset = side*(width/2+annexWidth/2-.75)
  room(rooms,frame,width,depth,height)
  room(rooms,frame*CFrame.new(offset,0,-3),annexWidth,depth*.7,height*.8)
  local low = math.min(-width/2,offset-annexWidth/2)
  local high = math.max(width/2,offset+annexWidth/2)
  local center = (low+high)/2
  bank(rooms,"RoomTerrace",frame*CFrame.new(center,0,-depth/2),high-low+3.2,depth+4)
  bank(rooms,"LowerShoulder",frame*CFrame.new(center,-5,1.2),high-low+7,12)
  return frame, W(x,y,z).Y+10.304*height
 end
 local function pipeBetween(parent, first, last, radius)
  local direction = (last-first).Unit
  local up = if math.abs(direction.Y)>.95 then Vector3.xAxis else Vector3.yAxis
  local frame = CFrame.lookAt(first,last,up)*CFrame.new(0,-1.5*radius,0)
  Finish.Skin(kit,"PipeStraight",parent,frame,Vector3.new(radius,radius,(last-first).Magnitude/10))
 end

 -- Small height offsets keep overlapping earth tops from flashing.
 local earth = group(art,"HatcheryEarthBase")
 for _, lobe in ipairs({
  {"Nestyard",-105,120,150,130,279.98},
  {"Sorting",-170,-45,125,160,279.96},
  {"Shellworks",-50,-175,160,110,279.94},
  {"Incubator",149,-76,150,150,280},
  {"Rookery",144,69,190,150,279.92},
  {"Return",48,156,190,100,279.90},
  {"Central",0,10,72,80,280},
 }) do
  local name,x,z,width,depth,top = table.unpack(lobe)
  local base = place(earth,"RockSupportLow",x,top-Authoring.Origin.Y,z,Vector3.new(width/8.6,1.8,depth/4.98))
  base.Name = name.."Earth"
  recolor(base,"Green",Color3.fromRGB(225,207,169))
  recolor(base,"GreenShade",Color3.fromRGB(205,180,135))
 end
 local central = group(art,"CentralNest")
 place(central,"RockSupportLow",0,-2,10,Vector3.new(6.5,1.8,10))
 place(central,"NestRing",0,-2,10,Vector3.one*3.15)
 place(central,"EggCoral",0,-2,10,Vector3.one*6)
 for _, site in ipairs({{-39,-9,14},{33,-8,30},{-17,-9,51},{30,-10,-18}}) do
  local position = W(site[1],site[2],site[3])
  Finish.Skin(kit,"BareRock",central,CFrame.new(position),Vector3.new(1.7,(position.Y-280)/7,1.7))
  place(central,"ShrubGroup",site[1],site[2],site[3],Vector3.one)
 end

 local nursery = group(art,"NestyardNursery")
 compound(nursery,"LowerNurseryRooms",-65,-8,177,22,16,1,180,14,1)
 compound(nursery,"UpperNurseryRooms",-125,-3,170,22,16,.9,180,14,1)
 place(nursery,"ShrubGroup",-90,-8,188,Vector3.one*1.2)
 place(nursery,"ShrubGroup",-151,-3,182,Vector3.one*1.3)
 building(nursery,"MintPipeArch",-176,-2,142,Vector3.one,90,13,8)
 place(nursery,"NestRing",-105,-1,154,Vector3.one*.8)
 island(nursery,W(-105,-1,154),14,14)
 for _, site in ipairs({{-172,-1,113},{-185,1,87},{-159,-4,158}}) do
  grove(nursery,site[1],site[2],site[3])
 end

 local sorting = group(art,"EggSortingSheds")
 for index, data in ipairs({{12,-23},{14,-86}}) do
  local height,z = data[1],data[2]
  local source = W(-192,height,z)
  local chuteFrame = CFrame.new(source-Vector3.new(16,4.6,0))*CFrame.Angles(0,-math.pi/2,0)
  Finish.Skin(kit,"EggChute",sorting,chuteFrame)
  bareSupport(sorting,chuteFrame*Vector3.new(0,-.9,-8),13,23,chuteFrame.Rotation)
  local eggModel = root.Obstacles.Mechanisms:FindFirstChild("EggBand"..index)
  assert(eggModel, "Missing tested egg band")
  local travel = eggModel:GetAttribute("Travel")
  local endpoint = source+eggModel:GetPivot():VectorToWorldSpace(travel)
  local bowlBase = endpoint-Vector3.new(0,5.1,0)
  Finish.Skin(kit,"ShellBowl",sorting,CFrame.new(bowlBase))
  bareSupport(sorting,bowlBase,8,8)
 end
 for _, site in ipairs({{-224,0,-32},{-224,3,-94}}) do
  building(sorting,"SortingShed",site[1],site[2],site[3],Vector3.one*1.5,0,22,18)
  place(sorting,"EggDisplay",site[1]-2,site[2],site[3],Vector3.one*1.5)
  place(sorting,"EggDisplay",site[1]+4,site[2],site[3]+5,Vector3.one*1.25)
  grove(sorting,site[1]+4,site[2]-1,site[3]-16)
 end

 local incubator = group(art,"IncubatorServiceCourt")
 bank(incubator,"IncubatorLowerBank",CFrame.new(W(178,8,-72)),38,36)
 building(incubator,"IncubatorHousing",178,24,-72,Vector3.one*1.5,0,28,28)
 place(incubator,"EggDisplay",178,28.5,-72,Vector3.one*3)
 local serviceFrame, roof = compound(incubator,"IncubatorServiceRooms",178,14,-91,24,16,1,-90,16,-1)
 building(incubator,"NurseryWallBay",45,15,-162,Vector3.one*1.1,0,20,10)
 Finish.Skin(kit,"MintArchWindow",incubator,serviceFrame*CFrame.new(0,.2,1.8),Vector3.one*.85)
 for _, port in ipairs({{1.8,-59.5},{5,-55.8}}) do
  local mouth = Vector3.new(W(178,44.5,-72).X+port[1],W(178,44.5,-72).Y,port[2])
  local elbow = CFrame.new(mouth)*CFrame.Angles(0,math.pi,0)*CFrame.Angles(math.pi,0,0)*CFrame.new(0,-1.8,0)
  Finish.Skin(kit,"PipeElbow",incubator,elbow,Vector3.one*1.2)
  local lower = elbow*Vector3.new(0,8.4,-7.2)
  pipeBetween(incubator,Vector3.new(lower.X,roof-.45,lower.Z),lower,1.2)
 end
 place(incubator,"RailPair",82,23.45,-78,Vector3.new(1.2,1,39/22))
 for _, z in ipairs({-101.87,-54.13}) do
  local top = W(82,23.05,z)
  Finish.Skin(kit,"BareRock",incubator,CFrame.new(top),Vector3.new(1.4,(top.Y-280)/7,.4))
 end
 for _, site in ipairs({{195,20,-91},{153,17,-146},{32,11,-172}}) do
  grove(incubator,site[1],site[2],site[3],1.1)
 end

 local rookery = group(art,"GuardianRookery")
 local tailFrame = root.Obstacles.Mechanisms.GuardianTail:GetPivot()
 local bodyFrame = tailFrame*CFrame.new(-9.6,-8,0)*CFrame.Angles(0,-math.pi/2,0)
 Finish.Skin(kit,"GuardianBody",rookery,bodyFrame,Vector3.one*2)
 local nestFrame = CFrame.new(bodyFrame.Position)
 Finish.Skin(kit,"NestRing",rookery,nestFrame,Vector3.one*2)
 island(rookery,nestFrame.Position,35,35)
 for _, site in ipairs({{226,31,30,32,42},{224,26,61,34,24},{221,21,92,36,42}}) do
  bank(rookery,"OuterRookeryBank",CFrame.new(W(site[1],site[2],site[3])),site[4],site[5])
  place(rookery,"ShrubGroup",site[1]+5,site[2],site[3]-7,Vector3.one*1.8)
  place(rookery,"BareRock",site[1]+8,site[2]+4,site[3]+5,Vector3.new(1.9,12/7,2.2))
 end
 bank(rookery,"GuardianRoostBacking",CFrame.new(W(54,17.5,84)),32,26)
 place(rookery,"NestRing",48,17.5,86,Vector3.one*1.2)
 place(rookery,"ShrubGroup",41,17.5,75,Vector3.one*1.4)

 local arrival = group(art,"ReturnNurseryCourt")
 compound(arrival,"UpperReturnRooms",96,0,188,24,16,1,180,16,1)
 compound(arrival,"LowerReturnRooms",50,-7,178,22,14,.9,180,15,1)
 place(arrival,"ShrubGroup",68,0,201,Vector3.one*1.4)
 place(arrival,"ShrubGroup",22,-7,191,Vector3.one*1.2)
 building(arrival,"MintPipeArch",15,-10,165,Vector3.one*1.1,180,14,9)
 place(arrival,"MintArchWindow",15,-9,166,Vector3.one*.85,180)
 place(arrival,"GateLintel",0,12,120,Vector3.new(4/3,1,1),90)

 local choices = group(art,"BranchChoices")
 local normal,expert = Color3.fromRGB(185,123,67),Color3.fromRGB(182,136,216)
 for _, fork in ipairs({
  {normal={-56,10,158},expert={-56,10,85},target=W(-43,3,120)},
  {normal={-196,21,-20},expert={-113,21,-10},target=W(-145,11,30)},
  {normal={204,41,40},expert={111,41,30},target=W(145,38,-14)},
 }) do
  local n,e = fork.normal,fork.expert
  decision(kit,choices,"NORMAL",n[1],n[2],n[3],fork.target,normal)
  decision(kit,choices,"EXPERT",e[1],e[2],e[3],fork.target,expert)
 end

 hideArt(root.Decoration.RoughSupports)
 hideArt(root.Decoration.CentralLandmark)
 for _, part in ipairs(root.Decoration:GetChildren()) do
  if part.Name == "DistrictRoughMass" or part.Name == "EggRunout" or part.Name == "ExposedRail" then hideArt(part) end
 end
 local gateVisuals = root.StartPen:FindFirstChild("GateVisuals")
 if gateVisuals then
  for _, part in ipairs(gateVisuals:GetChildren()) do if part.Name == "GateLintel" then hideArt(part) end end
 end
 root:SetAttribute("WorldArt",1)
 return art
end

return WorldFinish
