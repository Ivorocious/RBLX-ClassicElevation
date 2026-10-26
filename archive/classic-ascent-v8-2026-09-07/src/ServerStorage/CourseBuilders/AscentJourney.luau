--!strict

local Props = require(script.Parent.AscentProps)
local Journey = {}
local ROCK = Color3.fromRGB(80, 101, 105)
local SNOW = Color3.fromRGB(221, 235, 237)
local DARK = Color3.fromRGB(48, 64, 71)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function mass(parent: Instance, kind: string, size: Vector3, cf: CFrame, color: Color3?): Model
    return Props.PlaceSized(parent,kind,size,cf,color)
end

local function prop(parent: Instance, kind: string, node: BasePart, x: number, y: number, z: number, height: number, yaw: number?): Model
	return Props.Place(parent, kind, node.CFrame * CFrame.new(x, y, z) * CFrame.Angles(0, yaw or 0, 0), height)
end

local function talus(parent: Instance, node: BasePart, side: number, length: number, snowy: boolean?)
    local color = if snowy then Color3.fromRGB(142,164,173) else Color3.fromRGB(84,105,99)
    mass(parent,"FaultWallB",Vector3.new(42,51,length),node.CFrame*CFrame.new(side*59,-30,0)*CFrame.Angles(0,side*.19,0),color)
    mass(parent,"TalusFan",Vector3.new(29,11,length*.7),node.CFrame*CFrame.new(side*48,-5,0),color)
end

local function switchback(parent: Instance, node: BasePart, step: number)
    local beats = {[4]={73,116,109},[12]={84,138,125},[20]={76,113,105}}
    local beat = beats[step]
    if beat then
        mass(parent,if step==12 then "FaultWallB" else "FaultWallA",Vector3.new(76,beat[2],beat[3]),node.CFrame*CFrame.new(beat[1],-6,0)*CFrame.Angles(0,.18*math.sin(step),0),ROCK)
    end
    if step==2 or step==9 or step==15 or step==23 then talus(parent,node,-1,57) end
    if step==2 or step==6 then
        prop(parent,if step==2 then "CedarLite" else "PineWind",node,-67,-5,8,52,step*.43)
        mass(parent,"FaultWallA",Vector3.new(45,66,52),node.CFrame*CFrame.new(-68,-36,6),Color3.fromRGB(72,93,75))
    end
end

local function ridgeBridges(parent: Instance, node: BasePart, step: number)
    if step==4 or step==8 or step==12 or step==16 then
        local x=if step==8 then 83 else 71
        mass(parent,if step==12 then "FaultWallB" else "FaultWallA",Vector3.new(77,86+step*2,72),node.CFrame*CFrame.new(x,4,-6)*CFrame.Angles(0,step*.13,0),ROCK)
    end
    if step==2 or step==11 then
        talus(parent,node,-1,67)
        prop(parent,"PineWind",node,-62,-3,-8,42+step,-.7)
    end
end

local function pillarYard(parent: Instance, node: BasePart, step: number)
	for _,side in ipairs({-1,1}) do
		local x=side*(28+2*math.sin(step*.7))
		local bank=mass(parent,"EmbeddedShelf",Vector3.new(21*1.65,27,(node.Size.Z+8)*1.65),node.CFrame*CFrame.new(x,-17.3,0),Color3.fromRGB(51,60,56))
		bank.Name="LavaRavineBank"
		for _,mesh in ipairs(bank:GetDescendants()) do
			if mesh:IsA("MeshPart") then
				mesh.Material=Enum.Material.Basalt
				mesh.CanCollide,mesh.CanQuery,mesh.CanTouch=true,true,false
				mesh:SetAttribute("RavineBank",true)
				Props.UseCollision(mesh,Enum.CollisionFidelity.Hull)
			end
		end
	end
    local beats = {[1]={-57,39,.6},[5]={65,51,-.3},[11]={-70,68,.4},[16]={57,36,-.8}}
    local beat=beats[step]
    if beat then
        mass(parent,"BasaltFan",Vector3.new(37,beat[2],39),node.CFrame*CFrame.new(beat[1],beat[2]*.33-5,0)*CFrame.Angles(0,beat[3],0))
        mass(parent,"FaultWallB",Vector3.new(69,61,71),node.CFrame*CFrame.new(beat[1]*1.08,-31,-7),DARK)
    end
    if step==8 then
        mass(parent,"BasaltFan",Vector3.new(65,112,67),node.CFrame*CFrame.new(92,16,-31)*CFrame.Angles(0,.51,0))
    end
    if step==3 or step==7 or step==12 or step==17 then
        local side=if step==3 or step==12 then -1 else 1
        mass(parent,"TalusFan",Vector3.new(33,7,34),node.CFrame*CFrame.new(side*38,-6,0),DARK)
        mass(parent,"FaultWallA",Vector3.new(44,28,49),node.CFrame*CFrame.new(side*48,-20,3),Color3.fromRGB(46,55,56))
    end
