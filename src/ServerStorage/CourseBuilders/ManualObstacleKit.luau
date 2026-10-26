--!strict

local Kit = {}
local red = Color3.fromRGB(245, 43, 48)
local teal = Color3.fromRGB(55, 155, 157)
local cream = Color3.fromRGB(230, 216, 183)
local dark = Color3.fromRGB(46, 54, 65)
local orange = Color3.fromRGB(231, 153, 55)

local function block(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, hazard: string?): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.Position = name, size, position
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, true, true, true
	part.Color = color
	part.Material = if hazard == "Kill" then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if hazard then part:SetAttribute("HazardType", hazard) end
	part.Parent = parent
	return part
end

local function deck(model: Model, size: Vector3?)
	block(model, "Deck", size or Vector3.new(14, 1, 28), Vector3.new(0, .5, 0), cream)
end

local function pad(model: Model, name: string, position: Vector3, size: Vector3?)
	return block(model, name, size or Vector3.new(5, 1, 5), position, teal)
end

local function label(parent: Instance, title: string, position: Vector3, width: number)
	local board = block(parent, title, Vector3.new(width, 3, .35), position, dark)
	board.CanCollide, board.CanTouch, board.CanQuery = false, false, false
	board.Locked = true
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize = Enum.NormalId.Back, Vector2.new(width * 35, 105)
	gui.Parent = board
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Text, text.TextColor3 = title, cream
	text.Font, text.TextScaled = Enum.Font.GothamBold, true
	text.Parent = gui
	return board
end

local function movingTrap(model: Model, name: string, size: Vector3, position: Vector3, kind: string, axis: string, period: number)
	local part = block(model, name, size, position, red, "Kill")
	part.CanCollide = false
	part:SetAttribute("KitMotion", kind)
	part:SetAttribute("MotionAxis", axis)
	part:SetAttribute("MotionPeriod", period)
	return part
end

local function crumble(model: Model, name: string, position: Vector3, size: Vector3?)
	local tile = block(model, name, size or Vector3.new(4, 1, 4), position, orange, "Crumble")
	tile:SetAttribute("CrumbleDelay", .65)
	tile:SetAttribute("CrumbleResetTime", 2.5)
	return tile
end

