--!strict

local Config = require(game:GetService("ReplicatedStorage").Config.LobbyConfig)
local P = require(script.Parent.LobbyParts)
local Props = require(script.Parent.LobbyProps)
local C = Config.Colors
local F = P.Frame
local Builder = {}

local function slab(parent: Instance, name: string, x: number, y: number, z: number, width: number, depth: number)
	local group=P.Group(parent,name)
	P.Block(group,"Foundation",Vector3.new(width-1.5,2.4,depth-1.5),F(x,y-1.7,z),C.ShadowStone)
	P.Block(group,"Cornice",Vector3.new(width+1.2,.7,depth+1.2),F(x,y-.65,z),C.LightStone)
	P.Block(group,"WalkableFloor",Vector3.new(width,1,depth),F(x,y-.5,z),C.Paving,Enum.Material.Limestone)
	for _,side in ipairs({-1,1}) do
		P.Block(group,"BlueUnderside",Vector3.new(width*.32,.18,.25),F(x+side*width*.26,y-2.25,z-depth/2+.5),C.Glow,Enum.Material.Neon,false)
	end
	return group
end

local function tiles(parent: Instance, x: number, y: number, z: number, nx: number, nz: number, spacing: number)
	local group=P.Group(parent,"StonePaving")
	for ix=1,nx do for iz=1,nz do
		local color=if (ix+iz)%3==0 then C.LightStone else C.Stone
		P.Block(group,"Paver",Vector3.new(spacing-.12,.08,spacing-.12),F(x+(ix-(nx+1)/2)*spacing,y+.045,z+(iz-(nz+1)/2)*spacing),color,Enum.Material.Limestone,false)
	end end
end

local function plinth(parent: Instance, x: number, y: number, z: number)
	local group=P.Group(parent,"FloatingCorbel")
	P.Block(group,"Cap",Vector3.new(7,.6,6),F(x,y-.3,z),C.LightStone)
	P.Block(group,"Support",Vector3.new(5.4,3,4.5),F(x,y-2,z),C.ShadowStone)
	P.Block(group,"Collar",Vector3.new(6,.5,5),F(x,y-3.3,z),C.Blue)
	P.Block(group,"GlowBand",Vector3.new(6.05,.22,5.05),F(x,y-3.2,z),C.Glow,Enum.Material.Neon,false)
	Props.Place(group,"FloatingCrystal",CFrame.new(Config.Center)*F(x,y-8,z),4.6)
end

local function leaderboard(parent: Instance, side: number)
	local x=side*32
	local group=P.Group(parent,if side<0 then "WinsBoardSpace" else "BestTimesBoardSpace")
	P.Block(group,"BackWall",Vector3.new(27,14,3),F(x,7,-7),C.Stone)
	P.Arch(group,"BoardSurround",x,0,-9.2,23,13.5)
	local panel=P.Sign(group,"Leaderboard","",23,10.5,F(x,6.7,-11.25))
	P.Label(panel,"Heading",if side<0 then "MOST WINS" else "BEST TIMES",UDim2.fromScale(.05,.04),UDim2.fromScale(.9,.14),C.Gold)
	for row=1,5 do
		local label=P.Label(panel,"Row_"..row,string.format("%02d       —",row),UDim2.fromScale(.09,.17+row*.105),UDim2.fromScale(.82,.075))
		label.TextXAlignment=Enum.TextXAlignment.Left
	end
	P.Label(panel,"Placeholder","LEADERBOARD  ·  COMING LATER",UDim2.fromScale(.05,.87),UDim2.fromScale(.9,.065),Color3.fromRGB(174,192,197))
	for _,dx in ipairs({-13,13}) do P.Lamp(group,x+dx,0,-15,true) end
	P.Block(group,"BenchSeat",Vector3.new(11,.6,2.7),F(x,1.6,-25),C.Wood,Enum.Material.Wood)
	for _,dx in ipairs({-4,4}) do P.Block(group,"BenchFoot",Vector3.new(.65,1.3,2),F(x+dx,.65,-25),C.DarkBlue,Enum.Material.Metal) end
end

