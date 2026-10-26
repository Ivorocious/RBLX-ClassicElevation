--!strict

local Props = require(script.Parent.AscentProps)
local RoutedManifest = require(script.Parent.AscentRoutedManifest)
local Surfaces = {}
local KINDS = {[3]="GraniteLedge",[5]="BasaltStep",[6]="CausewaySlab",[7]="GraniteLedge",[9]="IceSpur"}

local function stone(parent: Instance, pad: BasePart, height: number, center: CFrame, solid: boolean): MeshPart
	local step,lane,section = pad:GetAttribute("SectionStep"),pad:GetAttribute("Lane"),pad:GetAttribute("SectionIndex")
	local motif = (step+lane+2)%5
	local kind = if motif==0 then "WeatheredSlab" elseif motif==1 or motif==3 then "EmbeddedShelf" elseif motif==2 then "BrokenLedge" else "RockSpurA"
	local checkpoint=pad.Parent.Name=="Checkpoints"
	if checkpoint then kind="WeatheredSlab" end
	local spread = ({EmbeddedShelf=1.65,BrokenLedge=1.35,WeatheredSlab=1.12})[kind] or 1
	if kind=="WeatheredSlab" then height=5 elseif kind=="BrokenLedge" then height=if section==9 then 11 else 15 end
	if checkpoint then height=12 end
	center=pad.CFrame*CFrame.new(0,pad.Size.Y/2-height/2,0)
	local model = Props.Place(parent,kind,CFrame.identity,3.5)
	local mesh = model:FindFirstChildWhichIsA("MeshPart",true) :: MeshPart
	mesh.Size = Vector3.new(pad.Size.X*spread,height,(pad.Size.Z-(if section==9 and not checkpoint then .4 else 0))*spread)
	mesh.CFrame = center
	mesh.Color = pad.Color:Lerp(Color3.fromRGB(85,100,100),.2)
	mesh.Name = (if solid then "Landing_" else "RockRoot_") .. pad.Name
	mesh.CanCollide,mesh.CanQuery,mesh.CanTouch = solid,solid,false
	mesh:SetAttribute("TopSpread",spread)
	if checkpoint then mesh:SetAttribute("SharedCheckpoint",true) end
	if solid then
		Props.UseCollision(mesh,Enum.CollisionFidelity.Hull)
		mesh:SetAttribute("RouteSurface",true)
		for _,key in ipairs({"SectionIndex","SectionStep","Lane"}) do mesh:SetAttribute(key,pad:GetAttribute(key)) end
	end
	return mesh
end

local function triangle(parent: Instance, a: Vector3, b: Vector3, c: Vector3)
	local ab,ac,bc = b-a,c-a,c-b
	if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
	elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
	ab,ac,bc=b-a,c-a,c-b
	local right = ac:Cross(ab).Unit
	local back = bc.Unit
	local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up))
	for index,point in ipairs({b,c}) do
		local sign = if index == 1 then 1 else -1
		local p = Instance.new("WedgePart")
		p.Name = "ConnectedLavaChannel"
		p.Size = Vector3.new(.8,height,math.abs((point-a):Dot(back)))
		p.CFrame = CFrame.fromMatrix((a+point)/2,right*sign,up,back*sign)
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery = true,false,true,false
		p:SetAttribute("HazardType","Kill")
		p.Color,p.Material = Color3.fromRGB(193,74,17),Enum.Material.Neon
		p.Parent = parent
	end
end

