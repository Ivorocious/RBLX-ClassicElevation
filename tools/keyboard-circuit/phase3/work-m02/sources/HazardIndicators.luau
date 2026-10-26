--!strict
local Art = require(script.Parent.EnvironmentParts)
local Mechanisms = require(script.Parent.Mechanisms)
local HazardIndicators = {}

local INK = Color3.fromRGB(247, 244, 230)
local AMBER = Color3.fromRGB(255, 211, 68)
local CLEAR = Color3.fromRGB(181, 241, 205)
local titles = {
	Seesaws = "SPACEBAR SEESAWS", Fallaway = "FALLAWAY ROWS", Foundry = "FALLING KEYS",
	Lift = "SPRING LIFT", Shuttle = "CARRIAGE SHUTTLE", Sweep = "KEY PULLER SWEEP",
	Domino = "DOMINO CASCADE", Shift = "SHIFT WINDOWS",
}

local function reference(parent: Instance, name: string, value: Instance): ObjectValue
	local link = Instance.new("ObjectValue")
	link.Name, link.Value, link.Parent = name, value, parent
	return link
end

local function label(parent: Instance, name: string, position: Vector2, size: Vector2, text: string, color: Color3): TextLabel
	local item = Instance.new("TextLabel")
	item.Name, item.Text, item.TextColor3 = name, text, color
	item.Position, item.Size = UDim2.fromScale(position.X, position.Y), UDim2.fromScale(size.X, size.Y)
	item.BackgroundTransparency, item.TextScaled, item.TextWrapped = 1, true, false
	item.Font, item.TextXAlignment = Enum.Font.GothamBold, Enum.TextXAlignment.Left
	item.Parent = parent
	return item
end

local function stroke(parent: Instance, name: string, x: number, y: number, width: number, height: number, rotation: number?): Frame
	local item = Instance.new("Frame")
	item.Name, item.BorderSizePixel, item.BackgroundColor3 = name, 0, INK
	item.AnchorPoint, item.Position, item.Size = Vector2.new(.5, .5), UDim2.fromScale(x, y), UDim2.fromScale(width, height)
	item.Rotation, item.Parent = rotation or 0, parent
	return item
end