local definitions: {{name: string, title: string, build: (Model) -> (), instructions: string?, difficulty: string?, category: string?}} = {
	{ name = "01_RedKillBlock", title = "01  KILL BLOCK", build = function(m: Model)
		block(m, "KillBlock", Vector3.new(6, 2, 6), Vector3.new(0, 1, 0), red, "Kill")
	end },
	{ name = "02_RedKillStrip", title = "02  KILL STRIP", build = function(m: Model)
		block(m, "KillStrip", Vector3.new(16, .6, 1), Vector3.new(0, .3, 0), red, "Kill")
	end },
	{ name = "03_RedKillWall", title = "03  KILL WALL", build = function(m: Model)
		block(m, "KillWall", Vector3.new(12, 9, 1), Vector3.new(0, 4.5, 0), red, "Kill")
	end },
	{ name = "04_RedKillSphere", title = "04  KILL SPHERE", build = function(m: Model)
		local sphere = block(m, "KillSphere", Vector3.new(5, 5, 5), Vector3.new(0, 2.5, 0), red, "Kill")
		sphere.Shape = Enum.PartType.Ball
	end },
	{ name = "05_RedHurdles", title = "05  HURDLE LANE", build = function(m: Model)
		deck(m)
		for i = 1, 3 do
			block(m, "KillHurdle_" .. i, Vector3.new(14, 1.2, .8), Vector3.new(0, 1.6, (i-2)*8), red, "Kill")
		end
	end },
	{ name = "06_OffsetJumps", title = "06  OFFSET JUMPS", build = function(m: Model)
		for i = 0, 3 do pad(m, "Landing_" .. (i+1), Vector3.new(if i%2 == 0 then -3 else 3, 2.5, -10.5+i*7)) end
	end },
	{ name = "07_ZigzagBalance", title = "07  ZIGZAG BEAMS", build = function(m: Model)
		pad(m, "Entry", Vector3.new(-5, 2.5, -11), Vector3.new(5, 1, 5))
		for i = 0, 2 do
			local beam = pad(m, "Beam_" .. (i+1), Vector3.new(0, 2.5, -7+i*7), Vector3.new(12, 1, 1.8))
			beam.CFrame *= CFrame.Angles(0, math.rad(if i%2 == 0 then -35 else 35), 0)
		end
		pad(m, "Exit", Vector3.new(5, 2.5, 11), Vector3.new(5, 1, 5))
	end },
	{ name = "08_PostJumps", title = "08  POST JUMPS", build = function(m: Model)
		for i = 0, 3 do
			local post = pad(m, "Post_" .. (i+1), Vector3.new(if i%2 == 0 then -2 else 2, 2.5, -10.5+i*7), Vector3.new(5, 3.5, 3.5))
			post.Shape = Enum.PartType.Cylinder
			post.CFrame *= CFrame.Angles(0, 0, math.pi/2)
		end
	end },
	{ name = "09_RisingSteps", title = "09  RISING JUMPS", build = function(m: Model)
		for i = 0, 3 do
			block(m, "Step_" .. (i+1), Vector3.new(6, 2+i*2, 5), Vector3.new(0, 1+i, -10.5+i*7), if i%2 == 0 then cream else teal)
		end
	end },
	{ name = "10_WindowHops", title = "10  WINDOW HOPS", build = function(m: Model)
		deck(m)
		for i, z in { -6, 6 } do
			local x = if i == 1 then -2 else 2
			block(m, "WindowLeft_" .. i, Vector3.new(3, 11, 1), Vector3.new(x-4, 6.5, z), dark)
			block(m, "WindowRight_" .. i, Vector3.new(3, 11, 1), Vector3.new(x+4, 6.5, z), dark)
			block(m, "Sill_" .. i, Vector3.new(5, 2, 1), Vector3.new(x, 2, z), orange)
			block(m, "Lintel_" .. i, Vector3.new(5, 1.5, 1), Vector3.new(x, 11.25, z), dark)
		end
	end },
	{ name = "11_WallWrap", title = "11  WALL WRAP", build = function(m: Model)
		block(m, "Wall", Vector3.new(1, 13, 10), Vector3.new(0, 6.5, 0), dark)
		pad(m, "Entry", Vector3.new(-3.5, 2.5, 0), Vector3.new(5, 1, 6))
		pad(m, "Corner", Vector3.new(0, 3.5, -7), Vector3.new(3, 1, 3))
		pad(m, "Exit", Vector3.new(3.5, 4.5, 0), Vector3.new(5, 1, 6))
	end },
	{ name = "12_CornerLedges", title = "12  CORNER LEDGES", build = function(m: Model)
		block(m, "Column", Vector3.new(6, 14, 6), Vector3.new(0, 7, 0), dark)
		pad(m, "Entry", Vector3.new(0, 2.5, -5), Vector3.new(8, 1, 3))
		pad(m, "Side", Vector3.new(5, 4.5, 0), Vector3.new(3, 1, 8))
		pad(m, "Exit", Vector3.new(0, 6.5, 5), Vector3.new(8, 1, 3))
	end },
	{ name = "13_RedCheckerFloor", title = "13  CHECKER TRAPS", build = function(m: Model)
		for x = 0, 2 do for z = 0, 4 do
			local lethal = (x+z)%2 == 1
			block(m, string.format("%s_%d_%d", if lethal then "KillTile" else "SafeTile", x, z),
				Vector3.new(4, 1, 4), Vector3.new((x-1)*4, .5, (z-2)*4), if lethal then red else cream, if lethal then "Kill" else nil)
		end end
	end },
	{ name = "14_PrecisionOverLava", title = "14  PRECISION + LAVA", build = function(m: Model)
		block(m, "KillFloor", Vector3.new(16, .6, 28), Vector3.new(0, .3, 0), red, "Kill")
		for i = 0, 3 do pad(m, "Landing_" .. (i+1), Vector3.new(if i%2 == 0 then -3 else 3, 3.5, -10.5+i*7), Vector3.new(3.5, 1, 4)) end
	end },
	{ name = "15_CrumbleBridge", title = "15  CRUMBLE BRIDGE", build = function(m: Model)
		for i = 0, 4 do
			local tile = block(m, "CrumbleTile_" .. (i+1), Vector3.new(6, 1, 4), Vector3.new(0, 2.5, -10+i*5), orange, "Crumble")
			tile:SetAttribute("CrumbleDelay", .75)
			tile:SetAttribute("CrumbleResetTime", 2.5)
		end
	end },
	{ name = "16_RedGateWeave", title = "16  KILL GATE WEAVE", build = function(m: Model)
		deck(m)
		for i = 0, 2 do
			block(m, "KillGate_" .. (i+1), Vector3.new(9, 10, 1), Vector3.new(if i%2 == 0 then -2.5 else 2.5, 6, -8+i*8), red, "Kill")
		end
	end },
	{ name = "17_SpinningKillStrip", title = "17  SPINNING STRIP", build = function(m: Model)
		deck(m, Vector3.new(28, 1, 28))
		block(m, "Hub", Vector3.new(3, 1, 3), Vector3.new(0, 1.5, 0), dark)
		movingTrap(m, "Spinner", Vector3.new(25, .8, 1), Vector3.new(0, 2.2, 0), "Spin", "Y", 6)
	end },
	{ name = "18_CrossSpinner", title = "18  CROSS SPINNER", build = function(m: Model)
		deck(m, Vector3.new(28, 1, 28))
		block(m, "Hub", Vector3.new(3, 1, 3), Vector3.new(0, 1.5, 0), dark)
		movingTrap(m, "SpinnerA", Vector3.new(25, .8, 1), Vector3.new(0, 2.2, 0), "Spin", "Y", 8)
		local second = movingTrap(m, "SpinnerB", Vector3.new(25, .8, 1), Vector3.new(0, 2.2, 0), "Spin", "Y", 8)
		second.CFrame *= CFrame.Angles(0, math.pi/2, 0)
	end },
	{ name = "19_SwingingKillBar", title = "19  SWINGING BAR", build = function(m: Model)
		deck(m, Vector3.new(28, 1, 28))
		block(m, "Support", Vector3.new(2, 10, 2), Vector3.new(0, 6, 2), dark)
		local bar = movingTrap(m, "SwingBar", Vector3.new(20, 1, 1), Vector3.new(0, 11, 0), "Swing", "Z", 6)
		bar:SetAttribute("MotionAngle", 65)
	end },
	{ name = "20_SlidingKillGate", title = "20  SLIDING GATE", build = function(m: Model)
		deck(m, Vector3.new(28, 1, 28))
		local gate = movingTrap(m, "SlidingGate", Vector3.new(8, 9, 1), Vector3.new(0, 5.5, 0), "Slide", "X", 6)
		gate:SetAttribute("MotionDistance", 8)
	end },
	{ name = "21_CrumbleSteppingStones", title = "21  CRUMBLE STONES", build = function(m: Model)
		for i = 0, 5 do
			crumble(m, "Stone_" .. i, Vector3.new(if i%2 == 0 then -3 else 3, 2.5, -12.5+i*5))
		end
	end },
	{ name = "22_CrumbleSplitFork", title = "22  CRUMBLE FORK", build = function(m: Model)
		pad(m, "Entry", Vector3.new(0, 2.5, -12), Vector3.new(12, 1, 4))
		pad(m, "Exit", Vector3.new(0, 2.5, 12), Vector3.new(12, 1, 4))
		for i = 0, 2 do crumble(m, "Wide_" .. i, Vector3.new(-4, 2.5, -6+i*6), Vector3.new(5, 1, 4)) end
		for i = 0, 1 do crumble(m, "Tight_" .. i, Vector3.new(4, 3.5, -4+i*8), Vector3.new(3, 1, 3)) end
	end },
	{ name = "23_SpinCarousel", title = "23  TRIPLE ROTOR", build = function(m: Model)
		deck(m, Vector3.new(28, 1, 28))
		block(m, "Hub", Vector3.new(2, 1, 2), Vector3.new(0, 1.5, 0), dark)
		for i = 0, 2 do
			local bar = movingTrap(m, "Rotor_" .. i, Vector3.new(21, .65, .65), Vector3.new(0, 2.1, 0), "Spin", "Y", 11)
			bar.CFrame *= CFrame.Angles(0, math.rad(i*60), 0)
		end
	end },
	{ name = "24_SpinVerticalWheel", title = "24  VERTICAL WHEEL", build = function(m: Model)
		deck(m, Vector3.new(22, 1, 28))
		for _, x in {-9, 9} do block(m, "WheelSupport", Vector3.new(1, 9, 1), Vector3.new(x, 5.5, 1.8), dark) end
		block(m, "Crossbeam", Vector3.new(19, 1, 1), Vector3.new(0, 9.5, 1.8), dark)
		block(m, "Axle", Vector3.new(.6, .6, 2.2), Vector3.new(0, 9.5, 1), dark)
		for i = 0, 1 do
			local bar = movingTrap(m, "WheelBar_" .. i, Vector3.new(17, .8, .8), Vector3.new(0, 9.5, 0), "Spin", "Z", 9)
			bar.CFrame *= CFrame.Angles(0, 0, math.pi/2*i)
		end
	end },
	{ name = "25_SwingTwinBars", title = "25  TWIN SWINGS", build = function(m: Model)
		deck(m, Vector3.new(22, 1, 28))
		for i, z in {-5, 5} do
			for _, x in {-10, 10} do block(m, "Support_" .. i, Vector3.new(1, 8, 1), Vector3.new(x, 5, z+1.5), dark) end
			block(m, "Crossbeam_" .. i, Vector3.new(21, 1, 1), Vector3.new(0, 9, z+1.5), dark)
			block(m, "Axle_" .. i, Vector3.new(.6, .6, 1.8), Vector3.new(0, 9, z+.8), dark)
			local bar = movingTrap(m, "Swing_" .. i, Vector3.new(18, .8, .8), Vector3.new(0, 9, z), "Swing", "Z", 5+i*1.5)
			bar:SetAttribute("MotionAngle", 60)
		end
	end },
	{ name = "26_SwingLowSweep", title = "26  LOW SWEEP", build = function(m: Model)
		deck(m, Vector3.new(24, 1, 28))
		for i, z in {-5, 5} do
			block(m, "Hub_" .. i, Vector3.new(2, 1, 2), Vector3.new(0, 1.5, z), dark)
			local bar = movingTrap(m, "Sweep_" .. i, Vector3.new(18, .7, .8), Vector3.new(0, 2.1, z), "Swing", "Y", 6+i)
			bar:SetAttribute("MotionAngle", 50)
		end
	end },
	{ name = "27_SlideTwinShutters", title = "27  TWIN SHUTTERS", build = function(m: Model)
		deck(m, Vector3.new(28, 1, 28))
		for i, z in {-5, 5} do
			local panel = movingTrap(m, "Shutter_" .. i, Vector3.new(7, 8, 1), Vector3.new(0, 5, z), "Slide", "X", 5+i)
			panel:SetAttribute("MotionDistance", 8)
			if i == 2 then panel.CFrame *= CFrame.Angles(0, math.pi, 0) end
		end
	end },
	{ name = "28_SlideJumpBars", title = "28  TRAVELLING HURDLES", build = function(m: Model)
		deck(m, Vector3.new(18, 1, 28))
		for i, z in {-6, 6} do
			local bar = movingTrap(m, "Hurdle_" .. i, Vector3.new(17, .8, .8), Vector3.new(0, 2.2, z), "Slide", "Z", 6+i)
			bar:SetAttribute("MotionDistance", 3)
		end
	end },
	{ name = "29_CrumbleRotorBridge", title = "29  CRUMBLE + ROTOR", build = function(m: Model)
		pad(m, "Entry", Vector3.new(0, 2.5, -13), Vector3.new(10, 1, 4))
		pad(m, "Exit", Vector3.new(0, 2.5, 13), Vector3.new(10, 1, 4))
		for i = 0, 3 do crumble(m, "Tile_" .. i, Vector3.new(0, 2.5, -7.5+i*5), Vector3.new(9, 1, 4.5)) end
		movingTrap(m, "Rotor", Vector3.new(16, .6, .6), Vector3.new(0, 4.1, 0), "Spin", "Y", 10)
	end },
	{ name = "30_SlideSlalom", title = "30  SLIDING SLALOM", build = function(m: Model)
		deck(m, Vector3.new(26, 1, 28))
		for i = 0, 2 do
			local panel = movingTrap(m, "Panel_" .. i, Vector3.new(6, 8, 1), Vector3.new(if i%2 == 0 then -3 else 3, 5, -8+i*8), "Slide", "X", 6+i)
			panel:SetAttribute("MotionDistance", 4)
		end
	end },
}