local function practice(parent: Instance)
	local floor=18
	local room=P.Group(parent,"PracticeRoom")
	P.Block(room,"BackWall",Vector3.new(57,20,2.5),F(0,floor+10,37),C.Stone)
	for _,side in ipairs({-1,1}) do
		P.Block(room,"SideWall",Vector3.new(2.5,20,40),F(side*28,floor+10,18),C.Stone)
		P.Block(room,"WallSkirting",Vector3.new(.45,1.2,40),F(side*26.55,floor+.6,18),C.LightStone)
		P.Block(room,"WindowInset",Vector3.new(.2,7,10),F(side*26.65,floor+10,20),C.Blue,Enum.Material.Glass,false).Transparency=.3
		for _,z in ipairs({10,29}) do P.Lamp(room,side*23,floor,z) end
		P.Block(room,"EntranceWing",Vector3.new(9,19,2.5),F(side*23.5,floor+9.5,-1),C.Stone)
	end
	P.Arch(room,"PracticeEntrance",0,floor,-2.3,36,16.5)
	P.Block(room,"EntranceInset",Vector3.new(40,3.8,1),F(0,floor+19,-2.8),C.DarkBlue)
	P.Sign(room,"PracticeTitle","PRACTICE",32,3.5,F(0,floor+19,-3.6))
	for _,side in ipairs({-1,1}) do
		P.Block(room,"BlueEntranceReveal",Vector3.new(1.3,13,.6),F(side*18.1,floor+6.5,-3.9),C.DarkBlue,Enum.Material.SmoothPlastic,false)
		P.Block(room,"GoldEntranceEdge",Vector3.new(.18,12,.7),F(side*17.4,floor+6,-3.94),C.Gold,Enum.Material.Metal,false)
	end
	P.Sign(room,"PracticeHint","FOLLOW THE NUMBERS",22,2,F(0,floor+10,35.5))
	for _,z in ipairs({9,27}) do
		P.Block(room,"CeilingBeam",Vector3.new(53,.5,1),F(0,37.1,z),C.Wood,Enum.Material.Wood,false)
		local glow=P.Block(room,"CeilingLantern",Vector3.new(1.8,.45,1.8),F(0,36.6,z),C.Lamp,Enum.Material.Neon,false)
		local light=Instance.new("PointLight")
		light.Color,light.Brightness,light.Range,light.Shadows=C.Lamp,1.25,29,false
		light.Parent=glow
	end
	local jumps=P.Group(room,"JumpingCourse")
	local points={
		{-18,5,1.4,6,6},{-18,14,2.2,6,6},{-16,23,3.2,6,6},
		{-8,29,4,6,6},{2,29,3,7,6},{12,27,4.2,6,6},
		{18,19,3.2,6,6},{18,10,2.4,6,6},{12,3,1.6,7,6},
	}
	for index,item in ipairs(points) do
		local x,z,height,width,depth=table.unpack(item)
		local pad=P.Block(jumps,string.format("Jump_%02d",index),Vector3.new(width,height,depth),F(x,floor+height/2,z),C.Stone,Enum.Material.Limestone)
		pad:SetAttribute("PracticeStep",index)
		local cap=P.Block(jumps,"BlueLanding_"..index,Vector3.new(width-.4,.12,depth-.4),F(x,floor+height+.055,z),if index==1 or index==#points then C.Gold else C.Blue,Enum.Material.SmoothPlastic)
		P.Label(cap,"StepNumber",tostring(index),UDim2.fromScale(.15,.15),UDim2.fromScale(.7,.7),C.LightStone)
		cap:FindFirstChildOfClass("SurfaceGui").Face=Enum.NormalId.Top
	end
	tiles(room,0,floor,16,3,6,3)
	P.Sign(room,"StartPractice","START →",7,1.5,F(-17,floor+4,-.15))
	P.Sign(room,"PracticeReturn","TRY AGAIN",8,1.5,F(13,floor+4,-.9))
end

local function shops(parent: Instance)
	local room=P.Group(parent,"ShopArcade")
	P.Block(room,"RearWall",Vector3.new(56,16,2.5),F(0,48,36),C.Stone)
	for _,side in ipairs({-1,1}) do
		P.Block(room,"SideFrontPier",Vector3.new(2.5,16,9),F(side*28,48,12.5),C.Stone)
		P.Block(room,"SideRearPier",Vector3.new(2.5,16,4),F(side*28,48,34.5),C.Stone)
		P.Block(room,"SideDoorLintel",Vector3.new(2.5,2.5,16),F(side*28,54.75,25),C.LightStone)
	end
	for _,x in ipairs({-18,0,18}) do
		local bay=P.Group(room,if x==-18 then "CosmeticsSpace" elseif x==0 then "ShopEntrance" else "TrailsSpace")
		P.Arch(bay,"ShopArch",x,40,8,14,13.5)
		P.Block(bay,"BlueBackPanel",Vector3.new(12,7.5,.25),F(x,46,34.5),C.Blue,Enum.Material.SmoothPlastic,false)
		P.Sign(bay,"FutureShopLabel",if x==-18 then "COSMETICS" elseif x==0 then "GEAR UP" else "TRAILS",10,1.4,F(x,50.5,34.05))
		P.Block(bay,"DisplayCounter",Vector3.new(10,3,3),F(x,41.5,29),C.Wood,Enum.Material.Wood)
		P.Block(bay,"CounterTop",Vector3.new(10.5,.35,3.5),F(x,43.2,29),C.LightStone)
		P.Lamp(bay,x,40,24)
	end
	P.Sign(room,"ShopsTitle","SHOPS",38,3.7,F(0,55.5,5.6))
	tiles(room,0,40,18,14,5,3.5)
end

local function podium(parent: Instance)
	local model=P.Group(parent,"Podium")
	P.Block(model,"ChampionsBackdrop",Vector3.new(37,8,.7),F(0,62,35),C.DarkBlue,Enum.Material.SmoothPlastic)
	P.Block(model,"BackdropCrown",Vector3.new(38,.45,1),F(0,66.1,35),C.Gold,Enum.Material.Metal)
	P.Block(model,"CeremonyRunner",Vector3.new(12,.08,10),F(0,58.05,10),C.Blue,Enum.Material.Fabric,false)
	for _,side in ipairs({-1,1}) do P.Block(model,"RunnerEdge",Vector3.new(.18,.1,10),F(side*6,58.08,10),C.Gold,Enum.Material.Metal,false) end
	local slots=Instance.new("Folder") slots.Name,slots.Parent="Slots",model
	for _,data in ipairs({{"Second",-11,3.3,Color3.fromRGB(167,183,198),"2"},{"First",0,5.2,C.Gold,"1"},{"Third",11,2.5,Color3.fromRGB(183,116,66),"3"}}) do
		local name,x,height,color,number=table.unpack(data)
		local slot=P.Group(slots,name)
		P.Block(slot,"PodiumBlock",Vector3.new(10,height,9),F(x,58+height/2,21),color,Enum.Material.Metal)
		P.Block(slot,"PlinthCap",Vector3.new(10.6,.45,9.6),F(x,58+height,21),C.LightStone)
		P.Sign(slot,"PlaceNumber",number,3.2,math.min(3.2,height-.25),F(x,58+height*.52,16.15))
		local nameplate=P.Sign(slot,"Nameplate","",10.2,2,F(x,59,11))
		P.Label(nameplate,"WinnerName","No result yet",UDim2.fromScale(.04,.04),UDim2.fromScale(.92,.45))
		P.Label(nameplate,"TimeLabel","—",UDim2.fromScale(.04,.52),UDim2.fromScale(.92,.3),C.Gold)
		local marker=P.Block(slot,"DisplayMarker",Vector3.new(1,.1,1),F(x,58+height+.26,21),C.Blue,Enum.Material.SmoothPlastic,false)
		marker.Transparency,marker.CanQuery=1,false
		Props.Place(slot,"TrophyCup",CFrame.new(Config.Center)*F(x,58+height+.25,24.4),3.3,color)
	end
	P.Sign(model,"PodiumTitle","LAST RACE CHAMPIONS",35,2.4,F(0,67.6,35))
	for _,side in ipairs({-1,1}) do
		P.Planter(model,side*26,58,27,true)
		P.Lamp(model,side*23,58,8,true)
	end
end

function Builder.Build(): Model
	Props.Prepare()
	local model=P.Group(nil,"Lobby")
	model:SetAttribute("LobbyRevision",1)
	model:SetAttribute("Candidate",4)
	model:SetAttribute("ManualEditing",true)
	local structure=P.Group(model,"Architecture")
	local overlook=P.Group(structure,"01_Overlook")
	local arrival=P.Group(structure,"02_Arrival")
	local upper=P.Group(structure,"03_Shops")
	local roof=P.Group(structure,"04_Rooftop")
	local stairs=P.Group(model,"Stairs")
	local gardens=P.Group(model,"Gardens")
	local lights=P.Group(model,"Lanterns")
	local banners=P.Group(model,"Banners")
	slab(overlook,"OverlookDeck",0,0,-8,108,88)
	slab(overlook,"FrontStairLanding",0,0,-57,24,20)
	slab(arrival,"ArrivalCenter",0,18,8.5,28,65)
	slab(arrival,"ArrivalLeftWing",-35,18,2,42,78)
	slab(arrival,"ArrivalRightWing",35,18,2,42,78)
	slab(arrival,"SpawnTerrace",0,18,-22,28,20)
	slab(upper,"ShopTerrace",0,40,19,76,43)
	slab(roof,"PodiumDeck",0,58,22,56,35)
	slab(roof,"RoofRearLanding",0,58,38,76,6)
	for _,side in ipairs({-1,1}) do
		slab(upper,"SideStairLanding",side*42,40,31,12,12)
		P.Block(overlook,"StructuralPier",Vector3.new(4,16,5),F(side*49,8,28),C.Stone)
		P.Block(overlook,"FrontPier",Vector3.new(4,16,5),F(side*49,8,-24),C.Stone)
		P.Stairs(stairs,if side<0 then "LeftShopStair" else "RightShopStair",side*42,-25,18,40,50,10)
		P.Stairs(stairs,if side<0 then "LeftRoofStair" else "RightRoofStair",side*33,6,40,58,29,7.5)
		P.Rail(arrival,"SideBalconyRail",Vector3.new(side*55,18,-35),Vector3.new(side*55,18,39))
		P.Rail(overlook,"OverlookSideRail",Vector3.new(side*53,0,-50),Vector3.new(side*53,0,35))
		P.Rail(overlook,"FrontViewingRail",Vector3.new(side*14,0,-50),Vector3.new(side*53,0,-50))
		P.Rail(arrival,"ArrivalFrontRail",Vector3.new(side*18,18,-36),Vector3.new(side*55,18,-36))
		P.Rail(upper,"ShopFrontRail",Vector3.new(side*6,40,-1),Vector3.new(side*31,40,-1))
		P.Rail(roof,"PodiumFrontRail",Vector3.new(side*2,58,5),Vector3.new(side*28,58,5))
		P.Rail(roof,"PodiumSideRail",Vector3.new(side*37.5,58,41),Vector3.new(side*37.5,58,35))
		leaderboard(overlook,side)
		for _,point in ipairs({{49,0,-39},{48,18,-25},{49,18,30},{24,40,1}}) do P.Planter(gardens,side*point[1],point[2],point[3],true) end
		for _,point in ipairs({{17,18,-23},{23,18,-6},{22,0,-43},{48,0,26},{24,58,1}}) do P.Planter(gardens,side*point[1],point[2],point[3]) end
		for _,point in ipairs({{12,0,-61},{13,18,-33},{50,18,-5},{42,40,27},{12,40,3}}) do P.Lamp(lights,side*point[1],point[2],point[3],true) end
		P.Banner(banners,side*25,29,-4.8,13)
		P.Banner(banners,side*26,49,5.4,11)
		P.Banner(banners,side*14,8,-10,10)
		for _,point in ipairs({{51,18,-37,8},{21,37,-4,6},{30,40,4,7},{25,58,4,7},{48,0,-51,7},{46,18,38,9}}) do
			P.Vine(gardens,side*point[1],point[2],point[3],point[4])
		end
		P.Sign(overlook,"CourseBelow","RACE BELOW",15,1.6,F(side*33,2.1,-49.8)*CFrame.Angles(0,math.pi,0))
		for _,point in ipairs({{48,0,-43},{48,18,-28},{30,40,8}}) do plinth(structure,side*point[1],point[2]-1,point[3]) end
	end
	P.Stairs(stairs,"CentralOverlookStair",0,-62,0,18,30,16)
	P.Rail(overlook,"RearRail",Vector3.new(-53,0,35),Vector3.new(53,0,35))
	P.Rail(arrival,"RearRail",Vector3.new(-55,18,40),Vector3.new(55,18,40))
	P.Rail(roof,"RearRoofRail",Vector3.new(-37.5,58,41),Vector3.new(37.5,58,41))
	practice(arrival)
	shops(upper)
	podium(model)
	tiles(arrival,0,18,-20,8,6,3.5)
	P.Compass(arrival,F(0,18.08,-23),7)
	P.Sign(arrival,"ArrivalTitle","WELCOME, CLIMBER",23,2.5,F(0,15.2,-39.5))
	P.Sign(overlook,"OverlookTitle","RACE OVERLOOK",22,2,F(0,8,-8.5))
	local spawn=P.Block(model,"LobbySpawnPadMarker",Vector3.new(28,.1,24),F(0,18.16,-22),C.Blue,Enum.Material.SmoothPlastic,false)
	spawn.Transparency,spawn.CanQuery=1,false
	local lobbyPlatform=P.Block(model,"LobbyPlatform",Vector3.new(28,.2,24),F(0,17.8,-22),C.Stone,nil,false)
	lobbyPlatform.Transparency=1
	local location=Instance.new("SpawnLocation")
	location.Name,location.Size,location.CFrame="SpawnLocation",Vector3.new(14,.15,12),CFrame.new(Config.Center)*F(0,18.08,-22)
	location.Anchored,location.CanCollide,location.Transparency,location.Neutral,location.Duration=true,false,1,true,0
	location.Parent=model
	local spectator=P.Block(model,"SpectatorPadMarker",Vector3.new(18,.1,8),F(28,.1,-42),C.Blue,Enum.Material.SmoothPlastic,false)
	spectator.Transparency,spectator.CanQuery=1,false
	local safety=P.Block(model,"LobbyFallReturn",Vector3.new(170,2,155),F(0,-17,-6),C.Blue,Enum.Material.SmoothPlastic,false)
	safety.Transparency,safety.CanTouch,safety.CanQuery=1,true,false
	model.PrimaryPart=spawn
	return model
end

function Builder.Ensure(): Model
	local existing=workspace:FindFirstChild("Lobby")
	if existing then return existing :: Model end
	local model=Builder.Build()
	model.Parent=workspace
	return model
end

return Builder