function Surfaces.Build(model: Model, nodes: {BasePart})
	local root = Instance.new("Folder")
	root.Name,root.Parent = "NaturalSurfaces",model.Obstacles
	local scenery = Instance.new("Folder")
	scenery.Name,scenery.Parent = "RouteGeology",model.Decoration
	for _,pad in ipairs(model:GetDescendants()) do
		if not pad:IsA("BasePart") or not pad:GetAttribute("RoutePad") then continue end
		local section = pad:GetAttribute("SectionIndex") :: number
		local checkpoint=pad.Parent==model.Checkpoints
		if not KINDS[section] and not (checkpoint and section>=3) then continue end
		local top = pad.Size.Y/2
		local random = Random.new(section*3301+pad:GetAttribute("SectionStep")*197+(pad:GetAttribute("Lane")+2)*67)
		local depth = random:NextNumber(24,43)
		if section==3 or section==9 then depth=random:NextNumber(12,18) end
		local landing = stone(root,pad,depth,pad.CFrame*CFrame.new(0,top-depth/2,0),true)
		local tint = if section==5 then Color3.fromRGB(57,66,63) elseif section==6 then Color3.fromRGB(119,117,99) else Color3.fromRGB(107,117,109)
		landing.Color = tint:Lerp(Color3.fromRGB(163,169,151),if pad:GetAttribute("Lane")==0 then .22 else random:NextNumber(0,.10))
		landing.Material = if section==5 then Enum.Material.Basalt elseif section==6 then Enum.Material.Limestone else Enum.Material.Slate
		if section==3 then
			landing.Color=if pad:GetAttribute("Lane")==0 then Color3.fromRGB(102,110,91) else Color3.fromRGB(81,96,83)
			landing.Material=Enum.Material.Rock
		end
		if (section==3 or section==6) and pad:GetAttribute("Lane")~=0 then
			landing.Color=landing.Color:Lerp(Color3.fromRGB(63,84,85),.28)
		end
		if section==9 and not checkpoint then
			landing.Color = if pad:GetAttribute("Lane")==0 then Color3.fromRGB(163,190,201) else Color3.fromRGB(102,145,159)
			landing.Material = Enum.Material.Ice
			landing.CustomPhysicalProperties = pad.CustomPhysicalProperties
		end
		if checkpoint then
			landing.Color,landing.Material=pad.Color,pad.Material
			if section==3 then landing.Color=Color3.fromRGB(112,118,98) end
		end
		if not checkpoint and (section==3 or section==9 or landing.Parent.Name=="WeatheredSlab" or landing.Parent.Name=="BrokenLedge") then
			local height = if section==3 or section==9 then 48 elseif landing.Parent.Name=="WeatheredSlab" then 27 else 34
			local capDepth = landing.Size.Y
			local support = Props.PlaceSized(scenery,if pad:GetAttribute("Lane")==0 then "FaultWallA" else "FaultWallB",Vector3.new(pad.Size.X*1.9,height,pad.Size.Z*2.25),pad.CFrame*CFrame.new(0,top-capDepth+2-height/2,0),landing.Color:Lerp(Color3.fromRGB(71,100,110),.15))
			for _,rock in ipairs(support:GetDescendants()) do
				if rock:IsA("MeshPart") then
					rock.Material=landing.Material
					rock.CanCollide,rock.CanQuery,rock.CanTouch=true,true,false
					rock:SetAttribute("RouteSupport",true)
					Props.UseCollision(rock,Enum.CollisionFidelity.Hull)
				end
			end
		end
		pad.Transparency,pad.CanCollide,pad.CanTouch,pad.CanQuery = 1,false,checkpoint,false
	end
	for _,pad in ipairs(nodes) do
		local section=pad:GetAttribute("SectionIndex")
		if section<3 or section>9 then continue end
		local step=pad:GetAttribute("SectionStep") or 0
		local base=pad.CFrame*CFrame.new(0,pad.Size.Y/2,0)
		if pad.Parent==model.Checkpoints then
			Props.PlaceSized(scenery,"FaultWallA",Vector3.new(pad.Size.X*1.04,68,pad.Size.Z*1.8),base*CFrame.new(0,-36,0),Color3.fromRGB(81,100,102))
		elseif step%4==2 and section~=3 and section~=5 and section~=6 and section~=8 and section~=9 then
			local side=if step%3==0 then -1 else 1
			Props.PlaceSized(scenery,if step%3==0 then "FaultWallB" else "FaultWallA",Vector3.new(73,97,56),base*CFrame.new(side*19,-79,5)*CFrame.Angles(0,side*.27,0),Color3.fromRGB(68,87,95))
		end
		if section==3 and (step==3 or step==8 or step==15 or step==21) then
			Props.PlaceSized(scenery,if step%2==0 then "FaultWallA" else "FaultWallB",Vector3.new(76,56,66),base*CFrame.new(20,-43,4)*CFrame.Angles(0,.35*math.sin(step),0),Color3.fromRGB(91,106,101))
		elseif section==6 and (step==2 or step==5 or step==9) then
			Props.PlaceSized(scenery,"FaultWallB",Vector3.new(67,65,56),base*CFrame.new(17,-49,0)*CFrame.Angles(0,.3,0),Color3.fromRGB(98,109,100))
		end
		if section==9 and (step==2 or step==6 or step==11 or step==15) then
			local side = if step==2 or step==11 then -1 else 1
			Props.PlaceSized(scenery,if side==1 then "FaultWallB" else "FaultWallA",Vector3.new(74,44,57),base*CFrame.new(side*8,-37,4)*CFrame.Angles(0,side*.35,0),Color3.fromRGB(108,150,165))
		end
	end
	local previous: BasePart? = nil
	local shelfPrevious: BasePart? = nil
	local joinedEnds: {[BasePart]: number} = {}
	local run: {BasePart} = {}
	local function finishShoulder()
		if #run<2 then return end
		local first,last=run[1],run[#run]
		local section,step=last:GetAttribute("SectionIndex"),last:GetAttribute("SectionStep")
		local fromStep=first:GetAttribute("SectionStep")
		local a=first.Position+Vector3.new(0,first.Size.Y/2-.4,0)
		local b=last.Position+Vector3.new(0,last.Size.Y/2-.4,0)
		local slope=CFrame.lookAt((a+b)/2,b)
		local width=if section==3 then 26 elseif section==6 then 22 else 19
		local color=if section==9 then Color3.fromRGB(157,185,198) elseif section==6 then Color3.fromRGB(127,127,109) else Color3.fromRGB(104,111,91)
		local definition=nil
		local shoulder: Model
		if section==3 or section==9 then
			local kind=string.format("RoutedShelf%02d_%02d_%02d",section,fromStep,step)
			definition=RoutedManifest.Props[kind]
			assert(definition and #definition.points==#run,"Missing authored terrain curve")
			for index,pad in ipairs(run) do
				local top=pad.Position+Vector3.new(0,pad.Size.Y/2-.4,0)
				assert((top-definition.points[index]).Magnitude<.02,"Terrain must be rebaked after route layout changes")
			end
			shoulder=Props.PlaceSized(scenery,kind,definition.size,CFrame.new(definition.center)*CFrame.Angles(0,math.pi,0),nil)
		else
			shoulder=Props.PlaceSized(scenery,"EmbeddedShelf",Vector3.new(width*1.65,14,((b-a).Magnitude+14)*1.65),slope*CFrame.new(0,-7,0),color)
		end
		local foot=Props.PlaceSized(scenery,"FaultWallB",Vector3.new(width*2.5,64,((b-a).Magnitude+14)*1.18),slope*CFrame.new(6,-43,3),color:Lerp(Color3.fromRGB(82,117,127),.23))
		for _,rock in ipairs(foot:GetDescendants()) do
			if rock:IsA("MeshPart") then
				rock.CanCollide,rock.CanQuery,rock.CanTouch=true,true,false
				rock:SetAttribute("RouteSupport",true)
				Props.UseCollision(rock,Enum.CollisionFidelity.Hull)
			end
		end
		shoulder.Name=string.format("ConnectedShoulder_%02d_%02d",section,step)
		for _,rock in ipairs(shoulder:GetDescendants()) do
			if not rock:IsA("MeshPart") then continue end
			local cell=if definition then definition.cells[rock.Name] else nil
			rock.Material=if section==9 then Enum.Material.Ice elseif section==6 then Enum.Material.Limestone else Enum.Material.Rock
			if section==3 and cell then
				rock.Material=if cell.path then Enum.Material.Ground else Enum.Material.Rock
				rock.Color=if cell.path then Color3.fromRGB(112,112,82) else Color3.fromRGB(72,88,79)
			end
			if section==9 then
				rock.Color=if cell and not cell.path then Color3.fromRGB(105,147,163) else color
				if cell and not cell.path then rock.CFrame-=Vector3.new(0,2.2,0) end
				rock.CustomPhysicalProperties=PhysicalProperties.new(.9,.005,0,100,100)
			end
			rock.CanCollide,rock.CanQuery,rock.CanTouch=true,true,false
			rock:SetAttribute(if cell and not cell.path then "RouteSupport" else "RouteLink",true)
			rock:SetAttribute("SectionIndex",section)
			rock:SetAttribute("SectionStep",if cell then cell.last else step)
			rock:SetAttribute("FromStep",if cell then cell.first else fromStep)
			Props.UseCollision(rock,Enum.CollisionFidelity.Hull)
		end
		table.clear(run)
	end
	for _,node in ipairs(nodes) do
		local step=node:GetAttribute("SectionStep") or 0
		local section=node:GetAttribute("SectionIndex")
		local joined = if section==3 then (step>=2 and step<=6) or (step>=10 and step<=15) or (step>=19 and step<=24)
			elseif section==6 then step==3 or step==4 or step==9 or step==10
			elseif section==9 then step==2 or step==3 or step==6 or step==7 or step==11 or step==12 or step==15 or step==16 else false
		if shelfPrevious and joined and shelfPrevious:GetAttribute("SectionIndex")==section then
			joinedEnds[shelfPrevious]=(joinedEnds[shelfPrevious] or 0)+1
			joinedEnds[node]=(joinedEnds[node] or 0)+1
			if #run==0 then table.insert(run,shelfPrevious) end
			table.insert(run,node)
		else
			finishShoulder()
		end
		shelfPrevious=node
	end
	finishShoulder()
	for pad,count in pairs(joinedEnds) do
		if count<1 or pad.Parent==model.Checkpoints then continue end
		pad:SetAttribute("ContinuousRoute",true)
		for _,surface in ipairs(root:GetDescendants()) do
			if surface:IsA("MeshPart") and surface.Name=="Landing_"..pad.Name then
				surface.Transparency,surface.CanCollide,surface.CanQuery=1,false,false
				surface:SetAttribute("RouteSurface",nil)
			end
		end
	end
	for _,node in ipairs(nodes) do
		if node:GetAttribute("SectionIndex") ~= 5 then continue end
		if previous then
			local oldStep=previous:GetAttribute("SectionStep")
			local step=node:GetAttribute("SectionStep")
			local oldCenter,center=7*math.sin(oldStep*.5),7*math.sin(step*.5)
			local oldWidth,width=12+2*math.sin(oldStep*.8),12+2*math.sin(step*.8)
			local a = (previous.CFrame*CFrame.new(oldCenter-oldWidth,-5.5,0)).Position
			local b = (previous.CFrame*CFrame.new(oldCenter+oldWidth,-5.5,0)).Position
			local c = (node.CFrame*CFrame.new(center-width,-5.5,0)).Position
			local d = (node.CFrame*CFrame.new(center+width,-5.5,0)).Position
			triangle(model.Hazards,a,b,c)
			triangle(model.Hazards,b,d,c)
		end
		previous = node
	end
end

return Surfaces