for _, definition in require(script.Parent.ManualObstacleCreative)({
    block=block, deck=deck, pad=pad, movingTrap=movingTrap, crumble=crumble,
}) do table.insert(definitions, definition) end

for _, definition in require(script.Parent.ManualObstacleInventive)({
	block=block, deck=deck, pad=pad, movingTrap=movingTrap, crumble=crumble,
}) do table.insert(definitions, definition) end

local function addPiece(root: Model, index: number)
	local definition = definitions[index]
	if root.CopyThese:FindFirstChild(definition.name) then return end
	local x, z = ((index-1)%4-1.5)*36, math.floor((index-1)/4)*39
	if index >= 21 then x, z = ((index-21)%4-1.5)*44, 214+math.floor((index-21)/4)*50 end
	if index >= 43 then x, z = 150+(index-43)%6*52, 214+math.floor((index-43)/6)*60 end
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = definition.name, CFrame.identity
	model:SetAttribute("KitPiece", true)
	model:SetAttribute("Instructions", definition.instructions)
	model:SetAttribute("Difficulty", definition.difficulty)
	model:SetAttribute("Category", definition.category)
	definition.build(model)
	model:PivotTo(root:GetPivot() * CFrame.new(x, 0, z))
	model.Parent = root.CopyThese
	local display = root.Display_DoNotCopy
	local stand = block(display, "DisplayBase_" .. index, Vector3.new(if index >= 43 then 46 elseif index >= 21 then 40 else 32, .5, if index >= 43 then 48 elseif index >= 21 then 42 else 32), Vector3.zero, dark)
	stand.CFrame = root:GetPivot() * CFrame.new(x, -.25, z)
	stand.CanCollide, stand.CanTouch, stand.CanQuery, stand.Locked = false, false, false, true
	local board = label(display, definition.title, Vector3.zero, if index >= 21 then 38 else 30)
	board.CFrame = root:GetPivot() * CFrame.new(x, 2, z+(if index >= 43 then 24 elseif index >= 21 then 21 else 16))
