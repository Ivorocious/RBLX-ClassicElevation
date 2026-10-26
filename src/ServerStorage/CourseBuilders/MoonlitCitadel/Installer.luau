--!strict
local Kit = require(script.Parent.Kit)
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local Installer = {}
local P = Kit.Palette

local function group(parent, name, className)
	local item = Instance.new(className or "Model")
	item.Name, item.Parent = name, parent
	return item
end

local function floor(parent, name, point, size, finished)
	local cf = CFrame.new(point)
	if finished then return Kit.Floor(parent, name, size, cf).PrimaryPart end
	local p = Kit.Part(parent, name, size, cf - Vector3.new(0, size.Y / 2, 0), P.StoneLight)
	p:SetAttribute("Role", "WalkableSurface")
	return p
end

local function trigger(parent, name, point, index, recovery)
	local p = Kit.Part(parent, name, Vector3.new(10, 6, 8), CFrame.new(point + Vector3.new(0, 3, 0)), P.Checkpoint, Enum.Material.SmoothPlastic, false)
	p.Transparency, p.CanTouch, p.CanQuery = 1, true, true
	p:SetAttribute("Role", "PreviewTrigger")
	if index then p:SetAttribute("CheckpointIndex", index) end
	p:SetAttribute("RecoveryCFrame", CFrame.new(recovery or point) + Vector3.new(0, 4, 0))
	return p
end

local function area(name, origin, size, fallOffset)
	local m = group(nil, name)
	m:SetAttribute("BoundsCenter", origin + Vector3.new(0, 70, 0))
	m:SetAttribute("BoundsSize", size)
	m:SetAttribute("FallY", origin.Y + fallOffset)
	group(m, "Checkpoints", "Folder")
	group(m, "MovingCars", "Folder")
	group(m, "SwingLanterns", "Folder")
	return m
end

local function lane(parent, name, points, width, gap, archHeight)
	local m = group(parent, name)
	local rise = if archHeight == nil then 1.2 else archHeight
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local flat = Vector3.new(b.X-a.X, 0, b.Z-a.Z)
		local length = flat.Magnitude
		local direction = flat.Unit
		local stop = b - direction * (gap or 0)
		local sections = math.max(2, math.ceil(length / 5))
		for step = 1, sections do
			local t0, t1 = (step-1)/sections, step/sections
			local pa, pb = a:Lerp(stop,t0), a:Lerp(stop,t1)
			pa += Vector3.new(0, math.sin(t0*math.pi)*rise, 0)
			pb += Vector3.new(0, math.sin(t1*math.pi)*rise, 0)
			local p = Kit.Part(m, "ArchTread_"..index.."_"..step, Vector3.new(width, 1, (pb-pa).Magnitude+.06), CFrame.lookAt((pa+pb)/2-Vector3.new(0,.5,0),pb-Vector3.new(0,.5,0)), P.StoneLight)
			p:SetAttribute("Role", "WalkableSurface")
		end
		floor(m,"Landing_"..index,b,Vector3.new(width+2,1,width+2),false)
	end
	return m
end

function Installer.AddExpertArchRoute(parent, origin): Model
	assert(not parent:FindFirstChild("E1_InnerDiagonal"), "Preserve the previous Expert arch route before rebuilding")
	local points = {}
	for _, point in {{-63,28,-23},{-51,34,-8},{-34,40,9},{-16,46,9},{-23,52,20},{-23,52,32},{-40,52,32}} do
		table.insert(points, origin + Vector3.new(point[1], point[2], point[3]))
	end
	local model = group(parent, "E1_InnerDiagonal")
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local distance = Vector3.new(b.X-a.X, 0, b.Z-a.Z).Magnitude
		local steps = math.max(1, math.ceil(distance / 7) - 1)
		for step = 1, steps do
			floor(model, "ArchTread_" .. index .. "_" .. step, a:Lerp(b, step / (steps + 1)), Vector3.new(5, 1, 5), false)
		end
		floor(model, "Landing_" .. index, b, Vector3.new(7, 1, 7), false)
	end
	return model
end

function Installer.AddGalleryToLifts(parent, origin): Model
	assert(not parent:FindFirstChild("GalleryToLifts"), "Preserve the previous join before rebuilding")
	return lane(parent, "GalleryToLifts", {
		origin + Vector3.new(52,64,32), origin + Vector3.new(76,72,32), origin + Vector3.new(76,72,14),
	}, 12, 0)
end

