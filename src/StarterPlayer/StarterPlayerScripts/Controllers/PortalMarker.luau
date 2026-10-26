--!strict
-- Floating "Practice portal" sign over the lobby portal (brief "Lobby"). Client-only: it replaces
-- the server's plain RouteLabel on this player's screen and follows the lobby HUD's visibility.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PracticeConfig = require(ReplicatedStorage.Config.PracticeConfig)
local Kit = require(script.Parent.UiKit)

local Marker = {}
local billboard: BillboardGui? = nil
local sign: Frame? = nil
local shown = false

local function build(trigger: BasePart)
	local old = trigger:FindFirstChild("RouteLabel")
	if old and old:IsA("BillboardGui") then old.Enabled = false end
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size, gui.StudsOffset = "PracticePortalMarker", UDim2.fromOffset(220, 90), Vector3.new(0, 7, 0)
	gui.MaxDistance, gui.AlwaysOnTop, gui.LightInfluence, gui.ResetOnSpawn = 160, false, 0, false
	gui.Adornee, gui.ZIndexBehavior = trigger, Enum.ZIndexBehavior.Sibling
	local holder = Kit.Frame(gui, "Sign", UDim2.fromScale(1, 1), UDim2.new())
	local plate = Kit.SkyPlate(holder, "Plate", UDim2.fromOffset(200, 44), UDim2.new(.5, -100, 0, 4), {fill = "Navy", class = "S"})
	local label = Kit.Caption(Kit.Content(plate), "Label", "Practice portal", 18, Kit.White)
	label.FontFace, label.Size = Kit.Display, UDim2.fromScale(1, 1)
	local arrow = Kit.Icon(holder, "Arrow", Kit.Images.FallArrow, 30, Kit.Navy)
	arrow.AnchorPoint, arrow.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 52)
	gui.Parent = trigger
	billboard, sign = gui, holder
end

local function find(): BasePart?
	local folder = workspace:FindFirstChild(PracticeConfig.LobbyPortalName, true)
	local trigger = folder and folder:FindFirstChild("PortalTrigger")
	return if trigger and trigger:IsA("BasePart") then trigger else nil
end

function Marker.Init(visible: () -> boolean)
	local waited = 0
	local started = os.clock()
	RunService.Heartbeat:Connect(function(dt)
		waited += dt
		if not billboard or not billboard.Parent then
			if waited < 2 then return end
			waited = 0
			local trigger = find()
			if trigger then build(trigger) end
			return
		end
		local want = visible()
		if want ~= shown then
			shown = want
			;(billboard :: BillboardGui).Enabled = want
			if want and sign then Kit.Punch(sign, .01, .5) end
		end
		if shown and sign and Kit.Motion() then
			sign.Position = UDim2.fromOffset(0, math.sin((os.clock() - started) * 2.2) * 4)
		end
	end)
end

return Marker
