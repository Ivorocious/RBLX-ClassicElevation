--!strict

local Props=require(script.Parent.AscentProps)
local Integration={}
local GREEN_ROCK=Color3.fromRGB(73,91,72)

local function rock(parent: Instance, kind: string, size: Vector3, cf: CFrame, color: Color3): Model
	local model=Props.PlaceSized(parent,kind,size,cf,color)
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Material=Enum.Material.Rock end
	end
	return model
end

local function grove(parent: Instance, node: BasePart, side: number, variant: number)
	local frame=node.CFrame*CFrame.new(side*44,0,0)
	rock(parent,"EmbeddedShelf",Vector3.new(46.2,24,72),frame*CFrame.new(0,-13,0),GREEN_ROCK)
	rock(parent,"FaultWallB",Vector3.new(48,53,73),frame*CFrame.new(side*4,-37,3)*CFrame.Angles(0,.23*side,0),Color3.fromRGB(57,75,67))
	local trees=if variant==1 then {{-7,-10,41},{5,2,31},{-2,13,36}} else {{4,-13,35},{-6,1,43},{6,11,27}}
	for index,p in ipairs(trees) do
		Props.Place(parent,if index==2 then "PineWind" else "CedarLite",frame*CFrame.new(p[1],-1.3,p[2])*CFrame.Angles(0,index*.73+variant,if index==2 then -.1*side else 0),p[3])
	end
	for _,offset in ipairs({{-11,-7},{9,9}}) do
		Props.Place(parent,"Fern",frame*CFrame.new(offset[1],-.8,offset[2])*CFrame.Angles(0,variant,0),2.6)
	end
end

function Integration.Build(model: Model, nodes: {BasePart})
	local root=Instance.new("Folder")
	root.Name,root.Parent="LowerMountainBanks",model.Decoration
	for _,node in ipairs(nodes) do
		local section,step=node:GetAttribute("SectionIndex"),node:GetAttribute("SectionStep")
		if section==3 then
			if step==3 or step==11 or step==20 then grove(root,node,-1,if step==11 then 2 else 1) end
			if step==8 or step==17 then
				rock(root,if step==8 then "FaultWallA" else "FaultWallB",Vector3.new(31,55,67),node.CFrame*CFrame.new(52,3,-5)*CFrame.Angles(0,.16,0),GREEN_ROCK)
				for _,z in ipairs({-9,7}) do
					Props.Place(root,"GrassClump",node.CFrame*CFrame.new(36,-1.2,z)*CFrame.Angles(0,z,0),2.1)
				end
			end
		elseif section==4 and (step==3 or step==11) then
			grove(root,node,if step==3 then -1 else 1,2)
		elseif section==5 and (step==3 or step==9 or step==15) then
			local side=if step==9 then -1 else 1
			local frame=node.CFrame*CFrame.new(side*58,0,0)
			rock(root,if side==1 then "FaultWallA" else "FaultWallB",Vector3.new(43,64+step,81),frame*CFrame.new(0,4,-8)*CFrame.Angles(0,side*.26,0),Color3.fromRGB(42,54,48))
			rock(root,"TalusFan",Vector3.new(31,22,71),frame*CFrame.new(-side*5,-12,4)*CFrame.Angles(0,side*.1,0),Color3.fromRGB(53,62,49))
		elseif section==6 and (step==3 or step==9) then
			local frame=node.CFrame*CFrame.new(58,0,0)
			rock(root,"EmbeddedShelf",Vector3.new(57,22,60),frame*CFrame.new(0,-14,0),Color3.fromRGB(104,107,86))
			rock(root,"FaultWallB",Vector3.new(51,46,67),frame*CFrame.new(3,-34,1),Color3.fromRGB(78,92,77))
			Props.Place(root,"RuinPillarA",frame*CFrame.new(-7,-3,-9)*CFrame.Angles(0,.5,0),32)
			Props.Place(root,"RuinPillarB",frame*CFrame.new(9,-3,8)*CFrame.Angles(0,-.3,.14),21)
			Props.Place(root,"Fern",frame*CFrame.new(-9,-2.7,8),3)
			Props.Place(root,"GrassClump",frame*CFrame.new(11,-2.7,-8),2.4)
		end
	end
end

return Integration