local function pulley(parent, point)
	for i, radius in {3.4, 2.8, .75} do
		local p = Kit.Part(parent, "Pulley_"..i, Vector3.new(.6,radius*2,radius*2), CFrame.new(point+Vector3.new(0,0,(i-1)*.18))*CFrame.Angles(0,math.pi/2,0), if i==2 then P.Iron else P.Brass, Enum.Material.Metal, false)
		p.Shape = Enum.PartType.Cylinder
	end
end

local function cable(parent, a, b)
	local top = Kit.Part(parent,"CableAnchor",Vector3.new(.2,.2,.2),CFrame.new(a),P.Iron,nil,false)
	top.Transparency = 1
	local t = Instance.new("Attachment"); t.Parent = top
	local bottom = Instance.new("Attachment"); bottom.Position = b.CFrame:PointToObjectSpace(b.Position+Vector3.new(0,2,0)); bottom.Parent = b
	local beam = Instance.new("Beam"); beam.Name = "ContinuousChain"; beam.Attachment0=t; beam.Attachment1=bottom
	beam.Width0,beam.Width1=.22,.22; beam.Color=ColorSequence.new(P.Brass); beam.FaceCamera=true; beam.Parent=top
end

local function lifts(parent, origin, low, finished, stage)
	for bay, x in {-9,9} do
		local base = origin + Vector3.new(x, low, 0)
		local car = Kit.Car(parent.MovingCars, stage.."_Bay"..bay, CFrame.new(base), Config.CarWidth, Config.CarDepth)
		car:SetAttribute("Travel", Vector3.new(0,Config.LiftRise,0))
		car:SetAttribute("CycleSeconds",Config.LiftCycleSeconds); car:SetAttribute("DwellSeconds",Config.LiftDwellSeconds)
		car:SetAttribute("PhaseSeconds", if bay==1 then 0 else Config.SecondBayDelay)
		local outside = if bay==1 then -27 else 27
		local weight = Kit.Weight(parent,stage.."_OutboardWeight"..bay,CFrame.new(origin+Vector3.new(outside,low+Config.LiftRise+5,0)),4,8)
		local link = Instance.new("ObjectValue"); link.Name="Counterweight"; link.Value=weight; link.Parent=car
		for _,railX in {x-8,x+8,outside-3,outside+3} do
			Kit.Part(parent,stage.."_Guide",Vector3.new(.5,Config.LiftRise+18,.8),CFrame.new(origin+Vector3.new(railX,low+18,-1)),P.Iron,Enum.Material.Metal,false)
		end
		if finished then
			pulley(parent,origin+Vector3.new(outside,low+Config.LiftRise+12,0))
			cable(parent,origin+Vector3.new(x,low+Config.LiftRise+12,0),car.PrimaryPart)
			cable(parent,origin+Vector3.new(outside,low+Config.LiftRise+12,0),weight.PrimaryPart)
		end
	end
end

local function upperApproaches(m, o, finished)
	floor(m,"CP04_Wait",o+Vector3.new(0,0,17),Vector3.new(48,2,18),finished)
	floor(m,"SharedUpperExit",o+Vector3.new(0,34,-17),Vector3.new(40,2,18),finished)
	local cp=trigger(m.Checkpoints,"CP04",o+Vector3.new(-18,0,21),1,o+Vector3.new(-18,0,21))
	floor(m,"CP04_Inlay",o+Vector3.new(-18,.05,21),Vector3.new(5,.15,5),false).Color=P.Checkpoint
	trigger(m,"Start",o+Vector3.new(-18,0,21),nil,o+Vector3.new(-18,0,21))
	trigger(m,"Finish",o+Vector3.new(0,34,-19))
	local approach=group(m,"ExpertBraceApproach")
	local points={Vector3.new(23,0,21),Vector3.new(31,4,19),Vector3.new(25,8,14),Vector3.new(17,12,12),Vector3.new(9,14,10.5)}
	for i,p in points do floor(approach,"BraceStep"..i,o+p,Vector3.new(6,1,5),finished) end
	floor(approach,"EarlyExitContact",o+Vector3.new(9,28,10.5),Vector3.new(6,1,5),finished)
	lane(approach,"ExitRise",{o+Vector3.new(9,28,10.5),o+Vector3.new(18,30,14),o+Vector3.new(26,32,15),o+Vector3.new(34,34,7),o+Vector3.new(34,34,-14),o+Vector3.new(21,34,-21)},6,0)
	floor(m,"CatchShelf",o+Vector3.new(0,-8,23),Vector3.new(54,1,14),finished):SetAttribute("Role","SafeRefuge")
	lane(m,"CatchReturn",{
		o+Vector3.new(-25,-8,24),o+Vector3.new(-31,-8,24),o+Vector3.new(-31,-4,18),
		o+Vector3.new(-31,0,12),o+Vector3.new(-23,0,12),
	},6,0,0)
	for _,x in {-9,9} do
		local kill=Kit.KillBlock(m,"NeonReset_"..x,CFrame.new(o+Vector3.new(x,-12,0)),Vector3.new(14,2,12))
		kill.PrimaryPart:SetAttribute("PreviewHazard",true)
	end
	return cp