end

local function causeway(parent: Instance, node: BasePart, step: number)
    if step==2 or step==7 or step==11 then
        mass(parent,"FaultWallA",Vector3.new(85,112,103),node.CFrame*CFrame.new(82,8,-8)*CFrame.Angles(0,.13*step,0),Color3.fromRGB(104,112,100))
        mass(parent,"TalusFan",Vector3.new(31,13,43),node.CFrame*CFrame.new(48,-4,-12),Color3.fromRGB(115,118,103))
    end
    if step==3 or step==9 then
        mass(parent,"RuinAbutment",Vector3.new(28,49,38),node.CFrame*CFrame.new(-51,-19,0)*CFrame.Angles(0,.4,0))
        mass(parent,"FaultWallB",Vector3.new(47,74,55),node.CFrame*CFrame.new(-62,-48,-7),ROCK)
    end
    if step==4 or step==10 then
		mass(parent,"FaultWallB",Vector3.new(67,110,64),node.CFrame*CFrame.new(75,-10,-9)*CFrame.Angles(0,.1,0),Color3.fromRGB(103,109,98))
    end
    if step==6 then
        mass(parent,"RuinAbutment",Vector3.new(61,42,30),node.CFrame*CFrame.new(0,-26,0))
        prop(parent,"RuinPillarB",node,-47,-4,-13,20,-.5)
    end
    if step==3 or step==8 then
        mass(parent,"RuinAbutment",Vector3.new(69,32,31),node.CFrame*CFrame.new(-8,-31,3)*CFrame.Angles(0,if step==3 then -.35 else .25,0),Color3.fromRGB(119,116,97))
    end
end

local function cliffside(parent: Instance, node: BasePart, step: number)
    if step==1 or step==6 or step==12 or step==16 then
        local height=if step==6 then 154 elseif step==12 then 101 else 118
        mass(parent,"FaultWallA",Vector3.new(77,height,94),node.CFrame*CFrame.new(77,height*.19-10,0)*CFrame.Angles(0,.3*math.sin(step),0),ROCK)
        mass(parent,"FaultWallB",Vector3.new(112,height+45,103),node.CFrame*CFrame.new(139,31,-20)*CFrame.Angles(0,-.27,0),Color3.fromRGB(77,97,104))
    end
    if step==4 or step==10 or step==15 then talus(parent,node,-1,49,step>10) end
    if step==3 or step==7 or step==9 or step==11 or step==15 then
        local chute=node.CFrame*CFrame.new(44,14,0)*CFrame.Angles(0,0,-.5)
        mass(parent,"TalusFan",Vector3.new(31,9,19),chute,Color3.fromRGB(110,121,115))
    end
    if step==12 or step==16 then
        mass(parent,"SnowRidge",Vector3.new(61,25,72),node.CFrame*CFrame.new(76,43,-9)*CFrame.Angles(0,.38,0))
    end
end

local function summitSteps(parent: Instance, node: BasePart, step: number)
    if step==2 or step==13 then
        local positions=if step==2 then {{-67,-9,61},{-76,-22,38},{-82,3,29},{-91,-13,43}} else {{-66,4,36},{-83,-11,23}}
        for _,p in ipairs(positions) do
            local base=node.CFrame*CFrame.new(p[1],-3,p[2])
            Props.Place(parent,"PineSnow",base*CFrame.Angles(0,p[1]*.17,if p[3]<40 then -.10 else .04),p[3])
            mass(parent,"RockSpurA",Vector3.new(21,39,22),base*CFrame.new(0,-19.5,0),Color3.fromRGB(117,139,143))
            part(parent,"PlantedSnowPocket",Vector3.new(7,.4,7),base*CFrame.new(0,-.2,0),SNOW,Enum.Material.Snow)
        end
        talus(parent,node,-1,74,true)
    elseif step==9 or step==16 then
        mass(parent,"SnowRidge",Vector3.new(68,27,76),node.CFrame*CFrame.new(-77,-12,0)*CFrame.Angles(0,.45,0))
    end
    if step==3 or step==11 or step==17 then
        mass(parent,"FaultWallB",Vector3.new(81,103,83),node.CFrame*CFrame.new(86,2,-11),Color3.fromRGB(116,143,153))
        mass(parent,"SnowRidge",Vector3.new(67,27,72),node.CFrame*CFrame.new(86,47,-9)*CFrame.Angles(0,.2,0))
    end
    if step==9 then
        for _,side in ipairs({-1,1}) do
            local cf=node.CFrame*CFrame.new(side*29,4.5,-4)
            local cover=part(parent,"SnowShelfCover",Vector3.new(7,6,4),cf,ROCK,Enum.Material.Rock)
            cover.CanCollide,cover.CanQuery=true,true
            cover:SetAttribute("ProjectileCover",true)
            mass(parent,"SnowCoverOutcrop",Vector3.new(9,7,6),cf)
            cover.Transparency=1
        end
    end