end

local function inventiveSigns(root: Model)
	local display = root.Display_DoNotCopy
	if display:FindFirstChild("V5_Title") then return end
	for _, item in {
		{"V5_Title", "V5  /  HINGES, ORBITS, PHASE ROUTES + CLIMBING", 16, 180},
		{"V5_Legend", "CYAN: SOLID  |  AMBER: FADING SOON  |  PURPLE GHOST: WAIT", 11, 180},
	} do
		local board = label(display, item[2], Vector3.zero, 290)
		board.Name = item[1]
		board.CFrame = root:GetPivot() * CFrame.new(280, item[3], item[4])
	end
end

function Kit.AddMovingPieces(root: Model)
	assert(game.PlaceId == 85558151074819 and root.Name == "ObstacleKit_Palette")
	assert(root:FindFirstChild("CopyThese") and root:FindFirstChild("Display_DoNotCopy"))
	for index = 17, 20 do addPiece(root, index) end
	root:SetAttribute("KitVersion", math.max(root:GetAttribute("KitVersion") or 1, 2))
end

function Kit.AddAdvancedPieces(root: Model)
	assert(game.PlaceId == 85558151074819 and root.Name == "ObstacleKit_Palette")
	assert(root:FindFirstChild("CopyThese") and root:FindFirstChild("Display_DoNotCopy"))
	for index = 21, 30 do addPiece(root, index) end
	root:SetAttribute("KitVersion", math.max(root:GetAttribute("KitVersion") or 1, 3))