end

local function sample()
	local o=Config.SampleOrigin
	local m=area("UpperSample",o,Vector3.new(150,250,140),-20)
	upperApproaches(m,o,true); lifts(m,o,0,true,"Upper")
	local art=group(m,"NearArchitecture")
	Installer.AddFacade(art,o)
	Kit.Window(art,"GreatAmberWindow",CFrame.new(o+Vector3.new(0,-8,-28))*CFrame.Angles(0,math.pi,0),24,58)
	for _,x in {-37,37} do
		Kit.Turret(art,"SlateSpire_"..x,CFrame.new(o+Vector3.new(x,-10,-23))*CFrame.Angles(0,math.pi,0),7,43)
		Kit.Arch(art,"SideSupport_"..x,CFrame.new(o+Vector3.new(x,-16,13))*CFrame.Angles(0,math.pi/2,0),24,17,4)
		Kit.Lantern(art,"FixedLantern_"..x,CFrame.new(o+Vector3.new(x,4,22)),Vector3.new(2,4,2))
	end
	Kit.Rail(art,"ForwardBalustrade",CFrame.new(o+Vector3.new(0,0,26)),44)
	Kit.Rail(art,"ExitBalustrade",CFrame.new(o+Vector3.new(0,34,-26)),36)
	Installer.AddSampleLights(art,o)
	return m
end

function Installer.AddSampleLights(art,o)
	local lights=group(art,"SampleLighting")
	for i,p in {Vector3.new(-22,15,18),Vector3.new(22,42,9),Vector3.new(0,22,-21)}do
		local a=Kit.Part(lights,"FillAnchor"..i,Vector3.one,CFrame.new(o+p),P.Stone,nil,false);a.Transparency=1
		local l=Instance.new("PointLight");l.Name="UnshadowedFill";l.Range=55;l.Brightness=if i==3 then 1.3 else 2;l.Color=if i==3 then Color3.fromRGB(255,181,83)else Color3.fromRGB(162,184,225);l.Shadows=false;l.Parent=a
	end
	return lights
end

function Installer.AddFacade(art, o)
	assert(not art:FindFirstChild("KeepFacade"),"Preserve existing facade")
	local facade=group(art,"KeepFacade")
	Kit.Part(facade,"ClosedStoneShell",Vector3.new(66,66,4),CFrame.new(o+Vector3.new(0,23,-31)),P.Stone,Enum.Material.Limestone,false)
	for _,x in {-30,-18,18,30} do
		Kit.Part(facade,"Buttress_"..x,Vector3.new(3.6,62,5),CFrame.new(o+Vector3.new(x,21,-27)),P.StoneDark,Enum.Material.Limestone,false)
		for _,y in {-8,12,32,50}do Kit.Part(facade,"PierCap_"..x.."_"..y,Vector3.new(4.4,.7,5.7),CFrame.new(o+Vector3.new(x,y,-27)),P.StoneLight,nil,false)end
	end
	for _,y in {-8,34,54} do Kit.Part(facade,"HorizontalCourse_"..y,Vector3.new(64,.7,4.8),CFrame.new(o+Vector3.new(0,y,-30)),P.StoneLight,nil,false)end
	for _,x in {-25,25} do
		Kit.Window(facade,"SideWindow_"..x,CFrame.new(o+Vector3.new(x,0,-28))*CFrame.Angles(0,math.pi,0),5,22)
		Kit.Part(facade,"BoardingPier_"..x,Vector3.new(4,18,5),CFrame.new(o+Vector3.new(x,-9,22)),P.StoneDark,Enum.Material.Limestone,false)
		Kit.Part(facade,"PierCoping_"..x,Vector3.new(5,1,6),CFrame.new(o+Vector3.new(x,0,22)),P.StoneLight,nil,false)
	end
	for _,x in {-31,31}do Kit.Turret(facade,"CrownSpire_"..x,CFrame.new(o+Vector3.new(x,39,-29))*CFrame.Angles(0,math.pi,0),5,28)end
	for _,x in {-19,19}do
		Kit.Part(facade,"MachinePier_"..x,Vector3.new(3,49,3),CFrame.new(o+Vector3.new(x,14.5,-4)),P.StoneDark,Enum.Material.Limestone,false)
		Kit.Part(facade,"PierHead_"..x,Vector3.new(4,1,4),CFrame.new(o+Vector3.new(x,39,-4)),P.StoneLight,nil,false)
	end
	return facade
