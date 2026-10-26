--!strict

local Players = game:GetService("Players")
local Builder = require(game:GetService("ServerStorage").CourseBuilders.LobbyBuilders.BlenderComparison)
local Service = {}
local context: any = nil
local lobby: Model? = nil
local cooldown: { [Player]: number } = {}

function Service.Init(services: any)
	context = services
	lobby = Builder.Ensure()
end

local function connectFallReturn(model: Instance?)
	if not model then return end
	local zone = model:FindFirstChild("LobbyFallReturn")
	local spawn = model:FindFirstChild("LobbySpawnPadMarker") or model:FindFirstChild("PreviewSpawn")
	if not zone or not zone:IsA("BasePart") or not spawn or not spawn:IsA("BasePart") then return end
	zone.Touched:Connect(function(part)
		local character = part:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if not player or not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return end
		if os.clock() - (cooldown[player] or 0) < 1 then return end
		local race = context.Services.RaceService
		local racers = context.Services.PlayerRaceService
		if race.IsRaceActive() and racers.IsOfficialRacer(player) then return end
		if math.abs(root.Position.Y-zone.Position.Y)>12 or (root.Position-zone.Position).Magnitude>120 then return end
		cooldown[player] = os.clock()
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		character:PivotTo(spawn.CFrame + Vector3.new(0,5,0))
	end)
end

function Service.Start()
	connectFallReturn(lobby)
	connectFallReturn(workspace:FindFirstChild("BlenderLobbyComparison"))
	Players.PlayerRemoving:Connect(function(player) cooldown[player] = nil end)
end

return Service