end

local function skyline(parent: Instance, node: BasePart, step: number)
	if step == 2 or step == 8 or step == 14 then
		mass(parent,if step==8 then "FaultWallB" else "FaultWallA",Vector3.new(67,82,75),node.CFrame*CFrame.new(-76,-12,-8)*CFrame.Angles(0,.4+step*.1,0),Color3.fromRGB(138,178,192))
		mass(parent,"SnowRidge",Vector3.new(53,49,70),node.CFrame*CFrame.new(72,-2,0)*CFrame.Angles(0,math.pi/2,0))
	elseif step%4 == 0 then
		talus(parent,node,-1,31,true)
	end
	if step == 5 or step == 13 then
		mass(parent,"SnowRidge",Vector3.new(105,78,70),node.CFrame*CFrame.new(-142,-64,-31)*CFrame.Angles(0,-.4,0))
	end
end

local function summitRun(parent: Instance, node: BasePart, step: number)
	if step == 2 or step == 6 then
		mass(parent,"FaultWallB",Vector3.new(98,86,119),node.CFrame*CFrame.new(-8,-48,0)*CFrame.Angles(0,if step==2 then -.2 else .25,0),Color3.fromRGB(131,158,170))
		mass(parent,"SnowRidge",Vector3.new(54,52,64),node.CFrame*CFrame.new(66,7,4)*CFrame.Angles(0,math.pi/2,0))
		mass(parent,"CliffButtress",Vector3.new(27,38,41),node.CFrame*CFrame.new(-57,-14,0),ROCK)
	end
	if step == 5 then
		prop(parent,"GlacierSerac",node,55,-18,-18,37,.65)
	elseif step == 10 then
		mass(parent,"SnowRidge",Vector3.new(101,22,61),node.CFrame*CFrame.new(0,-11,-7))
		for _, side in ipairs({-1,1}) do
			mass(parent,"CliffButtress",Vector3.new(18,if side == -1 then 19 else 28,24),node.CFrame*CFrame.new(side*45,1,-6)*CFrame.Angles(0,side*.5,0))
		end
		local mast = part(parent,"SummitFlagMast",Vector3.new(.7,58,.7),node.CFrame*CFrame.new(-29,30,-8),DARK,Enum.Material.Metal)
		part(parent,"SummitPennant",Vector3.new(14,8,.12),mast.CFrame*CFrame.new(7,23,0),Color3.fromRGB(239,181,65),Enum.Material.Fabric)
	end
end

function Journey.Build(model: Model, nodes: {BasePart})
	local root = Instance.new("Folder")
	root.Name,root.Parent = "Journey",model.Decoration
	local builders = {[3]=switchback,[4]=ridgeBridges,[5]=pillarYard,[6]=causeway,[7]=cliffside,[8]=summitSteps,[9]=skyline,[10]=summitRun}
	local groups: {[number]: Folder} = {}
	for section=1,10 do
		local group = Instance.new("Folder")
		group.Name,group.Parent = string.format("Section%02d",section),root
		groups[section] = group
	end
	for _,node in ipairs(nodes) do
		local section = node:GetAttribute("SectionIndex") :: number
		local step = node:GetAttribute("SectionStep") :: number?
		if step and builders[section] then builders[section](groups[section],node,step) end
	end
	for _,pad in ipairs(model:GetDescendants()) do
		if not pad:IsA("BasePart") then continue end
		local section = pad:GetAttribute("SectionIndex")
		if pad.Name == "LavaBasin" then
			pad.Transparency,pad.CanTouch=1,false
			pad:SetAttribute("HazardType",nil)
		end
		if pad:GetAttribute("RoutePad") then
			if section == 1 and pad:GetAttribute("Lane") == 0 then
				part(groups[1],"MainTrail",Vector3.new(8,.05,pad.Size.Z*.92),pad.CFrame*CFrame.new(0,pad.Size.Y/2+.035,0),Color3.fromRGB(151,129,92),Enum.Material.Ground)
			elseif section == 9 and pad.Parent ~= model.Checkpoints then
				local main = pad:GetAttribute("Lane") == 0
				pad.Color = if main then Color3.fromRGB(127,202,216) else Color3.fromRGB(88,153,174)
			end
		end
	end
	model:SetAttribute("JourneyRevision",1)
	model:SetAttribute("RecoveryRevision",1)
end

return Journey