end

local function lanterns(name, origin, finished)
	local m=area(name,origin,Vector3.new(110,210,150),-18)
	m:SetAttribute("BoundsCenter",origin+Config.LanternBoundsOffset)
	m:SetAttribute("BoundsSize",Config.LanternBoundsSize)
	floor(m,"EntranceWait",origin,Vector3.new(24,2,16),finished)
	trigger(m,"Start",origin); trigger(m.Checkpoints,"CP02",origin,1,origin+Vector3.new(-8,0,0))
	for band=1,3 do
		local z,y=-20-(band-1)*22,(band-1)*4+2
		local o=origin+Vector3.new(0,y,z)
		local pivot=o+Vector3.new(0,Config.LanternLength+3,0)
		local cage=Kit.Lantern(m.SwingLanterns,"SwingBand"..band,CFrame.new(o+Vector3.new(0,3,0)),Vector3.new(4,7,4))
		cage:SetAttribute("PivotPosition",pivot); cage:SetAttribute("SwingAngleDegrees",Config.LanternAngleDegrees)
		cage:SetAttribute("CycleSeconds",Config.LanternCycleSeconds); cage:SetAttribute("PhaseSeconds",(band-1)*1.5)
		Kit.Part(m,"Mount"..band,Vector3.new(30,1,2),CFrame.new(pivot),P.Iron,Enum.Material.Metal,false)
		cable(m,pivot,cage.PrimaryPart)
		local normalX=if band%2==1 then -8 else 8
		floor(m,"NormalCrossing"..band,origin+Vector3.new(normalX,y,z),Vector3.new(8,1,16),finished)
		floor(m,"NormalWait"..band,origin+Vector3.new(normalX,y+2,z-11),Vector3.new(12,1,10),finished):SetAttribute("Role","SafeRefuge")
		for _,dz in {7,-7} do floor(m,"ExpertIsland"..band.."_"..dz,origin+Vector3.new(0,y,z+dz),Vector3.new(5,1,6),finished) end
		local kill=Kit.KillBlock(m,"RedGap"..band,CFrame.new(origin+Vector3.new(0,y-12,z)),Vector3.new(16,2,8)); kill.PrimaryPart:SetAttribute("PreviewHazard",true)
	end
	floor(m,"ExitWait",origin+Vector3.new(0,12,-80),Vector3.new(24,2,14),finished)
	trigger(m,"Finish",origin+Vector3.new(0,12,-80))
	return m
end

