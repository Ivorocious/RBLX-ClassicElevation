--!strict

local Config = require(game:GetService("ReplicatedStorage").Config.LobbyConfig)
local C = Config.Colors
local Parts = {}
local ORIGIN = CFrame.new(Config.Center)

function Parts.Frame(x: number, y: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, yaw or 0, 0)
end

function Parts.Group(parent: Instance?, name: string): Model
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	return model
end

function Parts.Block(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3?, material: Enum.Material?, solid: boolean?): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, ORIGIN * frame
	part.Color, part.Material = color or C.Stone, material or Enum.Material.Sandstone
	part.Anchored, part.CanCollide = true, solid ~= false
	part.CanTouch, part.CanQuery = solid ~= false, true
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function Parts.Beam(parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, solid: boolean?): Part
	return Parts.Block(parent, name, Vector3.new(thickness, thickness, (a-b).Magnitude), CFrame.lookAt((a+b)/2,b), color, Enum.Material.SmoothPlastic, solid)
end

function Parts.Label(part: BasePart, name: string, text: string, position: UDim2?, size: UDim2?, color: Color3?): TextLabel
	local gui = part:FindFirstChildOfClass("SurfaceGui")
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 45
		gui.LightInfluence = 0.2
		gui.Parent = part
	end
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, text
	label.Position, label.Size = position or UDim2.fromScale(0.05,0.1), size or UDim2.fromScale(0.9,0.8)
	label.BackgroundTransparency, label.TextScaled = 1, true
	label.Font, label.TextColor3 = Enum.Font.GothamBold, color or Color3.fromRGB(255,245,214)
	label.TextStrokeTransparency = 1
	label.Parent = gui
	return label
end

function Parts.Vine(parent: Instance, x: number, y: number, z: number, length: number)
	local model = Parts.Group(parent, "TrailingVine")
	for i=0,math.floor(length/.65) do
		local dx=math.sin(i*1.7)*.45
		local leaf=Parts.Block(model,"Leaf",Vector3.new(.75,.95,.24),Parts.Frame(x+dx,y-i*.65,z)*CFrame.Angles(0,0,math.sin(i*2.1)*.65),if i%3==0 then C.LeafLight else C.Leaf,Enum.Material.Grass,false)
		leaf.CanQuery=false
	end
end

function Parts.Sign(parent: Instance, name: string, text: string, width: number, height: number, frame: CFrame): Part
	Parts.Block(parent, name.."Border", Vector3.new(width+0.45,height+0.4,0.6), frame, C.Gold, Enum.Material.Metal, false)
	local panel = Parts.Block(parent, name, Vector3.new(width,height,0.64), frame*CFrame.new(0,0,-0.07), C.DarkBlue, Enum.Material.SmoothPlastic, false)
	Parts.Label(panel,"Title",text)
	return panel
end

function Parts.Lamp(parent: Instance, x: number, y: number, z: number, tall: boolean?)
	local model = Parts.Group(parent,"Lantern")
	local baseHeight = if tall then 3.1 else 1.25
	Parts.Block(model,"StoneBase",Vector3.new(2.4,baseHeight,2.4),Parts.Frame(x,y+baseHeight/2,z),C.LightStone)
	Parts.Block(model,"BaseCap",Vector3.new(2.8,0.35,2.8),Parts.Frame(x,y+baseHeight,z),C.Gold)
	local cy=y+baseHeight+1.3
	local glow=Parts.Block(model,"WarmGlass",Vector3.new(1.12,1.8,1.12),Parts.Frame(x,cy,z),C.Lamp,Enum.Material.Neon,false)
	for _,dx in ipairs({-.72,.72}) do for _,dz in ipairs({-.72,.72}) do
		Parts.Block(model,"LanternFrame",Vector3.new(.16,2.15,.16),Parts.Frame(x+dx,cy,z+dz),C.Wood,Enum.Material.Metal,false)
	end end
	Parts.Block(model,"LanternFoot",Vector3.new(1.75,.22,1.75),Parts.Frame(x,cy-1,z),C.Wood,Enum.Material.Metal,false)
	Parts.Block(model,"LanternRoof",Vector3.new(2.05,.3,2.05),Parts.Frame(x,cy+1.12,z),C.Wood,Enum.Material.Metal,false)
	Parts.Block(model,"LanternCrown",Vector3.new(1.1,.4,1.1),Parts.Frame(x,cy+1.46,z),C.Gold,Enum.Material.Metal,false)
	local light=Instance.new("PointLight")
	light.Color,light.Range,light.Brightness,light.Shadows=C.Lamp,14,1.1,false
	light.Parent=glow
