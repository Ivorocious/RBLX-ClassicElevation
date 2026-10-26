--!strict
local expected = {
["DropState"] = [[--!strict
local DropState = {}

function DropState.Get(elapsed: number, offset: number, config): (string, number)
	local t = (elapsed + offset) % config.DropPeriod
	local warning, fall, hold, returning = config.DropWarning, config.DropFall, config.DropHold, config.DropReturn
	if t < warning then return "Warning", 0 end
	if t < warning + fall then return "Drop", (t - warning) / fall end
	if t < warning + fall + hold then return "Contact", 1 end
	if t < warning + fall + hold + returning then return "Return", 1 - (t - warning - fall - hold) / returning end
	return "Clear", 0
end

return DropState
]],
["Kit"] = [[--!strict
local Parts = require(script.Parent.Parts)
local Mechanisms = require(script.Parent.Mechanisms)
local Landmarks = require(script.Parent.Landmarks)
local Kit = {}
function Kit.PressExamples(parent: Instance, template: MeshPart)
 local examples=Parts.Model(parent,"PressExamples")
 for i,state in {"Released","Held"} do
  local x=12+i*4
  local depth=if state=="Held" then Parts.PressDepth else 0
  local key=Parts.Key(examples,template,CFrame.new(x,-.425-depth,30),"Creamy",1,if i==1 then "A" else "S")
  key.Name=state.."Cap"
  key:SetAttribute("Pressable",false)
  key:SetAttribute("ExampleState",state)
  Parts.Block(examples,state.."Socket",Vector3.new(2.54,.1,2.54),CFrame.new(x,-.825,30),Parts.Charcoal,false)
 end
end
function Kit.Build(parent: Instance, template: MeshPart): Model
 local kit=Parts.Model(parent,"KeyboardCircuit_EditableKit_K01")
 kit:SetAttribute("Revision","KC_KIT_C08_01")
 kit:SetAttribute("Phase1Only",true)
 kit:SetAttribute("RuntimeStatus","Inactive construction kit; remaining hazard controllers belong to Phase 2")
 local surfaces=Parts.Model(kit,"Surfaces")
 for i,family in {"Creamy","Thocky","Clacky","Clicky"} do
  Parts.Bank(surfaces,family.."Bank",template,CFrame.new((i-1)*18,0,0),10,6,family)
 end
 Kit.PressExamples(surfaces,template)
 Parts.SpecialKey(surfaces,"Spacebar",CFrame.new(0,0,20),Vector3.new(14,1.25,3.5),"Creamy","SPACE")
 Parts.SpecialKey(surfaces,"Shift",CFrame.new(20,0,20),Vector3.new(10,1.25,4),"Clicky","Shift")
 Parts.SpecialKey(surfaces,"Ctrl",CFrame.new(38,0,20),Vector3.new(5,1.25,5),"Thocky","Ctrl")
 local enter=Parts.Model(surfaces,"EnterL")
 local stem=Parts.SpecialKey(enter,"Stem",CFrame.new(58,0,20),Vector3.new(5,1.25,12),"Creamy","ENTER")
 local returnKey=Parts.SpecialKey(enter,"Return",CFrame.new(53,0,24),Vector3.new(5,1.25,4),"Creamy","↵")
 Parts.JoinSpecialKeys(stem,returnKey)
 local bracket=Parts.Model(surfaces,"Bracket")
 for _,p in {Vector3.new(72,0,17),Vector3.new(77.2,0,20),Vector3.new(72,0,23)} do Parts.Bank(bracket,"BracketArm",template,CFrame.new(p),4,2,"Clacky") end
 local arrow=Parts.Model(surfaces,"Arrow")
 Parts.Bank(arrow,"Shaft",template,CFrame.new(86.1,0,20),6,2,"Clicky","→")
 for i,rows in {6,4,2} do Parts.Bank(arrow,"HeadBand"..i,template,CFrame.new(90.65+(i-1)*2.6,0,20),2,rows,"Clicky","→") end
 local hardware=Parts.Model(kit,"Hardware")
 Parts.Support(hardware,CFrame.new(0,0,42),8)
 Parts.Support(hardware,CFrame.new(12,0,42),14,Parts.Palette.Clacky[2])
 local switch=Parts.Model(hardware,"SwitchAssembly")
 Parts.Block(switch,"Housing",Vector3.new(3,1.5,3),CFrame.new(26,-.75,42),Parts.Palette.Creamy[1],false)
 Parts.Block(switch,"Stem",Vector3.new(1,3,1),CFrame.new(26,1,42),Parts.Palette.Creamy[3],false)
 local warning=Parts.Model(hardware,"WarningStrip")
 Parts.Warning(warning,CFrame.new(38,0,42),Vector3.new(6,.2,3))
 Parts.CheckpointFlag(hardware,CFrame.new(48,0,42),"CP")
 local refuge=Parts.Bank(hardware,"CtrlRefuge",template,CFrame.new(65,0,42),10,6,"Thocky","Ctrl")
 local roof=Parts.Block(refuge,"Roof",Vector3.new(14,1,10),CFrame.new(65,14.5,42),Parts.Charcoal)
 roof:SetAttribute("Role","SolidBlocker")
 for _,x in {-6.4,6.4} do
  local post=Parts.Block(refuge,"GuardPost",Vector3.new(.8,15,.8),CFrame.new(65+x,6.7,46),Parts.Charcoal)
  post:SetAttribute("Role","SolidBlocker")
 end
 local mechanisms=Parts.Model(kit,"Mechanisms")
 Mechanisms.Foundry(mechanisms,template,CFrame.new(20,0,78))
 Mechanisms.Lift(mechanisms,template,CFrame.new(60,0,78))
 Mechanisms.Shuttle(mechanisms,template,CFrame.new(88,0,78))
 local seesaw=Parts.Model(mechanisms,"H02_SeesawVisual")
 Parts.SpecialKey(seesaw,"Spacebar",CFrame.new(5,0,110)*CFrame.Angles(0,0,.12),Vector3.new(18,1.25,4),"Creamy","SPACE")
 Parts.Cylinder(seesaw,"Pivot",CFrame.new(5,-3,110)*CFrame.Angles(0,math.pi/2,0),5,4,Parts.Charcoal)
 local fallaway=Parts.Bank(mechanisms,"H03_FallawayRowVisual",template,CFrame.new(32,0,110),10,4,"Creamy")
 Parts.Warning(fallaway,CFrame.new(32,.04,112),Vector3.new(8,.12,.35))
 local sweep=Parts.KillBody(mechanisms,"H07_SweepVisual",CFrame.new(58,1,110),Vector3.new(16,2.5,3))
 Parts.Cylinder(sweep,"Pivot",CFrame.new(51,-1,110)*CFrame.Angles(0,0,math.pi/2),4,4,Parts.Charcoal)
 local domino=Parts.Model(mechanisms,"H08_DominoVisual")
 for i=1,3 do Parts.KillBody(domino,"Domino"..i,CFrame.new(76+i*4,3,110)*CFrame.Angles(0,0,(i-2)*.35),Vector3.new(3,6,3)) end
 local windows=Parts.Model(mechanisms,"H01_ShiftWindowVisual")
 Parts.SpecialKey(windows,"ShiftBar",CFrame.new(105,0,110),Vector3.new(14,1.25,4),"Clicky","Shift")
 for _,x in {96,114} do Parts.Block(windows,"StopHousing",Vector3.new(2,5,6),CFrame.new(x,-1,110),Parts.Charcoal,false) end
 local world=Parts.Model(kit,"Landmarks")
 Landmarks.USB(world,CFrame.new(0,0,150))
 Landmarks.Rack(world,CFrame.new(30,0,150),template)
 Landmarks.Magazine(world,CFrame.new(60,0,150),template)
 Landmarks.SplitShell(world,CFrame.new(90,0,150),template)
 Landmarks.Dial(world,CFrame.new(120,0,150))
 return kit
end
return Kit

]],
["Landmarks"] = [[--!strict
local Parts = require(script.Parent.Parts)
local Landmarks = {}
local function decoration(unit: Model)
 for _,p in unit:GetDescendants() do if p:IsA("BasePart") then p.CanCollide,p.CanQuery,p.CanTouch=false,false,false; p:SetAttribute("Role","Decoration") end end
end
function Landmarks.Magazine(parent: Instance, cf: CFrame, template: MeshPart): Model
 local unit=Parts.Model(parent,"CapMagazine")
 local sand,teal=Parts.Palette.Thocky[1],Parts.Palette.Thocky[2]
 Parts.Block(unit,"BackHousing",Vector3.new(11,22,4),cf*CFrame.new(0,11,2),teal,false)
 for _,x in {-5.8,5.8} do
  Parts.Block(unit,"SideHousing",Vector3.new(2.5,24,8),cf*CFrame.new(x,12,0),teal,false)
  Parts.Block(unit,"SideInsert",Vector3.new(.3,5,3.5),cf*CFrame.new(x*1.23,13,0),sand,false)
  Parts.Block(unit,"Foot",Vector3.new(4,2,9),cf*CFrame.new(x,0,0),Parts.Charcoal,false)
 end
 for i=1,3 do
  local y=5+i*5
  local tray=Parts.Model(unit,"Drawer"..i)
  Parts.Bank(tray,"StoredCaps",template,cf*CFrame.new(0,y,-4),7,4,if i==1 then "Creamy" else if i==2 then "Thocky" else "Clacky")
  Parts.Block(tray,"DrawerFront",Vector3.new(10,.9,.6),cf*CFrame.new(0,y-.7,-7),sand,false)
  for _,x in {-5,5} do Parts.Block(tray,"DrawerSide",Vector3.new(.6,1.4,6),cf*CFrame.new(x,y-.7,-4),sand,false) end
 end
 Parts.Block(unit,"TopCap",Vector3.new(9,1.2,5),cf*CFrame.new(0,24,0),sand,false)
 Parts.Block(unit,"Outlet",Vector3.new(5,4,.4),cf*CFrame.new(0,3,-2.3),Parts.Charcoal,false)
 Parts.Block(unit,"OutletLip",Vector3.new(5.8,.6,3),cf*CFrame.new(0,1,-3.3),teal,false)
 decoration(unit)
 unit.WorldPivot=cf
 return unit
end
function Landmarks.Rack(parent: Instance, cf: CFrame, template: MeshPart): Model
 local unit=Parts.Model(parent,"KeyboardRack")
 unit.WorldPivot=cf
 for _,x in {-8,8} do
  Parts.Block(unit,"RackPost",Vector3.new(2,18,3),cf*CFrame.new(x,7,1)*CFrame.Angles(-.15,0,0),Parts.Charcoal,false)
  Parts.Block(unit,"Foot",Vector3.new(4,1.5,8),cf*CFrame.new(x,-2,0),Parts.Charcoal,false)
 end
 for i=1,2 do
  local tray=Parts.Bank(unit,"KeyboardTray"..i,template,cf*CFrame.new(0,3+i*6,-1)*CFrame.Angles(.35,0,0),11,5,"Creamy")
  for _,x in {-7.8,7.8} do Parts.Cylinder(tray,"Pivot",cf*CFrame.new(x,3+i*6,0),.8,2.5,Parts.Palette.Thocky[1]) end
 end
 decoration(unit)
 return unit
end
function Landmarks.USB(parent: Instance, cf: CFrame): Model
 local unit=Parts.Model(parent,"USBPortal")
 unit.WorldPivot=cf
 for _,x in {-8,8} do
  Parts.Block(unit,"Housing",Vector3.new(4,17,6),cf*CFrame.new(x,8.5,0),Parts.Charcoal,false)
  Parts.Warning(unit,cf*CFrame.new(x,7,-3.05)*CFrame.Angles(math.pi/2,0,0),Vector3.new(2.5,.2,6))
 end
 Parts.Block(unit,"Connector",Vector3.new(20,5,8),cf*CFrame.new(0,18,0),Color3.fromRGB(188,198,208),false)
 Parts.Block(unit,"DarkSocket",Vector3.new(13,3,.3),cf*CFrame.new(0,17.8,-4.2),Parts.Charcoal,false)
 for i=1,4 do Parts.Block(unit,"Contact",Vector3.new(1.5,2,.7),cf*CFrame.new((i-2.5)*3,17.5,-4.5),Parts.Yellow,false) end
 decoration(unit)
 return unit
end
function Landmarks.SplitShell(parent: Instance, cf: CFrame, template: MeshPart): Model
 local unit=Parts.Model(parent,"SplitKeyboardShells")
 unit.WorldPivot=cf
 for _,side in {-1,1} do
  local half=Parts.Model(unit,if side==-1 then "LeftShell" else "RightShell")
  local pose=cf*CFrame.new(side*7,3,0)*CFrame.Angles(.2,side*.25,side*.12)
  Parts.Block(half,"Housing",Vector3.new(10,5,13),pose,Parts.Palette.Clacky[2],false)
  Parts.Bank(half,"KeyboardFace",template,pose*CFrame.new(0,3.4,0),6,8,"Clacky")
  Parts.Block(half,"Port",Vector3.new(5,1.5,.3),pose*CFrame.new(0,0,-6.6),Parts.Charcoal,false)
 end
 decoration(unit)
 return unit
end
function Landmarks.Dial(parent: Instance, cf: CFrame): Model
 local unit=Parts.Model(parent,"RotaryDial")
 unit.WorldPivot=cf
 Parts.Support(unit,cf*CFrame.new(0,7,0),6,Parts.Palette.Clicky[2])
 Parts.Cylinder(unit,"CoralBase",cf*CFrame.new(0,7,0)*CFrame.Angles(0,0,math.pi/2),2,11,Parts.Palette.Clicky[3])
 Parts.Cylinder(unit,"Dial",cf*CFrame.new(0,11,0)*CFrame.Angles(0,0,math.pi/2),7,9,Parts.Palette.Clicky[2])
 for i=1,10 do
  local angle=i*math.pi/5
  Parts.Block(unit,"Grip",Vector3.new(1,6,1),cf*CFrame.new(math.cos(angle)*4.5,11,math.sin(angle)*4.5)*CFrame.Angles(0,-angle,0),Parts.Palette.Clicky[2],false)
 end
 Parts.Block(unit,"Indicator",Vector3.new(.6,.2,3),cf*CFrame.new(0,14.6,-1),Parts.Palette.Clicky[1],false)
 decoration(unit)
 return unit
end
return Landmarks

]],
["Layout"] = [[--!strict
local Layout = {}
Layout.Revision = "KC_LAYOUT_P1_01"
Layout.Main = {"F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"}
Layout.Branches = {{from = "H04", id = "X01", before = "CP2"}, {from = "H07", id = "X02", before = "CP3"}}
Layout.Nodes = {
	F00 = {-96, 0, 86, "Creamy"}, O01 = {-112, 0, 51, "Creamy"},
	H02 = {-112, 1, 13, "Creamy"}, O02 = {-103, 2, -24, "Creamy"},
	H03 = {-72, 4, -58, "Creamy"}, CP1 = {-36, 5, -80, "Creamy"},
	O03 = {0, 7, -84, "Thocky"}, H04 = {42, 9, -77, "Thocky"},
	H05 = {84, 15, -56, "Thocky"}, O04 = {118, 15, -27, "Thocky"},
	CP2 = {136, 15, 3, "Thocky"}, O05 = {134, 15, 36, "Clacky"},
	H06 = {109, 15, 68, "Clacky"}, H07 = {72, 15, 91, "Clacky"},
	O06 = {31, 13, 110, "Clacky"}, CP3 = {-6, 11, 108, "Clacky"},
	O07 = {-41, 10, 99, "Clicky"}, H08 = {-40, 7, 63, "Clicky"},
	H01 = {-52, 4, 26, "Clicky"}, O08 = {-72, 2, 51, "Clicky"},
	F01 = {-62, 0, 77, "Clicky"}, X01 = {62, 11, -27, "Thocky"},
	X02 = {22, 13, 78, "Clacky"},
}
Layout.MovementBaseline = {walkSpeed = 16, jumpHeight = 7.2, useJumpPower = false, gravity = 196.2}
Layout.WorkingCapacity = 20
Layout.TargetLaps = 3
return Layout
]],
["Mechanisms"] = [[--!strict
local Parts = require(script.Parent.Parts)
local Mechanisms = {}

function Mechanisms.Slider(parent: Instance, name: string, template: MeshPart, cf: CFrame, axis: Vector3, travel: number, family: string)
	local unit = Parts.Model(parent, name)
	local bank = Parts.Bank(unit, "RideableBank", template, cf, 10, 8, family, "↑")
	local root = bank.PrimaryPart :: BasePart
	root.CustomPhysicalProperties = PhysicalProperties.new(.7, 1, 0, 100, 100)
	local guide = Parts.Block(unit, "Guide", Vector3.new(2, 2, 2), root.CFrame, Parts.Charcoal, false)
	guide.Transparency = 1
	guide:SetAttribute("Role", "MechanismGuide")
	local fixed = Instance.new("Attachment")
	fixed.Name, fixed.Axis = "FixedAxis", axis
	fixed.SecondaryAxis = if math.abs(axis.Y) > .5 then Vector3.xAxis else Vector3.yAxis
	fixed.Parent = guide
	local moving = fixed:Clone()
	moving.Name, moving.Parent = "MovingAxis", root
	local slider = Instance.new("PrismaticConstraint")
	slider.Name, slider.Attachment0, slider.Attachment1 = "Slider", fixed, moving
	slider.ActuatorType, slider.TargetPosition = Enum.ActuatorType.Servo, 0
	slider.LimitsEnabled, slider.LowerLimit, slider.UpperLimit = true, 0, travel
	slider.Speed, slider.ServoMaxForce, slider.LinearResponsiveness = 4, 10000000, 15
	slider.Restitution = 0
	slider.Enabled = false
	slider.Parent = unit
	for _,part in bank:GetDescendants() do
		if part:IsA("BasePart") and part ~= root then
			part.Massless = true
			part.CustomPhysicalProperties = PhysicalProperties.new(.7, 1, 0, 100, 100)
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = root, part, root
		end
	end
	unit:SetAttribute("Travel", travel)
	unit:SetAttribute("RestTop", cf.Position)
	unit:SetAttribute("MotionAxis", axis)
	unit.PrimaryPart = root
	return unit
end

function Mechanisms.Lift(parent: Instance, template: MeshPart, cf: CFrame): Model
	local unit = Mechanisms.Slider(parent, "H05_SpringLift", template, cf, Vector3.yAxis, 8, "Thocky")
	Parts.Block(unit, "Foot", Vector3.new(14, 1, 11), cf * CFrame.new(0, -7.5, 0), Parts.Charcoal, false)
	Parts.Cylinder(unit, "Stem", cf * CFrame.new(0, -4, 0) * CFrame.Angles(0, 0, math.pi / 2), 6, 3, Parts.Charcoal)
	for i = 1, 4 do
		Parts.Cylinder(unit, "SpringDisc", cf * CFrame.new(0, -1.8 - i * 1.1, 0) * CFrame.Angles(0, 0, math.pi / 2), .5, 5.5, Color3.fromRGB(128, 132, 135))
	end
	return unit
end

function Mechanisms.Shuttle(parent: Instance, template: MeshPart, cf: CFrame): Model
	local unit = Mechanisms.Slider(parent, "H06_CarriageShuttle", template, cf, Vector3.xAxis, 24, "Clacky")
	local rail = Parts.Model(unit, "PermanentRails")
	for _,z in {-4.5, 4.5} do
		Parts.Cylinder(rail, "Rail", cf * CFrame.new(12, -2.8, z), 37, .7, Color3.fromRGB(144, 155, 164))
	end
	for _,x in {-6.5, 30.5} do
		local stop = Parts.Block(rail, "StopHousing", Vector3.new(2, 5, 13), cf * CFrame.new(x, -3.2, 0), Parts.Charcoal)
		stop:SetAttribute("Role", "SolidBlocker")
		Parts.Warning(rail, cf * CFrame.new(x, .6, -5.5), Vector3.new(1.9, .2, 1.8))
	end
	return unit
end

function Mechanisms.Foundry(parent: Instance, template: MeshPart, cf: CFrame): Model
	local unit = Parts.Model(parent, "H04_FallingKeyFoundry")
	local crossing = Parts.Bank(unit, "CrossingBank", template, cf, 30, 14, "Thocky")
	for _,z in {-12, 12} do
		local column = Parts.Block(unit, "GantryColumn", Vector3.new(2.5, 23, 3), cf * CFrame.new(0, 10, z), Parts.Charcoal)
		column:SetAttribute("Role", "SolidBlocker")
		Parts.Warning(unit, cf * CFrame.new(-1.3, 11, z) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(6, .2, 2.1))
	end
	Parts.Block(unit, "OverheadFeeder", Vector3.new(31, 3, 3), cf * CFrame.new(0, 22, 0), Parts.Charcoal, false)
	for i,offset in {Vector3.new(-12, 0, -4), Vector3.new(0, 0, 4), Vector3.new(12, 0, -4)} do
		local drop = Parts.KillBody(unit, "Drop" .. i, cf * CFrame.new(offset + Vector3.new(0, 17.5, 0)), Vector3.new(7, 5, 8))
		drop:SetAttribute("DropOffset", offset)
		drop:SetAttribute("CycleOffset", (i - 1) * 2.1)
		local plunger = Parts.Block(drop, "Plunger", Vector3.new(2.5, 5, 2.5), drop:GetPivot() * CFrame.new(0, 3.5, 0), Parts.Crimson, false)
		plunger.CanQuery = true
		plunger:SetAttribute("Role", "Lethal")
		local warning = Parts.Block(unit, "Warning" .. i, Vector3.new(5, .04, 3), cf * CFrame.new(offset + Vector3.new(0, -Parts.PressDepth + .025, 0)), Parts.Yellow, false)
		Parts.Legend(warning, "↓", nil, Parts.Charcoal)
		for _,key in crossing:GetChildren() do
			if not key:IsA("MeshPart") then continue end
			local point = cf:PointToObjectSpace(key.Position) - offset
			if math.abs(point.X) > 3.6 or math.abs(point.Z) > 4.1 then continue end
			key:SetAttribute("DropWarningIndex", i)
			local frame = Instance.new("Frame")
			frame.Name, frame.Size, frame.Position = "DropWarning", UDim2.fromScale(.96, .96), UDim2.fromScale(.02, .02)
			frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel = Parts.Yellow, 1, 0
			local stroke = Instance.new("UIStroke")
			stroke.Color, stroke.Thickness, stroke.Parent = Parts.Yellow, 6, frame
			local arrow = Instance.new("TextLabel")
			arrow.Position, arrow.Size = UDim2.fromScale(.78, .02), UDim2.fromScale(.2, .2)
			arrow.Text, arrow.TextScaled, arrow.Font = "↓", true, Enum.Font.GothamBold
			arrow.BackgroundColor3, arrow.TextColor3, arrow.BorderSizePixel, arrow.ZIndex = Parts.Yellow, Parts.Charcoal, 0, 3
			arrow.Parent, frame.Parent = frame, key.Legend
		end
		for _,side in {-1, 1} do
			Parts.Block(unit, "ZoneEdge", Vector3.new(7.3, .055, .22), cf * CFrame.new(offset + Vector3.new(0, -Parts.PressDepth + .03, side * 4.1)), Parts.Yellow, false)
			Parts.Block(unit, "ZoneEdge", Vector3.new(.22, .055, 8), cf * CFrame.new(offset + Vector3.new(side * 3.6, -Parts.PressDepth + .03, 0)), Parts.Yellow, false)
		end
	end
	local refuge = Parts.Bank(unit, "PermanentCtrlRefuge", template, cf * CFrame.new(0, 0, 17), 10, 6, "Thocky", "Ctrl")
	refuge:SetAttribute("Role", "SafeRefuge")
	local roof = Parts.Block(refuge, "GuardRoof", Vector3.new(14, 1, 10), cf * CFrame.new(0, 14.5, 17), Parts.Charcoal)
	roof:SetAttribute("Role", "SolidBlocker")
	for _,x in {-6.4, 6.4} do
		local post = Parts.Block(refuge, "GuardPost", Vector3.new(.8, 15, .8), cf * CFrame.new(x, 6.7, 21), Parts.Charcoal)
		post:SetAttribute("Role", "SolidBlocker")
	end
	return unit
end

return Mechanisms
]],
["Parts"] = [[--!strict
local Parts = {}
local Config = require(script.Parent:FindFirstChild("ConfigSnapshot") or game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig)

Parts.Palette = {
	Creamy = {Color3.fromRGB(247, 230, 194), Color3.fromRGB(231, 156, 173), Color3.fromRGB(156, 222, 191)},
	Thocky = {Color3.fromRGB(221, 192, 144), Color3.fromRGB(31, 84, 96), Color3.fromRGB(143, 98, 62)},
	Clacky = {Color3.fromRGB(224, 240, 255), Color3.fromRGB(148, 196, 238), Color3.fromRGB(248, 248, 246)},
	Clicky = {Color3.fromRGB(245, 230, 194), Color3.fromRGB(48, 98, 204), Color3.fromRGB(231, 136, 124)},
}
Parts.Charcoal = Color3.fromRGB(47, 54, 64)
Parts.Crimson = Color3.fromRGB(201, 33, 49)
Parts.Yellow = Color3.fromRGB(244, 195, 49)
Parts.Pitch = 1.3
Parts.KeyPitch = 2.6
Parts.PressDepth = Config.PressDepth
local keyboardRows = {
	{"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="},
	{"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]"},
	{"A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "\\"},
	{"Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "⇧", "⌃"},
}
local specialLegends = {Esc = "⎋", ESC = "⎋", Ctrl = "⌃", CTRL = "⌃", SHIFT = "⇧", SPACE = "␣", ENTER = "↵", ["↑"] = "↑", ["↓"] = "↓", ["→"] = "→", ["←"] = "←"}

function Parts.Model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	model:SetAttribute("KCEditUnit", true)
	return model
end

function Parts.Block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, collidable: boolean?): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, cf
	part.Color, part.Material = color, Enum.Material.SmoothPlastic
	part.Anchored, part.CanCollide = true, collidable ~= false
	part.CanTouch, part.CanQuery = false, part.CanCollide
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	part:SetAttribute("Role", if part.CanCollide then "Walkable" else "Decoration")
	return part
end

function Parts.Legend(part: BasePart, text: string, face: Enum.NormalId?, color: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face = "Legend", face or Enum.NormalId.Top
	gui.CanvasSize, gui.LightInfluence, gui.AlwaysOnTop = Vector2.new(128, 128), 1, false
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextScaled, label.Font = text, true, Enum.Font.GothamBold
	label.TextColor3 = color or Parts.Charcoal
	label.Parent, gui.Parent = gui, part
end

function Parts.Key(parent: Instance, template: MeshPart, cf: CFrame, family: string, index: number, legend: string?): MeshPart
	local key = template:Clone()
	key.Name, key.Size, key.CFrame = "Key", Vector3.new(2.4, .85, 2.4), cf
	key.PivotOffset = CFrame.identity
	key.Color, key.Material = Parts.Palette[family][(index - 1) % 3 + 1], Enum.Material.SmoothPlastic
	key.Anchored, key.CanCollide, key.CanQuery, key.CanTouch = true, false, true, false
	key.CollisionFidelity = Enum.CollisionFidelity.Hull
	key:SetAttribute("KeyFamily", family)
	key:SetAttribute("Role", "WalkableSkin")
	key:SetAttribute("PressDepth", Parts.PressDepth)
	key:SetAttribute("Pressable", true)
	key:SetAttribute("KeyLegend", legend or "A")
	key.Parent = parent
	Parts.KeyLegend(key, legend or "A")
	return key
end

function Parts.KeyLegend(key: BasePart, text: string)
	local color = key.Color
	local lightInk = color.R * .2126 + color.G * .7152 + color.B * .0722 < .5
	Parts.Legend(key, text, nil, if lightInk then Color3.fromRGB(255, 248, 230) else Parts.Charcoal)
	local gui = key.Legend :: SurfaceGui
	gui.CanvasSize, gui.LightInfluence = Vector2.new(256, 256), .25
	local label = gui:FindFirstChildOfClass("TextLabel") :: TextLabel
	label.Position, label.Size = UDim2.fromScale(.17, .17), UDim2.fromScale(.66, .66)
	key:SetAttribute("KeyLegend", text)
end

function Parts.Bank(parent: Instance, name: string, template: MeshPart, cf: CFrame, columns: number, rows: number, family: string, legend: string?): Model
	local model = Parts.Model(parent, name)
	local size = Vector3.new(columns * Parts.Pitch, .7, rows * Parts.Pitch)
	local gridColumns, gridRows = math.max(1, math.floor(columns / 2)), math.max(1, math.floor(rows / 2))
	local pitchX, pitchZ = size.X / gridColumns, size.Z / gridRows
	local base = Parts.Block(model, "Base", size, cf * CFrame.new(0, -1.2, 0), Parts.Charcoal)
	model.PrimaryPart = base
	base.Material = Enum.Material.Metal
	base.CanCollide = false
	base.CanQuery = false
	base:SetAttribute("Role", "Decoration")
	local collider = Parts.Block(model, "BankContact", Vector3.new(size.X - .2, .25, size.Z - .2), cf * CFrame.new(0, -Parts.PressDepth - .125, 0), Parts.Palette[family][1])
	collider.Transparency = 1
	collider:SetAttribute("Role", "Walkable")
	model:SetAttribute("KeyFamily", family)
	model:SetAttribute("TopPosition", cf.Position)
	model:SetAttribute("Columns", gridColumns)
	model:SetAttribute("Rows", gridRows)
	model:SetAttribute("GridPitchX", pitchX)
	model:SetAttribute("GridPitchZ", pitchZ)
	model:SetAttribute("BankWidth", size.X)
	model:SetAttribute("BankDepth", size.Z)
	for x = 1, gridColumns do
		for z = 1, gridRows do
			local row = keyboardRows[(z - 1) % #keyboardRows + 1]
			local mark = if x == 1 and z == 1 and legend then specialLegends[legend] or row[1] else row[(x - 1) % #row + 1]
			local colorIndex = if x == 1 then 3 else if x == gridColumns then 2 else 1
			local pose = cf * CFrame.new((x - (gridColumns + 1) / 2) * pitchX, -.425, (z - (gridRows + 1) / 2) * pitchZ)
			local key = Parts.Key(model, template, pose, family, colorIndex, mark)
			key.Name, key.Size = "Key_" .. x .. "_" .. z, Vector3.new(pitchX - .18, .85, pitchZ - .18)
			Parts.Block(model, "Socket_" .. x .. "_" .. z, Vector3.new(pitchX - .06, .1, pitchZ - .06), pose * CFrame.new(0, -.4, 0), Parts.Charcoal, false)
		end
	end
	return model
end

function Parts.Support(parent: Instance, cf: CFrame, height: number, color: Color3?)
	local unit = Parts.Model(parent, "Support")
	local body = Parts.Block(unit, "Housing", Vector3.new(5, height, 5), cf * CFrame.new(0, -height / 2 - 1.55, 0), Parts.Charcoal)
	body:SetAttribute("Role", "SolidBlocker")
	body.Material = Enum.Material.Metal
	Parts.Block(unit, "Insert", Vector3.new(2.4, math.min(3, height * .5), .22), body.CFrame * CFrame.new(0, 0, -2.6), color or Parts.Palette.Thocky[2], false)
	for _,x in {-2.4, 2.4} do
		Parts.Block(unit, "CornerHousing", Vector3.new(1.2, 2.4, 1.1), body.CFrame * CFrame.new(x, -height / 2 + 1.2, -2.3), Parts.Palette.Thocky[1], false)
	end
	Parts.Block(unit, "CircuitTrace", Vector3.new(3.2, .35, .18), body.CFrame * CFrame.new(-.1, .4, -2.74), Color3.fromRGB(156, 222, 191), false)
	Parts.Block(unit, "CircuitReturn", Vector3.new(.35, 1.7, .18), body.CFrame * CFrame.new(1.3, -.3, -2.74), Color3.fromRGB(156, 222, 191), false)
	local foot = Parts.Block(unit, "Foot", Vector3.new(6, .6, 6), cf * CFrame.new(0, -height - 1.85, 0), Parts.Charcoal)
	foot:SetAttribute("Role", "SolidBlocker")
	unit.PrimaryPart = body
	return unit
end

function Parts.SpecialKey(parent: Instance, name: string, cf: CFrame, size: Vector3, family: string, legend: string): Model
	local unit = Parts.Model(parent, name)
	local body = Parts.Block(unit, "KeyBody", Vector3.new(size.X, 1.25, size.Z), cf * CFrame.new(0, -.625, 0), Parts.Palette[family][1], false)
	local top = Parts.Block(unit, "KeyTop", Vector3.new(size.X - .35, .22, size.Z - .35), cf * CFrame.new(0, -.11, 0), Parts.Palette[family][1], false)
	for _,v in {body, top} do v:SetAttribute("KeyFamily", family) end
	top:SetAttribute("Pressable", true)
	top:SetAttribute("PressDepth", Parts.PressDepth)
	Parts.KeyLegend(top, specialLegends[string.upper(legend)] or (if legend == "" then "↵" else legend))
	local contact = Parts.Block(unit, "KeyContact", Vector3.new(size.X, .25, size.Z), cf * CFrame.new(0, -Parts.PressDepth - .125, 0), Parts.Charcoal)
	contact.Transparency = 1
	local link = Instance.new("ObjectValue")
	link.Name, link.Value, link.Parent = "PressKey", top, contact
	local bodyLink = Instance.new("ObjectValue")
	bodyLink.Name, bodyLink.Value, bodyLink.Parent = "PressBody", body, top
	unit.PrimaryPart = body
	unit:SetAttribute("KeyFamily", family)
	unit:SetAttribute("TopPosition", cf.Position)
	return unit
end

function Parts.CheckpointFlag(parent: Instance, cf: CFrame, text: string)
	local flag = Parts.Model(parent, "RecoveryMarker")
	local pole = Parts.Block(flag, "Pole", Vector3.new(.35, 6, .35), cf * CFrame.new(0, 3, 0), Parts.Charcoal, false)
	local cloth = Parts.Block(flag, "Flag", Vector3.new(2.7, 1.5, .15), cf * CFrame.new(1.25, 5, 0), Parts.Palette.Creamy[3], false)
	Parts.Legend(cloth, text, Enum.NormalId.Front)
	Parts.Legend(cloth, text, Enum.NormalId.Back)
	flag.PrimaryPart = pole
end

function Parts.JoinSpecialKeys(primary: Model, secondary: Model)
	local key = primary.KeyTop :: BasePart
	secondary.KeyContact.PressKey.Value = key
	secondary.KeyTop:SetAttribute("Pressable", false)
	-- Joined sections share the primary key's legend.
	local secondaryLegend = secondary.KeyTop.Legend :: SurfaceGui
	secondaryLegend.Enabled = false
	for _,part in {secondary.KeyTop, secondary.KeyBody} do
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "PressCompanion", part, key
	end
end

function Parts.Warning(parent: Instance, cf: CFrame, size: Vector3): Part
	local plate = Parts.Block(parent, "MovementWarning", size, cf, Parts.Yellow, false)
	for n = -1, 1 do
		Parts.Block(parent, "BlackBand", Vector3.new(size.X * .15, size.Y + .015, size.Z * .94), cf * CFrame.new(n * size.X * .3, 0, 0) * CFrame.Angles(0, .25, 0), Parts.Charcoal, false)
	end
	return plate
end

function Parts.KillBody(parent: Instance, name: string, cf: CFrame, size: Vector3): Model
	local unit = Parts.Model(parent, name)
	local body = Parts.Block(unit, "Contact", size, cf, Parts.Crimson, false)
	body.CanQuery = true
	body:SetAttribute("Role", "Lethal")
	unit.PrimaryPart = body
	for _,face in {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom} do
		Parts.Legend(body, "X", face, Color3.new(1, 1, 1))
	end
	for _,y in {-.3, .3} do
		Parts.Block(unit, "BlackBand", Vector3.new(size.X + .035, size.Y * .12, size.Z + .035), cf * CFrame.new(0, size.Y * y, 0), Parts.Charcoal, false)
	end
	return unit
end

function Parts.Cylinder(parent: Instance, name: string, cf: CFrame, length: number, diameter: number, color: Color3): Part
	local part = Parts.Block(parent, name, Vector3.new(length, diameter, diameter), cf, color, false)
	part.Shape, part.Material = Enum.PartType.Cylinder, Enum.Material.Metal
	return part
end

return Parts
]],
["RouteStudy"] = [=[--!strict
local Parts = require(script.Parent.Parts)
local Layout = require(script.Parent.Layout)
local RouteStudy = {}

function RouteStudy.Build(parent: Instance, origin: Vector3): Model
	local study = Parts.Model(parent, "CheapWholeRouteStudy")
	study:SetAttribute("PlanningProofOnly", true)
	study:SetAttribute("MechanismsImplemented", "None; S02 and H06 proofs are separate")
	study:SetAttribute("TargetLaps", 3)
	study:SetAttribute("WorkingCapacity", 20)
	local platforms = {}
	for _,id in Layout.Main do
		local node = Layout.Nodes[id]
		local cp = id:sub(1, 2) == "CP" or id == "F00"
		local width, depth = if cp then 18 else 12, if cp then 16 else 10
		local unit = Parts.Model(study, id)
		local block = Parts.Block(unit, "StudySurface", Vector3.new(width, 1, depth), CFrame.new(origin + Vector3.new(node[1], node[2] - .5, node[3])), Parts.Palette[node[4]][1])
		Parts.Legend(block, id)
		unit.PrimaryPart = block
		unit:SetAttribute("SequenceId", id)
		if cp then unit:SetAttribute("RecoveryBay", true) end
		if cp then Parts.CheckpointFlag(unit, CFrame.new(origin + Vector3.new(node[1] - 7, node[2], node[3] + 6)), if id == "F00" then "LAP" else id) end
		platforms[id] = block
	end
	local links = Parts.Model(study, "OrderedNormalConnections")
	local function connect(from: string, to: string, branch: boolean)
		local a, b = platforms[from], platforms[to]
		local delta = b.Position - a.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		local distance = flat.Magnitude
		local count = math.max(1, math.ceil(distance / 10) - 1)
		for i = 1, count do
			local t = i / (count + 1)
			local center = a.Position:Lerp(b.Position, t)
			local width = if branch then 2.4 else 7
			local cf = CFrame.lookAt(center, center + flat.Unit)
			local part = Parts.Block(links, from .. "_to_" .. to .. "_" .. i, Vector3.new(width, 1, 6), cf, if branch then Parts.Palette.Thocky[2] else a.Color)
			part:SetAttribute("ConnectionFrom", from)
			part:SetAttribute("ConnectionTo", to)
			part:SetAttribute("StudyOnly", true)
			part:SetAttribute("ConnectionIndex", i)
		end
	end
	for i,from in Layout.Main do connect(from, Layout.Main[i % #Layout.Main + 1], false) end
	for _,branch in Layout.Branches do
		local node = Layout.Nodes[branch.id]
		local part = Parts.Block(study, branch.id, Vector3.new(3, 1, 3), CFrame.new(origin + Vector3.new(node[1], node[2] - .5, node[3])), Parts.Palette[node[4]][2])
		Parts.Legend(part, branch.id, nil, Color3.new(1, 1, 1))
		platforms[branch.id] = part
		connect(branch.from, branch.id, true)
		connect(branch.id, branch.before, true)
	end
	return study
end

return RouteStudy
]=],
["Runtime"] = [[--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(script.Parent:FindFirstChild("ConfigSnapshot") or game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig)
local Clock = require(script.Parent.Parent.StudGardenV2.HazardClock)
local DropState = require(script.Parent.DropState)
local Runtime = {}

function Runtime.Start(candidate: Model, eligible: (Player) -> boolean, recover: (Player, string) -> boolean)
	assert(RunService:IsServer(), "Keyboard Circuit contact and motion must run on the server")
	assert(candidate:GetAttribute("Phase1Only") == true, "Isolated Phase 1 candidate required")
	local sample = candidate.S02_ThockySwitchworks
	local foundry = sample.H04_FallingKeyFoundry
	local drops = {}
	for i = 1, 3 do
		local model = foundry["Drop" .. i]
		local contacts = {}
		for _,part in model:GetDescendants() do if part:IsA("BasePart") and part:GetAttribute("Role") == "Lethal" then table.insert(contacts, part) end end
		local warnings = {}
		for _,key in foundry.CrossingBank:GetChildren() do
			if key:GetAttribute("DropWarningIndex") == i then table.insert(warnings, key.Legend.DropWarning) end
		end
		table.insert(drops, {model = model, shapes = contacts, start = model:GetPivot(), warning = foundry["Warning" .. i], warningFrames = warnings, offset = model:GetAttribute("CycleOffset"), wasWarning = nil, lastState = nil})
	end
	local sliders = {sample.H05_SpringLift, candidate.H06_EarlyProof.H06_CarriageShuttle}
	local starts = {}
	for _,unit in sliders do
		local bank = unit.RideableBank
		starts[unit] = bank:GetPivot()
		for _,v in bank:GetDescendants() do if v:IsA("BasePart") then v.Anchored = false end end
		bank.PrimaryPart:SetNetworkOwner(nil)
		unit.Slider.Enabled = true
	end
	local lift, shuttle = sliders[1], sliders[2]
	lift.Slider.Speed, shuttle.Slider.Speed = Config.LiftSpeed, 6
	local boardingRay = RaycastParams.new()
	boardingRay.FilterType, boardingRay.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {lift.RideableBank}
	boardingRay.RespectCanCollide = true
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.RespectCanCollide = false
	local clock = Clock.New(Workspace:GetServerTimeNow())
	local characters = {}
	local warningColor, idleWarningColor = Color3.fromRGB(255, 215, 38), Color3.fromRGB(157, 126, 40)
	local active, contacts, bodyChecks, pivotCalls, stationarySweeps, movingSweeps = true, 0, 0, 0, 0, 0
	local liftState, liftAt = "Waiting", 0
	local lastLiftState, lastLiftBoarding, lastLiftExit, lastShuttleBoarding, lastShuttleExit
	local connection: RBXScriptConnection
	local function onBody(body: BasePart)
		if body:FindFirstAncestorWhichIsA("Accessory") then return end
		local character = body:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if player and eligible(player) and recover(player, "FoundryContact") then contacts += 1 end
	end
	local function checkShapes(drop)
		if #characters == 0 then return end
		for _,shape in drop.shapes do
			for _,body in Workspace:GetPartsInPart(shape, params) do onBody(body) end
			bodyChecks += 1
		end
	end
	connection = RunService.Heartbeat:Connect(function()
		local old, now, advanced = Clock.Step(clock, Workspace:GetServerTimeNow())
		if not advanced then return end
		table.clear(characters)
		local players = Players:GetPlayers()
		for _,player in players do if eligible(player) and player.Character then table.insert(characters, player.Character) end end
		params.FilterDescendantsInstances = characters
		for _,drop in drops do
			local state, alpha = DropState.Get(now, drop.offset, Config)
			local isWarning = state == "Warning"
			if isWarning ~= drop.wasWarning then
				drop.wasWarning = isWarning
				drop.warning.Color = if isWarning then warningColor else idleWarningColor
				for _,frame in drop.warningFrames do
					frame.BackgroundTransparency = if isWarning then .45 else 1
					frame.UIStroke.Color = drop.warning.Color
				end
			end
			if state ~= drop.lastState then drop.lastState = state; drop.model:SetAttribute("CycleState", state) end
			local previous = drop.model:GetPivot()
			local destination = drop.start * CFrame.new(0, -Config.DropDistance * alpha, 0)
			if previous == destination then
				stationarySweeps += 1
				checkShapes(drop)
			else
				movingSweeps += 1
				local distance = (destination.Position - previous.Position).Magnitude
				local steps = math.max(1, math.ceil(distance / .35))
				for step = 0, steps do
					drop.model:PivotTo(previous:Lerp(destination, step / steps))
					pivotCalls += 1
					checkShapes(drop)
				end
			end
		end
		if lift.Slider.Speed ~= Config.LiftSpeed then lift.Slider.Speed = Config.LiftSpeed end
		if liftState == "Waiting" then
			for _,player in players do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
				if eligible(player) and root and root:IsA("BasePart") and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air and Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), boardingRay) then liftState, liftAt = "Boarding", now; break end
			end
		elseif liftState == "Boarding" and now - liftAt >= Config.LiftBoardDwell then liftState, liftAt = "Rising", now
		elseif liftState == "Rising" and math.abs(lift.Slider.CurrentPosition - 8) < .2 then liftState, liftAt = "HighDwell", now
		elseif liftState == "HighDwell" and now - liftAt >= Config.LiftHighDwell then liftState, liftAt = "Returning", now
		elseif liftState == "Returning" and math.abs(lift.Slider.CurrentPosition) < .2 then liftState, liftAt = "Waiting", now end
		local liftTarget = if liftState == "Rising" or liftState == "HighDwell" then 8 else 0
		if lift.Slider.TargetPosition ~= liftTarget then lift.Slider.TargetPosition = liftTarget end
		if liftState ~= lastLiftState then lastLiftState = liftState; lift:SetAttribute("CycleState", liftState) end
		local liftBoarding, liftExit = liftState == "Waiting" or liftState == "Boarding", liftState == "HighDwell"
		if liftBoarding ~= lastLiftBoarding then lastLiftBoarding = liftBoarding; lift:SetAttribute("BoardingWindow", liftBoarding) end
		if liftExit ~= lastLiftExit then lastLiftExit = liftExit; lift:SetAttribute("ExitWindow", liftExit) end
		local shuttleTime = now % Config.ShuttlePeriod
		if shuttle.Slider.Speed ~= 6 then shuttle.Slider.Speed = 6 end
		local shuttleTarget = if shuttleTime >= Config.ShuttleDepart and shuttleTime < Config.ShuttleReturn then 24 else 0
		if shuttle.Slider.TargetPosition ~= shuttleTarget then shuttle.Slider.TargetPosition = shuttleTarget end
		local shuttlePosition = shuttle.Slider.CurrentPosition
		local shuttleBoarding, shuttleExit = math.abs(shuttlePosition) < .2, math.abs(shuttlePosition - 24) < .2
		if shuttleBoarding ~= lastShuttleBoarding then lastShuttleBoarding = shuttleBoarding; shuttle:SetAttribute("BoardingWindow", shuttleBoarding) end
		if shuttleExit ~= lastShuttleExit then lastShuttleExit = shuttleExit; shuttle:SetAttribute("ExitWindow", shuttleExit) end
		candidate:SetAttribute("KCElapsed", now)
	end)
	local controller = {}
	function controller.Diagnostics()
		return {active = active, elapsed = clock.elapsed, contacts = contacts, bodyChecks = bodyChecks, pausedStalls = clock.pausedStalls,
			pivotCalls = pivotCalls, stationarySweeps = stationarySweeps, movingSweeps = movingSweeps,
			liftPosition = sliders[1].Slider.CurrentPosition, shuttlePosition = sliders[2].Slider.CurrentPosition}
	end
	function controller.Stop()
		if not active then return end
		active = false
		connection:Disconnect()
		for _,unit in sliders do
			local bank = unit.RideableBank
			local ray = RaycastParams.new()
			ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {bank}
			for _,player in Players:GetPlayers() do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if eligible(player) and root and root:IsA("BasePart") and Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), ray) then recover(player, "MechanismStop") end
			end
			unit.Slider.Enabled = false
			for _,v in bank:GetDescendants() do if v:IsA("BasePart") then v.Anchored = true; v.AssemblyLinearVelocity = Vector3.zero; v.AssemblyAngularVelocity = Vector3.zero end end
			bank:PivotTo(starts[unit])
			unit.Slider.TargetPosition = 0
			unit:SetAttribute("CycleState", "Stopped")
			unit:SetAttribute("BoardingWindow", false)
			unit:SetAttribute("ExitWindow", false)
		end
		for _,drop in drops do drop.model:PivotTo(drop.start); drop.model:SetAttribute("CycleState", "Stopped") end
		candidate:SetAttribute("KCElapsed", 0)
	end
	return controller
end

return Runtime

]],
["Sample"] = [[--!strict
local Parts = require(script.Parent.Parts)
local Mechanisms = require(script.Parent.Mechanisms)
local Landmarks = require(script.Parent.Landmarks)
local Sample = {}

function Sample.Build(parent: Instance, origin: Vector3, template: MeshPart): Model
	local sample = Parts.Model(parent, "S02_ThockySwitchworks")
	sample:SetAttribute("CandidateRevision", "KC_P1_C08")
	sample:SetAttribute("CourseId", "keyboard-circuit")
	sample:SetAttribute("Phase1Only", true)
	local function cf(x: number, y: number, z: number): CFrame return CFrame.new(origin + Vector3.new(x, y, z)) end
	local function bank(name: string, x: number, y: number, z: number, cols: number, rows: number, legend: string?): Model
		local unit = Parts.Bank(sample, name, template, cf(x, y, z), cols, rows, "Thocky", legend)
		Parts.Support(unit, cf(x, y, z), 7, Parts.Palette.Thocky[2])
		return unit
	end
	local cp1 = bank("CP1_Recovery", 0, 0, 0, 12, 12, "CP1")
	cp1:SetAttribute("CheckpointIndex", 1)
	cp1:SetAttribute("RespawnOffset", Vector3.new(-3, 3, 3))
	Parts.CheckpointFlag(cp1, cf(-6, 0, 6), "CP1")
	for i,step in {Vector3.new(20, 2, 0), Vector3.new(37, 4, -3), Vector3.new(54, 6, 0)} do
		bank("O03_EscStep" .. i, step.X, step.Y, step.Z, 10, 8, "Esc")
	end
	bank("H04_Approach", 69, 6, 0, 8, 10, "↓")
	Mechanisms.Foundry(sample, template, cf(96, 6, 0))
	local exit = bank("H04_CommonExit", 127, 6, 0, 10, 12, "→")
	exit:SetAttribute("BranchAfter", "H04")
	local function routeSign(parent: Instance, name: string, position: CFrame, text: string, color: Color3)
		local sign = Parts.Block(parent, name, Vector3.new(8, 2.8, .3), position * CFrame.Angles(0, math.pi / 2, 0), color, false)
		for _,face in {Enum.NormalId.Front, Enum.NormalId.Back} do Parts.Legend(sign, text, face, Color3.new(1, 1, 1)) end
		for _,gui in sign:GetChildren() do if gui:IsA("SurfaceGui") then gui.CanvasSize = Vector2.new(768, 256) end end
	end
	routeSign(exit, "NormalRouteSign", cf(128, 9, -6), "NORMAL\nLIFT + ENTER", Parts.Palette.Thocky[2])
	bank("H05_Departure", 145, 6, 0, 10, 10, "↑")
	Mechanisms.Lift(sample, template, cf(161, 6, 0))
	bank("H05_FixedExit", 177, 14, 0, 10, 10, "→")
	local enter = Parts.Model(sample, "O04_EnterHairpin")
	local enterStem = Parts.SpecialKey(enter, "EnterStem", cf(194, 14, 0), Vector3.new(13, 1.25, 20.8), "Thocky", "ENTER")
	local enterReturn = Parts.SpecialKey(enter, "EnterReturn", cf(183.6, 14, 7.8), Vector3.new(7.8, 1.25, 5.2), "Thocky", "↵")
	Parts.JoinSpecialKeys(enterStem, enterReturn)
	Parts.Support(enter, cf(194, 14, 0), 11)
	bank("O04_OffsetExit", 190, 14, 22, 10, 8, "ENTER")
	bank("O04_ReturnLanding", 174, 14, 27, 10, 8, "→")
	local expert = Parts.Model(sample, "X01_SwitchSpine")
	routeSign(expert, "ExpertMarker", cf(130, 9, 7), "EXPERT X01\nHARD JUMPS", Parts.Palette.Thocky[3])
	for i,p in {Vector3.new(135, 8, 10), Vector3.new(143, 10, 16), Vector3.new(136, 9, 24), Vector3.new(144, 11.5, 29)} do
		local landing = Parts.Model(expert, "SwitchLanding" .. i)
		local top = Parts.Key(landing, template, CFrame.new(origin + p + Vector3.new(0, -.425, 0)), "Thocky", 2, ({"[", "]", ",", "."})[i])
		top.Name, top.Size = "SwitchCap", Vector3.new(2.4, .85, 2.4)
		landing.PrimaryPart = top
		local contact = Parts.Block(landing, "KeyContact", Vector3.new(2.4, .25, 2.4), cf(p.X, p.Y - Parts.PressDepth - .125, p.Z), Parts.Charcoal)
		contact.Transparency = 1
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "PressKey", top, contact
		Parts.Block(landing, "SwitchStem", Vector3.new(1.3, 2.4, 1.3), cf(p.X, p.Y - 2, p.Z), Parts.Charcoal, false)
		Parts.Block(landing, "SwitchFoot", Vector3.new(1.5, .4, 1.5), cf(p.X, p.Y - 4, p.Z), Parts.Charcoal, false)
	end
	local merge = bank("BeforeCP2_MergeApron", 156, 14, 36, 12, 10, "→")
	merge:SetAttribute("ExpertRejoin", "X01")
	local cp2 = bank("CP2_Recovery", 156, 14, 54, 12, 12, "CP2")
	cp2:SetAttribute("CheckpointIndex", 2)
	cp2:SetAttribute("RespawnOffset", Vector3.new(-3, 3, 3))
	Parts.CheckpointFlag(cp2, cf(150, 14, 60), "CP2")
	Landmarks.Magazine(sample, cf(176, 1, -24), template)
	Landmarks.Rack(sample, cf(50, -5, -29), template)
	local proof = Parts.Model(parent, "H06_EarlyProof")
	Parts.Bank(proof, "CP2_DepartureDock", template, cf(0, 0, 100), 12, 12, "Clacky", "CP2")
	Mechanisms.Shuttle(proof, template, cf(16, 0, 100))
	Parts.Bank(proof, "ReceivingDock", template, cf(56, 0, 100), 12, 12, "Clacky", "→")
	proof:SetAttribute("Phase1Only", true)
	proof:SetAttribute("RecoveryCheckpoint", "CP2")
	local comparisons = Parts.Model(parent, "FourFamilyAudioAudition")
	comparisons:SetAttribute("AudioStatus", "Actual recording candidates; final family selection pending")
	for i,family in {"Creamy", "Thocky", "Clacky", "Clicky"} do
		local strip = Parts.Bank(comparisons, family, template, cf((i - 1) * 13, 0, 130), 8, 6, family, family)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "Audition", "Listen", family .. " candidate"
		prompt.MaxActivationDistance, prompt.HoldDuration = 10, 0
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("AuditionFamily", family)
		prompt.Parent = strip.PrimaryPart
	end
	return sample
end

return Sample
]],
["Session"] = [[--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Http = game:GetService("HttpService")
if not RunService:IsStudio() or not RunService:IsServer() then return end
local candidate = script.Parent.Parent
if not candidate:IsA("Model") or candidate:GetAttribute("KCSessionEnabled") ~= true then return end
local participants, cooldowns, records = {}, {}, {}
local sample = candidate.S02_ThockySwitchworks
local diagnosticsDirty, diagnosticsAt, diagnosticEncodes = true, -math.huge, 0
local diagnosticStates = {}
local supportRay = RaycastParams.new()
supportRay.FilterType, supportRay.FilterDescendantsInstances, supportRay.RespectCanCollide = Enum.RaycastFilterType.Include, {sample}, true
local function eligible(player: Player): boolean return participants[player] ~= nil end
local function recover(player: Player, reason: string): boolean
	local state = participants[player]
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not state or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
	local now = Workspace:GetServerTimeNow()
	if (cooldowns[player] or 0) > now then return false end
	cooldowns[player] = now + .7
	local cf
	if state.mode == "Shuttle" then cf = candidate.H06_EarlyProof.CP2_DepartureDock:GetAttribute("TopPosition")
	elseif state.mode == "Study" then
		local id = if state.cp == 0 then "F00" else "CP" .. state.cp
		cf = candidate.CheapWholeRouteStudy[id].PrimaryPart.Position + Vector3.new(0, .5, 0)
	else cf = sample[if state.cp == 2 then "CP2_Recovery" else "CP1_Recovery"]:GetAttribute("TopPosition") end
	root.Anchored = false
	root.CFrame = CFrame.new(cf + Vector3.new(-3, 3.2, 3))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	if reason ~= "Begin" then table.insert(records, {userId = player.UserId, reason = reason, cp = state.cp, mode = state.mode, at = now}) end
	diagnosticsDirty = true
	return true
end
local runtime = require(script.Parent.Runtime).Start(candidate, eligible, recover)
local function publishDiagnostics(now: number, force: boolean?)
	if not force and not diagnosticsDirty and now - diagnosticsAt < .1 then return end
	diagnosticsAt, diagnosticsDirty = now, false
	diagnosticEncodes += 1
	table.clear(diagnosticStates)
	for player,state in participants do diagnosticStates[tostring(player.UserId)] = state end
	candidate:SetAttribute("KCServerDiagnostics", Http:JSONEncode({runtime = runtime.Diagnostics(), recoveries = records, participants = diagnosticStates, realServer = RunService:IsServer(), diagnosticEncodes = diagnosticEncodes}))
end
local controls = Instance.new("Folder")
controls.Name, controls.Parent = "StudioProbeControls", candidate
local function event(name: string, callback): BindableEvent
	local signal = Instance.new("BindableEvent")
	signal.Name, signal.Parent = name, controls
	signal.Event:Connect(callback)
	return signal
end
event("Begin", function(userId: number, mode: string)
	if mode ~= "Sample" and mode ~= "Shuttle" and mode ~= "Study" then return end
	local player = Players:GetPlayerByUserId(userId)
	if not player or not player.Character then return end
	participants[player] = {mode = mode, cp = if mode == "Study" then 0 else if mode == "Shuttle" then 2 else 1, laps = 0, began = Workspace:GetServerTimeNow(), insideGate = false}
	cooldowns[player] = 0
	recover(player, "Begin")
	diagnosticsDirty = true
end)
local heartbeat: RBXScriptConnection
heartbeat = RunService.Heartbeat:Connect(function()
	for _,player in Players:GetPlayers() do
		if participants[player] then continue end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.FloorMaterial == Enum.Material.Air then continue end
		local top = sample.CP1_Recovery:GetAttribute("TopPosition")
		if math.abs(root.Position.X - top.X) < 7 and math.abs(root.Position.Z - top.Z) < 7 and root.Position.Y > top.Y and root.Position.Y < top.Y + 7 then
			participants[player] = {mode = "Sample", cp = 1, laps = 0, began = Workspace:GetServerTimeNow(), insideGate = false}
			diagnosticsDirty = true
		end
	end
	for player,state in participants do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not root or not root:IsA("BasePart") or not humanoid then continue end
		if root.Position.Y < 318 then recover(player, "Fall") end
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			if state.mode == "Sample" then
				local ground = Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), supportRay)
				if ground and ground.Instance:GetAttribute("Role") == "SolidBlocker" then recover(player, "SupportLanding"); continue end
			end
			if state.mode == "Sample" and state.cp == 1 then
				local top = sample.CP2_Recovery:GetAttribute("TopPosition")
				if math.abs(root.Position.X - top.X) < 7 and math.abs(root.Position.Z - top.Z) < 7 and root.Position.Y > top.Y and root.Position.Y < top.Y + 7 then state.cp = 2; diagnosticsDirty = true end
			elseif state.mode == "Study" and not state.finished then
				local id = if state.cp < 3 then "CP" .. (state.cp + 1) else "F00"
				local bank = candidate.CheapWholeRouteStudy[id].PrimaryPart
				local point = bank.CFrame:PointToObjectSpace(root.Position)
				local inside = math.abs(point.X) < bank.Size.X / 2 and math.abs(point.Z) < bank.Size.Z / 2 and point.Y > 0 and point.Y < 7
				if inside and not state.insideGate then
					if state.cp == 3 then state.laps += 1; state.cp = 0; state.finished = state.laps >= 3 else state.cp += 1 end
					diagnosticsDirty = true
				end
				if inside ~= state.insideGate then diagnosticsDirty = true end
				state.insideGate = inside
			end
		end
	end
	publishDiagnostics(Workspace:GetServerTimeNow())
end)
event("Stop", function()
	runtime.Stop()
	heartbeat:Disconnect()
	candidate:SetAttribute("KCSessionStopped", true)
	publishDiagnostics(Workspace:GetServerTimeNow(), true)
end)
candidate:SetAttribute("KCRealServerStarted", true)

]],
["ConfigSnapshot"] = [[--!strict
return {
	Revision = "KC_P1_C08",
	DropPeriod = 6.6,
	DropWarning = 1,
	DropFall = .55,
	DropHold = .65,
	DropReturn = .9,
	DropDistance = 15,
	LiftBoardDwell = 1.2,
	LiftHighDwell = 2.8,
	LiftSpeed = 6,
	ShuttlePeriod = 14,
	ShuttleDepart = 3,
	ShuttleReturn = 10,
	PressDepth = .45,
	PressAttack = .055,
	PressRelease = .145,
	ContactGrace = .05,
	OwnVolume = .42,
	ReleaseVolume = .095,
	NearbyVolume = .05,
	OwnPressVoices = 4,
	OwnReleaseVoices = 2,
	NearbyVoices = 2,
	OwnAudioInterval = .065,
	ReleaseAudioInterval = .12,
	NearbyAudioInterval = .12,
	NearbyRadius = 26,
	AudioPitchVariation = .02,
	AudioGainVariation = .025,
	AuditionReleaseDelay = .16,
	AudioReadyTimeout = 10,
	AudioStatus = "Dedicated down/up keycap recordings; owner listening judgment pending",
	Audio = {
		Creamy = {id = "136185332283213", upId = "84458483180547", name = "KeycapShowcase1 [D/U]", creator = "Creynex", gain = 1, upGain = .7, speed = .97, upSpeed = 1.04, downRegion = NumberRange.new(0, .18), upRegion = NumberRange.new(0, .2), low = 3, mid = -2, high = -8, upHigh = -10, body = {decay = .12, wet = -22, dry = -1, density = .7}},
		Thocky = {id = "140067773632575", upId = "73995464860692", name = "KeycapShowcase2 [D/U]", creator = "Creynex", gain = .8, upGain = 1, speed = .95, upSpeed = 1.03, downRegion = NumberRange.new(0, .18), upRegion = NumberRange.new(0, .2), low = 4, mid = -2, high = -10, upHigh = -12, body = {decay = .14, wet = -24, dry = -1, density = .8}},
		Clacky = {id = "138741356128554", upId = "134668651361926", name = "KeycapShowcase3 [D/U]", creator = "Creynex", gain = 1.5, upGain = 1.35, speed = 1, upSpeed = 1.04, downRegion = NumberRange.new(0, .18), upRegion = NumberRange.new(0, .18), low = 0, mid = -1, high = -4, upHigh = -7},
		Clicky = {id = "118137355838031", upId = "72521239166699", name = "KeycapShowcase4 [D/U]", creator = "Creynex", gain = 1.4, upGain = .75, speed = 1.02, upSpeed = 1.06, downRegion = NumberRange.new(.03, .26), upRegion = NumberRange.new(.03, .24), low = -2, mid = -1, high = -4, upHigh = -8},
	},
}
]],
["KeyboardCircuitFeedback"] = [[--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PromptService = game:GetService("ProximityPromptService")
local Audio = require(script.Parent.KeyboardCircuitAudio)
local Feedback = {}
local running = setmetatable({}, {__mode = "k"})

function Feedback.Start(candidate: Model)
	assert(RunService:IsClient(), "Key feedback belongs to the local client")
	if running[candidate] then return running[candidate] end
	local existing = Feedback.Get(candidate)
	if existing then return existing end
	local snapshot = candidate:FindFirstChild("SourceSnapshot")
	local Config = require(if snapshot then snapshot.ConfigSnapshot else game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig)
	local localPlayer = Players.LocalPlayer
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "KeyboardCircuitAudition", localPlayer.PlayerGui
	local identity = Instance.new("ObjectValue")
	identity.Name, identity.Value, identity.Parent = "Candidate", candidate, folder
	local audio = Audio.Start(folder, Config)
	local states, contacts, occupied, ownKeys = {}, {}, {}, {}
	local active, nearbyAt, ownAudioAt, releaseAudioAt, nearbyAudioAt = true, 0, 0, 0, 0
	local totals = {entries = 0, releases = 0, coalesced = 0, releaseCoalesced = 0, visualWrites = 0, warningWrites = 0, createdVisuals = 0, restoredVisuals = 0}
	local visualCamera = Workspace.CurrentCamera
	local ray = RaycastParams.new()
	ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
	local banks = setmetatable({}, {__mode = "k"})
	local function keyAt(hit: RaycastResult, position: Vector3): BasePart?
		local support = hit.Instance
		local link = support:FindFirstChild("PressKey")
		if link and link:IsA("ObjectValue") and link.Value and link.Value:IsA("BasePart") then
			return if link.Value:IsDescendantOf(candidate) and link.Value:GetAttribute("Pressable") then link.Value else nil
		end
		if support.Name ~= "BankContact" then return nil end
		local bank = support.Parent
		if not bank then return nil end
		local data = banks[bank]
		if not data then
			data = {columns = bank:GetAttribute("Columns"), rows = bank:GetAttribute("Rows"), pitchX = bank:GetAttribute("GridPitchX"), pitchZ = bank:GetAttribute("GridPitchZ"), keys = {}}
			if typeof(data.columns) ~= "number" or typeof(data.rows) ~= "number" or typeof(data.pitchX) ~= "number" or typeof(data.pitchZ) ~= "number" then return nil end
			if data.columns < 1 or data.rows < 1 or data.pitchX <= 0 or data.pitchZ <= 0 then return nil end
			for _,child in bank:GetChildren() do if child:IsA("BasePart") and child:GetAttribute("Pressable") then data.keys[child.Name] = child end end
			banks[bank] = data
		end
		local point = support.CFrame:PointToObjectSpace(position)
		local x = math.clamp(math.floor(point.X / data.pitchX + data.columns / 2) + 1, 1, data.columns)
		local z = math.clamp(math.floor(point.Z / data.pitchZ + data.rows / 2) + 1, 1, data.rows)
		return data.keys["Key_" .. x .. "_" .. z]
	end
	local function groundedFeet(player: Player)
		local fresh, slots = {}, {}
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return character, fresh, slots, false end
		local feet = {
			Left = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),
			Right = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg"),
		}
		for name,foot in feet do if foot:IsA("BasePart") then slots[name] = true end end
		if not next(slots) then slots.Root = true end
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then return character, fresh, slots, false end
		if humanoid.FloorMaterial == Enum.Material.Air then return character, fresh, slots, true end
		local support = Workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
		if not support then return character, fresh, slots, true end
		for name,foot in feet do
			if not slots[name] then continue end
			local sole = foot.CFrame:PointToWorldSpace(Vector3.new(0, -foot.Size.Y / 2, 0))
			local hit = Workspace:Raycast(sole + Vector3.new(0, 1.2, 0), Vector3.new(0, -2.2, 0), ray)
			if hit and hit.Normal.Y > .5 and math.abs((sole - hit.Position):Dot(hit.Normal)) < .85 then
				local key = keyAt(hit, sole)
				if key then fresh[name] = key end
			end
		end
		if slots.Root then
			local key = keyAt(support, root.Position)
			if key then fresh.Root = key end
		end
		return character, fresh, slots, true
	end
	local function restore(state)
		for _,item in state.visuals do
			if item.original.Parent then item.original.LocalTransparencyModifier = item.transparency end
			for _,gui in item.guis do if gui.original.Parent then gui.original.Enabled = gui.enabled end end
			item.clone:Destroy()
			totals.restoredVisuals += 1
		end
		table.clear(state.visuals)
	end
	local function makeVisuals(key: BasePart)
		local visuals = {}
		if not visualCamera then return visuals end
		local originals, seen = {key}, {[key] = true}
		for _,link in key:GetChildren() do
			if link:IsA("ObjectValue") and (link.Name == "PressBody" or link.Name == "PressCompanion") and link.Value and link.Value:IsA("BasePart") and not seen[link.Value] then
				seen[link.Value] = true
				table.insert(originals, link.Value)
			end
		end
		for _,original in originals do
			if not original:IsDescendantOf(candidate) then continue end
			local visual = original:Clone()
			visual.Name = "LocalKeyPress"
			for _,child in visual:GetChildren() do
				if child:IsA("Constraint") or child:IsA("WeldConstraint") or child:IsA("JointInstance") or child:IsA("ObjectValue") then child:Destroy() end
			end
			visual.Anchored, visual.CanCollide, visual.CanTouch, visual.CanQuery = true, false, false, false
			visual.LocalTransparencyModifier = 0
			visual.Parent = visualCamera
			local guis = {}
			for _,gui in original:GetChildren() do
				if gui:IsA("SurfaceGui") then
					table.insert(guis, {original = gui, enabled = gui.Enabled})
					gui.Enabled = false
				end
			end
			local legend = original:FindFirstChild("Legend")
			local warning = if legend then legend:FindFirstChild("DropWarning") else nil
			local clonedLegend = visual:FindFirstChild("Legend")
			local clonedWarning = if clonedLegend then clonedLegend:FindFirstChild("DropWarning") else nil
			table.insert(visuals, {
				original = original, clone = visual, transparency = original.LocalTransparencyModifier, guis = guis,
				warning = warning, clonedWarning = clonedWarning,
				warningStroke = if warning then warning:FindFirstChildOfClass("UIStroke") else nil,
				clonedStroke = if clonedWarning then clonedWarning:FindFirstChildOfClass("UIStroke") else nil,
				lastPose = nil, lastAmount = nil, lastDepth = nil, warningTransparency = nil, warningColor = nil,
			})
			original.LocalTransparencyModifier = 1
			totals.createdVisuals += 1
		end
		return visuals
	end
	local function createState(key: BasePart)
		local state = {key = key, held = false, amount = 0, from = 0, changed = os.clock(), visuals = makeVisuals(key), occupants = 0, ownPressed = false}
		states[key] = state
		return state
	end
	local function sample(player: Player, now: number, distance: number)
		local character, fresh, slots, canRetain = groundedFeet(player)
		local previous = contacts[player]
		if not character then contacts[player] = nil; return end
		if not previous or previous.character ~= character then previous = {character = character, feet = {}, keys = {}} end
		local feet, keys = {}, {}
		for name,key in fresh do
			if key:IsDescendantOf(candidate) then feet[name] = {key = key, last = now} end
		end
		-- Grace covers a missed support sample, not an extra old cell after the foot moves.
		for name,old in previous.feet do
			if not feet[name] and slots[name] and canRetain and old.key:IsDescendantOf(candidate) and now - old.last < Config.ContactGrace then feet[name] = old end
		end
		for _,foot in feet do keys[foot.key] = true end
		local own = player == localPlayer
		for key in keys do
			if not previous.keys[key] then
				totals.entries += 1
				if (own and now - ownAudioAt >= Config.OwnAudioInterval) or (not own and now - nearbyAudioAt >= Config.NearbyAudioInterval) then
					audio.Play(key:GetAttribute("KeyFamily"), "down", if own then Config.OwnVolume else Config.NearbyVolume * (1 - distance / Config.NearbyRadius), not own, key)
					if own then ownAudioAt = now else nearbyAudioAt = now end
				else totals.coalesced += 1 end
			end
		end
		contacts[player] = {character = character, feet = feet, keys = keys}
	end
	local controller
	local render = RunService.PreRender:Connect(function()
		if not candidate.Parent or not folder.Parent then controller.Stop(); return end
		if not audio.IsResolved() then return end
		local now = os.clock()
		if visualCamera ~= Workspace.CurrentCamera then
			visualCamera = Workspace.CurrentCamera
			for key,state in states do
				restore(state)
				if key:IsDescendantOf(candidate) then state.visuals = makeVisuals(key) end
			end
		end
		sample(localPlayer, now, 0)
		if now - nearbyAt >= .08 then
			nearbyAt = now
			local character = localPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			for _,player in Players:GetPlayers() do
				if player == localPlayer then continue end
				local other = player.Character
				local otherRoot = if other then other:FindFirstChild("HumanoidRootPart") else nil
				local distance = if root and root:IsA("BasePart") and otherRoot and otherRoot:IsA("BasePart") then (root.Position - otherRoot.Position).Magnitude else math.huge
				if distance < Config.NearbyRadius then sample(player, now, distance) else contacts[player] = nil end
			end
		end
		table.clear(occupied)
		table.clear(ownKeys)
		for player,contact in contacts do
			local humanoid = contact.character:FindFirstChildOfClass("Humanoid")
			if not player.Parent or player.Character ~= contact.character or not humanoid or humanoid.Health <= 0 then contacts[player] = nil; continue end
			for key in contact.keys do
				if key:IsDescendantOf(candidate) then
					occupied[key] = (occupied[key] or 0) + 1
					if player == localPlayer then ownKeys[key] = true end
				end
			end
		end
		for key,count in occupied do
			local state = states[key] or createState(key)
			state.occupants = count
			if not state.held then
				state.held, state.from, state.changed, state.ownPressed = true, state.amount, now, ownKeys[key] == true
			elseif ownKeys[key] then state.ownPressed = true end
		end
		for key,state in states do
			if not key:IsDescendantOf(candidate) then restore(state); states[key] = nil; continue end
			if not occupied[key] and state.held then
				state.held, state.from, state.changed, state.occupants = false, state.amount, now, 0
				totals.releases += 1
				local character = localPlayer.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				local distance = if root and root:IsA("BasePart") then (root.Position - key.Position).Magnitude else math.huge
				if distance < 8 then
					local last = if state.ownPressed then releaseAudioAt else nearbyAudioAt
					local interval = if state.ownPressed then Config.ReleaseAudioInterval else Config.NearbyAudioInterval
					if now - last >= interval then
						local volume = if state.ownPressed then Config.ReleaseVolume else Config.NearbyVolume * (Config.ReleaseVolume / Config.OwnVolume) * (1 - distance / Config.NearbyRadius)
						audio.Play(key:GetAttribute("KeyFamily"), "up", volume, not state.ownPressed, key)
						if state.ownPressed then releaseAudioAt = now else nearbyAudioAt = now end
					else totals.releaseCoalesced += 1 end
				end
			end
			local duration = if state.held then Config.PressAttack else Config.PressRelease
			local progress = math.clamp((now - state.changed) / duration, 0, 1)
			local eased = if state.held then 1 - (1 - progress) ^ 3 else progress * progress * (3 - 2 * progress)
			state.amount = state.from + ((if state.held then 1 else 0) - state.from) * eased
			local depth = key:GetAttribute("PressDepth") or Config.PressDepth
			for _,item in state.visuals do
				if not item.original:IsDescendantOf(candidate) then continue end
				local pose = item.original.CFrame
				if item.lastPose ~= pose or item.lastAmount ~= state.amount or item.lastDepth ~= depth then
					item.clone.CFrame = pose * CFrame.new(0, -depth * state.amount, 0)
					item.lastPose, item.lastAmount, item.lastDepth = pose, state.amount, depth
					totals.visualWrites += 1
				end
				if item.warning and item.clonedWarning then
					local transparency = item.warning.BackgroundTransparency
					if item.warningTransparency ~= transparency then
						item.clonedWarning.BackgroundTransparency = transparency
						item.warningTransparency = transparency
						totals.warningWrites += 1
					end
					if item.warningStroke and item.clonedStroke then
						local color = item.warningStroke.Color
						if item.warningColor ~= color then
							item.clonedStroke.Color = color
							item.warningColor = color
							totals.warningWrites += 1
						end
					end
				end
			end
			if not state.held and progress == 1 then restore(state); states[key] = nil end
		end
	end)
	local prompt = PromptService.PromptTriggered:Connect(function(trigger: ProximityPrompt)
		if audio.IsResolved() and trigger:IsDescendantOf(candidate) then
			local family = trigger:GetAttribute("AuditionFamily")
			if typeof(family) == "string" then audio.Audition(family) end
		end
	end)
	controller = {
		AwaitReady = audio.AwaitReady,
		Readiness = audio.Readiness,
		Diagnostics = function()
			local result = audio.Diagnostics()
			result.active, result.held = active, {}
			for name,value in totals do result.totals[name] = value end
			for key,state in states do table.insert(result.held, {key = key:GetFullName(), amount = state.amount, held = state.held, occupants = state.occupants, visuals = #state.visuals}) end
			return result
		end,
		Audition = function(family: string)
			if audio.IsResolved() then audio.Audition(family) end
		end,
		Stop = function()
			if not active then return end
			active = false
			running[candidate] = nil
			render:Disconnect(); prompt:Disconnect()
			for _,state in states do restore(state) end
			table.clear(states); table.clear(contacts); table.clear(occupied); table.clear(ownKeys)
			audio.Stop()
			folder:Destroy()
		end,
	}
	if RunService:IsStudio() then
		for name,callback in {Diagnostics = controller.Diagnostics, Audition = controller.Audition, StopFeedback = controller.Stop} do
			local probe = Instance.new("BindableFunction")
			probe.Name, probe.OnInvoke, probe.Parent = name, callback, folder
		end
	end
	running[candidate] = controller
	return controller
end

function Feedback.Get(candidate: Model)
	if running[candidate] then return running[candidate] end
	local folder = Players.LocalPlayer.PlayerGui:FindFirstChild("KeyboardCircuitAudition")
	local identity = if folder then folder:FindFirstChild("Candidate") else nil
	if not identity or not identity:IsA("ObjectValue") or identity.Value ~= candidate or not folder:FindFirstChild("Diagnostics") then return nil end
	return {
		AwaitReady = function(cancelled: (() -> boolean)?)
			while folder.Parent do
				local status = folder.Diagnostics:Invoke().readiness
				if status.state ~= "loading" then return status end
				if cancelled and cancelled() then status.state = "cancelled"; return status end
				task.wait(.05)
			end
			return {state = "stopped"}
		end,
		Readiness = function() return folder.Diagnostics:Invoke().readiness end,
		Diagnostics = function() return folder.Diagnostics:Invoke() end,
		Audition = function(family: string) folder.Audition:Invoke(family) end,
		Stop = function() if folder.Parent then folder.StopFeedback:Invoke() end end,
	}
end

return Feedback
]],
["KeyboardCircuitAudio"] = [[--!strict
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local Audio = {}

type Voice = {sound: Sound, equalizer: EqualizerSoundEffect, began: number}
type Variation = {speed: number, gain: number}
type FailedClip = {family: string, kind: string, id: string}
type Readiness = {state: string, reason: string?, elapsed: number, timeout: number, loaded: number, total: number, failed: {FailedClip}, retryStarted: boolean, preloadComplete: boolean, error: string?}

function Audio.Start(folder: Folder, config: any)
	assert(RunService:IsClient(), "Key audio belongs to the local client")
	local active = true
	local started = os.clock()
	local readyTimeout = config.AudioReadyTimeout or 10
	assert(type(readyTimeout) == "number" and readyTimeout > 0 and readyTimeout <= 30, "Key audio readiness must resolve within 30 seconds")
	local readiness: Readiness = {state = "loading", elapsed = 0, timeout = readyTimeout, loaded = 0, total = 0, failed = {}, retryStarted = false, preloadComplete = false}
	local readinessConnection: RBXScriptConnection? = nil
	local preloadThread: thread? = nil
	local sources: {[string]: {[string]: Sound}} = {}
	local pools: {[string]: {Voice}} = {}
	local bodyGroups: {[string]: SoundGroup} = {}
	local sounds: {Sound} = {}
	local variations: {[BasePart]: Variation} = setmetatable({}, {__mode = "k"}) :: any
	local counts: {[string]: number} = {}
	local totals: {[string]: number} = {played = 0, unavailable = 0, steals = 0, downSteals = 0, upSteals = 0, nearbySteals = 0}
	local pitchVariation = math.clamp(config.AudioPitchVariation or .02, 0, .04)
	local gainVariation = math.clamp(config.AudioGainVariation or .025, 0, .06)
	local maxVoices = config.OwnPressVoices + config.OwnReleaseVoices + config.NearbyVoices
	local neutralVariation: Variation = {speed = 1, gain = 1}

	for family, info in config.Audio do
		local body = info.body
		if body then
			local group = Instance.new("SoundGroup")
			group.Name = family .. "_KeyBody"
			group.Volume = 1
			group.Parent = folder
			local reverb = Instance.new("ReverbSoundEffect")
			reverb.Name = "KeyBody"
			reverb.Priority = 10
			reverb.DecayTime = math.clamp(body.decay, .1, .18)
			reverb.WetLevel = math.clamp(body.wet, -40, -18)
			reverb.DryLevel = math.clamp(body.dry or -1, -3, 0)
			reverb.Density = math.clamp(body.density or .75, 0, 1)
			reverb.Diffusion = 1
			reverb.Parent = group
			bodyGroups[family] = group
		end
		local pair: {[string]: Sound} = {}
		for kind, id in {down = info.id, up = info.upId} do
			local sound = Instance.new("Sound")
			sound.Name = family .. "_" .. kind
			sound.SoundId = "rbxassetid://" .. id
			sound.Volume = 0
			sound.Parent = folder
			pair[kind] = sound
			table.insert(sounds, sound)
			readiness.total += 1
		end
		sources[family] = pair
	end

	for name, count in {down = config.OwnPressVoices, up = config.OwnReleaseVoices, nearby = config.NearbyVoices} do
		assert(count >= 1 and count <= 8 and count % 1 == 0, "Key audio pools must have 1 to 8 voices")
		local pool: {Voice} = {}
		for index = 1, count do
			local sound = Instance.new("Sound")
			sound.Name = name .. index
			sound.Parent = folder
			local equalizer = Instance.new("EqualizerSoundEffect")
			equalizer.Priority = 20
			equalizer.Parent = sound
			table.insert(pool, {sound = sound, equalizer = equalizer, began = 0})
			table.insert(sounds, sound)
		end
		pools[name] = pool
	end

	local function cancelPreload()
		local threadToCancel = preloadThread
		preloadThread = nil
		if threadToCancel and threadToCancel ~= coroutine.running() then
			pcall(task.cancel, threadToCancel)
		end
	end

	local function refreshReadiness()
		if not active or readiness.state ~= "loading" then return end
		readiness.elapsed = os.clock() - started
		local failed: {FailedClip} = {}
		for family, pair in sources do
			for kind, sound in pair do
				if not sound.IsLoaded or sound.TimeLength <= 0 then
					table.insert(failed, {family = family, kind = kind, id = sound.SoundId})
				end
			end
		end
		table.sort(failed, function(a, b) return a.family < b.family or (a.family == b.family and a.kind < b.kind) end)
		readiness.failed = failed
		readiness.loaded = readiness.total - #failed
		if not folder.Parent then
			readiness.state, readiness.reason = "stopped", "removed"
		elseif readiness.elapsed >= readyTimeout then
			readiness.state, readiness.reason = "degraded", "deadline"
		elseif #failed == 0 then
			readiness.preloadComplete = true
			readiness.state, readiness.reason = "ready", "loaded"
		elseif readiness.preloadComplete then
			readiness.state, readiness.reason = "degraded", "failed"
		end
		if readiness.state ~= "loading" then
			if readinessConnection then readinessConnection:Disconnect(); readinessConnection = nil end
			cancelPreload()
		end
	end

	local function readinessSnapshot(): Readiness
		refreshReadiness()
		local result = table.clone(readiness)
		result.failed = {}
		for _, clip in readiness.failed do table.insert(result.failed, table.clone(clip)) end
		return result
	end

	local function canPreload(): boolean
		refreshReadiness()
		return active and folder.Parent ~= nil and readiness.state == "loading"
	end

	readinessConnection = RunService.Heartbeat:Connect(refreshReadiness)
	preloadThread = task.defer(function()
		if not canPreload() then return end
		local function preload(list: {Instance}): boolean
			local ok, err = pcall(function() ContentProvider:PreloadAsync(list) end)
			if not active or not folder.Parent or readiness.state ~= "loading" then return false end
			if not ok then
				readiness.error = tostring(err)
				warn("[KeyboardCircuit Audio] " .. tostring(err))
			end
			return canPreload()
		end
		local list: {Instance} = {}
		for _, pair in sources do
			for _, sound in pair do table.insert(list, sound) end
		end
		if not preload(list) then return end
		local retry: {Instance} = {}
		for family, pair in sources do
			for kind, sound in pair do
				if not sound.IsLoaded or sound.TimeLength <= 0 then
					local info = config.Audio[family]
					sound.SoundId = "https://www.roblox.com/asset/?id=" .. (if kind == "up" then info.upId else info.id)
					table.insert(retry, sound)
				end
			end
		end
		if #retry > 0 then
			readiness.retryStarted = true
			if not preload(retry) then return end
		end
		readiness.preloadComplete = true
		refreshReadiness()
	end)

	local function variationFor(key: BasePart?): Variation
		if not key then return neutralVariation end
		local cached = variations[key]
		if cached then return cached end
		local name = (if key.Parent then key.Parent.Name else "") .. "/" .. key.Name
		local hash = 0
		for index = 1, #name do hash = (hash * 31 + string.byte(name, index)) % 65521 end
		local variation = {
			speed = 1 + ((hash % 5) / 2 - 1) * pitchVariation,
			gain = 1 - (math.floor(hash / 5) % 5) / 4 * gainVariation,
		}
		variations[key] = variation
		return variation
	end

	local function play(family: string, kind: string, volume: number, nearby: boolean?, key: BasePart?): boolean
		if not active or not folder.Parent then return false end
		local pair, info = sources[family], config.Audio[family]
		local source = if pair then pair[kind] else nil
		if not source or not source.IsLoaded then totals.unavailable += 1; return false end
		local poolName = if nearby then "nearby" else kind
		local pool = pools[poolName]
		if not pool then return false end
		local chosen = pool[1]
		for _, voice in pool do
			if not voice.sound.IsPlaying then chosen = voice; break end
			if voice.began < chosen.began then chosen = voice end
		end
		if chosen.sound.IsPlaying then
			chosen.sound:Stop()
			totals.steals += 1
			local metric = if nearby then "nearbySteals" else kind .. "Steals"
			totals[metric] += 1
		end
		local variation = variationFor(key)
		local speed = if kind == "up" then (info.upSpeed or info.speed or 1) else (info.speed or 1)
		chosen.began = os.clock()
		chosen.sound.SoundId = source.SoundId
		chosen.sound.Volume = volume * (if kind == "up" then info.upGain else info.gain) * variation.gain
		chosen.sound.PlaybackSpeed = speed * variation.speed
		chosen.sound.PlaybackRegionsEnabled = true
		chosen.sound.PlaybackRegion = if kind == "up" then info.upRegion else info.downRegion
		chosen.equalizer.LowGain = if kind == "up" then (info.upLow or info.low) else info.low
		chosen.equalizer.MidGain = if kind == "up" then (info.upMid or info.mid) else info.mid
		chosen.equalizer.HighGain = if kind == "up" then (info.upHigh or info.high) else info.high
		chosen.sound.SoundGroup = if kind == "down" and not nearby then bodyGroups[family] else nil
		chosen.sound:Play()
		totals.played += 1
		local countKey = family .. "_" .. kind
		counts[countKey] = (counts[countKey] or 0) + 1
		return true
	end

	return {
		Play = play,
		Readiness = readinessSnapshot,
		IsResolved = function(): boolean
			refreshReadiness()
			return readiness.state == "ready" or readiness.state == "degraded"
		end,
		AwaitReady = function(cancelled: (() -> boolean)?): Readiness
			while true do
				local result = readinessSnapshot()
				if result.state ~= "loading" then return result end
				if cancelled and cancelled() then
					result = readinessSnapshot()
					if result.state == "stopped" then return result end
					result.state, result.reason = "cancelled", "cancelled"
					return result
				end
				task.wait(math.min(.05, math.max(readyTimeout - result.elapsed, 0)))
			end
		end,
		Audition = function(family: string)
			if not play(family, "down", config.OwnVolume) then return end
			task.delay(config.AuditionReleaseDelay or .16, function()
				if active and folder.Parent then play(family, "up", config.ReleaseVolume) end
			end)
		end,
		Diagnostics = function()
			local result: any = {plays = table.clone(counts), totals = table.clone(totals), audio = {}, body = {}, maxVoices = maxVoices, readiness = readinessSnapshot()}
			for family, pair in sources do
				result.audio[family] = {}
				for kind, sound in pair do
					result.audio[family][kind] = {loaded = sound.IsLoaded, duration = sound.TimeLength, id = sound.SoundId}
				end
			end
			for family, group in bodyGroups do
				local reverb = group:FindFirstChild("KeyBody") :: ReverbSoundEffect
				result.body[family] = {decay = reverb.DecayTime, wet = reverb.WetLevel, dry = reverb.DryLevel, density = reverb.Density, diffusion = reverb.Diffusion}
			end
			return result
		end,
		Stop = function()
			if not active then return end
			refreshReadiness()
			active = false
			readiness.state, readiness.reason = "stopped", "stopped"
			if readinessConnection then readinessConnection:Disconnect(); readinessConnection = nil end
			cancelPreload()
			for _, sound in sounds do sound:Destroy() end
			for _, group in bodyGroups do group:Destroy() end
			table.clear(sounds)
			table.clear(sources)
			table.clear(pools)
			table.clear(bodyGroups)
			table.clear(variations)
		end,
	}
end

return Audio
]],
["KeyboardCircuitPreview"] = [[--!strict
if not game:GetService("RunService"):IsStudio() then return end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Feedback = require(script.Parent.Controllers.KeyboardCircuitFeedback)
local root, controller
local sequence, clearLoading = 0, nil
local function beginLoading(candidate: Model, current: any)
	sequence += 1
	local action = "KeyboardCircuitLoading" .. sequence
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "KeyboardCircuitLoading", false, 81
	gui.Parent = player.PlayerGui
	local label = Instance.new("TextLabel")
	label.Name, label.Text = "Status", "Preparing key sounds…"
	label.AnchorPoint, label.Position, label.Size = Vector2.new(.5, 1), UDim2.fromScale(.5, .94), UDim2.new(.86, 0, 0, 64)
	label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(255, 248, 225), Color3.fromRGB(12, 30, 59)
	label.Font, label.TextSize, label.TextWrapped = Enum.Font.FredokaOne, 19, true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 14), label
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize, bounds.Parent = Vector2.new(360, 64), label
	local alive, holding = true, true
	ContextActionService:BindActionAtPriority(action, function() return Enum.ContextActionResult.Sink end, false, 5000,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	-- Override movement after normal input without changing another screen's control state.
	RunService:BindToRenderStep(action, Enum.RenderPriority.Input.Value + 1, function()
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then humanoid:Move(Vector3.zero); humanoid.Jump = false end
	end)
	local function releaseMovement()
		if not holding then return end
		holding = false
		ContextActionService:UnbindAction(action)
		RunService:UnbindFromRenderStep(action)
	end
	local function cleanup()
		if not alive then return end
		alive = false
		releaseMovement()
		gui:Destroy()
	end
	clearLoading = cleanup
	task.spawn(function()
		local result = current.AwaitReady(function() return not alive or root ~= candidate or not candidate.Parent end)
		if not alive then return end
		releaseMovement()
		if result.state == "degraded" then
			label.Text = "Some key sounds could not load. You can still play."
			task.delay(3, cleanup)
		else cleanup() end
	end)
end
local function refresh()
	local found
	for _,model in workspace:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("CourseId") == "keyboard-circuit" and model:GetAttribute("KCSessionEnabled") == true then found = model; break end
	end
	if found == root then return end
	if clearLoading then clearLoading(); clearLoading = nil end
	if controller then controller.Stop() end
	local snapshot = if found then found:FindFirstChild("SourceSnapshot") else nil
	local frozenFeedback = if snapshot then snapshot:FindFirstChild("KeyboardCircuitFeedback") else nil
	local implementation = if frozenFeedback and frozenFeedback:IsA("ModuleScript") then require(frozenFeedback) else Feedback
	root, controller = found, if found then implementation.Start(found) else nil
	if found and controller then beginLoading(found, controller) end
end
workspace.ChildAdded:Connect(refresh)
workspace.ChildRemoved:Connect(refresh)
refresh()
]]
}
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local storage = game.ServerStorage
local prepared = storage.KeyboardCircuit_C08_Prepared
local candidate = workspace:FindFirstChild("KeyboardCircuit_P1_C08") or prepared.KeyboardCircuit_P1_C08
local kit = if candidate.Parent == workspace then storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01 else prepared.KeyboardCircuit_EditableKit_K01
candidate.SourceSnapshot.Session.Disabled = false
local previous = workspace:FindFirstChild("KeyboardCircuit_P1_C07") or storage.DeveloperArchives.KeyboardCircuitP1_Archives.KeyboardCircuit_P1_C07
local previousKit = if previous.Parent == workspace then storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01 else storage.DeveloperArchives.KeyboardCircuitP1_Archives.KeyboardCircuit_EditableKit_K01_C07_sources
local serialization = game:GetService("SerializationService")
shared.KCC08Exports = shared.KCC08Exports or {}
local function relative(v, root) return v:GetFullName():sub(#root:GetFullName() + 2) end
local function norm(s) return s:gsub("\r\n", "\n") end
local function geometry(root)
    local rows = {}
    for _,v in root:GetDescendants() do
        if v:IsA("BasePart") then
            local cf = {v.CFrame:GetComponents()}
            for i,n in cf do cf[i] = string.format("%.4f", if math.abs(n) < .00005 then 0 else n) end
            table.insert(rows, relative(v, root) .. "|" .. tostring(v.Size) .. "|" .. table.concat(cf, ",") .. "|" .. tostring(v.Color) .. "|" .. tostring(v.Material) .. "|" .. tostring(v.CanCollide) .. "|" .. tostring(v.CanQuery) .. "|" .. tostring(v.CanTouch) .. "|" .. tostring(v.Transparency))
        end
    end
    table.sort(rows)
    return table.concat(rows, "\n")
end
local function signature(root)
    local rows = {geometry(root)}
    for _,v in root:GetDescendants() do
        local path = relative(v, root)
        if v:IsA("LuaSourceContainer") then
            table.insert(rows, path .. "|" .. norm(v.Source) .. "|" .. (if v:IsA("BaseScript") then tostring(v.Disabled) else "module"))
        elseif v:IsA("TextLabel") then
            table.insert(rows, path .. "|" .. v.Text .. "|" .. tostring(v.Font) .. "|" .. tostring(v.TextColor3) .. "|" .. tostring(v.Position) .. "|" .. tostring(v.Size))
        elseif v:IsA("SurfaceGui") then
            table.insert(rows, path .. "|" .. tostring(v.CanvasSize) .. "|" .. tostring(v.Face) .. "|" .. tostring(v.Enabled) .. "|" .. tostring(v.AlwaysOnTop) .. "|" .. tostring(v.LightInfluence) .. "|" .. tostring(v.MaxDistance))
        end
    end
    table.sort(rows)
    return table.concat(rows, "\n")
end
local function census(root, singleLegends)
    local out = {descendants = #root:GetDescendants(), parts = 0, meshes = 0, colliders = 0, lights = 0, sources = 0, legends = 0, welds = 0, links = 0}
    for _,v in root:GetDescendants() do
        if v:IsA("BasePart") then
            out.parts += 1
            if v:IsA("MeshPart") then out.meshes += 1 end
            if v.CanCollide then out.colliders += 1 end
            local legend = v:GetAttribute("KeyLegend")
            if legend then out.legends += 1; if singleLegends then assert(utf8.len(legend) == 1, "Multiple key symbols: " .. relative(v, root)) end end
        end
        if v:IsA("Light") then out.lights += 1 end
        if v:IsA("LuaSourceContainer") then out.sources += 1 end
        if v:IsA("WeldConstraint") then out.welds += 1; assert(v.Part0 and v.Part1 and v.Part0:IsDescendantOf(root) and v.Part1:IsDescendantOf(root)) end
        if v:IsA("ObjectValue") then out.links += 1; assert(v.Value and v.Value:IsDescendantOf(root)) end
        if v:IsA("PrismaticConstraint") then assert(v.Attachment0 and v.Attachment1 and v.Attachment0:IsDescendantOf(root) and v.Attachment1:IsDescendantOf(root)) end
    end
    return out
end
local sourceMatches = 0
for name, source in expected do
    local object
    if name == "ConfigSnapshot" then object = game.ReplicatedStorage.Config.KeyboardCircuitConfig
    elseif name == "KeyboardCircuitFeedback" or name == "KeyboardCircuitAudio" then object = game.StarterPlayer.StarterPlayerScripts.Controllers[name]
    elseif name == "KeyboardCircuitPreview" then object = game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPreview
    else object = storage.CourseBuilders.KeyboardCircuit[name] end
    assert(norm(object.Source) == norm(source), "Rojo source mismatch: " .. name)
    assert(loadstring(source), "Source compile failed: " .. name)
    sourceMatches += 1
end
assert(#storage.CourseBuilders.KeyboardCircuit:GetChildren() == 10)
for _,model in {candidate, kit} do
    assert(#model.SourceSnapshot:GetChildren() == 14)
    for _,source in model.SourceSnapshot:GetChildren() do assert(norm(source.Source) == norm(expected[source.Name]), "Snapshot mismatch: " .. source.Name) end
end
assert(geometry(candidate) == geometry(previous), "Candidate geometry differs from C07")
assert(geometry(kit) == geometry(previousKit), "Kit geometry differs from C07")
assert(candidate.S02_ThockySwitchworks.O04_EnterHairpin.EnterStem.KeyTop.Legend.Enabled and not candidate.S02_ThockySwitchworks.O04_EnterHairpin.EnterReturn.KeyTop.Legend.Enabled)
assert(kit.Surfaces.EnterL.Stem.KeyTop.Legend.Enabled and not kit.Surfaces.EnterL.Return.KeyTop.Legend.Enabled)
for name,model in {candidate = previous, kit = previousKit} do
    local saved = serialization:DeserializeInstancesAsync(shared.KCC08NativeBefore[name])[1]
    assert(signature(model) == signature(saved), "C07 owner changes detected: " .. name)
    saved:Destroy()
end
local probe = Instance.new("Model")
candidate.SourceSnapshot:Clone().Parent = probe
candidate.StudGardenV2:Clone().Parent = probe
local template = storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true)
require(probe.SourceSnapshot.Sample).Build(probe, Vector3.new(2300, 330, -1300), template)
require(probe.SourceSnapshot.RouteStudy).Build(probe, Vector3.new(2300, 330, -1850))
assert(signature(candidate) == signature(probe), "Candidate cannot be rebuilt from sources")
local kitParent = Instance.new("Folder")
local kitProbe = require(probe.SourceSnapshot.Kit).Build(kitParent, template)
kit.SourceSnapshot:Clone().Parent = kitProbe
assert(signature(kit) == signature(kitProbe), "Kit cannot be rebuilt from sources")
local report = {revision = "KC_P1_C08", sourceMatches = sourceMatches, builders = 10, snapshotSources = 14, unchangedGeometry = true, previousUnchanged = true, candidateRebuild = true, kitRebuild = true, oneVisibleSymbolPerJoinedKey = true, native = {}, preserved = {}}
for name,model in {C08 = candidate, KitC08 = kit, C07BeforeC08 = previous, KitC07BeforeC08 = previousKit} do
    local copy = model:Clone()
    if name == "KitC07BeforeC08" then copy.Name = "KeyboardCircuit_EditableKit_K01" end
    local bytes = serialization:SerializeInstancesAsync({copy})
    copy:Destroy()
    local reopened = serialization:DeserializeInstancesAsync(bytes)[1]
    assert(signature(model) == signature(reopened), "Native round-trip changed " .. name)
    local before, after = census(model, name == "C08" or name == "KitC08"), census(reopened, false)
    for key,value in before do assert(after[key] == value) end
    shared.KCC08Exports[name] = buffer.tostring(bytes)
    report.native[name] = {bytes = buffer.len(bytes), census = before, roundTrip = true}
    reopened:Destroy()
end
probe:Destroy()
kitParent:Destroy()
for name,model in {SGV2_Phase3_F04 = workspace.SGV2_Phase3_F04, Lobby = workspace.Lobby, GrandArcade = workspace.GrandArcade, ObstacleKit_Palette = workspace.ObstacleKit_Palette, CourseLibrary = storage.CourseLibrary} do report.preserved[name] = #model:GetDescendants() end
shared.KCC08Verification = report
return report