local function rough()
	local o=Config.RoughOrigin
	local m=area("RoughRoute",o,Vector3.new(260,360,230),-20)
	floor(m,"GateCourt",o+Vector3.new(-80,0,70),Vector3.new(42,2,36),false)
	trigger(m,"Start",o+Vector3.new(-80,0,70))
	local function points(values) local a={}for _,v in values do table.insert(a,o+Vector3.new(v[1],v[2],v[3]))end return a end
	lane(m,"OpeningClimb",points({{-80,0,55},{-86,12,30},{-94,18,8},{-83,23,-10},{-70,28,-25}}),10,4)
	floor(m,"ArchRest",o+Vector3.new(-70,28,-25),Vector3.new(22,2,18),false)
	trigger(m.Checkpoints,"CP01",o+Vector3.new(-70,28,-25),1,o+Vector3.new(-75,28,-24))
	lane(m,"H1_NormalOuter",points({{-70,28,-25},{-106,32,-42},{-106,36,-66},{-78,40,-70},{-60,44,-46},{-58,48,-10},{-40,52,32}}),10,4)
	Installer.AddExpertArchRoute(m, o)
	floor(m,"GalleryEntrance",o+Vector3.new(-40,52,32),Vector3.new(22,2,18),false)
	trigger(m.Checkpoints,"CP02",o+Vector3.new(-40,52,32),2,o+Vector3.new(-45,52,29))
	local gal=lanterns("H2_ThreeBands",Vector3.zero,false)
	gal.WorldPivot=CFrame.identity
	local galleryFrame=CFrame.new(o+Vector3.new(-28,52,32))*CFrame.Angles(0,-math.pi/2,0)
	gal:PivotTo(galleryFrame)
	gal:SetAttribute("BoundsCenter",galleryFrame:PointToWorldSpace(Config.LanternBoundsOffset))
	gal:SetAttribute("BoundsSize",Vector3.new(Config.LanternBoundsSize.Z,Config.LanternBoundsSize.Y,Config.LanternBoundsSize.X))
	gal:SetAttribute("FallY",galleryFrame.Position.Y-18)
	for _,item in gal:GetDescendants()do
		local recovery=item:GetAttribute("RecoveryCFrame")
		if typeof(recovery)=="CFrame"then item:SetAttribute("RecoveryCFrame",galleryFrame*recovery)end
	end
	-- Nested studies use the rough route's progress and recovery, not independent checkpoints.
	gal.Start.CanTouch=false; gal.Start.CanQuery=false; gal.Finish.CanTouch=false; gal.Finish.CanQuery=false
	for _,cp in gal.Checkpoints:GetChildren()do cp.CanTouch=false; cp.CanQuery=false end
	for _,cage in gal.SwingLanterns:GetChildren()do
		cage:SetAttribute("PivotPosition",cage:GetPivot().Position+Vector3.new(0,Config.LanternLength,0))
		cage:SetAttribute("SwingAxis",galleryFrame:VectorToWorldSpace(Vector3.zAxis))
	end
	gal.Parent=m
	lane(m,"GalleryJoin",points({{-40,52,32},{-28,52,32}}),12,0)
	floor(m,"CP03Wait",o+Vector3.new(64,72,18),Vector3.new(34,2,20),false)
	Installer.AddGalleryToLifts(m,o)
	trigger(m.Checkpoints,"CP03",o+Vector3.new(64,72,18),3,o+Vector3.new(59,72,21))
	local liftO=o+Vector3.new(76,0,0)
	floor(m,"LowerBoarding",liftO+Vector3.new(0,72,17),Vector3.new(48,2,18),false)
	lifts(m,liftO,72,false,"Lower")
	floor(m,"MidGallery",liftO+Vector3.new(0,106,-17),Vector3.new(40,2,18),false)
	trigger(m.Checkpoints,"CP04",liftO+Vector3.new(-17,106,-17),4,liftO+Vector3.new(-17,106,-17))
	local upper=group(m,"UpperApproaches")
	local upperO=liftO+Vector3.new(0,106,-34)
	upper:SetAttribute("Study",true); group(upper,"Checkpoints","Folder")
	upperApproaches(upper,upperO,false)
	for _,p in upper:GetDescendants()do if p:IsA('BasePart') and p:GetAttribute('Role')=='PreviewTrigger'then p.CanTouch=false;p.CanQuery=false end end
	lifts(m,upperO,0,false,"Upper")
	lane(m,"CrownApproach",points({{76,140,-58},{46,145,-58},{20,150,-40}}),12,0)
	floor(m,"CrownTerrace",o+Vector3.new(10,150,-38),Vector3.new(30,2,24),false)
	trigger(m,"Finish",o+Vector3.new(10,150,-38))
	Kit.Part(m,"KeepSpaceReserve",Vector3.new(66,125,62),CFrame.new(o+Vector3.new(0,62.5,-15)),P.StoneDark,nil,false).Transparency=.7
	floor(m,"ArchCatch",o+Vector3.new(-85,8,-12),Vector3.new(48,1,22),false):SetAttribute("Role","SafeRefuge")
	lane(m,"ArchCatchReturn",points({{-104,8,-10},{-109,6,16},{-100,4,40},{-86,0,57}}),6,0)
	return m
end

function Installer.BuildRough(): Model
	return rough()
end

function Installer.Build(parent: Instance?): Model
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Build only in Studio Edit")
	assert(game.PlaceId==Config.PlaceId,"Wrong project destination")
	local destination=parent or workspace
	assert(not destination:FindFirstChild(Config.RootName),"Existing candidate preserved; use a scoped revision")
	local root=group(destination,Config.RootName)
	root:SetAttribute("CandidateId",Config.CandidateId);root:SetAttribute("CommissionPhase",1)
	root:SetAttribute("TaskId","MC-PHASE1-20261010");root:SetAttribute("PreviewOnly",true)
	for _,build in {rough,sample,function()return lanterns("LanternStudy",Config.LanternOrigin,true)end} do
		local section=build();section.Parent=root;task.wait()
	end
	return root
end

return Installer