local function display(panel: BasePart, title: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.CanvasSize = "HazardDisplay", Enum.NormalId.Front, Vector2.new(708, 372)
	gui.LightInfluence, gui.AlwaysOnTop, gui.MaxDistance = .15, false, 170
	gui.Parent = panel
	local header = Instance.new("Frame")
	header.Name, header.BackgroundColor3, header.BorderSizePixel = "Header", AMBER, 0
	header.Position, header.Size, header.Parent = UDim2.fromScale(.025, .045), UDim2.fromScale(.95, .18), gui
	label(header, "Title", Vector2.new(.025, .08), Vector2.new(.95, .84), title, Art.Charcoal)
	label(gui, "Phase", Vector2.new(.255, .31), Vector2.new(.71, .2), "WAIT", INK)
	label(gui, "Action", Vector2.new(.255, .57), Vector2.new(.71, .16), "HOLD ON CTRL", INK)
	label(gui, "Scope", Vector2.new(.045, .82), Vector2.new(.91, .11), "THIS INDICATOR DESCRIBES THIS OBSTACLE", Art.Silver)
	local glyph = Instance.new("Frame")
	glyph.Name, glyph.BackgroundTransparency = "DirectionGlyph", 1
	glyph.Position, glyph.Size, glyph.Parent = UDim2.fromScale(.035, .32), UDim2.fromScale(.18, .37), gui
	local arrow = Instance.new("Frame")
	arrow.Name, arrow.BackgroundTransparency, arrow.Size, arrow.Parent = "Arrow", 1, UDim2.fromScale(1, 1), glyph
	stroke(arrow, "Shaft", .42, .5, .68, .12)
	stroke(arrow, "HeadA", .69, .35, .47, .12, 45)
	stroke(arrow, "HeadB", .69, .65, .47, .12, -45)
	local hold = Instance.new("Frame")
	hold.Name, hold.BackgroundTransparency, hold.Size, hold.Parent = "Hold", 1, UDim2.fromScale(1, 1), glyph
	stroke(hold, "CrossA", .5, .5, .85, .13, 45)
	stroke(hold, "CrossB", .5, .5, .85, .13, -45)
	arrow.Visible = false
	return gui
end

local function actorFor(unit: Model, plate: BasePart): Model?
	local kind = unit:GetAttribute("MechanismKind")
	local index = plate:GetAttribute("MotionIndex") or tonumber(plate.Name:match("(%d+)$")) or 1
	for _, item in unit:GetDescendants() do
		if not item:IsA("Model") or not item:GetAttribute("KCMover") then continue end
		if kind == "Fallaway" then
			if item:GetAttribute("LaneIndex") == plate:GetAttribute("LaneIndex") and item:GetAttribute("RowIndex") == 1 then return item end
		elseif item:GetAttribute("MotionIndex") == index then
			return item
		end
	end
	return nil
end

local function makeSign(group: Model, unit: Model, plate: BasePart, role: string, frame: CFrame, title: string): Model
	local model = Art.Model(group, unit:GetAttribute("MechanismId") .. "_" .. plate.Name .. "_" .. role)
	model:SetAttribute("HazardIndicator", true)
	model:SetAttribute("IndicatorRole", role)
	model:SetAttribute("WarningMechanismId", unit:GetAttribute("MechanismId"))
	model:SetAttribute("StateSource", "Existing server mechanism state and admission windows")
	model:SetAttribute("IndicatorKind", unit:GetAttribute("MechanismKind"))
	local panel = Art.Block(model, "DisplayPanel", Vector3.new(11.8, 6.2, .65), frame, Art.Charcoal)
	panel.Material = Enum.Material.Metal
	model.PrimaryPart = panel
	Art.Block(model, "UpperCautionRail", Vector3.new(12.2, .6, .8), frame * CFrame.new(0, 3.4, 0), AMBER)
	Art.Block(model, "LowerSilverRail", Vector3.new(12.2, .35, .85), frame * CFrame.new(0, -3.25, 0), Art.Silver)
	for _, side in {-1, 1} do
		Art.Block(model, "Stand", Vector3.new(.7, 6.8, .75), frame * CFrame.new(side * 4.8, -4.2, 1.6), Art.Charcoal)
		Art.Block(model, "StandFoot", Vector3.new(2.2, .65, 2.3), frame * CFrame.new(side * 4.8, -7.4, 1.6), Art.Silver)
	end
	for index = -2, 2 do
		Art.Block(model, "CautionSlash", Vector3.new(.65, .58, .05), frame * CFrame.new(index * 2.25, 3.4, -.43) * CFrame.Angles(0, 0, math.rad(-26)), Art.Charcoal)
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then part:SetAttribute("Pressable", false); part:SetAttribute("KCPress", false) end
	end
	display(panel, title)
	reference(model, "SourceMechanism", unit)
	reference(model, "SourceWarning", plate)
	local actor = actorFor(unit, plate)
	if actor then reference(model, "SourceActor", actor) end
	local links = plate:FindFirstChild("M02Indicators")
	if not links then
		links = Instance.new("Folder")
		links.Name, links.Parent = "M02Indicators", plate
	end
	reference(links, model.Name, model)
	return model
end

local function presentation(sign: Model, warning: boolean, admission: boolean): (string, string, string, Color3)
	local source = sign.SourceMechanism.Value :: Model
	local actorLink = sign:FindFirstChild("SourceActor") :: ObjectValue?
	local actor = if actorLink then actorLink.Value else nil
	local unitState = source:GetAttribute("CycleState") or "Stopped"
	local kind, role = sign:GetAttribute("IndicatorKind"), sign:GetAttribute("IndicatorRole")
	local state = if kind == "Lift" or kind == "Shuttle" then unitState else (if actor then actor:GetAttribute("CycleState") else unitState) or "Stopped"
	if unitState == "Stopped" or state == "Stopped" then return "STOPPED", "HOLD ON CTRL", "hold", INK end
	if kind == "Lift" or kind == "Shuttle" then
		local slider = source:FindFirstChild("Slider") :: PrismaticConstraint?
		if not slider or not slider.Enabled then return "STOPPED", "HOLD ON CTRL", "hold", INK end
	end
	if kind == "Seesaws" then return "ROCKING", "BALANCE; STEP TO THE NEXT BAR", "tilt", AMBER end
	if kind == "Lift" then
		if role == "Exit" then
			if source:GetAttribute("ExitWindow") == true then return "EXIT NOW", "STEP FORWARD ONTO CTRL", "forward", CLEAR end
			return if unitState == "Rising" then "LIFT RISING" else "WAIT FOR LIFT", "HOLD ON THE LANDING", "up", AMBER
		end
		if source:GetAttribute("BoardingWindow") == true and admission then
			return if unitState == "Boarding" then "LIFT LEAVES SOON" else "BOARD NOW", "STEP ON; RIDE UP", "up", if warning then AMBER else CLEAR
		end
		return if unitState == "Returning" then "LIFT RETURNING" elseif unitState == "HighDwell" then "LIFT AT TOP" else "LIFT RISING", "HOLD ON CTRL", if unitState == "Returning" then "down" else "up", AMBER
	end
	if kind == "Shuttle" then
		local window = if role == "Exit" then "ExitWindow" else "BoardingWindow"
		if source:GetAttribute(window) == true and admission then
			local action = if role == "Exit" then "STEP FORWARD ONTO CTRL" else "STEP ON; RIDE ACROSS"
			return if role == "Exit" then "EXIT NOW" else "BOARD NOW", if warning then "DEPARTS SOON; " .. action else action, "forward", if warning then AMBER else CLEAR
		end
		return if unitState == "Returning" then "SHUTTLE RETURNING" elseif unitState == "Boarding" or unitState == "Exit" then "WAIT FOR DOCK" else "SHUTTLE MOVING", "HOLD ON CTRL; WAIT FOR DOCK", "side", AMBER
	end
	if kind == "Fallaway" then
		if warning then return "ROWS DROP NEXT", "STAY ON CTRL", "down", AMBER end
		if admission then return "LANE OPEN", "CROSS THIS LANE NOW", "forward", CLEAR end
		if state == "Return" then return "ROWS RETURNING", "WAIT ON CTRL", "up", AMBER end
		if state == "Drop" or state == "Down" then return "ROWS DOWN", "WAIT ON CTRL", "down", AMBER end
		return "ENTRY CLOSED", "WAIT ON CTRL FOR NEXT WINDOW", "hold", AMBER
	end
	if kind == "Foundry" then
		if warning then return "DROP INCOMING", "KEEP OUT OF THIS MARKED ZONE", "down", AMBER end
		if state == "Return" then return "KEY RISING", "WAIT OUTSIDE THE MARKED ZONE", "up", AMBER end
		if state == "Clear" and admission then return "THIS ZONE CLEAR", "CHECK THE NEXT DROP; MOVE FORWARD", "forward", CLEAR end
		return if state == "Drop" then "KEY FALLING" else "KEY DOWN", "USE CTRL COVER; KEEP OUT", "down", AMBER
	end
	if kind == "Sweep" then
		if state == "Rest" and admission then return "ARM PARKED", "CROSS BEFORE THE NEXT SWEEP", "forward", CLEAR end
		if state == "Warning" then return "SWEEP INCOMING", "WAIT ON CTRL", "side", AMBER end
		return if state == "Return" then "ARM RETURNING" else "ARM SWEEPING", "WAIT ON CTRL; KEEP OUT", "side", AMBER
	end
	if kind == "Domino" then
		if state == "ResetWarning" then return "PANEL RISES NEXT", "CLEAR THE PANEL; WAIT ON CTRL", "up", AMBER end
		if state == "Reset" then return "PANEL RISING", "WAIT ON CTRL", "up", AMBER end
		if state == "Warning" then return "PANEL FALLS NEXT", "WAIT ON CTRL; KEEP OUT", "down", AMBER end
		if state == "Tip" then return "PANEL FALLING", "WAIT ON CTRL; KEEP OUT", "down", AMBER end
		if state == "ClearPassage" and admission then return "PANEL DOWN", "PASS THIS PANEL; CHECK THE NEXT", "forward", CLEAR end
		return "PANEL UPRIGHT", "WAIT ON CTRL", "hold", AMBER
	end
	if kind == "Shift" then
		if warning then return "KEY RETRACTS NEXT", "STAY ON CTRL", "side", AMBER end
		if admission then return "SHIFT WINDOW OPEN", "CROSS THIS KEY NOW", "forward", CLEAR end
		if state == "Return" then return "KEY RETURNING", "WAIT ON CTRL", "side", AMBER end
		return "SHIFT ENTRY CLOSED", "WAIT ON CTRL FOR NEXT WINDOW", "hold", AMBER
	end
	return "WAIT", "HOLD ON CTRL", "hold", INK
end

function HazardIndicators.UpdatePlate(plate: BasePart, warning: boolean, admission: boolean?, _message: string?)
	local links = plate:FindFirstChild("M02Indicators")
	if not links then return end
	for _, link in links:GetChildren() do
		if not link:IsA("ObjectValue") or not link.Value or not link.Value:IsA("Model") then continue end
		local sign = link.Value
		local phase, action, icon, color = presentation(sign, warning, admission == true)
		local signature = phase .. "|" .. action .. "|" .. icon
		if sign:GetAttribute("DisplaySignature") == signature then continue end
		local panel = sign.PrimaryPart
		local gui = if panel then panel:FindFirstChild("HazardDisplay") else nil
		if not gui then continue end
		local guiPhase = gui.Phase :: TextLabel
		local guiAction = gui.Action :: TextLabel
		guiPhase.Text, guiAction.Text = phase, action
		guiPhase.TextColor3, guiAction.TextColor3 = color, color
		local glyph = gui.DirectionGlyph
		local glyphHold = glyph.Hold :: Frame
		local glyphArrow = glyph.Arrow :: Frame
		glyphHold.Visible, glyphArrow.Visible = icon == "hold", icon ~= "hold"
		glyphArrow.Rotation = if icon == "up" then -90 elseif icon == "down" then 90 elseif icon == "tilt" then -18 elseif icon == "side" then 180 else 0
		for _, part in glyph:GetDescendants() do if part:IsA("Frame") and part.BackgroundTransparency ~= 1 then part.BackgroundColor3 = color end end
		sign:SetAttribute("DisplaySignature", signature)
		sign:SetAttribute("DisplayedPhase", phase)
		sign:SetAttribute("DisplayedAction", action)
	end
end

function HazardIndicators.UpdateUnit(unit: Model)
	local links = unit:FindFirstChild("M02IndicatorWarnings")
	if not links then return end
	for _, link in links:GetChildren() do
		if link:IsA("ObjectValue") and link.Value and link.Value:IsA("BasePart") then
			local plate = link.Value
			HazardIndicators.UpdatePlate(plate, plate:GetAttribute("WarningActive") == true, plate:GetAttribute("AdmissionOpen") == true)
		end
	end
end

function HazardIndicators.Build(root: Model, _origin: Vector3): Model
	local artParent = root:FindFirstChild("MapEnvironment")
	assert(artParent and artParent:IsA("Model"), "Build MapEnvironment before hazard indicators")
	local previous = artParent:FindFirstChild("HazardIndicators")
	if previous and previous:IsA("Model") then return previous end
	local course = root
	local group = Art.Model(artParent, "HazardIndicators")
	group:SetAttribute("IndicatorRevision", "KC_WARN_M02_01")
	group:SetAttribute("StateWrites", "Existing warning flow; display writes only when phase or action changes; no additional clock")
	local count = 0
	for _, source in course:GetDescendants() do
		if not source:IsA("Model") or not source:GetAttribute("MechanismKind") then continue end
		local kind = source:GetAttribute("MechanismKind") :: string
		local cf = Mechanisms.GetFrame(source)
		local plates = {}
		local unitLinks = Instance.new("Folder")
		unitLinks.Name, unitLinks.Parent = "M02IndicatorWarnings", source
		for _, plate in source:GetDescendants() do
			if plate:IsA("BasePart") and plate:GetAttribute("KCWarning") and not plate:GetAttribute("KCActorWarning") then
				table.insert(plates, plate)
				reference(unitLinks, plate.Name, plate)
			end
		end
		for _, plate in plates do
			local point = cf:PointToObjectSpace(plate.CFrame.Position)
			local index = plate:GetAttribute("MotionIndex") or plate:GetAttribute("LaneIndex") or tonumber(plate.Name:match("(%d+)$"))
			local suffix = if kind == "Fallaway" then " / LANE " .. tostring(index) elseif kind == "Foundry" then " / DROP " .. tostring(index) elseif kind == "Domino" then " / PANEL " .. tostring(index) elseif kind == "Shift" or kind == "Seesaws" then " / " .. tostring(index) else ""
			local role = if plate.Name == "ExitWarning" then "Exit" else "Entry"
			local lateral = if kind == "Fallaway" then (if index == 2 then 29 else -29) elseif kind == "Shift" then -35 elseif kind == "Sweep" then -31 elseif kind=="Shuttle" and role=="Exit" then -17 else -25
			local exitLocal = source:GetAttribute("LocalExit") :: Vector3
			local height = if role == "Exit" then exitLocal.Y else 0
			local hostBank = source:FindFirstChild(if role == "Exit" then "ExitBank" else "EntryBank")
			local host = hostBank.BankContact :: BasePart
			local stacked = kind=="Foundry" or kind=="Domino"
			local position = cf:PointToWorldSpace(Vector3.new(if kind=="Foundry" then -12 elseif kind=="Domino" then -13 else point.X, height+6.8+(if stacked then (index-1)*7.6 else 0), lateral))
			local aim = Vector3.new(host.CFrame.Position.X,position.Y,host.CFrame.Position.Z)
			local signFrame = CFrame.lookAt(position,aim)
			if kind=="Shuttle" and role=="Exit" then
				local station=course.MapEnvironment.Wayfinding.CheckpointStation_R3
				signFrame=(station:GetAttribute("MountFrame") :: CFrame)*CFrame.new(0,9.2,0)
			end
			makeSign(group, source, plate, role, signFrame, source:GetAttribute("MechanismId") .. " " .. titles[kind] .. suffix)
			count += 1
			if kind == "Lift" then
				local exitHost=source.ExitBank.BankContact :: BasePart
				local exitPosition=cf:PointToWorldSpace(Vector3.new(exitLocal.X,exitLocal.Y+6.8,lateral))
				local liftExit=CFrame.lookAt(exitPosition,Vector3.new(exitHost.CFrame.Position.X,exitPosition.Y,exitHost.CFrame.Position.Z))
				makeSign(group, source, plate, "Exit", liftExit, source:GetAttribute("MechanismId") .. " SPRING LIFT / EXIT")
				count += 1
			end
			HazardIndicators.UpdatePlate(plate, false, false)
		end
	end
	group:SetAttribute("SignCount", count)
	return group
end

return HazardIndicators