end

function Parts.Planter(parent: Instance, x: number, y: number, z: number, tree: boolean?)
	local model=Parts.Group(parent,if tree then "PlantedTree" else "GardenPlanter")
	local width=if tree then 5.4 else 4
	Parts.Block(model,"PlanterBase",Vector3.new(width,1.7,width),Parts.Frame(x,y+.85,z),C.Stone)
	Parts.Block(model,"PlanterRim",Vector3.new(width+.4,.35,width+.4),Parts.Frame(x,y+1.7,z),C.LightStone)
	Parts.Block(model,"Soil",Vector3.new(width-.55,.16,width-.55),Parts.Frame(x,y+1.91,z),C.Wood,Enum.Material.Ground,false)
	if tree then
		local library=require(script.Parent.Parent.AssetStorage).Folder("AssetLibraries"):FindFirstChild("AscentMeshLibraryV7")
		local template=if z<10 then workspace:FindFirstChild("StylizedOakApiTest") else nil
		template=template or (library and library:FindFirstChild("Cedar"))
		if template and template:IsA("Model") then
			local plant=template:Clone()
			local _,size=plant:GetBoundingBox()
			plant:ScaleTo(plant:GetScale()*10.4/size.Y)
			local frame,scaled=plant:GetBoundingBox()
			local bottom=frame.Position-Vector3.new(0,scaled.Y/2,0)
			plant:PivotTo(plant:GetPivot()+(Config.Center+Vector3.new(x,y+1.9,z)-bottom))
			for _,p in ipairs(plant:GetDescendants()) do if p:IsA("BasePart") then p.Anchored,p.CanCollide,p.CanTouch=true,false,false end end
			plant.Parent=model
			return
		end
		Parts.Block(model,"Trunk",Vector3.new(.85,4,.85),Parts.Frame(x,y+3.3,z),C.Wood,Enum.Material.Wood,false)
	end
	for i=1,5 do
		local angle=i*2.4
		local p=Parts.Block(model,"Leaves",Vector3.new(2.5,if tree then 4 else 2.2,2.5),Parts.Frame(x+math.sin(angle)*1.1,y+(if tree then 6 else 2.5)+i%2*.6,z+math.cos(angle)*1.1),if i%2==0 then C.LeafLight else C.Leaf,Enum.Material.Grass,false)
		p.Shape=Enum.PartType.Ball
	end
end

function Parts.Arch(parent: Instance, name: string, x: number, y: number, z: number, width: number, height: number)
	local model=Parts.Group(parent,name)
	local rise=height*.24
	local spring=height-rise
	for _,side in ipairs({-1,1}) do
		Parts.Block(model,"Pier",Vector3.new(2.3,spring,3.4),Parts.Frame(x+side*(width/2+1),y+spring/2,z),C.LightStone)
		for _,cy in ipairs({.55,spring-.6}) do Parts.Block(model,"PierCollar",Vector3.new(3,.65,4),Parts.Frame(x+side*(width/2+1),y+cy,z),C.Stone) end
	end
	local segments=13
	for i=1,segments do
		local theta=(i-.5)*math.pi/segments
		local dx,dy=-(width/2+1)*math.sin(theta),rise*math.cos(theta)
		local length=math.sqrt(dx*dx+dy*dy)*math.pi/segments+.15
		local frame=Parts.Frame(x+math.cos(theta)*(width/2+1),y+spring+math.sin(theta)*rise,z)*CFrame.Angles(0,0,math.atan2(dy,dx))
		Parts.Block(model,"ArchStone_"..i,Vector3.new(length,1.55,3.6),frame,if i%3==0 then C.Stone else C.LightStone)
	end
end

