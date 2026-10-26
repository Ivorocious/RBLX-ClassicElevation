-- Decorative relief follows the owner's two manually rotated side walls.
assert(game.PlaceId == 85558151074819, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before applying")
local lobby = workspace.Lobby
local colors = {
	Cream = Color3.new(.95,.86,.67),
	Stone = Color3.new(.79,.70,.53),
	Gold = Color3.new(.88,.58,.16),
	Blue = Color3.new(.045,.12,.17),
}
local count = 0
for _, wall in lobby:GetChildren() do
	if not wall:IsA("MeshPart") or wall.Name ~= "Arrival_StairBackWall_-1__Stone__00" then continue end
	local side = math.sign(wall.Position.X - 1565)
	local name = "SideWallFinish_" .. side
	assert(not lobby.Editable["02_Arrival"]:FindFirstChild(name), "Finish already exists")
	local group = Instance.new("Model")
	group.Name = name
	group:SetAttribute("EditableComponent", true)
	group:SetAttribute("ManualWallFinish", true)
	group:SetAttribute("SourceWallPosition", wall.Position)
	local surface = wall.Position + Vector3.new(side * (wall.Size.Z/2), -wall.Size.X/2, 0)
	local frame = CFrame.fromMatrix(surface, Vector3.new(0,0,-side), Vector3.yAxis, Vector3.new(side,0,0))
	local function part(name, color, x,y,z, w,h,d)
		local p = Instance.new("Part")
		p.Name, p.Size = name, Vector3.new(w,h,d)
		p.CFrame = frame * CFrame.new(x,y,z)
		p.Color = colors[color]
		p.Material = if color=="Gold" then Enum.Material.Metal else Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, true
		p.Parent = group
		return p
	end
	for _, x in {-21,-7,7,21} do
		part("Pilaster", "Cream", x,9.3,.22, .85,18.6,.44)
		part("Foot", "Cream", x,.5,.3, 1.25,1,.6)
		part("Capital", "Cream", x,17.7,.35, 1.3,.8,.7)
	end
	for _, y in {1.2,17} do part("CourseTrim", "Cream",0,y,.16,44,.55,.32) end
	for _, x in {-14,0,14} do
		part("PanelBacking", "Stone",x,9.3,.10,11,11.8,.2)
		for _, dx in {-5.5,5.5} do part("PanelSide", "Cream",x+dx,9.3,.3,.32,12.2,.6) end
		for _, y in {3.2,15.4} do part("PanelCap", "Cream",x,y,.3,11.3,.32,.6) end
		if x==0 then
			part("BannerPanel", "Blue",x,9.5,.25,5.6,10.6,.2)
			for _, dx in {-2.9,2.9} do part("BannerEdge", "Gold",dx,9.5,.39,.12,10.9,.1) end
			for _, y in {4.1,14.9} do part("BannerEdge", "Gold",x,y,.39,5.9,.12,.1) end
			local diamond=part("Compass", "Gold",0,9.5,.46,1.6,1.6,.1)
			diamond.CFrame *= CFrame.Angles(0,0,math.rad(45))
			part("CompassVertical", "Cream",0,9.5,.53,.16,4,.1)
			part("CompassHorizontal", "Cream",0,9.5,.53,3,.16,.1)
		end
	end
	group.WorldPivot = frame
	group.Parent = lobby.Editable["02_Arrival"]
	count += 1
end
assert(count==2, "Expected the two manually placed side walls")
return {finishedSideWalls=count}