end

function Kit.AddCreativePieces(root: Model)
	assert(game.PlaceId == 85558151074819 and root.Name == "ObstacleKit_Palette")
	assert(root:FindFirstChild("CopyThese") and root:FindFirstChild("Display_DoNotCopy"))
	for index = 31, 42 do addPiece(root, index) end
	root:SetAttribute("KitVersion", math.max(root:GetAttribute("KitVersion") or 1, 4))
	root:SetAttribute("Purpose", "Shared obstacle library for all current and future courses")
	root:SetAttribute("Placement", "Duplicate a numbered model into the editable course's Obstacles folder before Play. Works with any course using CourseHazardService.")
end

function Kit.AddInventivePieces(root: Model)
	assert(game.PlaceId == 85558151074819 and root.Name == "ObstacleKit_Palette")
	assert(root:FindFirstChild("CopyThese") and root:FindFirstChild("Display_DoNotCopy"))
	for index = 43, #definitions do addPiece(root, index) end
	inventiveSigns(root)
	root:SetAttribute("KitVersion", math.max(root:GetAttribute("KitVersion") or 1, 5))
end

function Kit.Build(parent: Instance, origin: Vector3?): Model
	assert(game.PlaceId == 85558151074819, "Manual kit requires Project Classic Elevation")
	assert(parent:FindFirstChild("ObstacleKit_Palette") == nil, "Preserve the existing manually edited palette")
	local root = Instance.new("Model")
	root.Name = "ObstacleKit_Palette"
	root:SetAttribute("KitVersion", 5)
	root:SetAttribute("Purpose", "Shared obstacle library for all current and future courses")
	root:SetAttribute("Placement", "Duplicate a numbered model into the editable course's Obstacles folder before Play. Works with any course using CourseHazardService.")
	root.WorldPivot = CFrame.identity
	local display = Instance.new("Folder")
	display.Name, display.Parent = "Display_DoNotCopy", root
	local models = Instance.new("Folder")
	models.Name, models.Parent = "CopyThese", root
	for i = 1, #definitions do addPiece(root, i) end
	inventiveSigns(root)
	label(display, "OBSTACLE KIT  /  COPY NUMBERED MODELS INTO YOUR COURSE", Vector3.new(0, 15, -25), 140)
	root:PivotTo(CFrame.new(origin or Vector3.new(3330, 8, 600)))
	root.Parent = parent
	return root
end

return Kit