function Parts.Rail(parent: Instance, name: string, a: Vector3, b: Vector3)
	local group=Parts.Group(parent,name)
	local length=(b-a).Magnitude
	local n=math.max(1,math.ceil(length/10))
	Parts.Beam(group,"StoneSill",a+Vector3.new(0,.6,0),b+Vector3.new(0,.6,0),1.2,C.Stone)
	Parts.Beam(group,"Handrail",a+Vector3.new(0,3,0),b+Vector3.new(0,3,0),.32,C.Gold)
	for i=0,n do
		local p=a:Lerp(b,i/n)
		Parts.Block(group,"RailingPost",Vector3.new(1.1,3.1,1.1),CFrame.new(p+Vector3.new(0,1.55,0)),C.LightStone)
		Parts.Block(group,"PostCap",Vector3.new(1.45,.25,1.45),CFrame.new(p+Vector3.new(0,3.2,0)),C.Gold)
	end
	local fence=Parts.Block(group,"ClearSafetyRail",Vector3.new(.3,3.1,length),CFrame.lookAt((a+b)/2+Vector3.new(0,1.55,0),b+Vector3.new(0,1.55,0)),C.Blue,Enum.Material.SmoothPlastic)
	fence.Transparency=1
end

function Parts.Stairs(parent: Instance, name: string, x: number, z: number, bottom: number, top: number, run: number, width: number, direction: number?)
	local model=Parts.Group(parent,name)
	local count=math.ceil((top-bottom)/.7)
	local rise=(top-bottom)/count
	local tread=run/count
	local d=direction or 1
	local undersideA=Vector3.new(x,bottom-.85,z)
	local undersideB=Vector3.new(x,top-.85,z+d*run)
	Parts.Block(model,"StairUnderside",Vector3.new(width,.45,(undersideB-undersideA).Magnitude),CFrame.lookAt((undersideA+undersideB)/2,undersideB),C.ShadowStone)
	for i=1,count do
		local cy=bottom+i*rise
		Parts.Block(model,string.format("Step_%02d",i),Vector3.new(width,.9,tread+.09),Parts.Frame(x,cy-.45,z+d*(i-.5)*tread),if i%3==0 then C.Stone else C.LightStone)
	end
	for _,side in ipairs({-1,1}) do
		local a=Vector3.new(x+side*(width/2+.25),bottom,z)
		local b=Vector3.new(a.X,top,z+d*run)
		Parts.Beam(model,"StairStringer",a-Vector3.new(0,.65,0),b-Vector3.new(0,.65,0),1.5,C.ShadowStone)
		Parts.Beam(model,"StairHandrail",a+Vector3.new(0,3,0),b+Vector3.new(0,3,0),.45,C.Gold)
		for i=0,4 do
			local p=a:Lerp(b,i/4)
			Parts.Block(model,"Baluster",Vector3.new(.5,3,.5),CFrame.new(p+Vector3.new(0,1.5,0)),C.LightStone)
		end
	end
end

function Parts.Compass(parent: Instance, frame: CFrame, radius: number)
	local model=Parts.Group(parent,"CompassInlay")
	for i=1,32 do
		local angle=i*math.pi/16
		local cf=frame*CFrame.new(math.sin(angle)*radius,.06,math.cos(angle)*radius)*CFrame.Angles(0,angle,0)
		Parts.Block(model,"Ring",Vector3.new(radius*.205,.1,.16),cf,C.Gold,Enum.Material.Metal,false)
	end
	for i=0,3 do
		local cf=frame*CFrame.Angles(0,i*math.pi/2,0)
		Parts.Block(model,"CompassArm",Vector3.new(.34,.1,radius*1.5),cf,C.Gold,Enum.Material.Metal,false)
		Parts.Block(model,"Diamond",Vector3.new(radius*.56,.12,radius*.56),cf*CFrame.Angles(0,math.pi/4,0),C.Blue,Enum.Material.SmoothPlastic,false)
	end
end

function Parts.Banner(parent: Instance, x: number, y: number, z: number, height: number)
	local group=Parts.Group(parent,"BlueBanner")
	require(script.Parent.LobbyProps).Place(group,"HangingBanner",ORIGIN*Parts.Frame(x,y-height/2,z,math.pi),height)
	Parts.Block(group,"HangingRod",Vector3.new(height*.5+.6,.3,.4),Parts.Frame(x,y+height/2+.3,z),C.Gold,Enum.Material.Metal,false)
	Parts.Block(group,"CompassVertical",Vector3.new(.2,3.4,.08),Parts.Frame(x,y,z-.58),C.LightStone,Enum.Material.Metal,false)
	Parts.Block(group,"CompassHorizontal",Vector3.new(2.6,.2,.08),Parts.Frame(x,y,z-.58),C.LightStone,Enum.Material.Metal,false)
	Parts.Block(group,"CompassDiamond",Vector3.new(1.4,1.4,.09),Parts.Frame(x,y,z-.61)*CFrame.Angles(0,0,math.pi/4),C.Gold,Enum.Material.Metal,false)
end

return Parts
